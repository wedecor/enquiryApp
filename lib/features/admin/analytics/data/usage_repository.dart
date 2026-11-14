import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/usage/usage_tracker.dart';
import '../../../reengagement/domain/occasion_reminder.dart';
import '../domain/analytics_models.dart';

/// One IST calendar day of usage for a user.
@immutable
class UsageDayRecord {
  const UsageDayRecord({
    required this.day,
    required this.activeSeconds,
    required this.opens,
    this.firstOpenAt,
    this.lastSeenAt,
    this.platform,
    this.appVersion,
  });

  final String day;
  final int activeSeconds;
  final int opens;
  final DateTime? firstOpenAt;
  final DateTime? lastSeenAt;
  final String? platform;
  final String? appVersion;

  factory UsageDayRecord.fromMap(String id, Map<String, dynamic> data) {
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return UsageDayRecord(
      day: (data['day'] as String?) ?? id,
      activeSeconds: (data['activeSeconds'] as num?)?.toInt() ?? 0,
      opens: (data['opens'] as num?)?.toInt() ?? 0,
      firstOpenAt: ts(data['firstOpenAt']),
      lastSeenAt: ts(data['lastSeenAt']),
      platform: data['platform'] as String?,
      appVersion: data['appVersion'] as String?,
    );
  }
}

/// IST `yyyy-MM-dd` for [instant].
String usageIstDayKey(DateTime instant) {
  final c = IstDate.calendar(instant);
  final y = c.year.toString().padLeft(4, '0');
  final m = c.month.toString().padLeft(2, '0');
  final d = c.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Inclusive IST day keys covering [range] (analytics start inclusive / end exclusive).
(String fromDay, String toDay) usageDayBounds(DateRange range) {
  final from = usageIstDayKey(range.start);
  final to = usageIstDayKey(lastIncludedDay(range));
  return (from, to);
}

class UsageRepository {
  UsageRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String day) =>
      _db.collection('users').doc(uid).collection('usage').doc(day);

  /// Merge write with increments. [firstOpenAt] is the IST day start (stable across
  /// merges so the client never needs to read the doc).
  Future<void> recordDelta(String uid, int seconds, int opens) async {
    if (seconds <= 0 && opens <= 0) return;
    final capped = seconds > UsageTrackerEngine.maxFlushSeconds
        ? UsageTrackerEngine.maxFlushSeconds
        : (seconds < 0 ? 0 : seconds);
    final openDelta = opens < 0 ? 0 : opens;
    final now = DateTime.now();
    final day = usageIstDayKey(now);
    final ist = IstDate.calendar(now);
    final dayStart = IstDate.startOfDay(ist.year, ist.month, ist.day);
    const ttl = Duration(days: 180);
    final expireAt = dayStart.add(ttl);
    final platform = kIsWeb ? 'web' : 'android';
    final info = await PackageInfo.fromPlatform();
    final appVersion = '${info.version}+${info.buildNumber}';

    await _doc(uid, day).set({
      'day': day,
      // increment(0) is a no-op on existing docs and seeds 0 on create.
      'activeSeconds': FieldValue.increment(capped),
      'opens': FieldValue.increment(openDelta),
      'firstOpenAt': Timestamp.fromDate(dayStart),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'platform': platform,
      'appVersion': appVersion,
      'expireAt': Timestamp.fromDate(expireAt),
    }, SetOptions(merge: true));
  }

  /// Days in `[fromDay, toDay]` inclusive, ordered by day ascending.
  Future<List<UsageDayRecord>> usageFor(String uid, String fromDay, String toDay) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('usage')
        .where('day', isGreaterThanOrEqualTo: fromDay)
        .where('day', isLessThanOrEqualTo: toDay)
        .orderBy('day')
        .get();
    return snap.docs.map((d) => UsageDayRecord.fromMap(d.id, d.data())).toList();
  }
}

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(ref.watch(firestoreServiceProvider).firestore);
});

class FirestoreUsageFlushSink implements UsageFlushSink {
  FirestoreUsageFlushSink(this._repo);

  final UsageRepository _repo;

  @override
  Future<void> flush({required String uid, required int activeSeconds, required int opens}) {
    return _repo.recordDelta(uid, activeSeconds, opens);
  }
}
