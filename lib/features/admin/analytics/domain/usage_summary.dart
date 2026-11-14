import '../../../reengagement/domain/occasion_reminder.dart';
import '../data/usage_repository.dart';

/// Per-user rollup of [UsageDayRecord]s for a selected period.
class UsageUserSummary {
  const UsageUserSummary({
    required this.uid,
    required this.name,
    required this.days,
    required this.totalSeconds,
    required this.totalOpens,
    required this.daysActive,
    this.lastSeenAt,
    this.platform,
    this.appVersion,
  });

  final String uid;
  final String name;
  final List<UsageDayRecord> days;
  final int totalSeconds;
  final int totalOpens;
  final int daysActive;
  final DateTime? lastSeenAt;
  final String? platform;
  final String? appVersion;

  bool get hasActivity => daysActive > 0 || totalSeconds > 0 || totalOpens > 0;

  /// Average seconds per day that had any activity.
  int get averageSecondsPerActiveDay => daysActive == 0 ? 0 : (totalSeconds / daysActive).round();

  static UsageUserSummary aggregate({
    required String uid,
    required String name,
    required List<UsageDayRecord> days,
  }) {
    var seconds = 0;
    var opens = 0;
    var active = 0;
    DateTime? lastSeen;
    String? platform;
    String? appVersion;
    for (final d in days) {
      seconds += d.activeSeconds;
      opens += d.opens;
      if (d.activeSeconds > 0 || d.opens > 0) active += 1;
      final seen = d.lastSeenAt;
      if (seen != null && (lastSeen == null || seen.isAfter(lastSeen))) {
        lastSeen = seen;
        platform = d.platform ?? platform;
        appVersion = d.appVersion ?? appVersion;
      }
    }
    final sorted = [...days]..sort((a, b) => a.day.compareTo(b.day));
    return UsageUserSummary(
      uid: uid,
      name: name,
      days: sorted,
      totalSeconds: seconds,
      totalOpens: opens,
      daysActive: active,
      lastSeenAt: lastSeen,
      platform: platform,
      appVersion: appVersion,
    );
  }
}

String formatUsageDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0m';
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Relative last-active label using IST calendar days.
String formatLastActive(DateTime? lastSeen, {DateTime? now}) {
  if (lastSeen == null) return 'No activity';
  final n = now ?? DateTime.now();
  final today = IstDate.calendar(n);
  final seen = IstDate.calendar(lastSeen);
  final todayStart = DateTime.utc(today.year, today.month, today.day);
  final seenStart = DateTime.utc(seen.year, seen.month, seen.day);
  final dayDiff = todayStart.difference(seenStart).inDays;
  final time = _formatTime(lastSeen.toLocal());
  if (dayDiff == 0) return 'Today $time';
  if (dayDiff == 1) return 'Yesterday';
  return IstDate.short(lastSeen);
}

String _formatTime(DateTime local) {
  final h = local.hour;
  final m = local.minute.toString().padLeft(2, '0');
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  final ampm = h >= 12 ? 'PM' : 'AM';
  return '$hour12:$m $ampm';
}
