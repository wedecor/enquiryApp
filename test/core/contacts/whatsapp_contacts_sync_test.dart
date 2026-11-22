import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_decor_enquiries/core/contacts/whatsapp_contacts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Set<String> onPhone;
  late List<String> savedPhones;

  setUp(() {
    SharedPreferences.setMockInitialValues({WhatsAppContacts.prefEnabled: true});
    onPhone = {};
    savedPhones = [];
    WhatsAppContacts.debugIsAndroid = true;
    WhatsAppContacts.debugInvoker = (method, args) async {
      switch (method) {
        case 'hasContactsPermission':
          return true;
        case 'isInContacts':
          return onPhone.contains(args?['phone']);
        case 'saveContact':
          final phone = args?['phone'] as String? ?? '';
          savedPhones.add(phone);
          onPhone.add(phone);
          return true;
      }
      return null;
    };
  });

  tearDown(WhatsAppContacts.debugReset);

  test('dedupeCustomers keeps latest event date per digits', () {
    final unique = WhatsAppContacts.dedupeCustomers([
      const CustomerContactDraft(customerName: 'Old', customerPhone: '9380368142', eventDate: null),
      CustomerContactDraft(
        customerName: 'Sahana',
        customerPhone: '9380368142',
        eventDate: DateTime(2026, 1, 12),
      ),
      const CustomerContactDraft(customerName: 'Other', customerPhone: '9000000000'),
    ]);

    expect(unique, hasLength(2));
    final sahana = unique.firstWhere((d) => d.digits == '919380368142');
    expect(sahana.customerName, 'Sahana');
    expect(sahana.eventDate, DateTime(2026, 1, 12));
  });

  test('dedupeCustomers prefers whatsapp phone', () {
    final unique = WhatsAppContacts.dedupeCustomers([
      const CustomerContactDraft(
        customerName: 'A',
        customerPhone: '9000000000',
        whatsappPhone: '9380368142',
      ),
    ]);
    expect(unique.single.digits, '919380368142');
  });

  test('fromEnquiry maps fields and skips empty phones', () {
    expect(CustomerContactDraft.fromEnquiry({'customerName': 'X'}), isNull);
    final draft = CustomerContactDraft.fromEnquiry({
      'customerName': 'Sahana',
      'customerPhone': '9380368142',
      'whatsappNumber': '9999999999',
      'eventDate': DateTime(2026, 3, 1),
    });
    expect(draft?.preferredPhone, '9999999999');
    expect(draft?.eventDate, DateTime(2026, 3, 1));
  });

  testWidgets('syncCustomersToDevice skips already on phone', (tester) async {
    onPhone.add('919380368142');
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
    final context = tester.element(find.byType(SizedBox));

    final result = await WhatsAppContacts.syncCustomersToDevice(
      context: context,
      customers: const [
        CustomerContactDraft(customerName: 'Sahana', customerPhone: '9380368142'),
        CustomerContactDraft(customerName: 'New', customerPhone: '9000000000'),
      ],
      assumePermission: true,
    );

    expect(result.alreadyOnPhone, 1);
    expect(result.saved, 1);
    expect(result.failed, 0);
    expect(savedPhones, ['919000000000']);
  });
}
