import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/logger.dart';
import 'contact_launcher.dart';
import 'whatsapp_card_step_sheet.dart';
import 'whatsapp_package_sheet.dart';

/// Result of an Android card share to a customer's WhatsApp chat.
enum WhatsAppDirectShareResult {
  /// The customer's chat opened with the card attached (staff tap Send in WhatsApp).
  opened,

  /// The customer's chat opened with the message, but the card was not sent
  /// (staff skipped the card step or did not come back to the app).
  textOnly,

  /// User dismissed the WhatsApp / Business sheet — do not fall back.
  cancelled,

  /// Channel unavailable, bad digits, or no WhatsApp installed — caller may fall back.
  unavailable,
}

typedef WhatsAppChannelInvoker =
    Future<Object?> Function(String method, Map<String, Object?>? args);
typedef WhatsAppReturnWaiter = Future<bool> Function();
typedef WhatsAppCardStepConfirm = Future<bool> Function(BuildContext? context, String? firstName);

/// Android: send a customer card + message to the right WhatsApp chat.
///
/// Every WhatsApp launch happens from a tap while our app is in the foreground.
/// (Android 10+ silently blocks activity starts from an app in the background,
/// which is why the old "open chat, then share the card 1.1 s later" never
/// attached the card.)
///
/// * Chat already known on this device for this WhatsApp app → one intent:
///   card + caption straight into the chat (`jid`).
/// * Otherwise → two steps:
///   1. Click-to-Chat opens the customer's chat with the message typed in
///      (works for any number; no "send to…" picker). Staff send it.
///   2. When staff come back to the app, a sheet offers "Send card"; one tap
///      opens the same chat with the card attached. The chat now exists, so
///      WhatsApp honours `jid`. The number is then remembered as known.
class WhatsAppDirectShare {
  WhatsAppDirectShare._();

  static const MethodChannel _channel = MethodChannel('wedecor/whatsapp');
  static const _prefLastPkg = 'whatsapp_share.last_pkg';

  /// `package|digits` of chats this device has sent a card to.
  @visibleForTesting
  static const prefKnownChats = 'whatsapp_share.known_chats_v1';
  static const int _maxKnownChats = 2000;

  /// How long to wait for staff to come back from WhatsApp after step 1.
  static const Duration returnTimeout = Duration(minutes: 20);

  @visibleForTesting
  static WhatsAppChannelInvoker? debugInvoker;
  @visibleForTesting
  static WhatsAppReturnWaiter? debugReturnWaiter;
  @visibleForTesting
  static WhatsAppCardStepConfirm? debugConfirmCardStep;
  @visibleForTesting
  static bool? debugIsAndroid;

  @visibleForTesting
  static void debugReset() {
    debugInvoker = null;
    debugReturnWaiter = null;
    debugConfirmCardStep = null;
    debugIsAndroid = null;
  }

  static bool get _isAndroid =>
      debugIsAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  /// Shares [png] + [text] to [phone]'s chat on Android. See class docs.
  ///
  /// [customerFirstName] is only used in the "Send the card" sheet.
  static Future<WhatsAppDirectShareResult> shareImageToChat({
    required ContactLauncher launcher,
    required Uint8List png,
    required String phone,
    required String text,
    BuildContext? context,
    String? customerFirstName,
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

    // Known chat: card + caption in one go.
    if (await isKnownChat(pkg, digits)) {
      final sent = await _sendCard(png: png, digits: digits, text: text, pkg: pkg);
      if (sent) {
        await _rememberChat(pkg, digits);
        return WhatsAppDirectShareResult.opened;
      }
      Log.w('WhatsAppDirectShare: card intent failed for known chat');
      return WhatsAppDirectShareResult.unavailable;
    }

    // Step 1: open the customer's chat with the message typed in.
    final chatOpened = await _openChat(digits: digits, text: text, pkg: pkg);
    if (!chatOpened) {
      Log.w('WhatsAppDirectShare: click-to-chat failed');
      return WhatsAppDirectShareResult.unavailable;
    }

    // Step 2 only once staff are back in the app (foreground launch).
    final returned = await (debugReturnWaiter ?? _waitForReturn)();
    if (!returned) {
      Log.w('WhatsAppDirectShare: staff did not return; card not sent');
      return WhatsAppDirectShareResult.textOnly;
    }

    final sheetContext = (context != null && context.mounted) ? context : null;
    final wantsCard = await (debugConfirmCardStep ?? _confirmCardStep)(
      sheetContext,
      customerFirstName,
    );
    if (!wantsCard) return WhatsAppDirectShareResult.textOnly;

    // Caption already went with step 1; send the card on its own.
    final sent = await _sendCard(png: png, digits: digits, text: '', pkg: pkg);
    if (!sent) {
      Log.w('WhatsAppDirectShare: card intent failed after chat opened');
      return WhatsAppDirectShareResult.textOnly;
    }
    await _rememberChat(pkg, digits);
    return WhatsAppDirectShareResult.opened;
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

  static Future<bool> _confirmCardStep(BuildContext? context, String? firstName) async {
    if (context == null || !context.mounted) return false;
    return showWhatsAppCardStepSheet(context, firstName: firstName);
  }

  /// Completes true when the app goes to the background (WhatsApp opened) and
  /// then comes back; false after [returnTimeout].
  static Future<bool> _waitForReturn() {
    final binding = WidgetsBinding.instance;
    final completer = Completer<bool>();
    final observer = _ReturnObserver(() {
      if (!completer.isCompleted) completer.complete(true);
    });
    binding.addObserver(observer);
    return completer.future
        .timeout(returnTimeout, onTimeout: () => false)
        .whenComplete(() => binding.removeObserver(observer));
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

/// Fires [onReturn] on the first resume after the app was paused/hidden.
class _ReturnObserver with WidgetsBindingObserver {
  _ReturnObserver(this.onReturn);

  final VoidCallback onReturn;
  bool _left = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _left = true;
    } else if (state == AppLifecycleState.resumed && _left) {
      onReturn();
    }
  }
}

class _PackagePick {
  const _PackagePick.ok(this.package) : cancelled = false;
  const _PackagePick.cancelled() : package = null, cancelled = true;
  const _PackagePick.none() : package = null, cancelled = false;

  final String? package;
  final bool cancelled;
}
