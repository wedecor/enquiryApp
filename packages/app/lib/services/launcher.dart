import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class ContactLauncher {
  static Future<void> call(String e164Phone) async {
    final uri = Uri(scheme: 'tel', path: e164Phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Cannot place call';
    }
  }

  static Future<void> whatsapp(String phone, {String? message}) async {
    final text = Uri.encodeComponent(message ?? '');
    final web = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}${text.isNotEmpty ? '?text=$text' : ''}');
    final native = Uri.parse('whatsapp://send?phone=$phone${text.isNotEmpty ? '&text=$text' : ''}');
    if ((Platform.isAndroid || Platform.isIOS) && await canLaunchUrl(native)) {
      await launchUrl(native, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }
}

