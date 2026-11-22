import 'package:flutter/foundation.dart';

/// EventOS API configuration (M5-01 bridge). Disabled when [apiBaseUrl] is empty.
///
/// Pass at build time:
///   --dart-define=EVENTOS_API_URL=https://eventos-api-staging-….run.app
class EventosConfig {
  const EventosConfig._();

  /// Base URL without trailing slash. Empty = EventOS client disabled.
  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'EVENTOS_API_URL',
    defaultValue: '',
  );

  /// Test-only override (never set in production code).
  @visibleForTesting
  static String? debugApiBaseUrlOverride;

  static String get apiBaseUrl =>
      (debugApiBaseUrlOverride ?? _apiBaseUrlDefine).trim();

  static bool get isConfigured => apiBaseUrl.isNotEmpty;

  /// Release builds require https://; otherwise EventOS is force-disabled.
  static bool get isEnabled {
    final url = apiBaseUrl;
    if (url.isEmpty) return false;
    if (kReleaseMode && !url.startsWith('https://')) return false;
    return true;
  }

  static String get environmentLabel {
    final url = apiBaseUrl.toLowerCase();
    if (url.isEmpty) return 'disabled';
    if (url.contains('staging') || url.contains('-staging')) return 'staging';
    if (url.contains('localhost') || url.contains('127.0.0.1')) return 'local';
    return 'production';
  }

  static String path(String relative) {
    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = relative.startsWith('/') ? relative : '/$relative';
    return '$base$path';
  }
}
