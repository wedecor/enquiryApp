import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'accessibility_service.dart';
import 'tap_target.dart';

/// An accessible button with proper semantic information and tap targets
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.hint,
    this.icon,
    this.style,
    this.enabled = true,
    this.isDestructive = false,
    this.isLoading = false,
    this.loadingText,
    this.semanticLabel,
    this.semanticHint,
    this.minSize = AppTokens.minTapTarget,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? hint;
  final IconData? icon;
  final ButtonStyle? style;
  final bool enabled;
  final bool isDestructive;
  final bool isLoading;
  final String? loadingText;
  final String? semanticLabel;
  final String? semanticHint;
  final double minSize;
  final bool autofocus;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    if (semanticLabel != null) return semanticLabel!;
    if (isLoading) return loadingText ?? 'Loading';
    return label;
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (!enabled) hints.add('Disabled');
    if (isLoading) hints.add('Please wait');
    if (isDestructive) hints.add('This action cannot be undone');

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine button style based on context
    ButtonStyle effectiveStyle = style ?? _getDefaultStyle(context);

    Widget button = ElevatedButton(
      onPressed: enabled && !isLoading ? onPressed : null,
      style: effectiveStyle,
      autofocus: autofocus,
      focusNode: focusNode,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(loadingText ?? 'Loading'),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );

    return TapTarget(
      onTap: enabled && !isLoading ? onPressed : null,
      minSize: minSize,
      semanticLabel: _getSemanticLabel(),
      semanticHint: _getSemanticHint(),
      enabled: enabled && !isLoading,
      child: button,
    );
  }

  ButtonStyle _getDefaultStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDestructive) {
      return ElevatedButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        disabledBackgroundColor: colorScheme.error.withOpacity(0.5),
        disabledForegroundColor: colorScheme.onError.withOpacity(0.5),
      );
    }

    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
      disabledForegroundColor: colorScheme.onSurfaceVariant,
    );
  }
}

/// An accessible icon button with proper semantic information
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.isDestructive = false,
    this.size = AppTokens.iconMedium,
    this.minSize = AppTokens.minTapTarget,
    this.color,
    this.focusNode,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final bool isDestructive;
  final double size;
  final double minSize;
  final Color? color;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    if (semanticLabel != null) return semanticLabel!;
    return tooltip ?? icon.toString();
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (!enabled) hints.add('Disabled');
    if (isDestructive) hints.add('This action cannot be undone');

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconTapTarget(
      icon: icon,
      onPressed: enabled ? onPressed : null,
      size: size,
      color: color ?? (isDestructive ? colorScheme.error : colorScheme.onSurface),
      tooltip: tooltip,
      semanticLabel: _getSemanticLabel(),
      semanticHint: _getSemanticHint(),
      enabled: enabled,
      minSize: minSize,
    );
  }
}

/// An accessible text button with proper semantic information
class AccessibleTextButton extends StatelessWidget {
  const AccessibleTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.hint,
    this.icon,
    this.style,
    this.enabled = true,
    this.isDestructive = false,
    this.semanticLabel,
    this.semanticHint,
    this.minSize = AppTokens.minTapTarget,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? hint;
  final IconData? icon;
  final ButtonStyle? style;
  final bool enabled;
  final bool isDestructive;
  final String? semanticLabel;
  final String? semanticHint;
  final double minSize;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    return semanticLabel ?? label;
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (!enabled) hints.add('Disabled');
    if (isDestructive) hints.add('This action cannot be undone');

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ButtonStyle effectiveStyle = style ?? _getDefaultStyle(context);

    Widget button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: effectiveStyle,
      focusNode: focusNode,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );

    return TapTarget(
      onTap: enabled ? onPressed : null,
      minSize: minSize,
      semanticLabel: _getSemanticLabel(),
      semanticHint: _getSemanticHint(),
      enabled: enabled,
      child: button,
    );
  }

  ButtonStyle _getDefaultStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDestructive) {
      return TextButton.styleFrom(
        foregroundColor: colorScheme.error,
        disabledForegroundColor: colorScheme.error.withOpacity(0.5),
      );
    }

    return TextButton.styleFrom(
      foregroundColor: colorScheme.primary,
      disabledForegroundColor: colorScheme.onSurfaceVariant,
    );
  }
}

/// An accessible floating action button with proper semantic information
class AccessibleFloatingActionButton extends StatelessWidget {
  const AccessibleFloatingActionButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.icon,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final IconData? icon;
  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    if (semanticLabel != null) return semanticLabel!;
    return tooltip ?? 'Floating action button';
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (!enabled) hints.add('Disabled');

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingTapTarget(
      onPressed: enabled ? onPressed : null,
      semanticLabel: _getSemanticLabel(),
      semanticHint: _getSemanticHint(),
      enabled: enabled,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: FloatingActionButton(
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        focusNode: focusNode,
        child: child ?? (icon != null ? Icon(icon) : const Icon(Icons.add)),
      ),
    );
  }
}

/// An accessible toggle button with proper semantic information
class AccessibleToggleButton extends StatelessWidget {
  const AccessibleToggleButton({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.minSize = AppTokens.minTapTarget,
    this.focusNode,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? hint;
  final bool enabled;
  final String? semanticLabel;
  final String? semanticHint;
  final double minSize;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    return semanticLabel ?? label;
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (!enabled) hints.add('Disabled');
    hints.add(value ? 'Currently selected' : 'Currently unselected');

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    return ToggleTapTarget(
      onPressed: enabled ? () => onChanged(!value) : null,
      isSelected: value,
      semanticLabel: _getSemanticLabel(),
      semanticHint: _getSemanticHint(),
      enabled: enabled,
      minSize: minSize,
      child: Text(label),
    );
  }
}

/// An accessible switch with proper semantic information
class AccessibleSwitch extends StatelessWidget {
  const AccessibleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.activeColor,
    this.inactiveColor,
    this.focusNode,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? activeColor;
  final Color? inactiveColor;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    if (semanticLabel != null) return semanticLabel!;
    return label ?? 'Switch';
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (!enabled) hints.add('Disabled');
    hints.add(value ? 'Currently on' : 'Currently off');

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      value: value.toString(),
      enabled: enabled,
      focusable: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
      child: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: activeColor,
        inactiveThumbColor: inactiveColor,
        focusNode: focusNode,
      ),
    );
  }
}

/// An accessible checkbox with proper semantic information
class AccessibleCheckbox extends StatelessWidget {
  const AccessibleCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.tristate = false,
    this.activeColor,
    this.focusNode,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? semanticLabel;
  final String? semanticHint;
  final bool tristate;
  final Color? activeColor;
  final FocusNode? focusNode;

  String _getSemanticLabel() {
    if (semanticLabel != null) return semanticLabel!;
    return label ?? 'Checkbox';
  }

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;

    final hints = <String>[];
    if (hint != null) hints.add(hint!);
    if (!enabled) hints.add('Disabled');

    if (value == true) {
      hints.add('Currently checked');
    } else if (value == false) {
      hints.add('Currently unchecked');
    } else {
      hints.add('Currently indeterminate');
    }

    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      value: value?.toString(),
      enabled: enabled,
      focusable: enabled,
      onTap: enabled ? () => onChanged(!(value ?? false)) : null,
      child: Checkbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        tristate: tristate,
        activeColor: activeColor,
        focusNode: focusNode,
      ),
    );
  }
}
