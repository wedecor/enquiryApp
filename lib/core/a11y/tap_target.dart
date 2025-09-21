import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A widget that ensures minimum tap target size for accessibility
class TapTarget extends StatelessWidget {
  const TapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.minSize = AppTokens.minTapTarget,
    this.padding,
    this.decoration,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minSize;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final HitTestBehavior hitTestBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tapWidget = GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: hitTestBehavior,
      child: Container(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        padding:
            padding ??
            EdgeInsets.all(
              (minSize - _getChildSize()) / 2,
            ).clamp(EdgeInsets.zero, const EdgeInsets.all(24)),
        decoration: decoration,
        child: Center(child: child),
      ),
    );

    // Add semantic information if provided
    if (semanticLabel != null || semanticHint != null) {
      tapWidget = Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        hint: semanticHint,
        onTap: enabled ? onTap : null,
        child: tapWidget,
      );
    }

    return tapWidget;
  }

  double _getChildSize() {
    if (child is Icon) {
      return (child as Icon).size ?? AppTokens.iconMedium;
    } else if (child is Image) {
      return (child as Image).width ?? AppTokens.iconMedium;
    } else if (child is Text) {
      return AppTokens.iconMedium; // Approximate for text
    }
    return AppTokens.iconMedium;
  }
}

/// A specialized tap target for icon buttons
class IconTapTarget extends StatelessWidget {
  const IconTapTarget({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppTokens.iconMedium,
    this.color,
    this.tooltip,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minSize = AppTokens.minTapTarget,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final String? tooltip;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget iconWidget = Icon(
      icon,
      size: size,
      color: enabled ? color : theme.colorScheme.onSurfaceVariant,
    );

    if (tooltip != null) {
      iconWidget = Tooltip(message: tooltip!, child: iconWidget);
    }

    return TapTarget(
      onTap: enabled ? onPressed : null,
      minSize: minSize,
      semanticLabel: semanticLabel ?? tooltip,
      semanticHint: semanticHint,
      enabled: enabled,
      child: iconWidget,
    );
  }
}

/// A specialized tap target for text buttons
class TextTapTarget extends StatelessWidget {
  const TextTapTarget({
    super.key,
    required this.text,
    required this.onPressed,
    this.style,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minSize = AppTokens.minTapTarget,
    this.padding,
  });

  final String text;
  final VoidCallback? onPressed;
  final TextStyle? style;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double minSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TapTarget(
      onTap: enabled ? onPressed : null,
      minSize: minSize,
      padding: padding ?? 
          EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
      semanticLabel: semanticLabel ?? text,
      semanticHint: semanticHint,
      enabled: enabled,
      child: Text(
        text,
        style: style?.copyWith(color: enabled ? style?.color : theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// A specialized tap target for cards
class CardTapTarget extends StatelessWidget {
  const CardTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minSize = AppTokens.minTapTarget,
    this.margin,
    this.padding,
    this.decoration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double minSize;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      child: TapTarget(
        onTap: enabled ? onTap : null,
        minSize: minSize,
        padding: padding,
        decoration:
            decoration ??
            BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.medium,
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
        semanticLabel: semanticLabel,
        semanticHint: semanticHint,
        enabled: enabled,
        child: child,
      ),
    );
  }
}

/// A specialized tap target for list items
class ListItemTapTarget extends StatelessWidget {
  const ListItemTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minSize = AppTokens.minTapTarget,
    this.padding,
    this.decoration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double minSize;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TapTarget(
      onTap: enabled ? onTap : null,
      minSize: minSize,
      padding: padding ?? 
          EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space3),
      decoration: decoration,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      enabled: enabled,
      child: child,
    );
  }
}

/// A specialized tap target for floating action buttons
class FloatingTapTarget extends StatelessWidget {
  const FloatingTapTarget({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minSize = AppTokens.minTapTarget,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double minSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TapTarget(
      onTap: enabled ? onPressed : null,
      minSize: minSize,
      padding: AppSpacing.space4,
      decoration: BoxDecoration(
        color: enabled
            ? backgroundColor ?? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      enabled: enabled,
      child: IconTheme(
        data: IconThemeData(
          color: enabled
              ? foregroundColor ?? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
        child: child,
      ),
    );
  }
}

/// A specialized tap target for toggle buttons
class ToggleTapTarget extends StatelessWidget {
  const ToggleTapTarget({
    super.key,
    required this.child,
    required this.onPressed,
    this.isSelected = false,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minSize = AppTokens.minTapTarget,
    this.selectedColor,
    this.unselectedColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isSelected;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double minSize;
  final Color? selectedColor;
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveSelectedColor = selectedColor ?? theme.colorScheme.primary;
    final effectiveUnselectedColor = unselectedColor ?? theme.colorScheme.surfaceContainerHighest;

    return TapTarget(
      onTap: enabled ? onPressed : null,
      minSize: minSize,
      padding: EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: AppTokens.space2),
      decoration: BoxDecoration(
        color: isSelected ? effectiveSelectedColor : effectiveUnselectedColor,
        borderRadius: AppRadius.medium,
        border: Border.all(color: isSelected ? effectiveSelectedColor : theme.colorScheme.outline),
      ),
      semanticLabel: semanticLabel,
      semanticHint: semanticHint ?? 'Double tap to ${isSelected ? 'deselect' : 'select'}',
      enabled: enabled,
      child: DefaultTextStyle(
        style: TextStyle(
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        ),
        child: child,
      ),
    );
  }
}

/// Extension methods for easy tap target creation
extension TapTargetExtension on Widget {
  /// Wrap widget in a tap target with minimum size
  Widget asTapTarget({
    VoidCallback? onTap,
    double minSize = AppTokens.minTapTarget,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
    String? semanticLabel,
    String? semanticHint,
    bool enabled = true,
  }) {
    return TapTarget(
      onTap: onTap,
      minSize: minSize,
      padding: padding,
      decoration: decoration,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      enabled: enabled,
      child: this,
    );
  }

  /// Wrap widget in an icon tap target
  Widget asIconTapTarget({
    required VoidCallback? onPressed,
    String? tooltip,
    String? semanticLabel,
    String? semanticHint,
    bool enabled = true,
    double minSize = AppTokens.minTapTarget,
  }) {
    if (this is Icon) {
      final icon = this as Icon;
      final iconData = icon.icon;
      if (iconData != null) {
        return IconTapTarget(
          icon: iconData,
          onPressed: onPressed,
          size: icon.size ?? AppTokens.iconMedium,
          color: icon.color,
          tooltip: tooltip,
          semanticLabel: semanticLabel,
          semanticHint: semanticHint,
          enabled: enabled,
          minSize: minSize,
        );
      }
    }
    return asTapTarget(
      onTap: onPressed,
      minSize: minSize,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      enabled: enabled,
    );
  }

  /// Wrap widget in a card tap target
  Widget asCardTapTarget({
    required VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
    bool enabled = true,
    double minSize = AppTokens.minTapTarget,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
  }) {
    return CardTapTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      enabled: enabled,
      minSize: minSize,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: this,
    );
  }

  /// Wrap widget in a list item tap target
  Widget asListItemTapTarget({
    required VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
    bool enabled = true,
    double minSize = AppTokens.minTapTarget,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
  }) {
    return ListItemTapTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      enabled: enabled,
      minSize: minSize,
      padding: padding,
      decoration: decoration,
      child: this,
    );
  }
}
