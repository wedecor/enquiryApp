import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/dropdown_defaults.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/booking_amounts.dart';

String _label(String value) => 'L:$value';

void main() {
  group('parseAmountText', () {
    test('reads plain and decimal amounts, null for empty or unreadable', () {
      expect(parseAmountText('50000'), 50000);
      expect(parseAmountText(' 1250.5 '), 1250.5);
      expect(parseAmountText(''), isNull);
      expect(parseAmountText('   '), isNull);
      expect(parseAmountText(null), isNull);
      expect(parseAmountText('1.2.3'), isNull);
    });
  });

  group('derivePaymentStatus', () {
    test('uses canonical payment status values', () {
      final values = DropdownDefaults.paymentStatuses.map((m) => m['value']).toSet();
      expect(values, containsAll([kPaymentStatusPaid, kPaymentStatusPartial]));
    });

    test('advance >= total is paid', () {
      expect(derivePaymentStatus(total: 100000, advance: 100000), 'paid');
      expect(derivePaymentStatus(total: 100000, advance: 120000), 'paid');
    });

    test('some advance below total is partial', () {
      expect(derivePaymentStatus(total: 100000, advance: 25000), 'partial');
    });

    test('nothing to derive leaves the status alone', () {
      expect(derivePaymentStatus(total: 100000, advance: 0), isNull);
      expect(derivePaymentStatus(total: 100000), isNull);
      expect(derivePaymentStatus(advance: 5000), isNull);
      expect(derivePaymentStatus(total: 0, advance: 5000), isNull);
      expect(derivePaymentStatus(), isNull);
    });
  });

  group('bookingBalanceText', () {
    test('shows the balance once a total is entered (Indian grouping)', () {
      expect(bookingBalanceText(total: 150000, advance: 50000), 'Balance ₹1,00,000');
      expect(bookingBalanceText(total: 150000), 'Balance ₹1,50,000');
    });

    test('never negative', () {
      expect(bookingBalanceText(total: 1000, advance: 5000), 'Balance ₹0');
    });

    test('hidden without a total', () {
      expect(bookingBalanceText(advance: 5000), isNull);
      expect(bookingBalanceText(total: 0, advance: 0), isNull);
    });
  });

  group('bookingAmountFields', () {
    test('both empty and nothing stored → nothing written', () {
      expect(
        bookingAmountFields(
          oldData: const {},
          totalText: '',
          advanceText: '',
          paymentStatusLabel: _label,
        ),
        isEmpty,
      );
    });

    test('unchanged prefilled amounts → nothing written', () {
      expect(
        bookingAmountFields(
          oldData: const {'totalCost': 80000, 'advancePaid': 20000.0},
          totalText: '80000',
          advanceText: '20000',
          paymentStatusLabel: _label,
        ),
        isEmpty,
      );
    });

    test('new partial advance writes amounts and the partial status', () {
      expect(
        bookingAmountFields(
          oldData: const {'paymentStatusValue': 'pending'},
          totalText: '100000',
          advanceText: '25000',
          paymentStatusLabel: _label,
        ),
        {
          'totalCost': 100000.0,
          'advancePaid': 25000.0,
          'paymentStatus': 'partial',
          'paymentStatusValue': 'partial',
          'paymentStatusLabel': 'L:partial',
        },
      );
    });

    test('fully paid writes the paid status', () {
      final fields = bookingAmountFields(
        oldData: const {'totalCost': 50000},
        totalText: '50000',
        advanceText: '50000',
        paymentStatusLabel: _label,
      );
      expect(fields, {
        'advancePaid': 50000.0,
        'paymentStatus': 'paid',
        'paymentStatusValue': 'paid',
        'paymentStatusLabel': 'L:paid',
      });
    });

    test('total only: amount written, payment status left alone', () {
      expect(
        bookingAmountFields(
          oldData: const {'paymentStatus': 'pending'},
          totalText: '75000',
          advanceText: '',
          paymentStatusLabel: _label,
        ),
        {'totalCost': 75000.0},
      );
    });

    test('derived status equal to stored status is not rewritten', () {
      expect(
        bookingAmountFields(
          oldData: const {'totalCost': 100000, 'paymentStatusValue': 'partial'},
          totalText: '100000',
          advanceText: '10000',
          paymentStatusLabel: _label,
        ),
        {'advancePaid': 10000.0},
      );
    });

    test('clearing a stored amount writes null; unreadable text keeps it', () {
      expect(
        bookingAmountFields(
          oldData: const {'totalCost': 100000, 'advancePaid': 5000},
          totalText: '',
          advanceText: '5.0.0',
          paymentStatusLabel: _label,
        ),
        {'totalCost': null},
      );
    });
  });

  group('bookingAmountAuditChanges', () {
    test('records money changes like the edit form', () {
      final changes = bookingAmountAuditChanges(
        const {'totalCost': 80000, 'paymentStatusValue': 'pending'},
        const {
          'totalCost': 90000.0,
          'advancePaid': 30000.0,
          'paymentStatusValue': 'partial',
          'eventLocation': 'JP Nagar',
        },
      );
      expect(changes, {
        'totalCost': {'old_value': 80000, 'new_value': 90000.0},
        'advancePaid': {'old_value': 0, 'new_value': 30000.0},
        'paymentStatus': {'old_value': 'pending', 'new_value': 'partial'},
      });
    });

    test('no money fields → no entries', () {
      expect(bookingAmountAuditChanges(const {}, const {'eventLocation': 'HSR Layout'}), isEmpty);
    });

    test('cleared amount records 0 as the new value', () {
      expect(bookingAmountAuditChanges(const {'totalCost': 1000}, const {'totalCost': null}), {
        'totalCost': {'old_value': 1000, 'new_value': 0},
      });
    });
  });

  group('isApprovedAmountPending', () {
    test('approved or completed without a positive total', () {
      expect(isApprovedAmountPending({'statusValue': 'approved'}), isTrue);
      expect(isApprovedAmountPending({'statusValue': 'completed', 'totalCost': 0}), isTrue);
      expect(isApprovedAmountPending({'statusValue': 'approved', 'totalCost': -5}), isTrue);
      expect(isApprovedAmountPending({'statusValue': 'approved', 'totalCost': null}), isTrue);
      // Legacy alias resolves to approved.
      expect(isApprovedAmountPending({'statusValue': 'confirmed'}), isTrue);
    });

    test('false once a total exists or before approval', () {
      expect(isApprovedAmountPending({'statusValue': 'approved', 'totalCost': 50000}), isFalse);
      expect(isApprovedAmountPending({'statusValue': 'completed', 'totalCost': 1.5}), isFalse);
      expect(isApprovedAmountPending({'statusValue': 'in_talks'}), isFalse);
      expect(isApprovedAmountPending({'statusValue': 'new'}), isFalse);
      expect(isApprovedAmountPending({'statusValue': 'cancelled'}), isFalse);
      expect(isApprovedAmountPending(<String, dynamic>{}), isFalse);
    });

    test('multi-function booking uses the one top-level total', () {
      final functions = [
        {'eventType': 'haldi', 'date': '2026-12-10'},
        {'eventType': 'wedding', 'date': '2026-12-12'},
      ];
      expect(
        isApprovedAmountPending({'statusValue': 'approved', 'functions': functions}),
        isTrue,
      );
      expect(
        isApprovedAmountPending({
          'statusValue': 'approved',
          'functions': functions,
          'totalCost': 400000,
        }),
        isFalse,
      );
    });
  });

  group('bookingHasAmount', () {
    test('only a positive number counts', () {
      expect(bookingHasAmount({'totalCost': 1}), isTrue);
      expect(bookingHasAmount({'totalCost': 0}), isFalse);
      expect(bookingHasAmount({'totalCost': '50000'}), isFalse);
      expect(bookingHasAmount(<String, dynamic>{}), isFalse);
    });
  });

  group('formatBookingAmount', () {
    test('uses Indian digit grouping', () {
      expect(formatBookingAmount(150000), '₹1,50,000');
      expect(formatBookingAmount(0), '₹0');
    });
  });

  group('confirmBookingSubtitle', () {
    test('joins customer, event type and date', () {
      expect(
        confirmBookingSubtitle(
          customerName: ' Ayesha Khan ',
          eventType: 'Wedding',
          eventDate: DateTime(2026, 12, 12),
        ),
        'Ayesha Khan · Wedding · 12 Dec 2026',
      );
    });

    test('skips empty parts and placeholder dates', () {
      expect(confirmBookingSubtitle(customerName: 'Ali', eventType: ''), 'Ali');
      expect(
        confirmBookingSubtitle(eventType: 'Haldi', eventDate: DateTime(1970)),
        'Haldi',
      );
      expect(confirmBookingSubtitle(), '');
    });
  });
}
