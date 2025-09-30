import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Service for managing accessibility features and announcements
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  /// Announce text to screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Announce error messages with proper context
  static void announceError(BuildContext context, String error) {
    announce(context, 'Error: $error');
  }

  /// Announce success messages with proper context
  static void announceSuccess(BuildContext context, String message) {
    announce(context, 'Success: $message');
  }

  /// Announce loading state changes
  static void announceLoading(BuildContext context, bool isLoading) {
    if (isLoading) {
      announce(context, 'Loading, please wait');
    } else {
      announce(context, 'Loading complete');
    }
  }

  /// Announce status changes with context
  static void announceStatusChange(BuildContext context, String oldStatus, String newStatus) {
    announce(context, 'Status changed from $oldStatus to $newStatus');
  }

  /// Announce form validation errors
  static void announceValidationError(BuildContext context, String field, String error) {
    announce(context, '$field: $error');
  }

  /// Announce navigation changes
  static void announceNavigation(BuildContext context, String destination) {
    announce(context, 'Navigated to $destination');
  }

  /// Check if accessibility services are enabled
  static bool get isAccessibilityEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;
  }

  /// Check if screen readers are enabled
  static bool get isScreenReaderEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;
  }

  /// Get current accessibility features
  static AccessibilityFeatures get accessibilityFeatures {
    return SemanticsBinding.instance.accessibilityFeatures;
  }

  /// Check if high contrast mode is enabled
  static bool get isHighContrastEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.highContrast;
  }

  /// Check if reduce motion is enabled
  static bool get isReduceMotionEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.reduceMotion;
  }

  /// Check if bold text is enabled
  static bool get isBoldTextEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.boldText;
  }

  /// Get appropriate animation duration based on accessibility settings
  static Duration getAnimationDuration(BuildContext context) {
    if (isReduceMotionEnabled) {
      return Duration.zero;
    }
    return const Duration(milliseconds: 300);
  }

  /// Get appropriate animation curve based on accessibility settings
  static Curve getAnimationCurve(BuildContext context) {
    if (isReduceMotionEnabled) {
      return Curves.linear;
    }
    return Curves.easeInOut;
  }
}

/// Mixin for accessibility-aware widgets
mixin AccessibilityMixin<T extends StatefulWidget> on State<T> {
  /// Announce message to screen readers
  void announce(String message) {
    AccessibilityService.announce(context, message);
  }

  /// Announce error with context
  void announceError(String error) {
    AccessibilityService.announceError(context, error);
  }

  /// Announce success with context
  void announceSuccess(String message) {
    AccessibilityService.announceSuccess(context, message);
  }

  /// Announce loading state
  void announceLoading(bool isLoading) {
    AccessibilityService.announceLoading(context, isLoading);
  }

  /// Announce status change
  void announceStatusChange(String oldStatus, String newStatus) {
    AccessibilityService.announceStatusChange(context, oldStatus, newStatus);
  }

  /// Announce validation error
  void announceValidationError(String field, String error) {
    AccessibilityService.announceValidationError(context, field, error);
  }

  /// Announce navigation
  void announceNavigation(String destination) {
    AccessibilityService.announceNavigation(context, destination);
  }

  /// Check if accessibility is enabled
  bool get isAccessibilityEnabled => AccessibilityService.isAccessibilityEnabled;

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled => AccessibilityService.isScreenReaderEnabled;

  /// Check if high contrast is enabled
  bool get isHighContrastEnabled => AccessibilityService.isHighContrastEnabled;

  /// Check if reduce motion is enabled
  bool get isReduceMotionEnabled => AccessibilityService.isReduceMotionEnabled;

  /// Get animation duration based on accessibility settings
  Duration get animationDuration => AccessibilityService.getAnimationDuration(context);

  /// Get animation curve based on accessibility settings
  Curve get animationCurve => AccessibilityService.getAnimationCurve(context);
}

/// Widget for managing focus and accessibility
class AccessibilityFocusManager extends StatefulWidget {
  const AccessibilityFocusManager({
    super.key,
    required this.child,
    this.autoFocus = false,
    this.focusNode,
    this.onFocusChange,
  });

  final Widget child;
  final bool autoFocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<AccessibilityFocusManager> createState() => _AccessibilityFocusManagerState();
}

class _AccessibilityFocusManagerState extends State<AccessibilityFocusManager> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
      widget.onFocusChange?.call(_hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, autofocus: widget.autoFocus, child: widget.child);
  }
}

/// Widget for announcing dynamic content changes
class AccessibilityAnnouncer extends StatefulWidget {
  const AccessibilityAnnouncer({
    super.key,
    required this.message,
    required this.child,
    this.announceOnBuild = false,
  });

  final String message;
  final Widget child;
  final bool announceOnBuild;

  @override
  State<AccessibilityAnnouncer> createState() => _AccessibilityAnnouncerState();
}

class _AccessibilityAnnouncerState extends State<AccessibilityAnnouncer> {
  @override
  void initState() {
    super.initState();
    if (widget.announceOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AccessibilityService.announce(context, widget.message);
      });
    }
  }

  @override
  void didUpdateWidget(AccessibilityAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message) {
      AccessibilityService.announce(context, widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget for providing semantic information about live regions
class LiveRegion extends StatefulWidget {
  const LiveRegion({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.polite = false,
    this.assertive = false,
  });

  final Widget child;
  final String? label;
  final String? hint;
  final bool polite;
  final bool assertive;

  @override
  State<LiveRegion> createState() => _LiveRegionState();
}

class _LiveRegionState extends State<LiveRegion> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      hint: widget.hint,
      liveRegion: widget.polite || widget.assertive,
      attributedLabel: widget.label != null ? AttributedString(widget.label!) : null,
      attributedHint: widget.hint != null ? AttributedString(widget.hint!) : null,
      child: widget.child,
    );
  }
}

/// Widget for providing accessible error messages
class AccessibleErrorWidget extends StatelessWidget {
  const AccessibleErrorWidget({
    super.key,
    required this.error,
    this.icon,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String error;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: $error',
      hint: onRetry != null ? 'Double tap to retry' : null,
      button: onRetry != null,
      onTap: onRetry,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
            ],
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for providing accessible loading indicators
class AccessibleLoadingWidget extends StatelessWidget {
  const AccessibleLoadingWidget({
    super.key,
    this.message = 'Loading',
    this.showProgress = false,
    this.progress,
  });

  final String message;
  final bool showProgress;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      value: showProgress && progress != null ? '${(progress! * 100).round()}%' : null,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showProgress && progress != null)
              CircularProgressIndicator(value: progress)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            if (showProgress && progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress! * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
