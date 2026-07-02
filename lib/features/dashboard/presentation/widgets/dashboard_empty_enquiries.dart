import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Empty state shown when a dashboard enquiry tab has no results.
class DashboardEmptyEnquiries extends StatelessWidget {
  const DashboardEmptyEnquiries({
    super.key,
    required this.status,
    this.searchQuery,
    this.onClearSearch,
  });

  final String status;
  final String? searchQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.horizontal6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'No matches found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                'Nothing matches "$searchQuery"',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (onClearSearch != null) ...[
                const SizedBox(height: AppTokens.space4),
                OutlinedButton(
                  onPressed: onClearSearch,
                  child: const Text('Clear search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final message = switch (status) {
      'All' => 'No enquiries found',
      'reminders' => 'No upcoming follow-ups in the next 21 days',
      'closed' => 'No closed enquiries yet',
      'approved' => 'No approved enquiries',
      _ => 'No $status enquiries',
    };

    return Center(
      child: Padding(
        padding: AppSpacing.horizontal6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 32,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Tap + to create a new enquiry',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
