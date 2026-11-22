import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/primitives/primitives.dart';
import '../logging/logger.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'contact_launcher.dart';
import 'whatsapp_contacts.dart';
import 'whatsapp_package_sheet.dart';

/// Result of an Android card share to a customer's WhatsApp chat.
enum WhatsAppDirectShareResult {
  /// The customer's chat opened with the card attached (staff tap Send in WhatsApp).
  opened,

  /// Chat opened with the message only (no card) — new / unknown numbers, or
  /// card intent failed as a last resort.
  textOnly,

  /// User dismissed the WhatsApp / Business sheet — do not fall back.
  cancelled,

  /// Channel unavailable, bad digits, or no WhatsApp installed — caller may fall back.
  unavailable,
}

typedef WhatsAppChannelInvoker =
    Future<Object?> Function(String method, Map<String, Object?>? args);
typedef WhatsAppPermissionGate = Future<bool> Function(BuildContext? context);

/// Android WhatsApp handoff for customer cards / enquiry messages.
///
/// One tap only (no share-sheet second step). Knowledge is **per device**:
/// * **First open on this phone** (unknown) → save contact (if allowed) +
///   Click-to-Chat **text only** (number always attached, no image).
/// * **Later opens** (known) → card + caption (`jid`).
class WhatsAppDirectShare {
  WhatsAppDirectShare._();

  static const MethodChannel _channel = MethodChannel('wedecor/whatsapp');
  static const _prefLastPkg = 'whatsapp_share.last_pkg';

  /// `package|digits` of chats this device has sent a card to.
  /// v3 clears entries from 2.0.48 that marked chats "known" after an empty
  /// jid open (no text, no image).
  @visibleForTesting
  static const prefKnownChats = 'whatsapp_share.known_chats_v3';
  static const int _maxKnownChats = 2000;

  /// How long to wait after saving a contact before opening WhatsApp.
  static const Duration contactPrepareDelay = Duration(seconds: 5);

  @visibleForTesting
  static WhatsAppChannelInvoker? debugInvoker;
  @visibleForTesting
  static WhatsAppPermissionGate? debugEnsurePermission;
  @visibleForTesting
  static bool? debugIsAndroid;
  @visibleForTesting
  static Duration? debugPrepareDelay;

  @visibleForTesting
  static void debugReset() {
    debugInvoker = null;
    debugEnsurePermission = null;
    debugIsAndroid = null;
    debugPrepareDelay = null;
  }

  static bool get _isAndroid =>
      debugIsAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static Duration get _prepareDelay => debugPrepareDelay ?? contactPrepareDelay;

  /// Shares [png] + [text] to [phone]'s chat on Android. See class docs.
  ///
  /// [customerFullName] / [eventDate] build the device contact display name:
  /// `{name} – We Decor · 12 Jan 2026` (date omitted when missing/unusable).
  static Future<WhatsAppDirectShareResult> shareImageToChat({
    required ContactLauncher launcher,
    required String phone,
    required String text,
    Uint8List? png,
    BuildContext? context,
    String? customerFullName,
    DateTime? eventDate,
    @Deprecated('Use customerFullName') String? customerFirstName,
  }) async {
    if (!_isAndroid) return WhatsAppDirectShareResult.unavailable;

    final digits = launcher.toWhatsAppDigits(phone);
    if (digits.length < 11 || digits.length > 15) {
      Log.w('WhatsAppDirectShare: refusing weak jid digits', data: {'len': digits.length});
      return WhatsAppDirectShareResult.unavailable;
    }

    final pick = await _resolvePackage(context);
    if (pick.cancelled) return WhatsAppDirectShareResult.cancelled;
    final pkg = pick.package;
    if (pkg == null) return WhatsAppDirectShareResult.unavailable;

    final known = await isKnownChat(pkg, digits);

    // Later opens on THIS phone + card: image + caption.
    final cardPng = png;
    if (cardPng != null && cardPng.isNotEmpty && known) {
      final sent = await _sendCard(png: cardPng, digits: digits, text: text, pkg: pkg);
      if (sent) {
        await _rememberChat(pkg, digits);
        return WhatsAppDirectShareResult.opened;
      }
      Log.w('WhatsAppDirectShare: card intent failed for known chat');
      return WhatsAppDirectShareResult.unavailable;
    }

    // First open on this phone: save contact + text only (no image / no forward sheet).
    final prepContext = (context != null && context.mounted) ? context : null;
    await _prepareContactIfAllowed(
      // ignore: use_build_context_synchronously
      context: prepContext,
      digits: digits,
      customerFullName: customerFullName,
      eventDate: eventDate,
      // Click-to-Chat does not need WhatsApp to index the contact first.
      waitAfterSave: false,
      explicitPermission: true,
    );

    final chatOpened = await _openChat(digits: digits, text: text, pkg: pkg);
    if (!chatOpened) {
      Log.w('WhatsAppDirectShare: click-to-chat failed');
      return WhatsAppDirectShareResult.unavailable;
    }
    // Next tap on this phone can attach the card.
    await _rememberChat(pkg, digits);
    return WhatsAppDirectShareResult.textOnly;
  }

