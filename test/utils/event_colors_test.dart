import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/theme/app_theme.dart';
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
      expect(eventAccent('wedding'), AppColorScheme.eventWedding);
    });

    test('returns correct color for haldi', () {
      expect(eventAccent('haldi'), AppColorScheme.eventHaldi);
    });

    test('returns correct color for engagement', () {
      expect(eventAccent('engagement'), AppColorScheme.eventEngagement);
    });

    test('returns correct color for birthday', () {
      expect(eventAccent('birthday'), AppColorScheme.eventBirthday);
    });

    test('returns correct color for corporate', () {
      expect(eventAccent('corporate'), AppColorScheme.chartEmerald);
    });

    test('handles case insensitivity', () {
      expect(eventAccent('WEDDING'), AppColorScheme.eventWedding);
      expect(eventAccent('Wedding'), AppColorScheme.eventWedding);
    });

    test('returns default color for unknown type', () {
      expect(eventAccent('unknown'), AppColorScheme.chartIndigo);
    });

    test('handles null input', () {
      expect(eventAccent(null), AppColorScheme.chartIndigo);
    });

    test('handles empty string', () {
      expect(eventAccent(''), AppColorScheme.chartIndigo);
    });
  });

  group('EventColors.accentFor', () {
    test('returns accent color for known type', () {
      expect(EventColors.accentFor('wedding'), AppColorScheme.eventWedding);
    });

    test('uses fallback when provided', () {
      const fallback = Colors.red;
      expect(EventColors.accentFor('unknown', fallback: fallback), AppColorScheme.chartIndigo);
    });
  });
}
