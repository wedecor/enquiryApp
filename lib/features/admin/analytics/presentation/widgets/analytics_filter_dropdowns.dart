import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../services/dropdown_lookup.dart';
import '../analytics_controller.dart';

InputDecoration _filterDecoration(String label) {
  return InputDecoration(labelText: label, isDense: true);
}

Widget _disabledDropdown(String label) {
  return DropdownButtonFormField<String>(
    items: const [],
    onChanged: null,
    decoration: _filterDecoration(label),
  );
}

DropdownLookup? _lookup(WidgetRef ref) =>
    ref.watch(dropdownLookupProvider).maybeWhen(data: (value) => value, orElse: () => null);

class AnalyticsEventTypeFilter extends ConsumerWidget {
  const AnalyticsEventTypeFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventTypesAsync = ref.watch(eventTypesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = _lookup(ref);

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
      loading: () => _disabledDropdown('Event Type'),
      error: (error, stack) => _disabledDropdown('Event Type (Error)'),
    );
  }
}

class AnalyticsStatusFilter extends ConsumerWidget {
  const AnalyticsStatusFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(statusesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = _lookup(ref);

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
      loading: () => _disabledDropdown('Status'),
      error: (error, stack) => _disabledDropdown('Status (Error)'),
    );
  }
}

class AnalyticsPriorityFilter extends ConsumerWidget {
  const AnalyticsPriorityFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prioritiesAsync = ref.watch(prioritiesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = _lookup(ref);

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
      loading: () => _disabledDropdown('Priority'),
      error: (error, stack) => _disabledDropdown('Priority (Error)'),
    );
  }
}

class AnalyticsSourceFilter extends ConsumerWidget {
  const AnalyticsSourceFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(sourcesForFilterProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final dropdownLookup = _lookup(ref);

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
      loading: () => _disabledDropdown('Source'),
      error: (error, stack) => _disabledDropdown('Source (Error)'),
    );
  }
}
