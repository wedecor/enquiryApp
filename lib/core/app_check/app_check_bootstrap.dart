import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../logging/logger.dart';
import 'web_debug_token_stub.dart' if (dart.library.js_interop) 'web_debug_token_web.dart';

/// App Check in MONITOR mode (docs/APP_CHECK_AND_QUERY_REVIEW.md).
///
/// Activated before the first callable so requests carry a token when one can
/// be obtained. Nothing enforces it: every function keeps `enforceAppCheck:
/// false`, and Firestore / Storage enforcement stays off in the console, so a
/// device that cannot attest (e.g. the sideloaded APK and Play Integrity) keeps
/// working. Watch the App Check metrics in the Firebase console before any
/// enforcement decision.
///
/// * Android: Play Integrity in release builds, the debug provider otherwise.
/// * Web: reCAPTCHA Enterprise, only when a site key is supplied at build time
///   (`--dart-define=APP_CHECK_RECAPTCHA_SITE_KEY=...`); no key is built in.
///   Debug web builds also enable the App Check debug token.
/// * Anything that fails is logged once and the app continues.
class AppCheckBootstrap {
  const AppCheckBootstrap._();

  static const String webSiteKey = String.fromEnvironment('APP_CHECK_RECAPTCHA_SITE_KEY');

  static bool _activated = false;
  static bool _loggedProblem = false;

  /// Never throws.
  static Future<void> activate() async {
    if (_activated) return;
    try {
      if (kIsWeb) {
        if (webSiteKey.isEmpty) {
          _logOnce('App Check: no web reCAPTCHA Enterprise site key configured; not activated');
          return;
        }
        if (!kReleaseMode) enableWebAppCheckDebugToken();
        await FirebaseAppCheck.instance
            .activate(providerWeb: ReCaptchaEnterpriseProvider(webSiteKey))
            .timeout(const Duration(seconds: 5));
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await FirebaseAppCheck.instance
            .activate(
              providerAndroid: kReleaseMode
                  ? const AndroidPlayIntegrityProvider()
                  : const AndroidDebugProvider(),
            )
            .timeout(const Duration(seconds: 5));
      } else {
        // No iOS / desktop target ships; nothing to activate.
        return;
      }
      _activated = true;
      Log.i('App Check activated (monitor only)', data: {'release': kReleaseMode});
      if (kReleaseMode) unawaited(_probeAttestation());
    } catch (e) {
      _logOnce('App Check: activation failed; continuing without it', e);
    }
  }

  /// One token fetch so an attestation problem (e.g. Play Integrity on a
  /// sideloaded APK) is logged once instead of silently on every call.
  static Future<void> _probeAttestation() async {
    try {
      await FirebaseAppCheck.instance.getToken().timeout(const Duration(seconds: 10));
    } catch (e) {
      _logOnce('App Check: device could not attest; requests continue without a token', e);
    }
  }

  static void _logOnce(String message, [Object? error]) {
    if (_loggedProblem) return;
    _loggedProblem = true;
    Log.w(message, data: {if (error != null) 'error': error.runtimeType.toString()});
  }
}
