/// App configuration with environment-aware values.
///
/// Use --dart-define to override at build time:
/// flutter build appbundle --release --dart-define=API_BASE_URL=https://your-api.com
class AppConfig {
  /// Base URL for API endpoints.
  ///
  /// Default: Vercel production API for development.
  /// Production: override via --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://travelapifresh-aw9m3822a-fitros-projects-1b98d7a0.vercel.app',
  );

  /// Full API endpoint base (Vercel routes all to /api via rewrites).
  static String get baseUrl => '$apiBaseUrl/api';

  /// Check if running in production mode.
  static bool get isProduction =>
      apiBaseUrl.contains('railway.app') || apiBaseUrl.contains('production');

  /// App version (read from pubspec at build time if needed).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}
