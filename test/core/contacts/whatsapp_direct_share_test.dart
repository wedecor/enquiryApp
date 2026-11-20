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
  late bool inContacts;
  late bool saveOk;
  late bool permissionOk;

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
      case 'hasContactsPermission':
        return permissionOk;
      case 'requestContactsPermission':
        return permissionOk;
      default:
        fail('unexpected method $method');
    }
  }

  Future<WhatsAppDirectShareResult> share() {
    return WhatsAppDirectShare.shareImageToChat(
      launcher: launcher,
      png: png,
      phone: '9380368142',
      text: message,
      customerFullName: 'Sahana Gowda',
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    installed = ['com.whatsapp'];
    openChatOk = true;
    shareOk = true;
    inContacts = false;
    saveOk = true;
    permissionOk = true;

    WhatsAppDirectShare.debugIsAndroid = true;
    WhatsAppDirectShare.debugPrepareDelay = Duration.zero;
    WhatsAppDirectShare.debugEnsurePermission = (_) async => permissionOk;
    WhatsAppDirectShare.debugInvoker = invoker;
    WhatsAppContacts.debugInvoker = invoker;
  });

  tearDown(() {
    WhatsAppDirectShare.debugReset();
    WhatsAppContacts.debugReset();
  });

  test('known chat skips contact checks and sends card', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(WhatsAppDirectShare.prefKnownChats, [
      WhatsAppDirectShare.chatKey('com.whatsapp', '919380368142'),
    ]);

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(calls.map((c) => c.method), ['listInstalledPackages', 'shareImageToChat']);
    expect(calls.any((c) => c.method == 'isInContacts'), isFalse);
    expect(calls.any((c) => c.method == 'saveContact'), isFalse);
    expect(calls.any((c) => c.method == 'openChat'), isFalse);
  });

  test('in contacts → card + remembered', () async {
    inContacts = true;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(calls.map((c) => c.method), [
      'listInstalledPackages',
      'isInContacts',
      'shareImageToChat',
    ]);
    final shareCall = calls.firstWhere((c) => c.method == 'shareImageToChat');
    expect(shareCall.args?['phone'], '919380368142');
    expect(shareCall.args?['text'], message);
    expect(shareCall.args?['package'], 'com.whatsapp');
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isTrue);
  });

  test('not in contacts + saved → wait then card + remembered', () async {
    inContacts = false;
    saveOk = true;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(calls.map((c) => c.method), [
      'listInstalledPackages',
      'isInContacts',
      'saveContact',
      'shareImageToChat',
    ]);
    final save = calls.firstWhere((c) => c.method == 'saveContact');
    expect(save.args?['name'], 'Sahana Gowda – We Decor');
    expect(save.args?['phone'], '919380368142');
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isTrue);
  });

  test('save fails → message only', () async {
    inContacts = false;
    saveOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(calls.map((c) => c.method), [
      'listInstalledPackages',
      'isInContacts',
      'saveContact',
      'openChat',
    ]);
    expect(calls.any((c) => c.method == 'shareImageToChat'), isFalse);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isFalse);
  });

  test('permission refused → message only', () async {
    permissionOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(calls.map((c) => c.method), ['listInstalledPackages', 'openChat']);
    expect(calls.any((c) => c.method == 'isInContacts'), isFalse);
    expect(calls.any((c) => c.method == 'saveContact'), isFalse);
    expect(calls.any((c) => c.method == 'shareImageToChat'), isFalse);
  });

  test('click-to-chat fails: unavailable', () async {
    permissionOk = false;
    openChatOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.unavailable);
  });

  test('card intent fails for known chat: unavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(WhatsAppDirectShare.prefKnownChats, [
      WhatsAppDirectShare.chatKey('com.whatsapp', '919380368142'),
    ]);
    shareOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.unavailable);
  });

  test('no WhatsApp installed: unavailable', () async {
    installed = [];

    final result = await share();

    expect(result, WhatsAppDirectShareResult.unavailable);
    expect(calls.map((c) => c.method), ['listInstalledPackages']);
  });

  test('weak digits are refused before any platform call', () async {
    final result = await WhatsAppDirectShare.shareImageToChat(
      launcher: launcher,
      png: png,
      phone: '123',
      text: message,
    );

    expect(result, WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });

  test('trunk-zero number is repaired for share', () async {
    inContacts = true;

    final result = await WhatsAppDirectShare.shareImageToChat(
      launcher: launcher,
      png: png,
      phone: '+91 09876543210',
      text: message,
      customerFullName: 'Test',
    );

    expect(result, WhatsAppDirectShareResult.opened);
    final shareCall = calls.firstWhere((c) => c.method == 'shareImageToChat');
    expect(shareCall.args?['phone'], '919876543210');
  });

  test('not Android: unavailable', () async {
    WhatsAppDirectShare.debugIsAndroid = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });
}
