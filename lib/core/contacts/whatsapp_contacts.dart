import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/confirmation_dialog.dart';
import '../logging/logger.dart';
import 'contact_launcher.dart';
import 'customer_contact_draft.dart';

export 'customer_contact_draft.dart';

/// Outcome of an explicit staff "Save contact" tap.
enum StaffSaveContactResult { saved, alreadySaved, permissionDenied, failed, unsupported }

/// Device contacts permission + prefs for saving customers on this phone.
///
/// Numbers stay on this phone only (null account). Permission is asked once
/// with an explanation; if refused we never auto-prompt again — staff can
/// re-enable via Settings → Preferences.
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
  static bool? debugIsAndroid;

  @visibleForTesting
  static void debugReset() {
    debugInvoker = null;
    debugIsAndroid = null;
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
    if (!_isAndroid) return false;
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

  /// True if [phone] is already on this device's contacts.
  static Future<bool> isInContacts(String phone) async {
    if (!_isAndroid) return false;
    try {
      final result = await _invoke('isInContacts', {'phone': phone});
      return result == true;
    } on PlatformException catch (e) {
      Log.w('WhatsAppContacts: isInContacts failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Inserts a device-only contact. Never updates existing rows.
  static Future<bool> saveContact({required String name, required String phone}) async {
    if (!_isAndroid) return false;
    try {
      final result = await _invoke('saveContact', {'name': name, 'phone': phone});
      return result == true;
    } on PlatformException catch (e) {
      Log.w('WhatsAppContacts: saveContact failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Device-contact label: `{name} – We Decor` or `{name} – We Decor · 12 Jan 2026`.
  static String contactDisplayName(String? fullName, {DateTime? eventDate}) {
    final n = (fullName ?? '').trim();
    final base = n.isEmpty ? 'We Decor customer' : '$n – We Decor';
    final dateBit = _contactDateSuffix(eventDate);
    if (dateBit.isEmpty) return base;
    return '$base · $dateBit';
  }

  static String _contactDateSuffix(DateTime? eventDate) {
    if (eventDate == null || eventDate.year <= 1971) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${eventDate.day} ${months[eventDate.month - 1]} ${eventDate.year}';
  }

  /// Best-effort: if permitted and the number is not already saved, insert a
  /// device-only contact. Never throws; enquiry save must not depend on this.
  ///
  /// Prefers [whatsappPhone] when set, otherwise [customerPhone].
  static Future<bool> saveCustomerIfNeeded({
    BuildContext? context,
    required String customerName,
    required String customerPhone,
    String? whatsappPhone,
    DateTime? eventDate,
    ContactLauncher? launcher,
  }) async {
    if (!_isAndroid) return false;
    try {
      final canUse = await ensurePermission((context != null && context.mounted) ? context : null);
      if (!canUse) return false;

      final raw = (whatsappPhone ?? '').trim().isNotEmpty
          ? whatsappPhone!.trim()
          : customerPhone.trim();
      if (raw.isEmpty) return false;

      final digits = (launcher ?? ContactLauncher()).toWhatsAppDigits(raw);
      if (digits.length < 11 || digits.length > 15) {
        Log.w(
          'WhatsAppContacts: refusing weak digits for contact save',
          data: {'len': digits.length},
        );
        return false;
      }

      if (await isInContacts(digits)) return true;

      final name = contactDisplayName(customerName, eventDate: eventDate);
      return saveContact(name: name, phone: digits);
    } catch (e) {
      Log.w('WhatsAppContacts: saveCustomerIfNeeded failed', data: {'error': e.toString()});
      return false;
    }
  }

  /// Staff tapped **Save contact** — always prompts for permission if needed
  /// ([ensurePermission] with `explicit: true`), then saves or reports status.
  static Future<StaffSaveContactResult> saveCustomerFromButton({
    required BuildContext context,
    required String customerName,
    required String customerPhone,
    String? whatsappPhone,
    DateTime? eventDate,
    ContactLauncher? launcher,
  }) async {
    if (!_isAndroid) return StaffSaveContactResult.unsupported;
    try {
      if (!context.mounted) return StaffSaveContactResult.failed;
      final canUse = await ensurePermission(context, explicit: true);
      if (!canUse) return StaffSaveContactResult.permissionDenied;

      final raw = (whatsappPhone ?? '').trim().isNotEmpty
          ? whatsappPhone!.trim()
          : customerPhone.trim();
      if (raw.isEmpty) return StaffSaveContactResult.failed;

      final digits = (launcher ?? ContactLauncher()).toWhatsAppDigits(raw);
      if (digits.length < 11 || digits.length > 15) {
        Log.w('WhatsAppContacts: saveFromButton weak digits', data: {'len': digits.length});
        return StaffSaveContactResult.failed;
      }

      if (await isInContacts(digits)) return StaffSaveContactResult.alreadySaved;

      final name = contactDisplayName(customerName, eventDate: eventDate);
      final ok = await saveContact(name: name, phone: digits);
      return ok ? StaffSaveContactResult.saved : StaffSaveContactResult.failed;
    } catch (e) {
      Log.w('WhatsAppContacts: saveCustomerFromButton failed', data: {'error': e.toString()});
      return StaffSaveContactResult.failed;
    }
  }

  static String messageFor(StaffSaveContactResult result) {
    switch (result) {
      case StaffSaveContactResult.saved:
        return 'Contact saved on this phone. You can open WhatsApp now.';
      case StaffSaveContactResult.alreadySaved:
        return 'Contact already saved on this phone.';
      case StaffSaveContactResult.permissionDenied:
        return 'Contacts permission is needed to save the number.';
      case StaffSaveContactResult.failed:
        return 'Could not save contact. Check the number and try again.';
      case StaffSaveContactResult.unsupported:
        return 'Saving contacts works on Android phones.';
    }
  }

  /// True when contacts can be used (feature on + permission).
  ///
  /// Shows the explanation dialog the first time, then the system prompt.
  /// Returns false without prompting when the feature is off or previously denied.
  ///
  /// [explicit]: staff tapped Sync (or similar) — ignore the master switch and
  /// previous denial so they can grant permission again.
  static Future<bool> ensurePermission(BuildContext? context, {bool explicit = false}) async {
    if (!_isAndroid) return false;
    if (!explicit && !await isFeatureEnabled()) return false;
    if (await hasPermission()) return true;
    if (!explicit && await wasDenied()) return false;

    if (context == null || !context.mounted) return false;

    final proceed = await ConfirmationDialog.show(
      context: context,
      title: 'Save to contacts?',
      message: explicit
          ? 'We Decor needs contacts permission to save customer numbers on '
                'this phone. They stay on this phone only.'
          : 'We Decor can save the customer\'s number in this phone\'s contacts '
                '(for example when you save an enquiry). They stay on this phone only.',
      confirmText: 'Continue',
      cancelText: 'Not now',
      icon: Icons.contact_page_outlined,
    );
    if (!proceed) {
      if (!explicit) await _markDenied();
      return false;
    }

    final granted = await _requestPermissionNative();
    if (!granted) await _markDenied();
    if (granted && explicit) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(prefDenied);
      } catch (_) {}
    }
    return granted;
  }

  /// Dedupes [customers] by WhatsApp digits (prefer later usable event date,
  /// then non-empty name). Invalid phones are dropped.
  static List<CustomerContactDraft> dedupeCustomers(
    Iterable<CustomerContactDraft> customers, {
    ContactLauncher? launcher,
  }) {
    final launch = launcher ?? ContactLauncher();
    final byDigits = <String, CustomerContactDraft>{};
    for (final raw in customers) {
      final phone = raw.preferredPhone;
      if (phone.isEmpty) continue;
      final digits = launch.toWhatsAppDigits(phone);
      if (digits.length < 11 || digits.length > 15) continue;
      final next = CustomerContactDraft(
        customerName: raw.customerName,
        customerPhone: raw.customerPhone,
        whatsappPhone: raw.whatsappPhone,
        eventDate: raw.eventDate,
        digits: digits,
      );
      final prev = byDigits[digits];
      if (prev == null || _draftWins(next, prev)) {
        byDigits[digits] = next;
      }
    }
    return byDigits.values.toList(growable: false);
  }

  static bool _draftWins(CustomerContactDraft a, CustomerContactDraft b) {
    final aDate = _usableEventDate(a.eventDate);
    final bDate = _usableEventDate(b.eventDate);
    if (aDate != null && bDate != null) {
      final cmp = aDate.compareTo(bDate);
      if (cmp != 0) return cmp > 0;
    } else if (aDate != null) {
      return true;
    } else if (bDate != null) {
      return false;
    }
    final aName = a.customerName.trim();
    final bName = b.customerName.trim();
    if (aName.isNotEmpty && bName.isEmpty) return true;
    if (aName.isEmpty && bName.isNotEmpty) return false;
    return aName.length >= bName.length;
  }

  static DateTime? _usableEventDate(DateTime? eventDate) {
    if (eventDate == null || eventDate.year <= 1971) return null;
    return eventDate;
  }

  /// Saves missing customers as device contacts. Never throws.
  ///
  /// Pass already-deduped drafts when the UI showed a count first. When
  /// [assumePermission] is true, skips the permission prompt (caller already
  /// called [ensurePermission]).
  static Future<CustomerContactSyncResult> syncCustomersToDevice({
    required BuildContext context,
    required List<CustomerContactDraft> customers,
    ContactLauncher? launcher,
    void Function(int done, int total)? onProgress,
    bool assumePermission = false,
  }) async {
    if (!_isAndroid) {
      return const CustomerContactSyncResult(saved: 0, alreadyOnPhone: 0, failed: 0);
    }
    if (!context.mounted) {
      return const CustomerContactSyncResult(saved: 0, alreadyOnPhone: 0, failed: 0);
    }

    if (!assumePermission) {
      final canUse = await ensurePermission(context, explicit: true);
      if (!canUse || !context.mounted) {
        return const CustomerContactSyncResult(
          saved: 0,
          alreadyOnPhone: 0,
          failed: 0,
          permissionDenied: true,
        );
      }
    }

    final unique = dedupeCustomers(customers, launcher: launcher);
    var saved = 0;
    var already = 0;
    var failed = 0;
    final total = unique.length;

    for (var i = 0; i < unique.length; i++) {
      final draft = unique[i];
      final digits =
          draft.digits ?? (launcher ?? ContactLauncher()).toWhatsAppDigits(draft.preferredPhone);
      onProgress?.call(i, total);
      try {
        if (await isInContacts(digits)) {
          already++;
          continue;
        }
        final name = contactDisplayName(draft.customerName, eventDate: draft.eventDate);
        final ok = await saveContact(name: name, phone: digits);
        if (ok) {
          saved++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
        Log.w('WhatsAppContacts: sync item failed', data: {'error': e.toString()});
      }
    }
    onProgress?.call(total, total);
    return CustomerContactSyncResult(saved: saved, alreadyOnPhone: already, failed: failed);
  }

  static bool get _isAndroid =>
      debugIsAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static Future<Object?> _invoke(String method, [Map<String, Object?>? args]) {
    final override = debugInvoker;
    if (override != null) return override(method, args);
    return _channel.invokeMethod<Object?>(method, args);
  }
}
