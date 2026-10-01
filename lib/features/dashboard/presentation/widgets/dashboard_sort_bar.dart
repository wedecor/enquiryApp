import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

enum DashboardSortMode { eventDateAsc, eventDateDesc, createdDesc, nameAz }

extension DashboardSortModeLabel on DashboardSortMode {
  String get label => switch (this) {
    DashboardSortMode.eventDateAsc => 'Event date (soonest)',
    DashboardSortMode.eventDateDesc => 'Event date (latest)',
    DashboardSortMode.createdDesc => 'Newest first',
    DashboardSortMode.nameAz => 'Name A→Z',
  };
}

/// Result count (heavy figure + whisper noun) with a glass sort chip.
class DashboardSortBar extends StatelessWidget {
  const DashboardSortBar({
    super.key,
    required this.count,
    required this.current,
    required this.onSortSelected,
  });

  final int count;
  final DashboardSortMode current;
  final ValueChanged<DashboardSortMode> onSortSelected;

  Future<void> _showSortSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);

    final selected = await showModalBottomSheet<DashboardSortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  0,
                  AppTokens.space5,
                  AppTokens.space3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Order', accent: true),
                    const SizedBox(height: AppTokens.space1),
                    Text(
                      'Sort enquiries',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              ...DashboardSortMode.values.map((mode) {
                final isSelected = mode == current;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? s.accent : cs.onSurfaceVariant,
                  ),
                  title: Text(
                    mode.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(mode),
                );
              }),
              const SizedBox(height: AppTokens.space2),
            ],
          ),
        );
      },
    );

    if (selected != null) onSortSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space1,
        AppTokens.space3,
        AppTokens.space1,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$count',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: ' enquir${count == 1 ? 'y' : 'ies'}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Pressable(
                onTap: () => _showSortSheet(context),
                pressedScale: 0.95,
                borderRadius: AppRadius.full,
                child: SizedBox(
                  height: AppTokens.minTapTarget,
                  child: Center(
                    child: GlassPanel(
                      borderRadius: AppRadius.full,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3,
                        vertical: AppTokens.space2 - 1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            size: AppTokens.iconSmall,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppTokens.space1 + 2),
                          Flexible(
                            child: Text(
                              current.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
