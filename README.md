# CryptoSim

Flutter MVP for a crypto paper-trading app. The current build is UI-first and uses in-memory demo data so every screen and trade interaction can be tested before connecting external services.

## Included

- Google/Demo entry screen (Google button is currently a UI stub)
- Portfolio balance, holdings and P&L
- Searchable market list with sparklines
- Buy/sell sheet with percentage shortcuts and validation
- Average-cost calculation and synchronized trade history
- Dark/light themes, account reset and logout
- Supabase schema, RLS and trusted atomic trade function

## Run

Flutter is installed at `C:\flutter` on the current machine but is not yet visible in this terminal's PATH.

```powershell
& 'C:\flutter\bin\flutter.bat' pub get
& 'C:\flutter\bin\flutter.bat' run
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
```

6. Run with the local configuration:

```powershell
& 'C:\flutter\bin\flutter.bat' run --dart-define-from-file=config/supabase.local.json
```

When configured, Auth, portfolio reads, history, reset and trade execution use Supabase. Without the file, the app keeps working in local mock mode.

Never ship a CoinGecko secret or a Supabase service-role key inside the Flutter app.
