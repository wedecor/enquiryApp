import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../ui/primitives/primitives.dart';
import 'reengagement_providers.dart';
import 'upcoming_occasions_screen.dart';
import 'widgets/occasion_row.dart';

/// Dashboard card: pending yearly reminders (count + next 3, "See all").
/// Renders nothing while loading, on error, or when there is nothing to send.
class UpcomingOccasionsSection extends ConsumerWidget {
  const UpcomingOccasionsSection({super.key});

  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(upcomingRemindersProvider).valueOrNull;
    if (reminders == null || reminders.isEmpty) return const SizedBox.shrink();

    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    final preview = reminders.take(_previewCount).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: GlassPanel(
        strong: true,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space3,
          AppTokens.space2,
          AppTokens.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Eyebrow('Upcoming occasions', accent: true),
                      const SizedBox(height: 2),
                      Text(
                        reminders.length == 1
                            ? '1 customer to wish'
                            : '${reminders.length} customers to wish',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => const UpcomingOccasionsScreen()),
                  ),
                  style: TextButton.styleFrom(foregroundColor: s.accentInk),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space1),
            for (final reminder in preview) OccasionRow(reminder: reminder),
          ],
        ),
      ),
    );
  }
}
