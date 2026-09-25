const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=30',
    },
  })

let cache: { expiresAt: number; body: unknown } | null = null

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (request.method !== 'GET' && request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  if (cache && cache.expiresAt > Date.now()) return json(cache.body)

  try {
    const url = new URL('https://api.coingecko.com/api/v3/coins/markets')
    url.searchParams.set('vs_currency', 'usd')
    url.searchParams.set('order', 'market_cap_desc')
    url.searchParams.set('per_page', '100')
    url.searchParams.set('page', '1')
    url.searchParams.set('sparkline', 'true')
    url.searchParams.set('price_change_percentage', '24h')

    const apiKey = Deno.env.get('COINGECKO_DEMO_API_KEY')
    const response = await fetch(url, {
      headers: apiKey ? { 'x-cg-demo-api-key': apiKey } : {},
    })
    if (!response.ok) {
      console.error('CoinGecko status', response.status)
      return json({ error: 'Market data is temporarily unavailable' }, 503)
    }

    const raw = await response.json()
    const coins = raw.map((coin: Record<string, unknown>) => ({
      id: coin.id,
      name: coin.name,
      symbol: String(coin.symbol ?? '').toUpperCase(),
      price: coin.current_price,
      change24h: coin.price_change_percentage_24h ?? 0,
      image: coin.image,
      marketCap: coin.market_cap,
      volume24h: coin.total_volume,
      high24h: coin.high_24h,
      low24h: coin.low_24h,
      lastUpdated: coin.last_updated,
      sparkline: (coin.sparkline_in_7d as { price?: number[] } | null)?.price ?? [],
    }))
    const body = { coins, fetchedAt: new Date().toISOString() }
    cache = { expiresAt: Date.now() + 30_000, body }
    return json(body)
  } catch (error) {
    console.error(error)
    return json({ error: 'Unexpected market data error' }, 500)
  }
})
