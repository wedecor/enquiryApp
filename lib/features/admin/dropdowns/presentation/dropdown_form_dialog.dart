import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/glass_dialog.dart';
import '../domain/dropdown_item.dart';
import 'dropdown_providers.dart';
import 'widgets/dropdown_item_tile.dart';

export 'widgets/dropdown_action_dialogs.dart';

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

    return GlassDialog(
      eyebrow: widget.group.displayName,
      title: isEdit
          ? 'Edit ${widget.group.displayName} Item'
          : 'Add ${widget.group.displayName} Item',
      icon: dropdownGroupIcon(widget.group),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'e.g., new, in_progress',
                prefixIcon: Icon(Icons.code_rounded),
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
            const SizedBox(height: AppTokens.space4),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g., New, In Progress',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Label is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.space4),
            TextFormField(
              controller: _colorController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Color (Optional)',
                hintText: '#FF9800',
                prefixIcon: const Icon(Icons.palette_outlined),
                suffixIcon: _buildColorPreview(),
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
            const SizedBox(height: AppTokens.space2),
            MergeSemantics(
              child: Row(
                children: [
                  Switch(
                    value: _active,
                    onChanged: (value) {
                      setState(() {
                        _active = value;
                      });
                    },
                  ),
                  const SizedBox(width: AppTokens.space2),
                  const Text('Active'),
                ],
              ),
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
          onPressed: formState.isLoading ? null : _submitForm,
          child: formState.isLoading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget? _buildColorPreview() {
    final text = _colorController.text;
    if (text.isEmpty || !DropdownItemValidation.isValidHexColor(text)) return null;
    final color = parseDropdownColor(text);
    if (color == null) return null;

    return Tooltip(
      message: 'Color Preview',
      child: Center(
        widthFactor: 1,
        child: Padding(
          padding: const EdgeInsets.only(right: AppTokens.space3),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.quick),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              boxShadow: AppShadows.glow(color, strength: 0.35),
            ),
          ),
        ),
      ),
    );
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
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
