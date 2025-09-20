/// Application configuration using compile-time environment variables.
/// 
/// Use with --dart-define flags:
/// flutter build apk --dart-define=APP_ENV=prod --dart-define=ENABLE_CRASHLYTICS=true
class AppConfig {
  /// Current environment (dev, staging, prod)
  static const String env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  
  /// API base URL for backend services
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  
  /// Feature flags
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
  static const bool enableCrashlytics = bool.fromEnvironment('ENABLE_CRASHLYTICS', defaultValue: false);
  static const bool enablePerformance = bool.fromEnvironment('ENABLE_PERFORMANCE', defaultValue: false);
  
  /// Debug features
  static const bool enableDebugLogs = bool.fromEnvironment('ENABLE_DEBUG_LOGS', defaultValue: true);
  
  /// Environment helpers
  static bool get isDev => env == 'dev';
  static bool get isStaging => env == 'staging';
  static bool get isProd => env == 'prod';
  
  /// Legal URLs (to be configured per environment)
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL', 
    defaultValue: 'https://your-domain.com/privacy-policy',
  );
  
  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL', 
    defaultValue: 'https://your-domain.com/terms-of-service',
  );
  
  /// Support contact
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL', 
    defaultValue: 'support@your-domain.com',
  );
}