  static Future<void> _prepareContactIfAllowed({
    required BuildContext? context,
    required String digits,
    required String? customerFullName,
    DateTime? eventDate,
    bool waitAfterSave = true,
    bool explicitPermission = false,
  }) async {
    final gate = debugEnsurePermission;
    final canUse = gate != null
        ? await gate((context != null && context.mounted) ? context : null)
        : await WhatsAppContacts.ensurePermission(
            (context != null && context.mounted) ? context : null,
            explicit: explicitPermission,
          );
    if (!canUse) return;

    final already = await WhatsAppContacts.isInContacts(digits);
    if (already) return;

    final displayName = WhatsAppContacts.contactDisplayName(customerFullName, eventDate: eventDate);
    final saved = await WhatsAppContacts.saveContact(name: displayName, phone: digits);
    if (!saved) {
      Log.w('WhatsAppDirectShare: saveContact failed; continuing with click-to-chat');
      return;
    }
    if (waitAfterSave) {
      final waitContext = (context != null && context.mounted) ? context : null;
      // ignore: use_build_context_synchronously
      await _showPreparingAndWait(waitContext);
    }
  }

  /// See [WhatsAppContacts.contactDisplayName].
  @visibleForTesting
  static String contactDisplayName(String? fullName, {DateTime? eventDate}) =>
      WhatsAppContacts.contactDisplayName(fullName, eventDate: eventDate);

  static Future<void> _showPreparingAndWait(BuildContext? context) async {
    if (context == null || !context.mounted) {
      await Future<void>.delayed(_prepareDelay);
      return;
    }

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          const tint = AppColorScheme.whatsApp;
          return PopScope(
            canPop: false,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6),
                  child: GlassPanel(
                    blur: true,
                    strong: true,
                    shadow: true,
                    borderRadius: AppRadius.xLarge,
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space6,
                      AppTokens.space5,
                      AppTokens.space6,
                      AppTokens.space5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: tint),
                        ),
                        const SizedBox(width: AppTokens.space4),
                        Flexible(
                          child: Text(
                            'Preparing WhatsApp…',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    await Future<void>.delayed(_prepareDelay);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @visibleForTesting
  static String chatKey(String pkg, String digits) => '$pkg|$digits';

  @visibleForTesting
  static Future<bool> isKnownChat(String pkg, String digits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(prefKnownChats) ?? const <String>[]).contains(
        chatKey(pkg, digits),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> _rememberChat(String pkg, String digits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = chatKey(pkg, digits);
      final list = List<String>.of(prefs.getStringList(prefKnownChats) ?? const <String>[])
        ..remove(key)
        ..add(key);
      final trimmed = list.length > _maxKnownChats
          ? list.sublist(list.length - _maxKnownChats)
          : list;
      await prefs.setStringList(prefKnownChats, trimmed);
    } catch (_) {}
  }

  static Future<bool> _openChat({
    required String digits,
    required String text,
    required String pkg,
  }) {
    return _invokeBool('openChat', {'phone': digits, 'text': text, 'package': pkg});
  }

  static Future<bool> _sendCard({
    required Uint8List png,
    required String digits,
    required String text,
    required String pkg,
  }) {
    return _invokeBool('shareImageToChat', {
      'png': png,
      'phone': digits,
      'text': text,
      'package': pkg,
    });
  }

  static Future<bool> _invokeBool(String method, Map<String, Object?> args) async {
    try {
      final result = await _invoke(method, args);
      return result == true;
    } on PlatformException catch (e) {
      Log.w('WhatsAppDirectShare: $method failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<Object?> _invoke(String method, [Map<String, Object?>? args]) {
    final override = debugInvoker;
    if (override != null) return override(method, args);
    return _channel.invokeMethod<Object?>(method, args);
  }

  static Future<_PackagePick> _resolvePackage(BuildContext? context) async {
    List<String> installed;
    try {
      final raw = await _invoke('listInstalledPackages');
      installed = (raw is List ? raw : const <Object?>[])
          .map((e) => e.toString())
          .where((p) => p.isNotEmpty)
          .toList();
    } on PlatformException catch (e) {
      Log.w('WhatsAppDirectShare: list packages failed', data: {'error': e.message});
      return const _PackagePick.none();
    } on MissingPluginException {
      return const _PackagePick.none();
    }

    if (installed.isEmpty) return const _PackagePick.none();
    if (installed.length == 1) {
      await _remember(installed.first);
      return _PackagePick.ok(installed.first);
    }

    final last = await _lastPackage();
    final preferred = (last != null && installed.contains(last)) ? last : installed.first;

    if (context == null || !context.mounted) {
      await _remember(preferred);
      return _PackagePick.ok(preferred);
    }

    final picked = await showWhatsAppPackageSheet(
      context,
      packages: installed,
      preferredPackage: preferred,
    );
    if (picked == null) return const _PackagePick.cancelled();
    await _remember(picked);
    return _PackagePick.ok(picked);
  }

  static Future<String?> _lastPackage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefLastPkg);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _remember(String pkg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastPkg, pkg);
    } catch (_) {}
  }
}

class _PackagePick {
  const _PackagePick.ok(this.package) : cancelled = false;
  const _PackagePick.cancelled() : package = null, cancelled = true;
  const _PackagePick.none() : package = null, cancelled = false;

  final String? package;
  final bool cancelled;
}
