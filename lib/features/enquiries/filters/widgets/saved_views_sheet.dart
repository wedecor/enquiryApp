import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../ui/primitives/primitives.dart';
import '../filters_controller.dart';
import '../filters_state.dart';
import '../saved_views_repo.dart';
import 'save_view_dialog.dart';
import 'saved_view_tile.dart';

/// Bottom sheet for managing saved enquiry filter views
class SavedViewsSheet extends ConsumerWidget {
  const SavedViewsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedViewsAsync = ref.watch(savedViewsProvider);
    final currentFilters = ref.watch(enquiryFiltersProvider);
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: GlassPanel(
        blur: true,
        strong: true,
        borderRadius: AppRadius.only(
          topLeft: AppTokens.radiusXXLarge,
          topRight: AppTokens.radiusXXLarge,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space3,
              AppTokens.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('Library', accent: true),
                          const SizedBox(height: AppTokens.space1),
                          SplitHeading(
                            light: 'Saved',
                            bold: 'Views',
                            maxLines: 1,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space4),
                if (currentFilters.hasActiveFilters) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: AppTokens.space2),
                    child: SizedBox(
                      width: double.infinity,
                      child: PressScale(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSaveViewDialog(context, ref),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Save Current Filters'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                ],
                Expanded(
                  child: savedViewsAsync.when(
                    data: (views) => _buildViewsList(context, ref, views),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => ErrorState(
                      message: 'Failed to load saved views\n$error',
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.space6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewsList(BuildContext context, WidgetRef ref, List<SavedView> views) {
    if (views.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.bookmark_outline,
          eyebrow: 'Library',
          title: 'No saved views yet',
          message: 'Save your current filters as a view\nto quickly access them later.',
          action: () => _showSaveViewDialog(context, ref),
          actionText: 'Create First View',
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space6),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(right: AppTokens.space2),
      itemCount: views.length,
      itemBuilder: (context, index) {
        final view = views[index];
        return StaggerIn(
          index: index,
          child: SavedViewTile(
            view: view,
            onApply: () => _applyView(ref, view),
            onEdit: () => _editView(context, ref, view),
            onDelete: () => _deleteView(context, ref, view),
            onSetDefault: () => _setDefaultView(ref, view),
          ),
        );
      },
    );
  }

  void _applyView(WidgetRef ref, SavedView view) {
    ref.read(enquiryFiltersProvider.notifier).applyFilters(view.filters);
    Logger.info('Applied saved view: ${view.name}', tag: 'SavedViews');
  }

  void _editView(BuildContext context, WidgetRef ref, SavedView view) {
    _showSaveViewDialog(context, ref, existingView: view);
  }

  Future<void> _deleteView(BuildContext context, WidgetRef ref, SavedView view) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Saved View',
      message: 'Are you sure you want to delete "${view.name}"?',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    try {
      await ref.read(savedViewsRepositoryProvider).deleteView(view.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "${view.name}"')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete view: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _setDefaultView(WidgetRef ref, SavedView view) {
    if (view.isDefault) return;

    ref.read(savedViewsRepositoryProvider).setDefaultView(view.id);
    Logger.info('Set default view: ${view.name}', tag: 'SavedViews');
  }

  void _showSaveViewDialog(BuildContext context, WidgetRef ref, {SavedView? existingView}) {
    showDialog<void>(
      context: context,
      builder: (context) => SaveViewDialog(
        existingView: existingView,
        currentFilters: ref.read(enquiryFiltersProvider),
      ),
    );
  }
}

/// Function to show the saved views sheet
void showSavedViewsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => const SavedViewsSheet(),
  );
}
