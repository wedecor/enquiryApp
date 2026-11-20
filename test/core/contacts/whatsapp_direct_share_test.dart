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
  const message =
      'Hi Sahana, greetings from *We Decor*.\nI\'m writing about your *enquiry*. How can we help you today?';
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

  test('new / unknown: text-only openChat, no card intent, not remembered', () async {
    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'openChat']);
    expect(calls[1].args!['text'], message);
    expect(calls.any((c) => c.method == 'shareImageToChat'), isFalse);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isFalse);
  });

  test('known chat: one intent with card and caption', () async {
    // Seed known via prefs (enquiry path no longer remembers from text-only).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(WhatsAppDirectShare.prefKnownChats, [
      WhatsAppDirectShare.chatKey('com.whatsapp', '919380368142'),
    ]);

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'shareImageToChat']);
    expect(calls[1].args!['text'], message);
    expect(calls[1].args!['png'], png);
    expect(calls.any((c) => c.method == 'openChat'), isFalse);
  });

  test('not in contacts: save with date in name then text-only openChat', () async {
    canUseContacts = true;
    inContacts = false;
    saveOk = true;

    final result = await WhatsAppDirectShare.shareImageToChat(
      launcher: launcher,
      png: png,
      phone: '9380368142',
      text: message,
      customerFullName: 'Sahana Gowda',
      eventDate: DateTime(2026, 1, 12),
    );

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'isInContacts', 'saveContact', 'openChat']);
    final save = calls.firstWhere((c) => c.method == 'saveContact');
    expect(save.args?['name'], 'Sahana Gowda – We Decor · 12 Jan 2026');
    expect(calls.any((c) => c.method == 'shareImageToChat'), isFalse);
  });

  test('contactDisplayName omits date when missing', () {
    expect(WhatsAppDirectShare.contactDisplayName('Priya Sharma'), 'Priya Sharma – We Decor');
    expect(
      WhatsAppDirectShare.contactDisplayName('Priya Sharma', eventDate: DateTime(2026, 3, 5)),
      'Priya Sharma – We Decor · 5 Mar 2026',
    );
  });

  test('in contacts: no save, text-only openChat', () async {
    canUseContacts = true;
    inContacts = true;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'isInContacts', 'openChat']);
  });

  test('permission refused: still text-only openChat', () async {
    canUseContacts = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'openChat']);
  });

  test('click-to-chat fails: unavailable', () async {
    openChatOk = false;

    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(methods(), ['listInstalledPackages', 'openChat']);
  });

  test('card intent fails for known chat: unavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(WhatsAppDirectShare.prefKnownChats, [
      WhatsAppDirectShare.chatKey('com.whatsapp', '919380368142'),
    ]);
    shareOk = false;

    expect(await share(), WhatsAppDirectShareResult.unavailable);
  });

  test('no WhatsApp installed: unavailable', () async {
    installed = [];

    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(methods(), ['listInstalledPackages']);
  });

  test('weak digits refused before any platform call', () async {
    expect(await share(phone: '12345'), WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });

  test('not Android: unavailable', () async {
    WhatsAppDirectShare.debugIsAndroid = false;
    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });
}
