import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// A reusable empty state widget with consistent styling
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.actionText,
    this.padding,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionText;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: padding ?? AppSpacing.space8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (icon != null) ...[
              Icon(
                icon,
                size: AppTokens.iconXLarge * 2,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: AppTokens.space6),
            ],
            
            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action button
            if (action != null && actionText != null) ...[
              SizedBox(height: AppTokens.space6),
              ElevatedButton(
                onPressed: action,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for enquiries list
class EnquiriesEmptyState extends StatelessWidget {
  const EnquiriesEmptyState({
    super.key,
    this.onAddEnquiry,
  });

  final VoidCallback? onAddEnquiry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      message: 'No enquiries found.\nCreate your first enquiry to get started.',
      action: onAddEnquiry,
      actionText: 'Add Enquiry',
    );
  }
}

/// Empty state for filtered results
class FilteredEmptyState extends StatelessWidget {
  const FilteredEmptyState({
    super.key,
    this.onClearFilters,
  });

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      message: 'No enquiries match your current filters.\nTry adjusting your search criteria.',
      action: onClearFilters,
      actionText: 'Clear Filters',
    );
  }
}

/// Empty state for saved views
class SavedViewsEmptyState extends StatelessWidget {
  const SavedViewsEmptyState({
    super.key,
    this.onCreateView,
  });

  final VoidCallback? onCreateView;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.bookmark_outline,
      message: 'No saved views yet.\nCreate custom views to quickly filter your enquiries.',
      action: onCreateView,
      actionText: 'Create View',
    );
  }
}

/// Empty state for exports
class ExportsEmptyState extends StatelessWidget {
  const ExportsEmptyState({
    super.key,
    this.onExport,
  });

  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.file_download_outlined,
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
    return EmptyState(
      icon: Icons.notifications_none,
      message: 'No notifications.\nYou\'re all caught up!',
    );
  }
}

/// Empty state for search results
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  final String query;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      message: 'No results found for "$query".\nTry a different search term.',
      action: onClearSearch,
      actionText: 'Clear Search',
    );
  }
}

/// Empty state for analytics
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({
    super.key,
    this.onRefresh,
  });

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.analytics_outlined,
      message: 'No analytics data available.\nData will appear as enquiries are created.',
      action: onRefresh,
      actionText: 'Refresh',
    );
  }
}
