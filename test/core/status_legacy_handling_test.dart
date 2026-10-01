import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/dropdown_defaults.dart';
import 'package:we_decor_enquiries/core/constants/status_vocabulary.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/analytics_repository.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
import 'package:we_decor_enquiries/services/dropdown_lookup.dart';

void main() {
  group('EnquiryStatus.rawValuesFor', () {
    test('in_talks includes every legacy alias and fits a whereIn', () {
      final values = EnquiryStatus.rawValuesFor('in_talks');
      expect(values.first, 'in_talks');
      expect(
        values,
        containsAll(<String>['contacted', 'quote_sent', 'quoted', 'in_progress', 'assigned']),
      );
      expect(values.length, lessThanOrEqualTo(10));
    });

    test('approved includes confirmed and scheduled', () {
      expect(EnquiryStatus.rawValuesFor('approved'), ['approved', 'confirmed', 'scheduled']);
    });

    test('a legacy input resolves to its canonical group', () {
      expect(EnquiryStatus.rawValuesFor('quote_sent'), EnquiryStatus.rawValuesFor('in_talks'));
    });

    test('statuses without aliases return only themselves', () {
      expect(EnquiryStatus.rawValuesFor('cancelled'), ['cancelled']);
    });

    test('every canonical status stays within the whereIn limit', () {
      for (final status in EnquiryStatus.values) {
        expect(EnquiryStatus.rawValuesFor(status.value).length, lessThanOrEqualTo(10));
      }
    });
  });

  group('DropdownDefaults.resolveMap (statuses)', () {
    test('legacy aliases never override canonical labels', () {
      final map = DropdownDefaults.resolveMap({
        'in_talks': 'In Talks',
        'quote_sent': 'Quote Sent',
        'contacted': 'Contacted',
        'confirmed': 'Confirmed',
        'scheduled': 'Scheduled',
      }, 'statuses');
      expect(map['in_talks'], 'In Talks');
      expect(map['approved'], 'Approved');
      expect(map.containsKey('quote_sent'), isFalse);
      expect(map.values, isNot(contains('Quote Sent')));
    });

    test('canonical label overrides from Firestore are kept', () {
      final map = DropdownDefaults.resolveMap({'in_talks': 'Negotiating'}, 'statuses');
      expect(map['in_talks'], 'Negotiating');
      expect(map['new'], 'New');
    });

    test('empty input falls back to canonical labels', () {
      final map = DropdownDefaults.resolveMap({}, 'statuses');
      expect(map.length, EnquiryStatus.values.length);
    });
  });

  group('FirestoreService.parseValueLabelMap', () {
    test('skips inactive items and non-canonical status values', () {
      final map = FirestoreService.parseValueLabelMap('statuses', [
        ('a', {'value': 'in_talks', 'label': 'In Talks', 'active': true}),
        ('b', {'value': 'quote_sent', 'label': 'Quote Sent', 'active': false}),
        ('c', {'value': 'contacted', 'label': 'Contacted', 'active': true}),
        ('d', {'value': 'approved', 'label': 'Booked', 'active': false}),
      ]);
      expect(map, {'in_talks': 'In Talks'});
    });

    test('other kinds keep active custom values only', () {
      final map = FirestoreService.parseValueLabelMap('event_types', [
        ('a', {'value': 'haldi', 'label': 'Haldi', 'active': true}),
        ('b', {'value': 'old_type', 'label': 'Old', 'active': false}),
        ('c', {'value': 'mehendi', 'label': 'Mehendi'}),
      ]);
      expect(map, {'haldi': 'Haldi', 'mehendi': 'Mehendi'});
    });
  });

  group('DropdownLookup.statusLabelOf', () {
    test('legacy values show the canonical label', () {
      expect(DropdownLookup.statusLabelOf(null, 'quote_sent'), 'In Talks');
      expect(DropdownLookup.statusLabelOf(null, 'Quote Sent'), 'In Talks');
      expect(DropdownLookup.statusLabelOf(null, 'confirmed'), 'Approved');
      expect(DropdownLookup.statusLabelOf(null, 'contacted'), 'In Talks');
    });
  });

  group('shouldShowReminder with legacy statuses', () {
    final now = DateTime(2026, 10, 1, 10);

    test('quote_sent with an event in 10 days is a follow-up', () {
      final data = {
        'statusValue': 'quote_sent',
        'eventDate': Timestamp.fromDate(DateTime(2026, 10, 11)),
      };
      expect(shouldShowReminder(data, now), isTrue);
    });

    test('contacted with an event today is a follow-up', () {
      final data = {
        'statusValue': 'contacted',
        'eventDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
      };
      expect(shouldShowReminder(data, now), isTrue);
    });

    test('confirmed (approved) is not a follow-up', () {
      final data = {
        'statusValue': 'confirmed',
        'eventDate': Timestamp.fromDate(DateTime(2026, 10, 5)),
      };
      expect(shouldShowReminder(data, now), isFalse);
    });
  });

  group('AnalyticsRepository.aggregateCountByStatus with legacy statuses', () {
    test('legacy values are grouped under their canonical status', () {
      final counts = AnalyticsRepository.aggregateCountByStatus([
        {'statusValue': 'in_talks'},
        {'statusValue': 'quote_sent'},
        {'statusValue': 'contacted'},
        {'statusValue': 'confirmed'},
        {'statusValue': 'approved'},
        {'statusValue': 'mystery'},
        <String, dynamic>{},
      ]);
      expect(counts['in_talks'], 3);
      expect(counts['approved'], 2);
      expect(counts['unknown'], 2);
      expect(counts.containsKey('quote_sent'), isFalse);
      expect(counts.containsKey('confirmed'), isFalse);
    });
  });
}
