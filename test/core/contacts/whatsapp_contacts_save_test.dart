import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_decor_enquiries/core/contacts/whatsapp_contacts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> methods;
  late Map<String, Object?>? lastSaveArgs;
  late bool inContacts;
  late bool saveOk;
  late bool hasPermission;

  setUp(() {
    SharedPreferences.setMockInitialValues({WhatsAppContacts.prefEnabled: true});
    methods = [];
    lastSaveArgs = null;
    inContacts = false;
    saveOk = true;
    hasPermission = true;
    WhatsAppContacts.debugIsAndroid = true;

    WhatsAppContacts.debugInvoker = (method, args) async {
      methods.add(method);
      switch (method) {
        case 'hasContactsPermission':
          return hasPermission;
        case 'isInContacts':
          return inContacts;
        case 'saveContact':
          lastSaveArgs = args;
          return saveOk;
      }
      return null;
    };
  });

  tearDown(WhatsAppContacts.debugReset);

  test('contactDisplayName appends event date', () {
    expect(
      WhatsAppContacts.contactDisplayName('Sahana Gowda', eventDate: DateTime(2026, 1, 12)),
      'Sahana Gowda – We Decor · 12 Jan 2026',
    );
    expect(WhatsAppContacts.contactDisplayName('Sahana Gowda'), 'Sahana Gowda – We Decor');
  });

  test('saveCustomerIfNeeded saves when not in contacts', () async {
    final ok = await WhatsAppContacts.saveCustomerIfNeeded(
      customerName: 'Sahana Gowda',
      customerPhone: '9380368142',
      eventDate: DateTime(2026, 1, 12),
    );

    expect(ok, isTrue);
    expect(methods, containsAll(['hasContactsPermission', 'isInContacts', 'saveContact']));
    expect(lastSaveArgs?['name'], 'Sahana Gowda – We Decor · 12 Jan 2026');
    expect(lastSaveArgs?['phone'], '919380368142');
  });

  test('saveCustomerIfNeeded prefers whatsapp phone', () async {
    await WhatsAppContacts.saveCustomerIfNeeded(
      customerName: 'Sahana Gowda',
      customerPhone: '9000000000',
      whatsappPhone: '9380368142',
    );

    expect(lastSaveArgs?['phone'], '919380368142');
  });

  test('saveCustomerIfNeeded skips when already in contacts', () async {
    inContacts = true;

    final ok = await WhatsAppContacts.saveCustomerIfNeeded(
      customerName: 'Sahana Gowda',
      customerPhone: '9380368142',
    );

    expect(ok, isTrue);
    expect(methods, isNot(contains('saveContact')));
  });

  test('saveCustomerIfNeeded no-ops when permission missing', () async {
    hasPermission = false;
    SharedPreferences.setMockInitialValues({
      WhatsAppContacts.prefEnabled: true,
      WhatsAppContacts.prefDenied: true,
    });

    final ok = await WhatsAppContacts.saveCustomerIfNeeded(
      customerName: 'Sahana Gowda',
      customerPhone: '9380368142',
    );

    expect(ok, isFalse);
    expect(methods, isNot(contains('saveContact')));
  });

  test('saveCustomerFromButton saves and returns saved', () async {
    final result = await WhatsAppContacts.saveCustomerFromButton(
      context: _FakeContext(),
      customerName: 'Sahana Gowda',
      customerPhone: '9380368142',
      eventDate: DateTime(2026, 1, 12),
    );

    expect(result, StaffSaveContactResult.saved);
    expect(methods, containsAll(['hasContactsPermission', 'isInContacts', 'saveContact']));
    expect(lastSaveArgs?['name'], 'Sahana Gowda – We Decor · 12 Jan 2026');
    expect(
      WhatsAppContacts.messageFor(result),
      'Contact saved on this phone. You can open WhatsApp now.',
    );
  });

  test('saveCustomerFromButton returns alreadySaved without writing again', () async {
    inContacts = true;

    final result = await WhatsAppContacts.saveCustomerFromButton(
      context: _FakeContext(),
      customerName: 'Sahana Gowda',
      customerPhone: '9380368142',
    );

    expect(result, StaffSaveContactResult.alreadySaved);
    expect(methods, isNot(contains('saveContact')));
    expect(WhatsAppContacts.messageFor(result), 'Contact already saved on this phone.');
  });

  test('saveCustomerFromButton unsupported off Android', () async {
    WhatsAppContacts.debugIsAndroid = false;

    final result = await WhatsAppContacts.saveCustomerFromButton(
      context: _FakeContext(),
      customerName: 'Sahana Gowda',
      customerPhone: '9380368142',
    );

    expect(result, StaffSaveContactResult.unsupported);
    expect(methods, isEmpty);
  });
}

/// Minimal mounted context so [saveCustomerFromButton] can call ensurePermission.
class _FakeContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}
