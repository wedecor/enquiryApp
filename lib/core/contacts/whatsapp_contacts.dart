import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/confirmation_dialog.dart';
import '../logging/logger.dart';

/// Device contacts permission + prefs for one-tap WhatsApp card sends.
///
/// Numbers saved by the app stay on this phone only (null account). Permission
/// is asked once with an explanation; if refused we never auto-prompt again —
/// staff can re-enable via Settings → Preferences.
class WhatsAppContacts {
  WhatsAppContacts._();

  static const MethodChannel _channel = MethodChannel('wedecor/whatsapp');

  /// Master switch (Settings). Default on.
  @visibleForTesting
  static const prefEnabled = 'whatsapp_share.save_customers_to_contacts';

  /// Set when the user denies the system prompt (or dismisses the explanation).
  @visibleForTesting
  static const prefDenied = 'whatsapp_share.contacts_permission_denied';

  @visibleForTesting
  static Future<Object?> Function(String method, Map<String, Object?>? args)? debugInvoker;

  @visibleForTesting
  static void debugReset() {
    debugInvoker = null;
  }

  static Future<bool> isFeatureEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setFeatureEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefEnabled, enabled);
      if (enabled) {
        // Allow asking again after staff turns the switch back on.
        await prefs.remove(prefDenied);
      }
    } catch (_) {}
  }

  static Future<bool> wasDenied() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefDenied) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markDenied() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefDenied, true);
    } catch (_) {}
  }

  static Future<bool> hasPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _invoke('hasContactsPermission');
      return result == true;
    } on PlatformException catch (e) {
      Log.w('WhatsAppContacts: hasPermission failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> _requestPermissionNative() async {
    try {
      final result = await _invoke('requestContactsPermission');
      return result == true;
    } on PlatformException catch (e) {
      Log.w('WhatsAppContacts: requestPermission failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// True when contacts can be used for this send (feature on + permission).
  ///
  /// Shows the explanation dialog the first time, then the system prompt.
  /// Returns false without prompting when the feature is off or previously denied.
  static Future<bool> ensurePermission(BuildContext? context) async {
    if (!_isAndroid) return false;
    if (!await isFeatureEnabled()) return false;
    if (await hasPermission()) return true;
    if (await wasDenied()) return false;

    if (context == null || !context.mounted) return false;

    final proceed = await ConfirmationDialog.show(
      context: context,
      title: 'Save to contacts?',
      message:
          'To send the card straight to the customer\'s chat, We Decor saves '
          'their number in this phone\'s contacts. They stay on this phone only.',
      confirmText: 'Continue',
      cancelText: 'Not now',
      icon: Icons.contact_page_outlined,
    );
    if (!proceed) {
      await _markDenied();
      return false;
    }

    final granted = await _requestPermissionNative();
    if (!granted) await _markDenied();
    return granted;
  }

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<Object?> _invoke(String method, [Map<String, Object?>? args]) {
    final override = debugInvoker;
    if (override != null) return override(method, args);
    return _channel.invokeMethod<Object?>(method, args);
  }
}
