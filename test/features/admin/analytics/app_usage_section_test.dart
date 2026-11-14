import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/usage_summary.dart';
import 'package:we_decor_enquiries/features/admin/analytics/presentation/usage_providers.dart';
import 'package:we_decor_enquiries/features/admin/analytics/presentation/widgets/app_usage_section.dart';

UsageUserSummary _summary({
  required String name,
  int seconds = 0,
  int opens = 0,
  int daysActive = 0,
  DateTime? lastSeen,
}) {
  return UsageUserSummary(
    uid: name.toLowerCase(),
    name: name,
    days: const [],
    totalSeconds: seconds,
    totalOpens: opens,
    daysActive: daysActive,
    lastSeenAt: lastSeen,
    platform: seconds > 0 ? 'android' : null,
    appVersion: seconds > 0 ? '2.0.34+65' : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSection(WidgetTester tester, List<UsageUserSummary> summaries) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [teamAppUsageProvider.overrideWith((ref) async => summaries)],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AppUsageSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders rows and No activity muted state', (tester) async {
    await pumpSection(tester, [
      _summary(
        name: 'Active',
        seconds: 7200,
        opens: 4,
        daysActive: 2,
        lastSeen: DateTime.utc(2026, 11, 14, 10),
      ),
      _summary(name: 'Idle'),
    ]);

    expect(find.text('Time spent in the app'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('No activity'), findsOneWidget);
    expect(
      find.textContaining('Recorded from version $kUsageTrackingSinceVersion'),
      findsOneWidget,
    );
  });

  testWidgets('sort by name puts inactive last then orders active', (tester) async {
    await pumpSection(tester, [
      _summary(name: 'Zoe', seconds: 60, opens: 1, daysActive: 1),
      _summary(name: 'Ada', seconds: 120, opens: 2, daysActive: 1),
      _summary(name: 'Bo'),
    ]);

    // Default sort is time desc → Ada (120) then Zoe (60) then Bo.
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    final ada = texts.indexOf('Ada');
    final zoe = texts.indexOf('Zoe');
    final bo = texts.indexOf('Bo');
    expect(ada, lessThan(zoe));
    expect(zoe, lessThan(bo));

    await tester.tap(find.text('NAME'));
    await tester.pumpAndSettle();
    final after = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    // Name ascending among active; inactive still last.
    expect(after.indexOf('Ada'), lessThan(after.indexOf('Zoe')));
    expect(after.indexOf('Zoe'), lessThan(after.indexOf('Bo')));
  });

  testWidgets('period change reloads when provider data changes', (tester) async {
    var periodA = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamAppUsageProvider.overrideWith((ref) async {
            if (periodA) {
              return [_summary(name: 'Week', seconds: 3600, opens: 1, daysActive: 1)];
            }
            return [_summary(name: 'Month', seconds: 7200, opens: 2, daysActive: 2)];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AppUsageSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsNothing);

    periodA = false;
    final container = ProviderScope.containerOf(tester.element(find.byType(AppUsageSection)));
    container.invalidate(teamAppUsageProvider);
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Week'), findsNothing);
  });
}
