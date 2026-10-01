import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// A reusable error state widget with consistent styling
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.error,
    this.onRetry,
    this.retryText,
    this.icon,
    this.padding,
  });

  final String message;
  final Object? error;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: padding ?? AppSpacing.space8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              icon ?? Icons.error_outline,
              size: AppTokens.iconXLarge * 2,
              color: colorScheme.error,
            ),

            const SizedBox(height: AppTokens.space6),

            // Error message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),

            // Error details (if provided and in debug mode)
            if (error != null && kDebugMode) ...[
              const SizedBox(height: AppTokens.space4),
              Container(
                padding: AppSpacing.space4,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: AppRadius.medium,
                ),
                child: Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.space6),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
              ),
            ],
          ],
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
      message: 'Request timed out.\nPlease check your connection and try again.',
      onRetry: onRetry,
      retryText: 'Retry',
      padding: padding,
    );
  }
}
