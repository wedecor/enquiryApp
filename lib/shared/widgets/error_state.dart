import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../ui/primitives/primitives.dart';
import 'empty_state.dart';
import 'press_scale.dart';
import 'state_accent.dart';

/// Typographic error state: a broken-orbit accent in the error colour, a
/// tracked eyebrow, a split-weight headline (first line of [message]) and the
/// remaining copy as body. Debug builds also show the raw [error].
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.error,
    this.onRetry,
    this.retryText,
    this.icon,
    this.padding,
    this.eyebrow,
  });

  final String message;
  final Object? error;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final copy = StateCopy.from(message);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StateAccent(
                icon: icon ?? Icons.error_outline,
                color: colorScheme.error,
                broken: true,
              ),
              const SizedBox(height: AppTokens.space5),
              Eyebrow(eyebrow ?? 'Something went wrong', color: colorScheme.error),
              const SizedBox(height: AppTokens.space2),
              SplitHeading(
                light: copy.light,
                bold: copy.bold,
                maxLines: 3,
                style: theme.textTheme.headlineSmall,
              ),
              if (copy.body.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space2),
                Text(
                  copy.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
              if (error != null && kDebugMode) ...[
                const SizedBox(height: AppTokens.space4),
                GlassPanel(
                  borderRadius: AppRadius.medium,
                  tint: colorScheme.error.withValues(alpha: 0.08),
                  borderColor: colorScheme.error.withValues(alpha: 0.25),
                  padding: AppSpacing.space3,
                  child: Text(
                    error.toString(),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppTokens.space5),
                PressScale(
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(retryText ?? 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state for network connectivity issues
class NetworkErrorState extends StatelessWidget {
  const NetworkErrorState({super.key, this.onRetry, this.padding});

  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.wifi_off,
      eyebrow: 'Offline',
      message: 'No internet connection.\nPlease check your network and try again.',
      onRetry: onRetry,
      retryText: 'Retry',
      padding: padding,
    );
  }
}

/// Error state for authentication issues
class AuthErrorState extends StatelessWidget {
  const AuthErrorState({super.key, this.onRetry, this.padding});

  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.lock_outline,
      eyebrow: 'Session',
      message: 'Authentication failed.\nPlease sign in again.',
      onRetry: onRetry,
      retryText: 'Sign In',
      padding: padding,
    );
  }
}

/// Error state for permission issues
class PermissionErrorState extends StatelessWidget {
  const PermissionErrorState({super.key, this.onRetry, this.padding});

  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.block,
      eyebrow: 'Restricted',
      message: 'Access denied.\nYou don\'t have permission to view this content.',
      onRetry: onRetry,
      retryText: 'Go Back',
      padding: padding,
    );
  }
}

/// Error state for data loading failures
class DataLoadErrorState extends StatelessWidget {
  const DataLoadErrorState({
    super.key,
    required this.dataType,
    this.error,
    this.onRetry,
    this.padding,
  });

  final String dataType;
  final Object? error;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.cloud_off,
      eyebrow: 'Load failed',
      message: 'Failed to load $dataType.\nPlease try again.',
      error: error,
      onRetry: onRetry,
      retryText: 'Retry',
      padding: padding,
    );
  }
}

/// Error state for export failures
class ExportErrorState extends StatelessWidget {
  const ExportErrorState({super.key, this.error, this.onRetry, this.padding});

  final Object? error;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.file_download_off,
      eyebrow: 'Export',
      message: 'Export failed.\nUnable to generate CSV file.',
      error: error,
      onRetry: onRetry,
      retryText: 'Try Again',
      padding: padding,
    );
  }
}

/// Error state for upload failures
class UploadErrorState extends StatelessWidget {
  const UploadErrorState({super.key, this.error, this.onRetry, this.padding});

  final Object? error;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.cloud_upload_outlined,
      eyebrow: 'Upload',
      message: 'Upload failed.\nPlease check your connection and try again.',
      error: error,
      onRetry: onRetry,
      retryText: 'Retry Upload',
      padding: padding,
    );
  }
}

/// Error state for validation failures
class ValidationErrorState extends StatelessWidget {
  const ValidationErrorState({super.key, required this.message, this.onRetry, this.padding});

  final String message;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.warning_amber_outlined,
      eyebrow: 'Check details',
      message: message,
      onRetry: onRetry,
      retryText: 'Fix Issues',
      padding: padding,
    );
  }
}

/// Error state for server errors
class ServerErrorState extends StatelessWidget {
  const ServerErrorState({super.key, this.error, this.onRetry, this.padding});

  final Object? error;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.dns_outlined,
      eyebrow: 'Server',
      message: 'Server error occurred.\nPlease try again later.',
      error: error,
      onRetry: onRetry,
      retryText: 'Retry',
      padding: padding,
    );
  }
}

/// Error state for timeout errors
class TimeoutErrorState extends StatelessWidget {
  const TimeoutErrorState({super.key, this.onRetry, this.padding});

  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.timer_off_outlined,
      eyebrow: 'Timed out',
      message: 'Request timed out.\nPlease check your connection and try again.',
      onRetry: onRetry,
      retryText: 'Retry',
      padding: padding,
    );
  }
}
