import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/audit_provider.dart';
import '../../core/theme/tokens.dart';
import '../../services/dropdown_lookup.dart';
import '../../ui/primitives/primitives.dart';
import 'empty_state.dart';
import 'enquiry_history_item.dart';

/// Enquiry change history as a vertical timeline: a thin painted rail with a
/// [StatusDot] node per audit entry, newest first.
class EnquiryHistoryWidget extends ConsumerWidget {
  final String enquiryId;

  const EnquiryHistoryWidget({super.key, required this.enquiryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(enquiryHistoryProvider(enquiryId));

    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            eyebrow: 'Timeline',
            title: 'No changes recorded',
            message: 'Changes to this enquiry will appear here',
            padding: EdgeInsets.symmetric(vertical: AppTokens.space6),
          );
        }

        final theme = Theme.of(context);
        final count = history.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space4),
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
                      text: ' change${count == 1 ? '' : 's'} recorded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < count; i++)
              StaggerIn(
                index: i,
                child: EnquiryHistoryTimelineItem(
                  change: history[i],
                  dropdownLookup: dropdownLookup,
                  isFirst: i == 0,
                  isLast: i == count - 1,
                ),
              ),
          ],
        );
      },
      loading: () {
        final theme = Theme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Loading change history...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) => const EmptyState(
        icon: Icons.info_outline,
        eyebrow: 'Timeline',
        title: 'Change history not available',
        message: 'This feature requires additional setup',
        padding: EdgeInsets.symmetric(vertical: AppTokens.space6),
      ),
    );
  }
}

/// Extension to convert string to title case
extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
