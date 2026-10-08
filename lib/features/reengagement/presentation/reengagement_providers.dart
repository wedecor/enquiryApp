import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../../../shared/models/user_model.dart';
import '../data/reengagement_repository.dart';
import '../domain/occasion_reminder.dart';
import '../domain/reengagement_config.dart';

/// `app_config/reengagement` (defaults when the doc is missing). Consumers use
/// `valueOrNull ?? const ReengagementConfig()` so a read error falls back to defaults.
final reengagementConfigProvider = StreamProvider<ReengagementConfig>((ref) {
  return ref.watch(reengagementRepositoryProvider).watchConfig();
});

/// Pending reminders from today for the next 30 days (or the lead time, if
/// longer), soonest first. Admins: all; staff: their own.
final upcomingRemindersProvider = StreamProvider.autoDispose<List<OccasionReminder>>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  final role = ref.watch(roleProvider).valueOrNull;
  if (uid == null || role == null) return const Stream<List<OccasionReminder>>.empty();
  final config = ref.watch(reengagementConfigProvider).valueOrNull ?? const ReengagementConfig();
  final from = IstDate.todayStart(DateTime.now());
  final to = from.add(Duration(days: config.windowDays + 1));
  return ref
      .watch(reengagementRepositoryProvider)
      .watchPending(isAdmin: role == UserRole.admin, uid: uid, from: from, to: to);
});
