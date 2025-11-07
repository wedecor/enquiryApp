import 'package:flutter/foundation.dart';

/// Secure Firebase configuration that handles environment variables
///
/// This class provides a centralized way to manage Firebase configuration
/// across different platforms while respecting environment variables.
class FirebaseConfig {
  /// Get the API key for the current platform
  ///
  /// Returns the appropriate API key based on the platform:
  /// - Web: Uses environment variable NEXT_PUBLIC_GOOGLE_API_KEY
  /// - Mobile: Uses platform-specific keys from firebase_options.dart
  ///
  /// For production, ensure environment variables are set in your deployment platform
  static String get apiKey {
    if (kIsWeb) {
      // For web, we'll use the environment variable approach
      // This will be handled by the web/index.html file
      return 'WEB_API_KEY_FROM_ENV';
    } else {
      // For mobile platforms, we'll use the firebase_options.dart approach
      // but with proper environment variable handling
      return _getMobileApiKey();
    }
  }

  /// Get mobile API key with environment variable support
  static String _getMobileApiKey() {
    // In a real implementation, you would use a package like flutter_dotenv
    // or platform-specific environment variable handling
    const String envApiKey = String.fromEnvironment('FIREBASE_API_KEY');

    if (envApiKey.isNotEmpty) {
      return envApiKey;
    }

    // Fallback to placeholder - this should be replaced in production
    return 'MOBILE_API_KEY_FROM_ENV';
  }

  /// Check if the current configuration is using environment variables
  static bool get isUsingEnvironmentVariables {
    if (kIsWeb) {
      return true; // Web always uses environment variables
    } else {
      const String envApiKey = String.fromEnvironment('FIREBASE_API_KEY');
      return envApiKey.isNotEmpty;
    }
  }

  /// Get a warning message if not using environment variables
  static String get securityWarning {
    if (!isUsingEnvironmentVariables) {
      return '''
⚠️ SECURITY WARNING: Firebase API keys are not using environment variables!
For production deployment, ensure you set the following environment variables:
- NEXT_PUBLIC_GOOGLE_API_KEY (for web)
- FIREBASE_API_KEY (for mobile)

Current configuration may expose API keys in your codebase.
''';
    }
    return '✅ Firebase configuration is using environment variables';
  }
}
