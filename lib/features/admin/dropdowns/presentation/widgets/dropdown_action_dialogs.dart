import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/components/glass_dialog.dart';
import '../../domain/dropdown_item.dart';
import '../dropdown_providers.dart';
import 'dropdown_item_tile.dart';

/// Dialog for confirming dropdown item deletion
class DropdownDeleteDialog extends ConsumerWidget {
  final DropdownGroup group;
  final DropdownItem item;
  final bool hasReferences;

  const DropdownDeleteDialog({
    super.key,
    required this.group,
    required this.item,
    required this.hasReferences,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return GlassDialog(
      eyebrow: group.displayName,
      title: 'Delete Dropdown Item',
      icon: hasReferences ? Icons.warning_amber_rounded : Icons.delete_outline_rounded,
      iconColor: hasReferences ? AppColorScheme.snackWarning : cs.error,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasReferences) ...[
            Text(
              'Cannot delete "${item.label}" because it is referenced by existing enquiries.',
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            const SizedBox(height: AppTokens.space2),
            const Text(
              'Please deactivate it instead or use the "Replace in enquiries" feature to migrate existing references.',
            ),
          ] else ...[
            Text('Are you sure you want to delete "${item.label}"?'),
            const SizedBox(height: AppTokens.space2),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        if (!hasReferences)
          FilledButton(
            onPressed: () => _confirmDelete(context, ref),
            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            child: const Text('Delete'),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(dropdownFormControllerProvider.notifier).deleteItem(group, item.value);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dropdown item deleted successfully'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      }
    }
  }
}

/// Dialog for replacing dropdown values in enquiries
class DropdownReplaceDialog extends ConsumerStatefulWidget {
  final DropdownGroup group;
  final String oldValue;
  final String oldLabel;

  const DropdownReplaceDialog({
    super.key,
    required this.group,
    required this.oldValue,
    required this.oldLabel,
  });

  @override
  ConsumerState<DropdownReplaceDialog> createState() => _DropdownReplaceDialogState();
}

class _DropdownReplaceDialogState extends ConsumerState<DropdownReplaceDialog> {
  String? _selectedReplacement;

  @override
  Widget build(BuildContext context) {
    final replacementsAsync = ref.watch(
      availableReplacementsProvider((widget.group, widget.oldValue)),
    );
    final formState = ref.watch(dropdownFormControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return GlassDialog(
      eyebrow: widget.group.displayName,
      title: 'Replace in Enquiries',
      icon: Icons.swap_horiz_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Replace all occurrences of "${widget.oldLabel}" with:',
            style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          const SizedBox(height: AppTokens.space4),
          replacementsAsync.when(
            data: (replacements) {
              if (replacements.isEmpty) {
                return const Text(
                  'No other active dropdown items available for replacement.',
                  style: TextStyle(color: AppColorScheme.snackWarning),
                );
              }

              return DropdownButtonFormField<DropdownItem>(
                initialValue: _selectedReplacement != null
                    ? replacements.firstWhere((item) => item.value == _selectedReplacement)
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Replacement Value'),
                items: replacements.map((item) {
                  final swatch = parseDropdownColor(item.color);
                  return DropdownMenuItem<DropdownItem>(
                    value: item,
                    child: Row(
                      children: [
                        if (swatch != null) ...[
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: AppTokens.space2),
                        ],
                        Flexible(child: Text(item.label, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReplacement = value?.value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a replacement value';
                  }
                  return null;
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error loading replacements: $error'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: formState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedReplacement != null && !formState.isLoading
              ? () => _confirmReplace(context)
              : null,
          child: formState.isLoading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Replace'),
        ),
      ],
    );
  }

  Future<void> _confirmReplace(BuildContext context) async {
    if (_selectedReplacement == null) return;

    try {
      await ref
          .read(dropdownFormControllerProvider.notifier)
          .replaceInEnquiries(widget.group, widget.oldValue, _selectedReplacement!);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Values replaced successfully in all enquiries'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      }
    }
  }
}
