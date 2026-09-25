import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  try {
    const authHeader = request.headers.get('Authorization')
    const jwt = authHeader?.replace(/^Bearer\s+/i, '')
    if (!jwt) return json({ error: 'Authentication required' }, 401)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })

    const { data: authData, error: authError } = await admin.auth.getUser(jwt)
    if (authError || !authData.user) return json({ error: 'Invalid session' }, 401)

    const body = await request.json()
    const { client_order_id, side, coin_id, symbol, input_amount } = body
    if (
      typeof client_order_id !== 'string' ||
      !['buy', 'sell'].includes(side) ||
      typeof coin_id !== 'string' ||
      !/^[a-z0-9-]+$/.test(coin_id) ||
      typeof symbol !== 'string' ||
      typeof input_amount !== 'number' ||
      !Number.isFinite(input_amount) ||
      input_amount <= 0
    ) {
      return json({ error: 'Invalid trade request' }, 400)
    }

    const priceUrl = new URL('https://api.coingecko.com/api/v3/simple/price')
    priceUrl.searchParams.set('ids', coin_id)
    priceUrl.searchParams.set('vs_currencies', 'usd')
    priceUrl.searchParams.set('include_last_updated_at', 'true')
    const coinGeckoKey = Deno.env.get('COINGECKO_DEMO_API_KEY')
    const priceResponse = await fetch(priceUrl, {
      headers: coinGeckoKey ? { 'x-cg-demo-api-key': coinGeckoKey } : {},
    })
    if (!priceResponse.ok) return json({ error: 'Market price is unavailable' }, 503)

    const market = await priceResponse.json()
    const quote = market[coin_id]
    const price = Number(quote?.usd)
    const updatedAt = Number(quote?.last_updated_at ?? Math.floor(Date.now() / 1000))
    if (!Number.isFinite(price) || price <= 0) {
      return json({ error: 'Invalid market price' }, 503)
    }
    // Demo-tier market data can legitimately be cached for several minutes.
    // Reject unusually old quotes while allowing normal CoinGecko cache lag.
    if (Math.floor(Date.now() / 1000) - updatedAt > 600) {
      return json({ error: 'Market price is stale; try again shortly' }, 503)
    }

    // Buy input is USD; sell input is the number of coins.
    const amount = side === 'buy' ? input_amount / price : input_amount
    const { data, error } = await admin.rpc('execute_trade_trusted', {
      p_user_id: authData.user.id,
      p_client_order_id: client_order_id,
      p_side: side,
      p_coin_id: coin_id,
      p_symbol: symbol,
      p_amount: amount,
      p_price: price,
      p_price_timestamp: new Date(updatedAt * 1000).toISOString(),
    })
    if (error) {
      const safeMessage = error.message.includes('Insufficient')
        ? error.message
        : 'Trade could not be completed'
      return json({ error: safeMessage }, 400)
    }
    return json({ transaction: data })
  } catch (error) {
    console.error(error)
    return json({ error: 'Unexpected server error' }, 500)
  }
})
