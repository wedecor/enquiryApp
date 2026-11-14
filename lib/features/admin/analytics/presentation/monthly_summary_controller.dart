import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reengagement/data/reengagement_repository.dart';
import '../../../reengagement/domain/reengagement_stats.dart';
import '../../users/domain/user_model.dart';
import '../../users/presentation/users_providers.dart';
import '../data/analytics_repository.dart';
import '../domain/monthly_summary.dart';

/// Selected IST month for the monthly summary screen.
final monthlySummaryMonthProvider = StateProvider.autoDispose<SummaryMonth>((ref) {
  return SummaryMonth.lastComplete(DateTime.now());
});

/// Last 24 complete months plus the current month (newest first).
List<SummaryMonth> monthlySummaryMonthOptions(DateTime now) {
  final current = SummaryMonth.containing(now);
  final out = <SummaryMonth>[current];
  var m = current.previous;
  for (var i = 0; i < 24; i++) {
    out.add(m);
    m = m.previous;
  }
  return out;
}

String monthlySummaryMonthOptionLabel(SummaryMonth month, DateTime now) {
  final current = SummaryMonth.containing(now);
  if (month == current) return '${month.label} (so far)';
  return month.label;
}

/// Wish reminders sent in [month] (only extra Firestore read for the summary).
final monthlySummaryWishesProvider = FutureProvider.autoDispose
    .family<List<SentReminder>, SummaryMonth>((ref, month) async {
      final repo = ref.watch(reengagementRepositoryProvider);
      // Inclusive end for the repository API: last instant before next month.
      final end = month.endExclusive.subtract(const Duration(milliseconds: 1));
      return repo.fetchSent(month.start, end);
    });

/// Active team uid → display name.
final monthlySummaryTeamNamesProvider = Provider.autoDispose<Map<String, String>>((ref) {
  final users = ref.watch(usersStreamProvider).valueOrNull ?? const <UserModel>[];
  return {
    for (final u in users)
      if (u.isActive) u.uid: u.name,
  };
});

/// Built [MonthlySummary] for the selected month from cached analytics rows.
final monthlySummaryProvider = FutureProvider.autoDispose<MonthlySummary>((ref) async {
  final month = ref.watch(monthlySummaryMonthProvider);
  final rows = await ref.watch(analyticsRawRowsProvider.future);
  final wishes = await ref.watch(monthlySummaryWishesProvider(month).future);
  final teamNames = ref.watch(monthlySummaryTeamNamesProvider);
  return buildMonthlySummary(
    rows: rows,
    month: month,
    now: DateTime.now(),
    wishReminders: wishes,
    teamNames: teamNames,
  );
});
