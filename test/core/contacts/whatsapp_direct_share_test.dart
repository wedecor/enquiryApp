import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_decor_enquiries/core/contacts/contact_launcher.dart';
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
  late bool returned;
  late bool wantsCard;
  late List<String?> sheetNames;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    installed = ['com.whatsapp'];
    openChatOk = true;
    shareOk = true;
    returned = true;
    wantsCard = true;
    sheetNames = [];

    WhatsAppDirectShare.debugIsAndroid = true;
    WhatsAppDirectShare.debugInvoker = (method, args) async {
      calls.add(_Call(method, args));
      switch (method) {
        case 'listInstalledPackages':
          return installed;
        case 'openChat':
          return openChatOk;
        case 'shareImageToChat':
          return shareOk;
      }
      return null;
    };
    WhatsAppDirectShare.debugReturnWaiter = () async => returned;
    WhatsAppDirectShare.debugConfirmCardStep = (context, firstName) async {
      sheetNames.add(firstName);
      return wantsCard;
    };
  });

  tearDown(WhatsAppDirectShare.debugReset);

  Future<WhatsAppDirectShareResult> share({String phone = '9380368142'}) {
    return WhatsAppDirectShare.shareImageToChat(
      launcher: launcher,
      png: png,
      phone: phone,
      text: message,
      customerFirstName: 'Sahana',
    );
  }

  List<String> methods() => calls.map((c) => c.method).toList();

  test('new number: opens chat with message, then sends card alone after return', () async {
    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'openChat', 'shareImageToChat']);
    expect(calls[1].args!['phone'], '919380368142');
    expect(calls[1].args!['text'], message);
    expect(calls[1].args!['package'], 'com.whatsapp');
    expect(calls[2].args!['text'], '', reason: 'caption already sent in step 1');
    expect(calls[2].args!['png'], png);
    expect(sheetNames, ['Sahana']);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isTrue);
  });

  test('known chat: one intent with card and caption, no click-to-chat', () async {
    await share();
    calls.clear();
    sheetNames.clear();

    final result = await share();

    expect(result, WhatsAppDirectShareResult.opened);
    expect(methods(), ['listInstalledPackages', 'shareImageToChat']);
    expect(calls[1].args!['text'], message);
    expect(sheetNames, isEmpty);
  });

  test('known chats are per WhatsApp app', () async {
    await share();
    calls.clear();
    installed = ['com.whatsapp.w4b'];

    await share();

    expect(methods(), ['listInstalledPackages', 'openChat', 'shareImageToChat']);
    expect(calls[1].args!['package'], 'com.whatsapp.w4b');
  });

  test('staff skip the card: textOnly, number not remembered', () async {
    wantsCard = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'openChat']);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isFalse);
  });

  test('staff never come back: textOnly, no sheet, no card intent', () async {
    returned = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(methods(), ['listInstalledPackages', 'openChat']);
    expect(sheetNames, isEmpty);
  });

  test('card intent fails after chat opened: textOnly, not remembered', () async {
    shareOk = false;

    final result = await share();

    expect(result, WhatsAppDirectShareResult.textOnly);
    expect(await WhatsAppDirectShare.isKnownChat('com.whatsapp', '919380368142'), isFalse);
  });

  test('click-to-chat fails: unavailable so the caller can fall back', () async {
    openChatOk = false;

    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(methods(), ['listInstalledPackages', 'openChat']);
  });

  test('card intent fails for a known chat: unavailable', () async {
    await share();
    shareOk = false;

    expect(await share(), WhatsAppDirectShareResult.unavailable);
  });

  test('no WhatsApp installed: unavailable without launching anything', () async {
    installed = [];

    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(methods(), ['listInstalledPackages']);
  });

  test('weak digits are refused before any platform call', () async {
    expect(await share(phone: '12345'), WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });

  test('trunk-zero number is repaired for click-to-chat', () async {
    await share(phone: '+91 09380368142');
    expect(calls[1].args!['phone'], '919380368142');
  });

  test('not Android: unavailable', () async {
    WhatsAppDirectShare.debugIsAndroid = false;
    expect(await share(), WhatsAppDirectShareResult.unavailable);
    expect(calls, isEmpty);
  });
}
