import 'package:flutter/material.dart';

import 'accessibility_service.dart';
import 'tap_target.dart';

/// An accessible card with proper semantic information and tap targets
class AccessibleCard extends StatelessWidget {
  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.elevation,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.borderRadius,
    this.border,
    this.margin,
    this.padding,
    this.clipBehavior,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final double? elevation;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Clip? clipBehavior;
  final FocusNode? focusNode;

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    if (!enabled) hints.add('Disabled');
    if (onTap != null) hints.add('Double tap to activate');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget card = Card(
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: border?.left ?? BorderSide.none,
      ),
      margin: margin,
      clipBehavior: clipBehavior ?? Clip.none,
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );

    if (onTap != null) {
      card = CardTapTarget(
        onTap: enabled ? onTap : null,
        semanticLabel: semanticLabel,
        semanticHint: _getSemanticHint(),
        enabled: enabled,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: border,
          boxShadow: elevation != null && elevation! > 0
              ? [
                  BoxShadow(
                    color: shadowColor ?? Colors.black.withOpacity(0.1),
                    blurRadius: elevation! * 2,
                    offset: Offset(0, elevation!),
                  ),
                ]
              : null,
        ),
        child: child,
      );
    } else if (semanticLabel != null || semanticHint != null) {
      card = Semantics(
        label: semanticLabel,
        hint: _getSemanticHint(),
        child: card,
      );
    }

    return card;
  }
}

/// An accessible list tile with proper semantic information
class AccessibleListTile extends StatelessWidget {
  const AccessibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.iconColor,
    this.textColor,
    this.contentPadding,
    this.enableFeedback = true,
    this.mouseCursor,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final bool selected;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? tileColor;
  final Color? selectedTileColor;
  final Color? iconColor;
  final Color? textColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool enableFeedback;
  final MouseCursor? mouseCursor;

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    if (!enabled) hints.add('Disabled');
    if (selected) hints.add('Selected');
    if (onTap != null) hints.add('Double tap to activate');
    if (onLongPress != null) hints.add('Long press for more options');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    Widget listTile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      selected: selected,
      focusNode: focusNode,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding: contentPadding,
      enableFeedback: enableFeedback,
      mouseCursor: mouseCursor,
    );

    if (semanticLabel != null || semanticHint != null) {
      listTile = Semantics(
        label: semanticLabel,
        hint: _getSemanticHint(),
        selected: selected,
        enabled: enabled,
        button: onTap != null,
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: listTile,
      );
    }

    return listTile;
  }
}

/// An accessible expansion tile with proper semantic information
class AccessibleExpansionTile extends StatelessWidget {
  const AccessibleExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.children,
    this.onExpansionChanged,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.iconColor,
    this.textColor,
    this.collapsedIconColor,
    this.collapsedTextColor,
    this.controlAffinity,
    this.trailing,
  });

  final Widget title;
  final Widget? subtitle;
  final List<Widget>? children;
  final ValueChanged<bool>? onExpansionChanged;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;
  final bool initiallyExpanded;
  final bool maintainState;
  final EdgeInsetsGeometry? tilePadding;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final Alignment? expandedAlignment;
  final EdgeInsetsGeometry? childrenPadding;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? collapsedIconColor;
  final Color? collapsedTextColor;
  final ListTileControlAffinity? controlAffinity;
  final Widget? trailing;

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    if (!enabled) hints.add('Disabled');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    Widget expansionTile = ExpansionTile(
      title: title,
      subtitle: subtitle,
      children: children ?? [],
      onExpansionChanged: enabled ? onExpansionChanged : null,
      initiallyExpanded: initiallyExpanded,
      maintainState: maintainState,
      tilePadding: tilePadding,
      expandedCrossAxisAlignment: expandedCrossAxisAlignment,
      expandedAlignment: expandedAlignment,
      childrenPadding: childrenPadding,
      backgroundColor: backgroundColor,
      collapsedBackgroundColor: collapsedBackgroundColor,
      iconColor: iconColor,
      textColor: textColor,
      collapsedIconColor: collapsedIconColor,
      collapsedTextColor: collapsedTextColor,
      controlAffinity: controlAffinity,
      trailing: trailing,
    );

    if (semanticLabel != null || semanticHint != null) {
      expansionTile = Semantics(
        label: semanticLabel,
        hint: _getSemanticHint(),
        enabled: enabled,
        button: true,
        expanded: initiallyExpanded,
        onTap: enabled ? () => onExpansionChanged?.call(!initiallyExpanded) : null,
        child: expansionTile,
      );
    }

    return expansionTile;
  }
}

