import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'accessibility_service.dart';

/// An accessible form field that provides proper semantic information
class AccessibleFormField extends StatefulWidget {
  const AccessibleFormField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.value,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.semanticLabel,
    this.semanticHint,
    this.isRequired = false,
    this.autofillHints,
  });

  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isRequired;
  final List<String>? autofillHints;

  @override
  State<AccessibleFormField> createState() => _AccessibleFormFieldState();
}

class _AccessibleFormFieldState extends State<AccessibleFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.value);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AccessibleFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  void _handleFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  String? _validate(String? value) {
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() {
        _hasError = true;
      });
      // Announce validation error to screen readers
      if (_hasFocus) {
        AccessibilityService.announceValidationError(context, widget.label, error);
      }
    } else {
      setState(() {
        _hasError = false;
      });
    }
    return error;
  }

  String _getSemanticLabel() {
    final label = widget.semanticLabel ?? widget.label;
    return widget.isRequired ? '$label (required)' : label;
  }

  String? _getSemanticHint() {
    if (widget.semanticHint != null) return widget.semanticHint;
    
    final hints = <String>[];
    if (widget.hint != null) hints.add(widget.hint!);
    if (widget.helperText != null) hints.add(widget.helperText!);
    if (widget.errorText != null) hints.add('Error: ${widget.errorText!}');
    if (widget.isRequired) hints.add('Required field');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Semantics(
      textField: true,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      value: _controller.text,
      enabled: widget.enabled,
      focusable: widget.enabled,
      required: widget.isRequired,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        validator: _validate,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        autofocus: widget.autofocus,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        prefixText: widget.prefixText,
        suffixText: widget.suffixText,
        onFieldSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          counterText: widget.maxLength != null ? null : '',
          filled: true,
          fillColor: widget.enabled 
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}

/// An accessible dropdown form field
class AccessibleDropdownField<T> extends StatelessWidget {
  const AccessibleDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.semanticLabel,
    this.semanticHint,
    this.itemBuilder,
    this.selectedItemBuilder,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final bool isRequired;
  final String? semanticLabel;
  final String? semanticHint;
  final DropdownMenuItemBuilder<T>? itemBuilder;
  final DropdownMenuItemBuilder<T>? selectedItemBuilder;

  String _getSemanticLabel() {
    final label = this.semanticLabel ?? this.label;
    return isRequired ? '$label (required)' : label;
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (helperText != null) hints.add(helperText!);
    if (errorText != null) hints.add('Error: $errorText');
    if (isRequired) hints.add('Required field');
    hints.add('Double tap to open dropdown');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Semantics(
      button: true,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      value: value?.toString(),
      enabled: enabled,
      focusable: enabled,
      required: isRequired,
      onTap: enabled ? () {
        // This will trigger the dropdown to open
      } : null,
      child: FormField<T>(
        initialValue: value,
        validator: validator,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<T>(
                value: value,
                items: items,
                onChanged: enabled ? onChanged : null,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  helperText: helperText,
                  errorText: errorText ?? field.errorText,
                  filled: true,
                  fillColor: enabled 
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  ),
                ),
                itemBuilder: itemBuilder,
                selectedItemBuilder: selectedItemBuilder,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An accessible checkbox form field
class AccessibleCheckboxField extends StatelessWidget {
  const AccessibleCheckboxField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.semanticLabel,
    this.semanticHint,
    this.tristate = false,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<bool>? validator;
  final bool enabled;
  final bool isRequired;
  final String? semanticLabel;
  final String? semanticHint;
  final bool tristate;

  String _getSemanticLabel() {
    final label = this.semanticLabel ?? this.label;
    return isRequired ? '$label (required)' : label;
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (helperText != null) hints.add(helperText!);
    if (errorText != null) hints.add('Error: $errorText');
    if (isRequired) hints.add('Required field');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Semantics(
      button: true,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      value: value?.toString(),
      enabled: enabled,
      focusable: enabled,
      required: isRequired,
      onTap: enabled ? () => onChanged(!(value ?? false)) : null,
      child: FormField<bool>(
        initialValue: value,
        validator: validator,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: value,
                    onChanged: enabled ? onChanged : null,
                    tristate: tristate,
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (helperText != null) ...[
                const SizedBox(height: 4),
                Text(
                  helperText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (errorText != null || field.errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  errorText ?? field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// An accessible date picker form field
class AccessibleDateField extends StatefulWidget {
  const AccessibleDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.semanticLabel,
    this.semanticHint,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.dateFormat,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<DateTime>? validator;
  final bool enabled;
  final bool isRequired;
  final String? semanticLabel;
  final String? semanticHint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final String? dateFormat;

  @override
  State<AccessibleDateField> createState() => _AccessibleDateFieldState();
}

class _AccessibleDateFieldState extends State<AccessibleDateField> {
  String _getSemanticLabel() {
    final label = widget.semanticLabel ?? widget.label;
    return widget.isRequired ? '$label (required)' : label;
  }

  String? _getSemanticHint() {
    if (widget.semanticHint != null) return widget.semanticHint;
    
    final hints = <String>[];
    if (widget.hint != null) hints.add(widget.hint!);
    if (widget.helperText != null) hints.add(widget.helperText!);
    if (widget.errorText != null) hints.add('Error: ${widget.errorText!}');
    if (widget.isRequired) hints.add('Required field');
    hints.add('Double tap to open date picker');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return widget.dateFormat != null 
        ? DateFormat(widget.dateFormat).format(date)
        : '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    if (!widget.enabled) return;
    
    final date = await showDatePicker(
      context: context,
      initialDate: widget.value ?? widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );
    
    if (date != null) {
      widget.onChanged(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Semantics(
      button: true,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      value: _formatDate(widget.value),
      enabled: widget.enabled,
      focusable: widget.enabled,
      required: widget.isRequired,
      onTap: _selectDate,
      child: FormField<DateTime>(
        initialValue: widget.value,
        validator: widget.validator,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.enabled ? _selectDate : null,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hint,
                    helperText: widget.helperText,
                    errorText: widget.errorText ?? field.errorText,
                    suffixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: widget.enabled 
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.error, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                    ),
                  ),
                  child: Text(
                    _formatDate(widget.value),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.value != null 
                          ? colorScheme.onSurface 
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
