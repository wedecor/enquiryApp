import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

/// Service for managing user consent for analytics and data collection
/// GDPR-compliant with opt-in approach
class ConsentService {
  static const String _analyticsConsentKey = 'analytics_consent';
  static const String _crashlyticsConsentKey = 'crashlytics_consent';

  static ConsentService? _instance;
  static ConsentService get instance => _instance ??= ConsentService._();
  ConsentService._();

  SharedPreferences? _prefs;

  /// Initialize the consent service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if user has consented to analytics
  bool get hasAnalyticsConsent {
    if (_prefs == null) return false;
    return _prefs!.getBool(_analyticsConsentKey) ?? false;
  }

  /// Check if user has consented to crash reporting
  bool get hasCrashlyticsConsent {
    if (_prefs == null) return false;
    return _prefs!.getBool(_crashlyticsConsentKey) ?? false;
  }

  /// Set analytics consent
  Future<void> setAnalyticsConsent(bool consent) async {
    await _prefs?.setBool(_analyticsConsentKey, consent);
    await _updateAnalyticsCollection(consent);
  }

  /// Set crashlytics consent
  Future<void> setCrashlyticsConsent(bool consent) async {
    await _prefs?.setBool(_crashlyticsConsentKey, consent);
    // Note: Crashlytics consent is set at app startup, requires restart to change
  }

  /// Update Firebase Analytics collection based on consent
  Future<void> _updateAnalyticsCollection(bool enabled) async {
    if (AppConfig.enableAnalytics) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);

      if (enabled) {
        // Set user properties for analytics
        await FirebaseAnalytics.instance.setUserProperty(name: 'user_type', value: 'business_user');
        await FirebaseAnalytics.instance.logEvent(name: 'analytics_consent_granted');
      } else {
        await FirebaseAnalytics.instance.logEvent(name: 'analytics_consent_revoked');
      }
    }
  }

  /// Show consent dialog for new users (GDPR compliance)
  Future<bool> shouldShowConsentDialog() async {
    if (_prefs == null) return false;

    // Show consent dialog if user hasn't made a choice yet
    final hasSeenDialog = _prefs!.getBool('has_seen_consent_dialog') ?? false;
    return !hasSeenDialog;
  }

  /// Mark that user has seen the consent dialog
  Future<void> markConsentDialogSeen() async {
    await _prefs?.setBool('has_seen_consent_dialog', true);
  }

  /// Initialize analytics with current consent state
  Future<void> initializeAnalytics() async {
    if (AppConfig.enableAnalytics && hasAnalyticsConsent) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

      // Log app open event
      await FirebaseAnalytics.instance.logEvent(
        name: 'app_open',
        parameters: {'environment': AppConfig.env, 'platform': defaultTargetPlatform.name},
      );
    }
  }

  /// Log analytics event (only if consented)
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (AppConfig.enableAnalytics && hasAnalyticsConsent) {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    }
  }

  /// Log screen view (only if consented)
  Future<void> logScreenView(String screenName) async {
    if (AppConfig.enableAnalytics && hasAnalyticsConsent) {
      await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    }
  }
}
