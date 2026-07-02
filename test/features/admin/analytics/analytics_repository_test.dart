import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/analytics_repository.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/analytics_models.dart';
import 'package:we_decor_enquiries/features/admin/dropdowns/domain/dropdown_item.dart';

void main() {
  group('AnalyticsRepository aggregators', () {
    final raw = [
      {
        'statusValue': 'approved',
        'eventTypeValue': 'wedding',
        'sourceValue': 'instagram',
        'priorityValue': 'high',
        'totalCost': 50000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 15)),
      },
      {
        'statusValue': 'new',
        'eventType': 'birthday',
        'source': 'referral',
        'priority': 'low',
        'totalCost': 10000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 16)),
      },
      {
        'statusValue': 'completed',
        'eventTypeValue': 'wedding',
        'sourceValue': 'instagram',
        'priorityValue': 'medium',
        'totalCost': 75000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 17)),
      },
    ];

    test('aggregateCountByStatus counts canonical status values', () {
      final counts = AnalyticsRepository.aggregateCountByStatus(raw);
      expect(counts['approved'], 1);
      expect(counts['new'], 1);
      expect(counts['completed'], 1);
    });

    test('aggregateCountByEventType uses canonical and legacy fields', () {
      final counts = AnalyticsRepository.aggregateCountByEventType(raw);
      expect(counts['wedding'], 2);
      expect(counts['birthday'], 1);
    });

    test('aggregateSumRevenue includes won-category enquiries only', () {
      final revenue = AnalyticsRepository.aggregateSumRevenue(raw);
      expect(revenue, 125000);
    });

    test('aggregateTimeSeries buckets createdAt values', () {
      final dateRange = DateRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 2, 1));
      final series = AnalyticsRepository.aggregateTimeSeries(
        raw,
        dateRange: dateRange,
        bucket: TimeBucket.day,
      );

      final jan15 = series.firstWhere((point) => point.x == DateTime(2026, 1, 15));
      final jan16 = series.firstWhere((point) => point.x == DateTime(2026, 1, 16));
      expect(jan15.count, 1);
      expect(jan16.count, 1);
    });
  });

  group('DropdownGroup enquiryFieldNames', () {
    test('event types map to canonical and legacy fields', () {
      expect(DropdownGroup.eventTypes.enquiryFieldNames, ['eventTypeValue', 'eventType']);
      expect(DropdownGroup.eventTypes.enquiryLabelFieldName, 'eventTypeLabel');
    });

    test('sources map to canonical and legacy fields', () {
      expect(DropdownGroup.sources.enquiryFieldNames, ['sourceValue', 'source']);
    });
  });
}
