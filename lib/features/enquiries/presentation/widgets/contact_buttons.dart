import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/a11y/tap_target.dart';
import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/theme/tokens.dart';

/// Contact action buttons for calling and messaging customers
/// 
/// Provides accessible Call and WhatsApp buttons with proper error handling,
/// audit logging, and platform-appropriate fallbacks.
class ContactButtons extends ConsumerWidget {
  const ContactButtons({
    super.key,
    required this.customerPhone,
    required this.customerName,
    this.enquiryId,
    this.enabled = true,
  });

  final String? customerPhone;
  final String customerName;
  final String? enquiryId;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contactLauncher = ref.read(contactLauncherProvider);

    // Don't show buttons if no phone number
    if (customerPhone == null || customerPhone!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: AppTokens.space2),
      child: Row(
        children: [
          // Call Button
          Expanded(
            child: TapTarget(
              onTap: enabled ? () => _handleCall(context, ref, contactLauncher) : null,
              semanticLabel: 'Call $customerName',
              semanticHint: 'Opens phone dialer with customer number',
              enabled: enabled,
              minSize: AppTokens.minTapTarget,
              child: Container(
                height: AppTokens.minTapTarget,
                decoration: BoxDecoration(
                  color: enabled 
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: enabled 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call,
                      size: AppTokens.iconSmall,
                      color: enabled 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    SizedBox(width: AppTokens.space1),
                    Text(
                      'Call',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: enabled 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(width: AppTokens.space3),
          
          // WhatsApp Button
          Expanded(
            child: TapTarget(
              onTap: enabled ? () => _handleWhatsApp(context, ref, contactLauncher) : null,
              semanticLabel: 'Message $customerName on WhatsApp',
              semanticHint: 'Opens WhatsApp chat with customer',
              enabled: enabled,
              minSize: AppTokens.minTapTarget,
              child: Container(
                height: AppTokens.minTapTarget,
                decoration: BoxDecoration(
                  color: enabled 
                      ? const Color(0xFF25D366).withOpacity(0.1) // WhatsApp green
                      : theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: enabled 
                        ? const Color(0xFF25D366)
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat,
                      size: AppTokens.iconSmall,
                      color: enabled 
                          ? const Color(0xFF25D366)
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    SizedBox(width: AppTokens.space1),
                    Text(
                      'WhatsApp',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: enabled 
                            ? const Color(0xFF25D366)
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle call button tap
  Future<void> _handleCall(
    BuildContext context,
    WidgetRef ref,
    ContactLauncher contactLauncher,
  ) async {
    try {
      final status = await contactLauncher.callNumberWithAudit(
        customerPhone!,
        enquiryId: enquiryId,
      );

      if (!context.mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          // Success - no UI feedback needed
          break;
        
        case ContactLaunchStatus.invalidNumber:
          _showErrorSnackBar(
            context,
            'Invalid phone number format',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
        
        case ContactLaunchStatus.notInstalled:
          _showErrorSnackBar(
            context,
            'Phone dialer not available on this device',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
        
        case ContactLaunchStatus.failed:
          _showErrorSnackBar(
            context,
            'Could not open phone dialer',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error launching phone dialer',
          action: 'Copy Number',
          onAction: () => _copyToClipboard(context, customerPhone!),
        );
      }
    }
  }

  /// Handle WhatsApp button tap
  Future<void> _handleWhatsApp(
    BuildContext context,
    WidgetRef ref,
    ContactLauncher contactLauncher,
  ) async {
    try {
      final prefillText = 'Hi $customerName, I\'m following up on your enquiry with We Decor. How can I help you today?';
      
      final status = await contactLauncher.openWhatsAppWithAudit(
        customerPhone!,
        prefillText: prefillText,
        enquiryId: enquiryId,
      );

      if (!context.mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          // Success - no UI feedback needed
          break;
        
        case ContactLaunchStatus.invalidNumber:
          _showErrorSnackBar(
            context,
            'Invalid phone number format',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
        
        case ContactLaunchStatus.notInstalled:
          _showErrorSnackBar(
            context,
            'WhatsApp not installed. Opened in browser instead.',
            isError: false,
          );
          break;
        
        case ContactLaunchStatus.failed:
          _showErrorSnackBar(
            context,
            'Could not open WhatsApp',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error launching WhatsApp',
          action: 'Copy Number',
          onAction: () => _copyToClipboard(context, customerPhone!),
        );
      }
    }
  }

  /// Show error snackbar with optional action
  void _showErrorSnackBar(
    BuildContext context,
    String message, {
    String? action,
    VoidCallback? onAction,
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        action: action != null && onAction != null
            ? SnackBarAction(
                label: action,
                textColor: isError 
                    ? Theme.of(context).colorScheme.onError
                    : Theme.of(context).colorScheme.onPrimary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Copy phone number to clipboard
  Future<void> _copyToClipboard(BuildContext context, String phoneNumber) async {
    try {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone number copied to clipboard'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to copy phone number'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
