class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'app.cryptosim.cryptosim://login-callback/',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