/// An accessible dialog with proper semantic information
class AccessibleDialog extends StatelessWidget {
  const AccessibleDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.elevation,
    this.insetPadding,
    this.clipBehavior,
    this.shape,
    this.alignment,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.actionsOverflowDirection,
    this.actionsAlignment,
    this.buttonPadding,
    this.icon,
    this.iconPadding,
    this.iconColor,
    this.titleTextStyle,
    this.contentTextStyle,
    this.actionsTextStyle,
    this.titleAlignment,
    this.contentAlignment,
  });

  final Widget title;
  final Widget content;
  final List<Widget>? actions;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? insetPadding;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final VerticalDirection? actionsOverflowDirection;
  final MainAxisAlignment? actionsAlignment;
  final EdgeInsetsGeometry? buttonPadding;
  final Widget? icon;
  final EdgeInsetsGeometry? iconPadding;
  final Color? iconColor;
  final TextStyle? titleTextStyle;
  final TextStyle? contentTextStyle;
  final TextStyle? actionsTextStyle;
  final TextAlign? titleAlignment;
  final TextAlign? contentAlignment;

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    hints.add('Dialog');
    if (actions != null && actions!.isNotEmpty) hints.add('Use buttons below to interact');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    Widget dialog = AlertDialog(
      title: title,
      content: content,
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: elevation,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      alignment: alignment,
      titlePadding: titlePadding,
      contentPadding: contentPadding,
      actionsPadding: actionsPadding,
      actionsOverflowDirection: actionsOverflowDirection,
      actionsAlignment: actionsAlignment,
      buttonPadding: buttonPadding,
      icon: icon,
      iconPadding: iconPadding,
      iconColor: iconColor,
      titleTextStyle: titleTextStyle,
      contentTextStyle: contentTextStyle,
      actionsTextStyle: actionsTextStyle,
    );

    if (semanticLabel != null || semanticHint != null) {
      dialog = Semantics(
        label: semanticLabel,
        hint: _getSemanticHint(),
        child: dialog,
      );
    }

    return dialog;
  }
}

/// An accessible bottom sheet with proper semantic information
class AccessibleBottomSheet extends StatelessWidget {
  const AccessibleBottomSheet({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.enableDrag = true,
    this.isDismissible = true,
    this.isScrollControlled = false,
    this.useSafeArea = false,
    this.showDragHandle = false,
  });

  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final bool enableDrag;
  final bool isDismissible;
  final bool isScrollControlled;
  final bool useSafeArea;
  final bool showDragHandle;

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    hints.add('Bottom sheet');
    if (enableDrag) hints.add('Swipe down to dismiss');
    if (isDismissible) hints.add('Tap outside to dismiss');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    Widget bottomSheet = BottomSheet(
      onClosing: () {},
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      enableDrag: enableDrag,
      child: child,
    );

    if (semanticLabel != null || semanticHint != null) {
      bottomSheet = Semantics(
        label: semanticLabel,
        hint: _getSemanticHint(),
        child: bottomSheet,
      );
    }

    return bottomSheet;
  }
}

/// An accessible snackbar with proper semantic information
class AccessibleSnackBar extends StatelessWidget {
  const AccessibleSnackBar({
    super.key,
    required this.content,
    this.action,
    this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.elevation,
    this.margin,
    this.padding,
    this.width,
    this.shape,
    this.behavior,
    this.animation,
    this.duration,
    this.onVisible,
    this.dismissDirection,
    this.clipBehavior,
    this.actionOverflowThreshold,
    this.showCloseIcon = false,
    this.closeIconColor,
  });

  final Widget content;
  final SnackBarAction? action;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final ShapeBorder? shape;
  final SnackBarBehavior? behavior;
  final Animation<double>? animation;
  final Duration? duration;
  final VoidCallback? onVisible;
  final DismissDirection? dismissDirection;
  final Clip? clipBehavior;
  final double? actionOverflowThreshold;
  final bool showCloseIcon;
  final Color? closeIconColor;

  String? _getSemanticHint() {
    if (semanticHint != null) return semanticHint;
    
    final hints = <String>[];
    hints.add('Notification');
    if (action != null) hints.add('Use action button to interact');
    if (dismissDirection != null) hints.add('Swipe to dismiss');
    
    return hints.isNotEmpty ? hints.join('. ') : null;
  }

  @override
  Widget build(BuildContext context) {
    Widget snackBar = SnackBar(
      content: content,
      action: action,
      backgroundColor: backgroundColor,
      elevation: elevation,
      margin: margin,
      padding: padding,
      width: width,
      shape: shape,
      behavior: behavior,
      animation: animation,
      duration: duration,
      onVisible: onVisible,
      dismissDirection: dismissDirection,
      clipBehavior: clipBehavior,
      actionOverflowThreshold: actionOverflowThreshold,
      showCloseIcon: showCloseIcon,
      closeIconColor: closeIconColor,
    );

    if (semanticLabel != null || semanticHint != null) {
      snackBar = Semantics(
        label: semanticLabel,
        hint: _getSemanticHint(),
        child: snackBar,
      );
    }

    return snackBar;
  }
}
