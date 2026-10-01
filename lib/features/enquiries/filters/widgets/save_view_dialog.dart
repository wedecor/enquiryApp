import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../ui/primitives/primitives.dart';
import '../filters_state.dart';
import '../saved_views_repo.dart';

/// Glass dialog for saving a new view or editing an existing one.
class SaveViewDialog extends ConsumerStatefulWidget {
  const SaveViewDialog({super.key, this.existingView, required this.currentFilters});

  final SavedView? existingView;
  final EnquiryFilters currentFilters;

  @override
  ConsumerState<SaveViewDialog> createState() => _SaveViewDialogState();
}

class _SaveViewDialogState extends ConsumerState<SaveViewDialog> {
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
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final isEditing = widget.existingView != null;
    final descriptions = widget.currentFilters.activeFilterDescriptions;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassPanel(
          blur: true,
          strong: true,
          shadow: true,
          borderRadius: AppRadius.xLarge,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space6,
            AppTokens.space6,
            AppTokens.space6,
            AppTokens.space5,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Eyebrow(isEditing ? 'Saved view' : 'New view', accent: true),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    isEditing ? 'Edit Saved View' : 'Save View',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppTokens.space5),
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
                  const SizedBox(height: AppTokens.space3),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
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
                    const SizedBox(height: AppTokens.space3),
                    GlassPanel(
                      borderRadius: AppRadius.medium,
                      padding: AppSpacing.space4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('Current filters'),
                          const SizedBox(height: AppTokens.space2),
                          if (descriptions.isEmpty)
                            Text(
                              'No filters applied',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          else
                            for (final desc in descriptions)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    StatusDot(color: s.accent, size: 5),
                                    const SizedBox(width: AppTokens.space2),
                                    Expanded(child: Text(desc, style: theme.textTheme.bodySmall)),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTokens.space6),
                  Row(
                    children: [
                      Expanded(
                        child: PressScale(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: PressScale(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveView,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'Update' : 'Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
            content: Text(widget.existingView != null ? 'Updated "$name"' : 'Saved "$name"'),
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
