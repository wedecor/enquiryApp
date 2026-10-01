import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/analytics_repository.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/analytics_models.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/dashboard_enquiry_utils.dart';

void main() {
  group('shouldShowInTalks', () {
    test('keeps past-dated and undated in-talks enquiries, incl. legacy values', () {
      final longAgo = Timestamp.fromDate(DateTime(2020, 1, 1));
      expect(shouldShowInTalks({'statusValue': 'in_talks', 'eventDate': longAgo}), isTrue);
      expect(shouldShowInTalks({'statusValue': 'quote_sent', 'createdAt': longAgo}), isTrue);
      expect(shouldShowInTalks({'statusValue': 'approved'}), isFalse);
    });
  });

  group('eventDayOffset', () {
    final now = DateTime(2026, 10, 1, 18, 30);

    test('counts calendar days, not 24h periods', () {
      expect(eventDayOffset(DateTime(2026, 10, 1), now), 0);
      expect(eventDayOffset(DateTime(2026, 10, 2), now), 1);
      expect(eventDayOffset(DateTime(2026, 10, 7, 23, 59), now), 6);
      expect(eventDayOffset(DateTime(2026, 10, 8), now), 7);
      expect(eventDayOffset(DateTime(2026, 9, 30, 23), now), -1);
    });
  });

  group('analytics date ranges', () {
    test('presets end at the start of tomorrow (exclusive)', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      for (final preset in DateRangePreset.values) {
        expect(preset.dateRange.end, tomorrow, reason: preset.name);
      }
    });

    test('lastIncludedDay is the day before an exclusive end', () {
      final range = DateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1));
      expect(lastIncludedDay(range), DateTime(2026, 9, 30));
    });

    test('time series covers the last day but not the exclusive end', () {
      final range = DateRange(start: DateTime(2026, 9, 28), end: DateTime(2026, 10, 1));
      final series = AnalyticsRepository.aggregateTimeSeries(
        [
          {'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30, 21))},
        ],
        dateRange: range,
        bucket: TimeBucket.day,
      );
      expect(series.map((p) => p.x), [
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 30),
      ]);
      expect(series.last.count, 1);
    });
  });
}
