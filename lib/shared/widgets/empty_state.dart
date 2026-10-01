import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../ui/primitives/primitives.dart';
import 'press_scale.dart';
import 'state_accent.dart';

/// Typographic empty state: a small geometric accent, a tracked eyebrow, a
/// split-weight headline and a quiet body line. Left-aligned and width-capped
/// so it reads like an editorial caption rather than a boxed placeholder.
///
/// The headline defaults to the first line of [message]; the rest becomes the
/// body. Pass [title] to set the headline explicitly.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.actionText,
    this.padding,
    this.eyebrow,
    this.title,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionText;
  final EdgeInsetsGeometry? padding;
  final String? eyebrow;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = StateCopy.from(message, title: title);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StateAccent(icon: icon),
              const SizedBox(height: AppTokens.space5),
              Eyebrow(eyebrow ?? 'Nothing here', accent: true),
              const SizedBox(height: AppTokens.space2),
              SplitHeading(
                light: copy.light,
                bold: copy.bold,
                maxLines: 3,
                style: theme.textTheme.headlineSmall,
              ),
              if (copy.body.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space2),
                Text(
                  copy.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
              if (action != null && actionText != null) ...[
                const SizedBox(height: AppTokens.space5),
                PressScale(
                  child: ElevatedButton(onPressed: action, child: Text(actionText!)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Splits state copy into a whisper/heavy headline and a body paragraph.
class StateCopy {
  const StateCopy(this.light, this.bold, this.body);

  factory StateCopy.from(String message, {String? title}) {
    final lines = message.trim().split('\n');
    final headline = (title ?? lines.first).trim();
    final body = (title == null ? lines.skip(1) : lines).join('\n').trim();
    final cut = headline.lastIndexOf(' ');
    if (cut <= 0) return StateCopy('', headline, body);
    return StateCopy(headline.substring(0, cut), headline.substring(cut + 1), body);
  }

  final String light;
  final String bold;
  final String body;
}

/// Empty state for enquiries list
class EnquiriesEmptyState extends StatelessWidget {
  const EnquiriesEmptyState({super.key, this.onAddEnquiry});

  final VoidCallback? onAddEnquiry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      eyebrow: 'Pipeline',
      message: 'No enquiries found.\nCreate your first enquiry to get started.',
      action: onAddEnquiry,
      actionText: 'Add Enquiry',
    );
  }
}

/// Empty state for filtered results
class FilteredEmptyState extends StatelessWidget {
  const FilteredEmptyState({super.key, this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      eyebrow: 'No matches',
      message: 'No enquiries match your current filters.\nTry adjusting your search criteria.',
      action: onClearFilters,
      actionText: 'Clear Filters',
    );
  }
}

/// Empty state for saved views
class SavedViewsEmptyState extends StatelessWidget {
  const SavedViewsEmptyState({super.key, this.onCreateView});

  final VoidCallback? onCreateView;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.bookmark_outline,
      eyebrow: 'Library',
      message: 'No saved views yet.\nCreate custom views to quickly filter your enquiries.',
      action: onCreateView,
      actionText: 'Create View',
    );
  }
}

/// Empty state for exports
class ExportsEmptyState extends StatelessWidget {
  const ExportsEmptyState({super.key, this.onExport});

  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.file_download_outlined,
      eyebrow: 'Exports',
      message: 'No exports yet.\nExport your enquiry data to CSV format.',
      action: onExport,
      actionText: 'Export Data',
    );
  }
}

/// Empty state for notifications
class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none,
      eyebrow: 'Inbox',
      message: 'No notifications.\nYou\'re all caught up!',
    );
  }
}

/// Empty state for search results
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.query, this.onClearSearch});

  final String query;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      eyebrow: 'No results',
      message: 'No results found for "$query".\nTry a different search term.',
      action: onClearSearch,
      actionText: 'Clear Search',
    );
  }
}

/// Empty state for analytics
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.analytics_outlined,
      eyebrow: 'Insights',
      message: 'No analytics data available.\nData will appear as enquiries are created.',
      action: onRefresh,
      actionText: 'Refresh',
    );
  }
}
