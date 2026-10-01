import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../domain/analytics_models.dart';
import '../analytics_controller.dart';

/// Compact, collapsible filter panel with date presets and dropdown filters.
class AnalyticsFiltersPanel extends ConsumerStatefulWidget {
  const AnalyticsFiltersPanel({super.key, required this.onCustomDateRange});

  final Future<void> Function(DateRange currentRange) onCustomDateRange;

  @override
  ConsumerState<AnalyticsFiltersPanel> createState() => _AnalyticsFiltersPanelState();
}

class _AnalyticsFiltersPanelState extends ConsumerState<AnalyticsFiltersPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space1,
        AppTokens.space4,
        AppTokens.space3,
      ),
      child: Card.filled(
        color: cs.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadius.large,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                  vertical: AppTokens.space3,
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded, size: AppTokens.iconMedium, color: cs.primary),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text(
                        'Filters',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
              Padding(
                padding: const EdgeInsets.all(AppTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date range',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    _DateRangeChips(onCustomDateRange: widget.onCustomDateRange),
                    const SizedBox(height: AppTokens.space4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < AppTokens.breakpointTablet;
                        if (isMobile) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _EventTypeFilter()),
                                  const SizedBox(width: AppTokens.space3),
                                  Expanded(child: _StatusFilter()),
                                ],
                              ),
                              const SizedBox(height: AppTokens.space3),
                              Row(
                                children: [
                                  Expanded(child: _PriorityFilter()),
                                  const SizedBox(width: AppTokens.space3),
                                  Expanded(child: _SourceFilter()),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: _EventTypeFilter()),
                            const SizedBox(width: AppTokens.space3),
                            Expanded(child: _StatusFilter()),
                            const SizedBox(width: AppTokens.space3),
                            Expanded(child: _PriorityFilter()),
                            const SizedBox(width: AppTokens.space3),
                            Expanded(child: _SourceFilter()),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRangeChips extends ConsumerWidget {
  const _DateRangeChips({required this.onCustomDateRange});

  final Future<void> Function(DateRange currentRange) onCustomDateRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final analyticsAsync = ref.watch(analyticsControllerProvider);

    return analyticsAsync.when(
      data: (state) {
        final selected = state.filters.preset;
        return Wrap(
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          children: DateRangePreset.values.map((preset) {
            final isSelected = selected == preset;
            return FilterChip(
              label: Text(preset.label),
              selected: isSelected,
              showCheckmark: false,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              selectedColor: cs.primaryContainer,
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.4)
                    : cs.outlineVariant.withValues(alpha: 0.6),
              ),
              onSelected: (_) async {
                if (preset == DateRangePreset.custom) {
                  await onCustomDateRange(state.filters.dateRange);
                } else {
                  ref.read(analyticsControllerProvider.notifier).updateDateRangePreset(preset);
                }
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

InputDecoration _filterDecoration(String label) {
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    border: OutlineInputBorder(borderRadius: AppRadius.medium),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppTokens.space3,
      vertical: AppTokens.space2,
    ),
  );
}

class _EventTypeFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventTypesAsync = ref.watch(eventTypesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return eventTypesAsync.when(
      data: (eventTypes) {
        final currentEventType = analyticsAsync.value?.filters.eventType;
        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: currentEventType,
          decoration: _filterDecoration('Event Type'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All Event Types')),
            ...eventTypes.map((eventType) {
              final label =
                  dropdownLookup?.labelForEventType(eventType) ??
                  DropdownLookup.titleCase(eventType);
              return DropdownMenuItem<String?>(value: eventType, child: Text(label));
            }),
          ],
          onChanged: (eventType) {
            ref.read(analyticsControllerProvider.notifier).updateEventTypeFilter(eventType);
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Event Type'),
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Event Type (Error)'),
      ),
    );
  }
}

class _StatusFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(statusesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return statusesAsync.when(
      data: (statuses) {
        final currentStatus = analyticsAsync.value?.filters.status;
        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: currentStatus,
          decoration: _filterDecoration('Status'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All Statuses')),
            ...statuses.map((status) {
              final label =
                  dropdownLookup?.labelForStatus(status) ?? DropdownLookup.titleCase(status);
              return DropdownMenuItem<String?>(value: status, child: Text(label));
            }),
          ],
          onChanged: (status) {
            ref.read(analyticsControllerProvider.notifier).updateStatusFilter(status);
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Status'),
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Status (Error)'),
      ),
    );
  }
}

class _PriorityFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prioritiesAsync = ref.watch(prioritiesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return prioritiesAsync.when(
      data: (priorities) {
        final currentPriority = analyticsAsync.value?.filters.priority;
        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: currentPriority,
          decoration: _filterDecoration('Priority'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All Priorities')),
            ...priorities.map((priority) {
              final label =
                  dropdownLookup?.labelForPriority(priority) ?? DropdownLookup.titleCase(priority);
              return DropdownMenuItem<String?>(value: priority, child: Text(label));
            }),
          ],
          onChanged: (priority) {
            ref.read(analyticsControllerProvider.notifier).updatePriorityFilter(priority);
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Priority'),
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Priority (Error)'),
      ),
    );
  }
}

class _SourceFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(sourcesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return sourcesAsync.when(
      data: (sources) {
        final currentSource = analyticsAsync.value?.filters.source;
        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: currentSource,
          decoration: _filterDecoration('Source'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All Sources')),
            ...sources.map((source) {
              final label =
                  dropdownLookup?.labelForSource(source) ?? DropdownLookup.titleCase(source);
              return DropdownMenuItem<String?>(value: source, child: Text(label));
            }),
          ],
          onChanged: (source) {
            ref.read(analyticsControllerProvider.notifier).updateSourceFilter(source);
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Source'),
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _filterDecoration('Source (Error)'),
      ),
    );
  }
}
