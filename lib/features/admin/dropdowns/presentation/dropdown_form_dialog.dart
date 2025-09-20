import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/dropdown_item.dart';
import 'dropdown_providers.dart';

/// Dialog for creating or editing dropdown items
class DropdownFormDialog extends ConsumerStatefulWidget {
  final DropdownGroup group;
  final DropdownItem? item; // null for create, non-null for edit

  const DropdownFormDialog({super.key, required this.group, this.item});

  @override
  ConsumerState<DropdownFormDialog> createState() => _DropdownFormDialogState();
}

class _DropdownFormDialogState extends ConsumerState<DropdownFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _labelController;
  late final TextEditingController _colorController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.item?.value ?? '');
    _labelController = TextEditingController(text: widget.item?.label ?? '');
    _colorController = TextEditingController(text: widget.item?.color ?? '');
    _active = widget.item?.active ?? true;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _labelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final formState = ref.watch(dropdownFormControllerProvider);

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit ${widget.group.displayName} Item' : 'Add ${widget.group.displayName} Item',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value field
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g., new, in_progress',
                  border: OutlineInputBorder(),
                ),
                enabled: !isEdit, // Value is immutable on edit
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Value is required';
                  }
                  if (value.contains(' ')) {
                    return 'Value cannot contain spaces';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 16),

              // Label field
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g., New, In Progress',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Label is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color field
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (Optional)',
                  hintText: '#FF9800',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!DropdownItemValidation.isValidHexColor(value)) {
                      return 'Color must be a valid HEX format (#RRGGBB)';
                    }
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 16),

              // Color preview
              if (_colorController.text.isNotEmpty &&
                  DropdownItemValidation.isValidHexColor(_colorController.text))
                _buildColorPreview(),

              const SizedBox(height: 16),

              // Active switch
              Row(
                children: [
                  Switch(
                    value: _active,
                    onChanged: (value) {
                      setState(() {
                        _active = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Active'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: formState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: formState.isLoading ? null : _submitForm,
          child: formState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildColorPreview() {
    Color? color;
    try {
      color = Color(int.parse(_colorController.text.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Invalid color, don't show preview
    }

    if (color == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette, color: _getContrastColor(color)),
          const SizedBox(width: 8),
          Text(
            'Color Preview',
            style: TextStyle(color: _getContrastColor(color), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use light or dark text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final input = DropdownItemInput(
      value: _valueController.text.trim(),
      label: _labelController.text.trim(),
      color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      active: _active,
    );

    try {
      if (widget.item == null) {
        // Create new item
        await ref.read(dropdownFormControllerProvider.notifier).createItem(widget.group, input);
      } else {
        // Update existing item
        final patch = <String, dynamic>{'label': input.label, 'active': input.active};
        if (input.color != null) {
          patch['color'] = input.color;
        }

        await ref
            .read(dropdownFormControllerProvider.notifier)
            .updateItem(widget.group, widget.item!.value, patch);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? 'Dropdown item created successfully'
                  : 'Dropdown item updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

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
    return AlertDialog(
      title: const Text('Delete Dropdown Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasReferences) ...[
            const Icon(Icons.warning, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Cannot delete "${item.label}" because it is referenced by existing enquiries.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please deactivate it instead or use the "Replace in enquiries" feature to migrate existing references.',
            ),
          ] else ...[
            Text('Are you sure you want to delete "${item.label}"?'),
            const SizedBox(height: 8),
            const Text('This action cannot be undone.', style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        if (!hasReferences)
          FilledButton(
            onPressed: () => _confirmDelete(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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

    return AlertDialog(
      title: const Text('Replace in Enquiries'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replace all occurrences of "${widget.oldLabel}" with:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            replacementsAsync.when(
              data: (replacements) {
                if (replacements.isEmpty) {
                  return const Text(
                    'No other active dropdown items available for replacement.',
                    style: TextStyle(color: Colors.orange),
                  );
                }

                return DropdownButtonFormField<DropdownItem>(
                  initialValue: _selectedReplacement != null
                      ? replacements.firstWhere((item) => item.value == _selectedReplacement)
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Replacement Value',
                    border: OutlineInputBorder(),
                  ),
                  items: replacements.map((item) {
                    return DropdownMenuItem<DropdownItem>(
                      value: item,
                      child: Row(
                        children: [
                          if (item.color != null) ...[
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(int.parse(item.color!.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(item.label),
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
              ? const SizedBox(
                  width: 16,
                  height: 16,
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
