import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/status_vocabulary.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/analytics_repository.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/analytics_models.dart';

void main() {
  group('KPI calculations (F-05, F-06)', () {
    test('approved enquiry with totalCost counts toward revenue (won category)', () {
      final raw = [
        {'statusValue': 'approved', 'eventTypeValue': 'wedding', 'totalCost': 42000},
        {'statusValue': 'new', 'eventTypeValue': 'birthday', 'totalCost': 99999},
      ];

      final revenue = AnalyticsRepository.aggregateSumRevenue(raw);
      expect(revenue, 42000);

      final statusCounts = AnalyticsRepository.aggregateCountByStatus(raw);
      final wonCount = statusCounts.entries
          .where((e) => EnquiryStatusCategory.fromStatus(e.key) == EnquiryStatusCategory.won)
          .fold<int>(0, (sum, e) => sum + e.value);
      expect(wonCount, 1);
      expect(EnquiryStatus.fromValue('approved')?.category, StatusCategory.won);
    });

    test('topEventTypes derives from event types not statuses (F-05)', () {
      final eventTypeCounts = {'wedding': 5, 'birthday': 3};
      final statusCounts = {'new': 8, 'approved': 2};

      final eventTypeBreakdown =
          eventTypeCounts.entries
              .map(
                (e) => CategoryCount(
                  key: e.key,
                  label: e.key,
                  count: e.value,
                  percentage: 0,
                ),
              )
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count));

      final statusBreakdown =
          statusCounts.entries
              .map(
                (e) => CategoryCount(
                  key: e.key,
                  label: e.key,
                  count: e.value,
                  percentage: 0,
                ),
              )
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count));

      final topEventTypes = eventTypeBreakdown.take(10).toList();
      final wrongTopFromStatus = statusBreakdown.take(10).toList();

      expect(topEventTypes.first.key, 'wedding');
      expect(topEventTypes.map((c) => c.key), isNot(contains('new')));
      expect(wrongTopFromStatus.first.key, 'new');
      expect(topEventTypes.first.key, isNot(equals(wrongTopFromStatus.first.key)));
    });

    test('scheduled enquiry also counts toward revenue', () {
      final raw = [
        {'statusValue': 'scheduled', 'totalCost': 15000},
        {'statusValue': 'completed', 'totalCost': 25000},
      ];
      expect(AnalyticsRepository.aggregateSumRevenue(raw), 40000);
    });
  });
}
