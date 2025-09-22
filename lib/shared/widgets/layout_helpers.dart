import 'package:flutter/material.dart';

/// Utility functions and widgets for robust layout handling.
///
/// This file contains helpers to prevent text overflow and ensure
/// consistent layouts across different screen sizes and text scales.
class LayoutHelpers {
  LayoutHelpers._();

  /// Creates a responsive row with text that won't overflow.
  ///
  /// Use this instead of a plain Row when you have text that might
  /// cause overflow issues.
  static Widget safeRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        // If the child is a Text widget, wrap it with Expanded and overflow handling
        if (child is Text) {
          return Expanded(
            child: Text(
              child.data ?? '',
              style: child.style,
              maxLines: child.maxLines ?? 1,
              overflow: child.overflow ?? TextOverflow.ellipsis,
              textAlign: child.textAlign,
            ),
          );
        }
        return child;
      }).toList(),
    );
  }

  /// Creates a responsive column with text that won't overflow.
  ///
  /// Use this for columns that contain text elements.
  static Widget safeColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        // If the child is a Text widget, add overflow protection
        if (child is Text && child.overflow == null) {
          return Text(
            child.data ?? '',
            style: child.style,
            maxLines: child.maxLines ?? 2,
            overflow: TextOverflow.ellipsis,
            textAlign: child.textAlign,
          );
        }
        return child;
      }).toList(),
    );
  }

  /// Creates an icon and text row that handles overflow properly.
  static Widget iconTextRow({
    required IconData icon,
    required String text,
    TextStyle? textStyle,
    double? iconSize,
    double spacing = 8.0,
    bool expandText = true,
  }) {
    final textWidget = Text(text, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize),
        SizedBox(width: spacing),
        if (expandText) Expanded(child: textWidget) else textWidget,
      ],
    );
  }

  /// Creates a responsive card with proper text handling.
  static Widget responsiveCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double? elevation,
  }) {
    return Card(
      margin: margin,
      color: color,
      elevation: elevation,
      child: Padding(padding: padding ?? const EdgeInsets.all(16.0), child: child),
    );
  }

  /// Creates a responsive list tile with overflow protection.
  static Widget responsiveListTile({
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    int? titleMaxLines,
    int? subtitleMaxLines,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: titleStyle,
        maxLines: titleMaxLines ?? 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: subtitleStyle,
              maxLines: subtitleMaxLines ?? 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Creates a responsive button with text overflow protection.
  static Widget responsiveButton({
    required String text,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    TextStyle? textStyle,
    Widget? icon,
    bool isExpanded = false,
  }) {
    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon, const SizedBox(width: 8)],
        Flexible(
          child: Text(text, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: isExpanded ? SizedBox(width: double.infinity, child: buttonChild) : buttonChild,
    );
  }

  /// Creates a responsive chip with text overflow protection.
  static Widget responsiveChip({
    required String label,
    VoidCallback? onDeleted,
    Widget? avatar,
    Color? backgroundColor,
    Color? labelColor,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return Chip(
      avatar: avatar,
      label: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: labelColor),
      padding: padding,
      onDeleted: onDeleted,
    );
  }

  /// Creates a responsive tab with text overflow protection.
  static Widget responsiveTab({required String text, Widget? icon, TextStyle? textStyle}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 4)],
          Flexible(
            child: Text(text, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Creates a responsive app bar title with overflow protection.
  static Widget responsiveAppBarTitle({required String title, TextStyle? style}) {
    return Text(title, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  /// Creates a responsive bottom navigation bar item.
  static Widget responsiveBottomNavItem({
    required String label,
    required IconData icon,
    TextStyle? labelStyle,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
      // Note: BottomNavigationBar handles text overflow internally
    );
  }

  /// Creates a responsive floating action button label.
  static Widget responsiveFabLabel({required String label, TextStyle? style}) {
    return Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  /// Creates a responsive dialog title with overflow protection.
  static Widget responsiveDialogTitle({required String title, TextStyle? style}) {
    return Text(title, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  /// Creates a responsive snackbar content with overflow protection.
  static Widget responsiveSnackBarContent({
    required String message,
    TextStyle? style,
    int? maxLines,
  }) {
    return Text(message, style: style, maxLines: maxLines ?? 2, overflow: TextOverflow.ellipsis);
  }
}

/// Extension methods for common layout operations.
extension LayoutExtensions on Widget {
  /// Wraps a widget with proper overflow handling for text content.
  Widget withOverflowProtection({int? maxLines, TextOverflow? overflow}) {
    if (this is Text) {
      final text = this as Text;
      return Text(
        text.data ?? '',
        style: text.style,
        maxLines: maxLines ?? text.maxLines ?? 1,
        overflow: overflow ?? text.overflow ?? TextOverflow.ellipsis,
        textAlign: text.textAlign,
      );
    }
    return this;
  }

  /// Wraps a widget in a flexible container to prevent overflow.
  Widget flexible({int flex = 1}) {
    return Flexible(flex: flex, child: this);
  }

  /// Wraps a widget in an expanded container to fill available space.
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  /// Wraps a widget with minimum size constraints.
  Widget withMinSize({double? width, double? height}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width ?? 0, minHeight: height ?? 0),
      child: this,
    );
  }

  /// Wraps a widget with maximum size constraints.
  Widget withMaxSize({double? width, double? height}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      child: this,
    );
  }
}
