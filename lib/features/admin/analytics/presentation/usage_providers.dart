import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../users/presentation/users_providers.dart';
import '../data/usage_repository.dart';
import '../domain/usage_summary.dart';
import 'analytics_controller.dart';

/// Cache key for the selected analytics period (IST day bounds).
typedef UsagePeriodKey = ({String fromDay, String toDay});

/// Active staff + admins with usage rolled up for the current analytics period.
///
/// Loads only when watched (Team tab). Cached per period for the provider
/// lifetime (screen); period changes invalidate via the date-range dependency.
final teamAppUsageProvider = FutureProvider.autoDispose<List<UsageUserSummary>>((ref) async {
  final analytics = await ref.watch(analyticsControllerProvider.future);
  final range = analytics.filters.dateRange;
  final (fromDay, toDay) = usageDayBounds(range);

  final users = await ref.watch(usersStreamProvider.future);
  final active = users.where((u) => u.isActive).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final repo = ref.watch(usageRepositoryProvider);
  final summaries = await Future.wait(
    active.map((u) async {
      final days = await repo.usageFor(u.uid, fromDay, toDay);
      return UsageUserSummary.aggregate(uid: u.uid, name: u.name, days: days);
    }),
  );
  return summaries;
});
