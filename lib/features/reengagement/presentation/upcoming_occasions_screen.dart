import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../ui/components/glass_page_scaffold.dart';
import '../../../ui/components/glass_state_message.dart';
import '../../../ui/primitives/primitives.dart';
import 'reengagement_providers.dart';
import 'widgets/occasion_row.dart';

/// Pending yearly reminders for the next 30 days, soonest first
/// (admins: everyone's; staff: their own).
class UpcomingOccasionsScreen extends ConsumerWidget {
  const UpcomingOccasionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(upcomingRemindersProvider);

    return GlassPageScaffold(
      eyebrow: 'Same time next year',
      title: 'Upcoming occasions',
      body: remindersAsync.when(
        loading: () => const GlassLoadingState(),
        error: (error, _) => GlassStateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Reminders unavailable',
          message: '$error',
          color: Theme.of(context).colorScheme.error,
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const GlassStateMessage(
              icon: Icons.celebration_outlined,
              title: 'Nothing to send right now',
              message:
                  'About a month before a past customer\'s anniversary, birthday or '
                  'yearly celebration, a reminder shows up here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space4,
              AppTokens.space4,
              AppTokens.space12,
            ),
            children: [
              GlassPanel(
                strong: true,
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  AppTokens.space2,
                  AppTokens.space2,
                  AppTokens.space2,
                ),
                child: Column(children: [for (final r in reminders) OccasionRow(reminder: r)]),
              ),
            ],
          );
        },
      ),
    );
  }
}
