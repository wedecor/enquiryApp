import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_decor_enquiries/core/contacts/contact_launcher.dart';
import 'package:we_decor_enquiries/core/contacts/whatsapp_contacts.dart';
import 'package:we_decor_enquiries/core/contacts/whatsapp_direct_share.dart';

class _Call {
  _Call(this.method, this.args);
  final String method;
  final Map<String, Object?>? args;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final png = Uint8List.fromList([1, 2, 3]);
  const message = 'Hi Sahana, greetings from We Decor.';
  final launcher = ContactLauncher();

  late List<_Call> calls;
  late List<String> installed;
  late bool openChatOk;
  late bool shareOk;
  late bool canUseContacts;
  late bool inContacts;
  late bool saveOk;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    installed = ['com.whatsapp'];
    openChatOk = true;
    shareOk = true;
    canUseContacts = false;
    inContacts = false;
    saveOk = true;

    WhatsAppDirectShare.debugIsAndroid = true;
    WhatsAppDirectShare.debugPrepareDelay = Duration.zero;
    WhatsAppDirectShare.debugEnsurePermission = (_) async => canUseContacts;

    Future<Object?> invoker(String method, Map<String, Object?>? args) async {
      calls.add(_Call(method, args));
      switch (method) {
        case 'listInstalledPackages':
          return installed;
        case 'openChat':
          return openChatOk;
        case 'shareImageToChat':
          return shareOk;
        case 'isInContacts':
          return inContacts;
        case 'saveContact':
          return saveOk;
      }
      return null;
    }

    WhatsAppDirectShare.debugInvoker = invoker;
    WhatsAppContacts.debugInvoker = invoker;
  });

  tearDown(() {
    WhatsAppDirectShare.debugReset();
    WhatsAppContacts.debugReset();
  });

  Future<WhatsAppDirectShareResult> share({String phone = '9380368142'}) {
    return WhatsAppDirectShare.shareImageToChat(
      launcher: launcher,
      png: png,
      phone: phone,
      text: message,
      customerFullName: 'Sahana Gowda',
    );
  }

  List<String> methods() => calls.map((c) => c.method).toList();

  test('known chat skips contact checks and sends card', () async {
    await share();
    calls.clear();
    canUseContacts = true;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'shareImageToChat']);
    expect(calls[1].args?['text'], message);
    expect(calls[1].args?['png'], png);
    expect(calls.any((c) => c.method == 'isInContacts' || c.method == 'saveContact'), isFalse);
  });

  test('in contacts → card + remembered', () async {
    canUseContacts = true;
    inContacts = true;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'isInContacts', 'shareImageToChat']);
    expect(calls.any((c) => c.method == 'saveContact'), isFalse);
    expect(calls.last.args?['text'], message);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isTrue);
  });

  test('not in contacts + saved → wait then card + remembered', () async {
    canUseContacts = true;
    inContacts = false;
    saveOk = true;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'isInContacts', 'saveContact', 'shareImageToChat']);
    final save = calls.firstWhere((c) => c.method == 'saveContact');
    expect(save.args?['name'], 'Sahana Gowda – We Decor');
    expect(save.args?['phone'], '919380368142');
    expect(calls.last.args?['text'], message);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isTrue);
  });

  test('save fails → still tries card', () async {
    canUseContacts = true;
    inContacts = false;
    saveOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'isInContacts', 'saveContact', 'shareImageToChat']);
    expect(calls.any((c) => c.method == 'openChat'), isFalse);
  });

  test('permission refused → still tries card (no contact calls)', () async {
    canUseContacts = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'shareImageToChat']);
    expect(calls.any((c) => c.method == 'isInContacts' || c.method == 'saveContact'), isFalse);
  });

  test('card intent fails → message only, not remembered', () async {
    shareOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'shareImageToChat', 'openChat']);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isFalse);
  });

  test('card and click-to-chat both fail: unavailable', () async {
    shareOk = false;
    openChatOk = false;

    expect(await share(), WhatsAppDirectShareResult.unavailable);
  });

  test('no WhatsApp installed: unavailable', () async {
    installed = [];

    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(methods(), ['listInstalledPackages']);
  });

  test('weak digits are refused before any platform call', () async {
    expect(await share(phone: '12345'), WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });

  test('trunk-zero number is repaired for share', () async {
    await share(phone: '+91 09380368142');
    expect(calls.last.args?['phone'], '919380368142');
  });

  test('not Android: unavailable', () async {
    WhatsAppDirectShare.debugIsAndroid = false;
    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });

  test('uses known_chats_v2 pref key', () {
    expect(WhatsAppDirectShare.prefKnownChats, 'whatsapp_share.known_chats_v2');
  });
}
