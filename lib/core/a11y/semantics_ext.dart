import 'package:flutter/material.dart';

/// Extension methods for adding semantic labels and improving accessibility
extension SemanticsExtension on Widget {
  /// Add semantic label to a widget
  Widget withSemanticLabel(String label) {
    return Semantics(label: label, child: this);
  }

  /// Add semantic hint to a widget
  Widget withSemanticHint(String hint) {
    return Semantics(hint: hint, child: this);
  }

  /// Add semantic button role to a widget
  Widget withButtonSemantics({String? label, String? hint, VoidCallback? onTap}) {
    return Semantics(button: true, label: label, hint: hint, onTap: onTap, child: this);
  }

  /// Add semantic header role to a widget
  Widget withHeaderSemantics({String? label}) {
    return Semantics(header: true, label: label, child: this);
  }

  /// Add semantic image role to a widget
  Widget withImageSemantics({String? label}) {
    return Semantics(image: true, label: label, child: this);
  }

  /// Add semantic text field role to a widget
  Widget withTextFieldSemantics({String? label, String? hint, String? value}) {
    return Semantics(textField: true, label: label, hint: hint, value: value, child: this);
  }

  /// Add semantic switch role to a widget
  Widget withSwitchSemantics({String? label, bool? value, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Double tap to ${value == true ? 'turn off' : 'turn on'}',
      value: value?.toString(),
      onTap: onTap,
      child: this,
    );
  }

  /// Add semantic checkbox role to a widget
  Widget withCheckboxSemantics({String? label, bool? value, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Double tap to ${value == true ? 'uncheck' : 'check'}',
      value: value?.toString(),
      onTap: onTap,
      child: this,
    );
  }

  /// Add semantic radio button role to a widget
  Widget withRadioSemantics({String? label, bool? value, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Double tap to ${value == true ? 'unselect' : 'select'}',
      value: value?.toString(),
      onTap: onTap,
      child: this,
    );
  }

  /// Add semantic slider role to a widget
  Widget withSliderSemantics({
    String? label,
    double? value,
    double? min,
    double? max,
    VoidCallback? onTap,
  }) {
    return Semantics(
      slider: true,
      label: label,
      value: value?.toString(),
      hint: 'Swipe left or right to adjust value',
      onTap: onTap,
      child: this,
    );
  }

  /// Add semantic progress indicator role to a widget
  Widget withProgressSemantics({String? label, double? value}) {
    return Semantics(label: label, value: value?.toString(), child: this);
  }

  /// Add semantic tab role to a widget
  Widget withTabSemantics({String? label, bool? selected, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      selected: selected ?? false,
      hint: selected == true ? 'Currently selected tab' : 'Double tap to select tab',
      onTap: onTap,
      child: this,
    );
  }

  /// Add semantic menu role to a widget
  Widget withMenuSemantics({String? label, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Double tap to open menu',
      onTap: onTap,
      child: this,
    );
  }

  /// Add semantic link role to a widget
  Widget withLinkSemantics({String? label, String? hint, VoidCallback? onTap}) {
    return Semantics(
      link: true,
      label: label,
      hint: hint ?? 'Double tap to open link',
      onTap: onTap,
      child: this,
    );
  }
}

/// Helper class for common accessibility patterns
class A11yHelper {
  A11yHelper._();

  /// Create a semantic button with proper labeling
  static Widget semanticButton({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      onTap: enabled ? onPressed : null,
      child: child,
    );
  }

