import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/logger.dart';
import 'contact_launcher.dart';
import 'whatsapp_package_sheet.dart';

/// Result of an Android direct image+caption share attempt.
enum WhatsAppDirectShareResult {
  /// Chat opened with the card.
  opened,

  /// User dismissed the WhatsApp / Business sheet — do not fall back.
  cancelled,

  /// Channel unavailable, bad digits, or no WhatsApp installed — caller may fall back.
  unavailable,
}

/// Android MethodChannel helper: pick WA/W4B in-app, then share image+caption.
class WhatsAppDirectShare {
  WhatsAppDirectShare._();

  static const MethodChannel _channel = MethodChannel('wedecor/whatsapp');
  static const _prefLastPkg = 'whatsapp_share.last_pkg';

  /// Shares [png] + [text] to [phone]'s chat on Android.
  static Future<WhatsAppDirectShareResult> shareImageToChat({
    required ContactLauncher launcher,
    required Uint8List png,
    required String phone,
    required String text,
    BuildContext? context,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return WhatsAppDirectShareResult.unavailable;
    }

    final digits = launcher.toWhatsAppDigits(phone);
    if (digits.length < 11 || digits.length > 15) {
      Log.w('WhatsAppDirectShare: refusing weak jid digits', data: {'len': digits.length});
      return WhatsAppDirectShareResult.unavailable;
    }

    final pick = await _resolvePackage(context);
    if (pick.cancelled) return WhatsAppDirectShareResult.cancelled;
    final pkg = pick.package;
    if (pkg == null) return WhatsAppDirectShareResult.unavailable;

    try {
      final opened = await _channel.invokeMethod<bool>('shareImageToChat', {
        'png': png,
        'phone': digits,
        'text': text,
        'package': pkg,
      });
      return (opened ?? false)
          ? WhatsAppDirectShareResult.opened
          : WhatsAppDirectShareResult.unavailable;
    } on PlatformException catch (e) {
      Log.w('WhatsAppDirectShare: share failed', data: {'error': e.message});
      return WhatsAppDirectShareResult.unavailable;
    } on MissingPluginException {
      return WhatsAppDirectShareResult.unavailable;
    }
  }

  static Future<_PackagePick> _resolvePackage(BuildContext? context) async {
    List<String> installed;
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('listInstalledPackages');
      installed = (raw ?? const []).map((e) => e.toString()).where((p) => p.isNotEmpty).toList();
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
