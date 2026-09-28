# CryptoSim

Flutter crypto paper-trading app for Android, iOS and web. It uses Supabase for authentication and portfolio storage, with server-side trade execution and live CoinGecko market data. When Supabase is not configured, the app can still run with local in-memory data for development and tests.

## Included

- Google OAuth and anonymous Demo authentication through Supabase Auth
- Portfolio balance, holdings and P&L
- Top-100 searchable market list with live prices and sparklines
- Buy/sell sheet with percentage shortcuts and validation
- Atomic server-side buy/sell execution, average-cost calculation and synchronized trade history
- Dark/light themes, account reset and logout
- Supabase PostgreSQL schema, RLS policies and trusted RPC functions
- CoinGecko requests proxied through Supabase Edge Functions so API secrets are not shipped in the app

## Run

Flutter is installed at `C:\flutter` on the current machine but is not yet visible in this terminal's PATH.

```powershell
& 'C:\flutter\bin\flutter.bat' pub get
& 'C:\flutter\bin\flutter.bat' run --dart-define-from-file=config/supabase.local.json
```

## Backend connection

1. Create a Supabase project and apply `supabase/migrations/001_initial_schema.sql` in the SQL Editor.
2. Enable Google and Anonymous providers in Supabase Auth.
3. Copy `config/supabase.example.json` to `config/supabase.local.json` and fill in the Project URL and publishable key from the Supabase Connect dialog.
4. Add `app.cryptosim.cryptosim://login-callback/` to Authentication > URL Configuration > Redirect URLs.
5. Deploy the trusted trade function and set its CoinGecko secret:

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set COINGECKO_DEMO_API_KEY=YOUR_KEY
supabase functions deploy execute-trade
supabase functions deploy market-data
```

6. Run with the local configuration:

```powershell
& 'C:\flutter\bin\flutter.bat' run --dart-define-from-file=config/supabase.local.json
```

When configured, authentication, portfolio reads, history, reset, live market data and trade execution use Supabase. Without the file, the app keeps working in local mock mode.

## Tests

```powershell
& 'C:\flutter\bin\flutter.bat' analyze
& 'C:\flutter\bin\flutter.bat' test
```

The test suite covers login state, buying, selling, balance validation, account reset and the demo navigation flow.

Never ship a CoinGecko secret or a Supabase service-role key inside the Flutter app.