  /// Create a semantic icon button with proper labeling
  static Widget semanticIconButton({
    required IconData icon,
    required String label,
    String? hint,
    VoidCallback? onPressed,
    bool enabled = true,
    Color? color,
    double? size,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      onTap: enabled ? onPressed : null,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }

  /// Create a semantic text field with proper labeling
  static Widget semanticTextField({
    required String label,
    String? hint,
    String? value,
    Widget? child,
  }) {
    return Semantics(textField: true, label: label, hint: hint, value: value, child: child);
  }

  /// Create a semantic card with proper labeling
  static Widget semanticCard({required String label, String? hint, Widget? child}) {
    return Semantics(button: true, label: label, hint: hint, child: child);
  }

  /// Create a semantic list item with proper labeling
  static Widget semanticListItem({required String label, String? hint, Widget? child}) {
    return Semantics(button: true, label: label, hint: hint, child: child);
  }

  /// Create a semantic header with proper labeling
  static Widget semanticHeader({required String label, Widget? child}) {
    return Semantics(header: true, label: label, child: child);
  }

  /// Create a semantic image with proper labeling
  static Widget semanticImage({required String label, Widget? child}) {
    return Semantics(image: true, label: label, child: child);
  }

  /// Create a semantic progress indicator with proper labeling
  static Widget semanticProgress({required String label, double? value, Widget? child}) {
    return Semantics(label: label, value: value?.toString(), child: child);
  }

  /// Create a semantic tab with proper labeling
  static Widget semanticTab({required String label, bool selected = false, Widget? child}) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      hint: selected ? 'Currently selected tab' : 'Double tap to select tab',
      child: child,
    );
  }

  /// Create a semantic menu with proper labeling
  static Widget semanticMenu({required String label, Widget? child}) {
    return Semantics(button: true, label: label, hint: 'Double tap to open menu', child: child);
  }

  /// Create a semantic link with proper labeling
  static Widget semanticLink({required String label, String? hint, Widget? child}) {
    return Semantics(
      link: true,
      label: label,
      hint: hint ?? 'Double tap to open link',
      child: child,
    );
  }
}

/// Mixin for accessibility-aware widgets
mixin AccessibilityMixin<T extends StatefulWidget> on State<T> {
  /// Add semantic label to a widget
  Widget withLabel(Widget child, String label) {
    return child.withSemanticLabel(label);
  }

  /// Add semantic hint to a widget
  Widget withHint(Widget child, String hint) {
    return child.withSemanticHint(hint);
  }

  /// Add semantic button role to a widget
  Widget asButton(Widget child, {String? label, String? hint, VoidCallback? onTap}) {
    return child.withButtonSemantics(label: label, hint: hint, onTap: onTap);
  }

  /// Add semantic header role to a widget
  Widget asHeader(Widget child, {String? label}) {
    return child.withHeaderSemantics(label: label);
  }

  /// Add semantic image role to a widget
  Widget asImage(Widget child, {String? label}) {
    return child.withImageSemantics(label: label);
  }

  /// Add semantic text field role to a widget
  Widget asTextField(Widget child, {String? label, String? hint, String? value}) {
    return child.withTextFieldSemantics(label: label, hint: hint, value: value);
  }

  /// Add semantic switch role to a widget
  Widget asSwitch(Widget child, {String? label, bool? value, VoidCallback? onTap}) {
    return child.withSwitchSemantics(label: label, value: value, onTap: onTap);
  }

  /// Add semantic checkbox role to a widget
  Widget asCheckbox(Widget child, {String? label, bool? value, VoidCallback? onTap}) {
    return child.withCheckboxSemantics(label: label, value: value, onTap: onTap);
  }

  /// Add semantic radio button role to a widget
  Widget asRadio(Widget child, {String? label, bool? value, VoidCallback? onTap}) {
    return child.withRadioSemantics(label: label, value: value, onTap: onTap);
  }

  /// Add semantic slider role to a widget
  Widget asSlider(
    Widget child, {
    String? label,
    double? value,
    double? min,
    double? max,
    VoidCallback? onTap,
  }) {
    return child.withSliderSemantics(label: label, value: value, min: min, max: max, onTap: onTap);
  }

  /// Add semantic progress indicator role to a widget
  Widget asProgress(Widget child, {String? label, double? value}) {
    return child.withProgressSemantics(label: label, value: value);
  }

  /// Add semantic tab role to a widget
  Widget asTab(Widget child, {String? label, bool? selected, VoidCallback? onTap}) {
    return child.withTabSemantics(label: label, selected: selected, onTap: onTap);
  }

  /// Add semantic menu role to a widget
  Widget asMenu(Widget child, {String? label, VoidCallback? onTap}) {
    return child.withMenuSemantics(label: label, onTap: onTap);
  }

  /// Add semantic link role to a widget
  Widget asLink(Widget child, {String? label, String? hint, VoidCallback? onTap}) {
    return child.withLinkSemantics(label: label, hint: hint, onTap: onTap);
  }
}
