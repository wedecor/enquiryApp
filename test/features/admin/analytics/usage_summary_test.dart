import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/usage_repository.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/usage_summary.dart';

void main() {
  group('UsageUserSummary.aggregate', () {
    test('rolls up time, opens, days active, average, and last seen', () {
      final days = [
        UsageDayRecord(
          day: '2026-11-10',
          activeSeconds: 3600,
          opens: 2,
          lastSeenAt: DateTime.utc(2026, 11, 10, 12),
          platform: 'android',
          appVersion: '2.0.33+64',
        ),
        UsageDayRecord(
          day: '2026-11-12',
          activeSeconds: 1800,
          opens: 1,
          lastSeenAt: DateTime.utc(2026, 11, 12, 15),
          platform: 'web',
          appVersion: '2.0.34+65',
        ),
        const UsageDayRecord(day: '2026-11-11', activeSeconds: 0, opens: 0),
      ];

      final s = UsageUserSummary.aggregate(uid: 'u1', name: 'Ada', days: days);
      expect(s.totalSeconds, 5400);
      expect(s.totalOpens, 3);
      expect(s.daysActive, 2);
      expect(s.averageSecondsPerActiveDay, 2700);
      expect(s.lastSeenAt, DateTime.utc(2026, 11, 12, 15));
      expect(s.platform, 'web');
      expect(s.appVersion, '2.0.34+65');
      expect(s.hasActivity, isTrue);
      expect(formatUsageDuration(s.totalSeconds), '1h 30m');
      expect(formatUsageDuration(s.averageSecondsPerActiveDay), '45m');
    });

    test('empty days → no activity', () {
      final s = UsageUserSummary.aggregate(uid: 'u1', name: 'Bo', days: const []);
      expect(s.hasActivity, isFalse);
      expect(s.daysActive, 0);
      expect(s.averageSecondsPerActiveDay, 0);
      expect(formatLastActive(null), 'No activity');
    });
  });

  group('formatLastActive', () {
    test('today / yesterday / earlier', () {
      final now = DateTime.utc(2026, 11, 14, 10); // 15:30 IST
      final today = DateTime.utc(2026, 11, 14, 5, 40); // ~11:10 IST
      final yesterday = DateTime.utc(2026, 11, 13, 12);
      final earlier = DateTime.utc(2026, 11, 12, 12);
      expect(formatLastActive(today, now: now), contains('Today'));
      expect(formatLastActive(yesterday, now: now), 'Yesterday');
      expect(formatLastActive(earlier, now: now), '12 Nov');
    });
  });
}
