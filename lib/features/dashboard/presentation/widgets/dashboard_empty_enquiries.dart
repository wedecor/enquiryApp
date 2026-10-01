import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'empty_accent.dart';

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
    final isSearch = searchQuery != null && searchQuery!.isNotEmpty;

    final message = switch (status) {
      'All' => 'No enquiries found',
      'reminders' => 'No upcoming follow-ups in the next 21 days',
      'closed' => 'No closed enquiries yet',
      'approved' => 'No approved enquiries',
      _ => 'No $status enquiries',
    };

    return DashboardEmptyMessage(
      eyebrow: isSearch ? 'Search' : 'All clear',
      title: isSearch ? 'No matches found' : message,
      body: isSearch ? 'Nothing matches "$searchQuery"' : 'Tap + to create a new enquiry',
      actionLabel: isSearch && onClearSearch != null ? 'Clear search' : null,
      onAction: isSearch ? onClearSearch : null,
    );
  }
}

/// Typographic empty message with a small geometric accent — shared by the
/// dashboard list and the calendar agenda.
class DashboardEmptyMessage extends StatelessWidget {
  const DashboardEmptyMessage({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyAccent(),
          const SizedBox(height: AppTokens.space5),
          Eyebrow(eyebrow, accent: true),
          const SizedBox(height: AppTokens.space2),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.4,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppTokens.space2),
            Text(
              body!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppTokens.space4),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
