import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/usage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late UsageRepository repo;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'We Decor',
      packageName: 'com.wedecor.test',
      version: '2.0.34',
      buildNumber: '65',
      buildSignature: '',
    );
    db = FakeFirebaseFirestore();
    repo = UsageRepository(db);
  });

  group('UsageRepository', () {
    test('recordDelta increments seconds and opens via merge', () async {
      await repo.recordDelta('u1', 60, 1);
      await repo.recordDelta('u1', 30, 0);

      final day = usageIstDayKey(DateTime.now());
      final doc = await db.collection('users').doc('u1').collection('usage').doc(day).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['day'], day);
      expect(data['activeSeconds'], 90);
      expect(data['opens'], 1);
      expect(data['platform'], isIn(['android', 'web']));
      expect(data['appVersion'], '2.0.34+65');
      expect(data['firstOpenAt'], isNotNull);
      expect(data['lastSeenAt'], isNotNull);
      expect(data['expireAt'], isNotNull);
    });

    test('recordDelta skips empty deltas', () async {
      await repo.recordDelta('u1', 0, 0);
      final snap = await db.collection('users').doc('u1').collection('usage').get();
      expect(snap.docs, isEmpty);
    });

    test('usageFor returns inclusive day range ordered by day', () async {
      Future<void> seed(String day, int seconds, int opens) async {
        await db.collection('users').doc('u1').collection('usage').doc(day).set({
          'day': day,
          'activeSeconds': seconds,
          'opens': opens,
          'platform': 'android',
          'appVersion': '2.0.34+65',
        });
      }

      await seed('2026-11-10', 100, 1);
      await seed('2026-11-11', 200, 2);
      await seed('2026-11-12', 300, 3);
      await seed('2026-11-13', 400, 4);

      final rows = await repo.usageFor('u1', '2026-11-11', '2026-11-12');
      expect(rows.map((r) => r.day).toList(), ['2026-11-11', '2026-11-12']);
      expect(rows.first.activeSeconds, 200);
      expect(rows.last.opens, 3);
    });
  });
}
