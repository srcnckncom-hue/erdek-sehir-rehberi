/// Derleme zamanı ayarları.
///
/// Değerler `--dart-define-from-file=config/env.json` ile gelir.
/// config/env.json repo'ya GİRMEZ; CI'da GitHub Secrets'tan
/// scripts/make_env.sh ile üretilir. Yerel/CI kontrol derlemesi için
/// config/env.example.json kullanılır (sahte değerler).
abstract final class Env {
  /// dev | prod
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// GitHub Pages kök adresi, ör. `https://<kullanici>.github.io/<repo>`
  /// Uzaktan JSON'lar `$dataBaseUrl/data/...` altından okunur.
  static const dataBaseUrl = String.fromEnvironment('DATA_BASE_URL');

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// anon anahtar gizli değildir (RLS ile korunur) ama yine de repo'ya
  /// gömülmez; ortama göre değiştirilebilsin diye buradan okunur.
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// MET Norway hava durumu API'si, iletişim bilgisi içeren bir
  /// User-Agent zorunlu tutuyor (kullanım koşulları).
  static const weatherUserAgent = String.fromEnvironment('WEATHER_USER_AGENT');

  static bool get isProd => appEnv == 'prod';
}
