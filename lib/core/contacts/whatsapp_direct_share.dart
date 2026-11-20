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

  /// Chat opened with the message only (no card) — card intent failed after
  /// contact prep / permission path.
  textOnly,

  /// User dismissed the WhatsApp / Business sheet — do not fall back.
  cancelled,

  /// Channel unavailable, bad digits, or no WhatsApp installed — caller may fall back.
  unavailable,
}

typedef WhatsAppChannelInvoker =
    Future<Object?> Function(String method, Map<String, Object?>? args);
typedef WhatsAppPermissionGate = Future<bool> Function(BuildContext? context);

/// Android: one-tap card + caption to the customer's WhatsApp chat.
///
/// * Known chat → card + caption in one intent.
/// * Else, with contacts permission:
///   - Already in phone contacts → card.
///   - Else save a device-only contact, wait [contactPrepareDelay], then card.
/// * No permission / save failed → still try card once; if that fails →
///   Click-to-Chat message only (last resort).
class WhatsAppDirectShare {
  WhatsAppDirectShare._();

  static const MethodChannel _channel = MethodChannel('wedecor/whatsapp');
  static const _prefLastPkg = 'whatsapp_share.last_pkg';

  /// `package|digits` of chats this device has sent a card to.
  /// v2 clears entries poisoned by earlier builds that remembered chats without
  /// a successful card attach.
  @visibleForTesting
  static const prefKnownChats = 'whatsapp_share.known_chats_v2';
  static const int _maxKnownChats = 2000;

  /// How long to wait after saving a contact before launching WhatsApp.
  static const Duration contactPrepareDelay = Duration(seconds: 5);

  @visibleForTesting
  static WhatsAppChannelInvoker? debugInvoker;
  @visibleForTesting
  static bool? debugIsAndroid;
  @visibleForTesting
  static Duration? debugPrepareDelay;
  @visibleForTesting
  static WhatsAppPermissionGate? debugEnsurePermission;

  @visibleForTesting
  static void debugReset() {
    debugInvoker = null;
    debugIsAndroid = null;
    debugPrepareDelay = null;
    debugEnsurePermission = null;
  }

  static bool get _isAndroid =>
      debugIsAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static Duration get _prepareDelay => debugPrepareDelay ?? contactPrepareDelay;

  /// Shares [png] + [text] to [phone]'s chat on Android. See class docs.
  ///
  /// [customerFullName] is used when saving a device contact
  /// (`"{name} – We Decor"`).
  static Future<WhatsAppDirectShareResult> shareImageToChat({
    required ContactLauncher launcher,
    required Uint8List png,
    required String phone,
    required String text,
    BuildContext? context,
    String? customerFullName,
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

    // Known chat: card + caption in one go (skip contact checks).
    if (await isKnownChat(pkg, digits)) {
      return _sendCardOrFallback(png: png, digits: digits, text: text, pkg: pkg);
    }

    final canUseContacts = await (debugEnsurePermission ?? WhatsAppContacts.ensurePermission)(
      (context != null && context.mounted) ? context : null,
    );

    if (canUseContacts) {
      final already = await WhatsAppContacts.isInContacts(digits);
      if (!already) {
        final displayName = _contactDisplayName(customerFullName);
        final saved = await WhatsAppContacts.saveContact(name: displayName, phone: digits);
        if (saved) {
          await _showPreparingAndWait(context);
        } else {
          Log.w('WhatsAppDirectShare: saveContact failed; still trying card');
        }
      }
    }

    // Always try the one-intent card path (with or without contacts).
    return _sendCardOrFallback(png: png, digits: digits, text: text, pkg: pkg);
  }

  static String _contactDisplayName(String? fullName) {
    final n = (fullName ?? '').trim();
    if (n.isEmpty) return 'We Decor customer';
    return '$n – We Decor';
  }

  /// Card first; Click-to-Chat message only if the card intent fails.
  static Future<WhatsAppDirectShareResult> _sendCardOrFallback({
    required Uint8List png,
    required String digits,
    required String text,
    required String pkg,
  }) async {
    final sent = await _sendCard(png: png, digits: digits, text: text, pkg: pkg);
    if (sent) {
      await _rememberChat(pkg, digits);
      return WhatsAppDirectShareResult.opened;
    }
    Log.w('WhatsAppDirectShare: card intent failed; message only');
    final chatOpened = await _openChat(digits: digits, text: text, pkg: pkg);
    if (!chatOpened) {
      Log.w('WhatsAppDirectShare: click-to-chat failed');
      return WhatsAppDirectShareResult.unavailable;
    }
    return WhatsAppDirectShareResult.textOnly;
  }

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
