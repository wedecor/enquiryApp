import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../ui/primitives/primitives.dart';
import '../domain/reengagement_config.dart';
import 'reengagement_providers.dart';
import 'upcoming_occasions_screen.dart';
import 'widgets/occasion_row.dart';

/// Dashboard card: pending yearly reminders (count + next 3, "See all").
/// With nothing pending it collapses to a one-line "View all" card so the
/// Customer occasions screen stays reachable; renders nothing while loading or
/// on error.
class UpcomingOccasionsSection extends ConsumerWidget {
  const UpcomingOccasionsSection({super.key});

  static const int _previewCount = 3;

  static void _openScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const UpcomingOccasionsScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(upcomingRemindersProvider).valueOrNull;
    if (reminders == null) return const SizedBox.shrink();

    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    if (reminders.isEmpty) return _EmptyOccasionsCard(onTap: () => _openScreen(context));
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
                  onPressed: () => _openScreen(context),
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

/// Compact one-line card shown when no reminder is due:
/// "No occasions in the next 30 days · View all".
class _EmptyOccasionsCard extends ConsumerWidget {
  const _EmptyOccasionsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(reengagementConfigProvider).valueOrNull ?? const ReengagementConfig();

    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: Pressable(
        onTap: onTap,
        borderRadius: AppRadius.large,
        semanticLabel: 'Customer occasions',
        child: GlassPanel(
          strong: true,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space1,
            AppTokens.space1,
            AppTokens.space1,
          ),
          child: Row(
            children: [
              Icon(Icons.celebration_outlined, size: AppTokens.iconSmall, color: s.accentInk),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Text(
                  'No occasions in the next ${config.windowDays} days',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(foregroundColor: s.accentInk),
                child: const Text('View all'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
