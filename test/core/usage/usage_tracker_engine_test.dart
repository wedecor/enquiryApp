import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/usage/usage_tracker.dart';

void main() {
  late DateTime now;
  late UsageTrackerEngine engine;

  setUp(() {
    now = DateTime.utc(2026, 11, 14, 10, 0, 0);
    engine = UsageTrackerEngine(clock: () => now);
  });

  void advance(Duration d) => now = now.add(d);

  group('UsageTrackerEngine', () {
    test('counts only while foreground and recently interacting', () {
      final open = engine.signIn();
      expect(open?.opens, 1);
      expect(open?.activeSeconds, 0);

      engine.onInteraction();
      advance(const Duration(minutes: 2));
      final flush = engine.onPaused();
      expect(flush?.activeSeconds, 120);
      expect(flush?.opens, 0);
    });

    test('stops after 5 idle minutes and resumes on interaction', () {
      engine.signIn();
      engine.onInteraction();
      advance(const Duration(minutes: 5));
      // Idle deadline hit; no more accrual until interaction.
      advance(const Duration(minutes: 3));
      engine.onInteraction();
      advance(const Duration(seconds: 20));
      final flush = engine.onPaused();
      // 5 min until idle + 20s after re-interact = 320s (under the 330 cap)
      expect(flush?.activeSeconds, 320);
    });

    test('periodic flush every 5 minutes while active', () {
      engine.signIn();
      engine.onInteraction();
      advance(const Duration(minutes: 5));
      final flush = engine.onTick();
      expect(flush?.activeSeconds, 300);
      expect(engine.pendingSeconds, 0);
    });

    test('flushes on pause', () {
      engine.signIn();
      engine.onInteraction();
      advance(const Duration(seconds: 45));
      final flush = engine.onPaused();
      expect(flush?.activeSeconds, 45);
    });

    test('caps flush at 330 seconds and drops excess', () {
      engine.signIn();
      engine.onInteraction();
      advance(const Duration(minutes: 4));
      engine.onInteraction(); // reset idle window; accrue 240
      advance(const Duration(minutes: 4)); // another 240 → 480 pending
      final flush = engine.onPaused();
      expect(flush?.activeSeconds, UsageTrackerEngine.maxFlushSeconds);
    });

    test('new open after 30 minutes in background but not after 5', () {
      engine.signIn();
      engine.onPaused();
      advance(const Duration(minutes: 5));
      expect(engine.onResumed(), isNull);
      expect(engine.pendingOpens, 0);

      engine.onPaused();
      advance(const Duration(minutes: 30));
      engine.onResumed();
      expect(engine.pendingOpens, 1);
      final flush = engine.onPaused();
      expect(flush?.opens, 1);
    });

    test('midnight crossing keeps seconds for the flush (day chosen at write)', () {
      now = DateTime.utc(2026, 11, 14, 18, 29, 0); // 23:59 IST
      engine = UsageTrackerEngine(clock: () => now);
      engine.signIn();
      engine.onInteraction();
      advance(const Duration(minutes: 2)); // crosses IST midnight
      final flush = engine.onPaused();
      expect(flush?.activeSeconds, 120);
    });

    test('nothing recorded when signed out', () {
      expect(engine.signIn()?.opens, 1);
      engine.onPaused();
      engine.signOut();
      engine.onInteraction();
      advance(const Duration(minutes: 2));
      expect(engine.onPaused(), isNull);
      expect(engine.onTick(), isNull);
      expect(engine.pendingSeconds, 0);
      expect(engine.pendingOpens, 0);
    });

    test('never flushes zero', () {
      engine.signIn(); // consumes open flush
      expect(engine.onPaused(), isNull);
      expect(engine.onTick(), isNull);
    });
  });
}
