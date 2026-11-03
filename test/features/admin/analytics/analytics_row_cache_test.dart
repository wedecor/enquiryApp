import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/analytics_row_cache.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/pipeline_metrics.dart';

/// Regression: the incremental refresh must produce exactly the rows a full read
/// returns, so every pipeline metric keeps its definition and value.
void main() {
  final t0 = DateTime(2026, 10, 1, 10);
  Map<String, dynamic> row(
    String id, {
    required DateTime updatedAt,
    String status = 'new',
    double? total,
    DateTime? created,
  }) => {
    'id': id,
    'statusValue': status,
    'customerName': 'C $id',
    'eventTypeValue': 'birthday',
    'eventDate': Timestamp.fromDate(DateTime(2026, 12, 1)),
    'createdAt': Timestamp.fromDate(created ?? t0),
    'updatedAt': Timestamp.fromDate(updatedAt),
    if (total != null) 'totalCost': total,
    if (status == 'approved') 'approvedAt': Timestamp.fromDate(updatedAt),
  };

  test('full read then delta merge equals a fresh full read (same pipeline metrics)', () {
    final now = DateTime(2026, 11, 4, 12);
    final initial = [
      row('a', updatedAt: t0),
      row('b', updatedAt: t0.add(const Duration(days: 1))),
      row('c', updatedAt: t0.add(const Duration(days: 2)), status: 'in_talks'),
    ];
    final cache = AnalyticsRowCache.fromFullRead(initial, uid: 'admin1', now: now);
    expect(cache.watermark, t0.add(const Duration(days: 2)));

    // Later: b approved with a total, d created.
    final later = DateTime(2026, 11, 4, 13);
    final changed = [
      row('b', updatedAt: later, status: 'approved', total: 50000),
      row('d', updatedAt: later, created: later),
    ];
    final merged = cache.applyDelta(changed);
    final full = [initial[0], changed[0], initial[2], changed[1]];

    Map<String, Map<String, dynamic>> byId(List<Map<String, dynamic>> rows) => {
      for (final r in rows) r['id'] as String: r,
    };
    expect(byId(merged.rows), byId(full));
    expect(merged.watermark, later);

    PipelineReport report(List<Map<String, dynamic>> rows) => buildPipelineReport(
      allRows: rows,
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 12, 31),
      attribution: AnalyticsAttribution.values.first,
      now: now,
    );
    final a = report(merged.rows);
    final b = report(full);
    expect(a.periodCount, b.periodCount);
    expect(a.bookingsInPeriod, b.bookingsInPeriod);
    expect(a.bookedValueInPeriod, b.bookedValueInPeriod);
    expect(a.overdue.length, b.overdue.length);
    expect(a.lostReasons.length, b.lostReasons.length);
  });

  test('delta query starts before the watermark (overlap)', () {
    final cache = AnalyticsRowCache.fromFullRead(
      [row('a', updatedAt: t0)],
      uid: 'admin1',
      now: t0,
    );
    expect(cache.deltaSince, t0.subtract(AnalyticsRowCache.overlap));
  });

  test('full reload when forced, first load, other user, stale, or no watermark', () {
    final now = DateTime(2026, 11, 4, 12);
    final cache = AnalyticsRowCache.fromFullRead(
      [row('a', updatedAt: t0)],
      uid: 'admin1',
      now: now,
    );
    bool full({AnalyticsRowCache? c, String uid = 'admin1', DateTime? at, bool force = false}) =>
        AnalyticsRowCache.needsFullReload(c, uid: uid, now: at ?? now, force: force);

    expect(full(c: null), isTrue);
    expect(full(c: cache), isFalse);
    expect(full(c: cache, force: true), isTrue);
    expect(full(c: cache, uid: 'admin2'), isTrue);
    expect(full(c: cache, at: now.add(AnalyticsRowCache.maxAge)), isTrue);
    final unstamped = AnalyticsRowCache.fromFullRead(
      [
        {'id': 'x'},
      ],
      uid: 'admin1',
      now: now,
    );
    expect(full(c: unstamped), isTrue);
  });
}
