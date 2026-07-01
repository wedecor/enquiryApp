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

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: AppTokens.space4),
            Text(
              'No enquiries match "$searchQuery"',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onClearSearch != null) ...[
              SizedBox(height: AppTokens.space3),
              TextButton(onPressed: onClearSearch, child: const Text('Clear search')),
            ],
          ],
        ),
      );
    }

    final message = switch (status) {
      'All' => 'No enquiries found',
      'reminders' => 'No upcoming follow-ups in the next 21 days',
      'closed' => 'No closed enquiries yet',
      _ => 'No $status enquiries',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied, size: 64, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(height: AppTokens.space4),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: AppTokens.space2),
          Text(
            'Tap the + button to create a new enquiry',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
