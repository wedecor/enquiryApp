import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import 'enquiry_status_control.dart';

/// Sticky footer for enquiry detail: primary status action + contact shortcuts.
class EnquiryDetailFooter extends ConsumerWidget {
  const EnquiryDetailFooter({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.userRole,
    required this.currentUserId,
    required this.statusValue,
    required this.statusLabel,
    required this.customerPhone,
    required this.customerName,
    this.onCall,
    this.onWhatsApp,
    this.onEdit,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final UserRole? userRole;
  final String currentUserId;
  final String statusValue;
  final String statusLabel;
  final String? customerPhone;
  final String customerName;
  final Future<void> Function()? onCall;
  final Future<void> Function()? onWhatsApp;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final phone = customerPhone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final isAdmin = userRole == UserRole.admin;
    final isAssignee = (enquiryData['assignedTo'] as String?) == currentUserId;
    final canUpdateStatus = isAdmin || isAssignee;

    return Row(
      children: [
        if (hasPhone && onCall != null)
          IconButton.outlined(
            tooltip: 'Call',
            onPressed: () => onCall!(),
            icon: Icon(Icons.call_outlined, color: AppColorScheme.phoneCall),
          ),
        if (hasPhone && onWhatsApp != null) ...[
          const SizedBox(width: AppTokens.space2),
          IconButton.outlined(
            tooltip: 'WhatsApp',
            onPressed: () => onWhatsApp!(),
            icon: Icon(
              Icons.chat_bubble_outline,
              color: AppColorScheme.whatsApp,
            ),
          ),
        ],
        const SizedBox(width: AppTokens.space2),
        Expanded(
          child: FilledButton.icon(
            onPressed: canUpdateStatus
                ? () => _showStatusSheet(
                    context,
                    enquiryId: enquiryId,
                    enquiryData: enquiryData,
                    statusValue: statusValue,
                    statusLabel: statusLabel,
                    isAdmin: isAdmin,
                    isAssignee: isAssignee,
                  )
                : null,
            icon: const Icon(Icons.swap_horiz, size: 20),
            label: const Text('Update status'),
          ),
        ),
        if (isAdmin && onEdit != null)
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'edit') onEdit!();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit enquiry')),
            ],
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  void _showStatusSheet(
    BuildContext context, {
    required String enquiryId,
    required Map<String, dynamic> enquiryData,
    required String statusValue,
    required String statusLabel,
    required bool isAdmin,
    required bool isAssignee,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppTokens.space4,
          0,
          AppTokens.space4,
          MediaQuery.paddingOf(ctx).bottom + AppTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update status', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: AppTokens.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: EnquiryStatusControl(
                enquiryId: enquiryId,
                enquiryData: enquiryData,
                currentStatusValue: statusValue,
                currentStatusLabel: statusLabel,
                isAdmin: isAdmin,
                isAssignee: isAssignee,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
