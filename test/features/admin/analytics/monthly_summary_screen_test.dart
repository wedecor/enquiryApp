import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/monthly_summary.dart';
import 'package:we_decor_enquiries/features/admin/analytics/presentation/monthly_summary_controller.dart';
import 'package:we_decor_enquiries/features/admin/analytics/presentation/monthly_summary_screen.dart';

MonthlySummary _sample() {
  final now = DateTime.utc(2026, 11, 15, 9);
  final mid = DateTime.utc(2026, 10, 10, 6);
  return buildMonthlySummary(
    rows: [
      for (var i = 0; i < 6; i++)
        {
          'id': 's$i',
          'statusValue': i < 2 ? 'approved' : 'new',
          'createdAt': mid,
          if (i < 2) 'approvedAt': mid,
          if (i < 2) 'eventDate': DateTime.utc(2026, 10, 22),
          'sourceValue': 'instagram',
          'eventTypeValue': 'wedding',
          'assignedTo': 'u1',
          'contactCount': 2,
          'firstContactAt': mid.add(Duration(hours: i + 1)),
          'customerName': 'Sample $i',
          'phoneNormalized': '910000000$i',
        },
      {
        'id': 'lost',
        'statusValue': 'not_interested',
        'createdAt': mid,
        'lostAt': mid,
        'lostReason': 'price_too_high',
        'sourceValue': 'instagram',
        'eventTypeValue': 'wedding',
        'customerName': 'Lost Sample',
        'phoneNormalized': '9199999999',
      },
    ],
    month: const SummaryMonth(2026, 10),
    now: now,
    wishReminders: const [],
    teamNames: {'u1': 'Asha'},
  );
}

MonthlySummary _empty() {
  return buildMonthlySummary(
    rows: const [],
    month: const SummaryMonth(2026, 10),
    now: DateTime.utc(2026, 11, 15, 9),
    wishReminders: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester, MonthlySummary summary) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthlySummaryMonthProvider.overrideWith((ref) => summary.month),
          monthlySummaryProvider.overrideWith((ref) async => summary),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const MaterialApp(home: MonthlySummaryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders sample monthly summary sections', (tester) async {
    await pumpScreen(tester, _sample());
    expect(find.text('Monthly summary'), findsOneWidget);
    expect(find.text('Share as PDF'), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('What was booked'), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
    expect(find.textContaining('Asha'), findsOneWidget);
  });

  testWidgets('empty month shows empty state', (tester) async {
    await pumpScreen(tester, _empty());
    expect(find.textContaining('No enquiries in October 2026'), findsOneWidget);
    expect(find.text('Share as PDF'), findsNothing);
  });
}
