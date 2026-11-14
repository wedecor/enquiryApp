import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/timing_metrics.dart';
import 'package:we_decor_enquiries/features/admin/analytics/presentation/timing_controller.dart';
import 'package:we_decor_enquiries/features/admin/analytics/presentation/widgets/timing_sections.dart';

TimingReport _emptyReport() {
  final emptyWeekday = computeEnquiriesByWeekday(const []);
  final emptyGrid = computeEnquiriesByTimeOfDay(const []);
  final emptyResponse = computeResponseByArrival(const []);
  final emptyEvents = computeEventsByWeekday(const []);
  final emptyBusy = computeBusiestDates(const []);
  final emptySeason = computeSeasonByEventType(const [], now: DateTime.utc(2026, 11, 15));
  final emptyLead = computeLeadTimeWithWinRates(const []);
  return TimingReport(
    weekdayEnquiries: emptyWeekday,
    timeOfDay: emptyGrid,
    timeOfDayWebsiteOnly: emptyGrid,
    responseArrival: emptyResponse,
    eventsByWeekday: emptyEvents,
    busiestDates: emptyBusy,
    season: emptySeason,
    leadTime: emptyLead,
  );
}

TimingReport _sampleReport() {
  final sat = DateTime.utc(2026, 11, 14, 6);
  final rows = [
    for (var i = 0; i < 6; i++)
      {
        'id': 'w$i',
        'statusValue': 'approved',
        'createdAt': sat,
        'eventDate': sat.add(const Duration(days: 20)),
        'sourceValue': 'instagram',
        'eventTypeValue': 'wedding',
        'firstContactAt': sat.add(const Duration(hours: 2)),
      },
    {
      'id': 'l0',
      'statusValue': 'not_interested',
      'createdAt': sat,
      'eventDate': sat.add(const Duration(days: 20)),
      'sourceValue': 'google_website',
      'eventTypeValue': 'birthday',
      'firstContactAt': sat.add(const Duration(hours: 5)),
    },
  ];
  return buildTimingReport(
    allRows: rows,
    start: DateTime.utc(2026, 11, 1),
    end: DateTime.utc(2026, 12, 1),
    now: DateTime.utc(2026, 11, 15),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpTab(WidgetTester tester, TimingReport report) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [timingReportProvider.overrideWith((ref) async => report)],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const MaterialApp(home: Scaffold(body: AnalyticsTimingTab())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty data shows empty states for sections', (tester) async {
    await pumpTab(tester, _emptyReport());
    expect(find.text('Enquiries by day of the week'), findsOneWidget);
    expect(find.text('No data available'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('How far ahead people enquire'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('How far ahead people enquire'), findsOneWidget);
  });

  testWidgets('sample data renders weekday summary and lead-time', (tester) async {
    await pumpTab(tester, _sampleReport());
    expect(find.textContaining('Most enquiries arrive on'), findsOneWidget);
    expect(find.text('Saturday'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Busiest dates'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Busiest dates'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Season by event type'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Season by event type'), findsOneWidget);
  });
}
