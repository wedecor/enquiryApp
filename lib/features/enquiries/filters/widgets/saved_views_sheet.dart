import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../filters_controller.dart';
import '../filters_state.dart';
import '../saved_views_repo.dart';

/// Bottom sheet for managing saved enquiry filter views
class SavedViewsSheet extends ConsumerWidget {
  const SavedViewsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedViewsAsync = ref.watch(savedViewsProvider);
    final currentFilters = ref.watch(enquiryFiltersProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: AppSpacing.space4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.bookmark),
              const SizedBox(width: AppTokens.space3),
              Text(
                'Saved Views',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: AppTokens.space4),

          // Save current view button
          if (currentFilters.hasActiveFilters) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSaveViewDialog(context, ref),
                icon: const Icon(Icons.save),
                label: const Text('Save Current Filters'),
              ),
            ),
            const SizedBox(height: AppTokens.space4),
          ],

          // Saved views list
          Expanded(
            child: savedViewsAsync.when(
              data: (views) => _buildViewsList(context, ref, views),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewsList(BuildContext context, WidgetRef ref, List<SavedView> views) {
    if (views.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return ListView.builder(
      itemCount: views.length,
      itemBuilder: (context, index) {
        final view = views[index];
        return _SavedViewTile(
          view: view,
          onApply: () => _applyView(ref, view),
          onEdit: () => _editView(context, ref, view),
          onDelete: () => _deleteView(context, ref, view),
          onSetDefault: () => _setDefaultView(ref, view),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'No saved views yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Save your current filters as a view\nto quickly access them later.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space6),
          ElevatedButton.icon(
            onPressed: () => _showSaveViewDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create First View'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Failed to load saved views',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _applyView(WidgetRef ref, SavedView view) {
    ref.read(enquiryFiltersProvider.notifier).applyFilters(view.filters);
    Logger.info('Applied saved view: ${view.name}', tag: 'SavedViews');
  }

  void _editView(BuildContext context, WidgetRef ref, SavedView view) {
    _showSaveViewDialog(context, ref, existingView: view);
  }

  void _deleteView(BuildContext context, WidgetRef ref, SavedView view) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved View'),
        content: Text('Are you sure you want to delete "${view.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(savedViewsRepositoryProvider).deleteView(view.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${view.name}"')),
                  );
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
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setDefaultView(WidgetRef ref, SavedView view) {
    if (view.isDefault) return;
    
    ref.read(savedViewsRepositoryProvider).setDefaultView(view.id);
    Logger.info('Set default view: ${view.name}', tag: 'SavedViews');
  }

  void _showSaveViewDialog(BuildContext context, WidgetRef ref, {SavedView? existingView}) {
    showDialog(
      context: context,
      builder: (context) => _SaveViewDialog(
        existingView: existingView,
        currentFilters: ref.read(enquiryFiltersProvider),
      ),
    );
  }
}

/// Individual saved view tile widget
class _SavedViewTile extends StatelessWidget {
  const _SavedViewTile({
    required this.view,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final SavedView view;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.space2),
      child: ListTile(
        leading: Icon(
          view.isDefault ? Icons.star : Icons.bookmark_outline,
          color: view.isDefault ? theme.colorScheme.primary : null,
        ),
        title: Text(
          view.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: view.isDefault ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (view.filters.activeFilterDescriptions.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space1),
              ...view.filters.activeFilterDescriptions.map((desc) => Text(
                '• $desc',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )),
            ],
            const SizedBox(height: AppTokens.space1),
            Text(
              'Created ${_formatDate(view.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'apply':
                onApply();
                break;
              case 'edit':
                onEdit();
                break;
              case 'default':
                onSetDefault();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'apply',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Apply'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!view.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: ListTile(
                  leading: Icon(Icons.star),
                  title: Text('Set as Default'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: onApply,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}

/// Dialog for saving a new view or editing an existing one
class _SaveViewDialog extends ConsumerStatefulWidget {
  const _SaveViewDialog({
    this.existingView,
    required this.currentFilters,
  });

  final SavedView? existingView;
  final EnquiryFilters currentFilters;

  @override
  ConsumerState<_SaveViewDialog> createState() => _SaveViewDialogState();
}

class _SaveViewDialogState extends ConsumerState<_SaveViewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingView != null) {
      _nameController.text = widget.existingView!.name;
      _isDefault = widget.existingView!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingView != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Saved View' : 'Save View'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'View Name',
                hintText: 'Enter a name for this view',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.space4),
            CheckboxListTile(
              title: const Text('Set as default view'),
              subtitle: const Text('This view will be applied when the app starts'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
            ),
            if (!isEditing) ...[
              const SizedBox(height: AppTokens.space4),
              Container(
                padding: AppSpacing.space4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadius.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Filters:',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    if (widget.currentFilters.activeFilterDescriptions.isNotEmpty) ...[
                      ...widget.currentFilters.activeFilterDescriptions.map((desc) => Text(
                        '• $desc',
                        style: theme.textTheme.bodySmall,
                      )),
                    ] else ...[
                      Text(
                        'No filters applied',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveView,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _saveView() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(savedViewsRepositoryProvider);
      final name = _nameController.text.trim();

      if (widget.existingView != null) {
        // Update existing view
        final updatedView = widget.existingView!.copyWith(
          name: name,
          isDefault: _isDefault,
          filters: widget.currentFilters,
        );
        await repository.updateView(updatedView);
      } else {
        // Create new view
        await repository.createView(
          name: name,
          filters: widget.currentFilters,
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingView != null
                  ? 'Updated "${name}"'
                  : 'Saved "${name}"',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save view: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

/// Function to show the saved views sheet
void showSavedViewsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SavedViewsSheet(),
  );
}
