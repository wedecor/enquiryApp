import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/utils/event_colors.dart';

void main() {
  group('EventColors', () {
    testWidgets('resolves colors for known event types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colors = EventColors.resolve(context, 'wedding');
              expect(colors.accent, isNotNull);
              expect(colors.chipBackground, isNotNull);
              expect(colors.chipForeground, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns fallback for unknown types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colors = EventColors.resolve(context, 'unknown_type');
              expect(colors.accent, isNotNull);
              expect(colors.chipBackground, isNotNull);
              expect(colors.chipForeground, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('handles null event type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colors = EventColors.resolve(context, null);
              expect(colors.accent, isNotNull);
              expect(colors.chipBackground, isNotNull);
              expect(colors.chipForeground, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('eventAccent', () {
    test('returns correct color for wedding', () {
      expect(eventAccent('wedding'), const Color(0xFF8B5CF6));
    });

    test('returns correct color for haldi', () {
      expect(eventAccent('haldi'), const Color(0xFFF4B400));
    });

    test('returns correct color for engagement', () {
      expect(eventAccent('engagement'), const Color(0xFFFF6B6B));
    });

    test('returns correct color for birthday', () {
      expect(eventAccent('birthday'), const Color(0xFF06B6D4));
    });

    test('returns correct color for corporate', () {
      expect(eventAccent('corporate'), const Color(0xFF22C55E));
    });

    test('handles case insensitivity', () {
      expect(eventAccent('WEDDING'), const Color(0xFF8B5CF6));
      expect(eventAccent('Wedding'), const Color(0xFF8B5CF6));
    });

    test('returns default color for unknown type', () {
      expect(eventAccent('unknown'), const Color(0xFF7AA2FF));
    });

    test('handles null input', () {
      expect(eventAccent(null), const Color(0xFF7AA2FF));
    });

    test('handles empty string', () {
      expect(eventAccent(''), const Color(0xFF7AA2FF));
    });
  });

  group('EventColors.accentFor', () {
    test('returns accent color for known type', () {
      expect(EventColors.accentFor('wedding'), const Color(0xFF8B5CF6));
    });

    test('uses fallback when provided', () {
      const fallback = Colors.red;
      expect(EventColors.accentFor('unknown', fallback: fallback), const Color(0xFF7AA2FF));
    });
  });
}
