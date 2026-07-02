import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Quick actions for an enquiry list row (long-press or overflow).
class EnquiryRowAction {
  const EnquiryRowAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.tint,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onSelected;
  final Color? tint;
}

Future<void> showEnquiryRowActionsSheet(
  BuildContext context, {
  required String customerName,
  required List<EnquiryRowAction> actions,
}) async {
  if (actions.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                customerName,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final action in actions)
              ListTile(
                leading: Icon(
                  action.icon,
                  color: action.tint ?? theme.colorScheme.onSurface,
                ),
                title: Text(action.label),
                onTap: () async {
                  Navigator.pop(ctx);
                  await action.onSelected();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.close,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    },
  );
}

List<EnquiryRowAction> contactEnquiryRowActions({
  required String customerName,
  String? phone,
  String? whatsapp,
  required String enquiryId,
  required Future<void> Function(String phone) onCall,
  required Future<void> Function(String phone) onWhatsApp,
  VoidCallback? onView,
  VoidCallback? onUpdateStatus,
}) {
  final actions = <EnquiryRowAction>[];

  if (onView != null) {
    actions.add(
      EnquiryRowAction(
        label: 'View details',
        icon: Icons.visibility_outlined,
        onSelected: () async {
          onView();
        },
      ),
    );
  }

  final callNumber = phone?.trim();
  if (callNumber != null && callNumber.isNotEmpty) {
    actions.add(
      EnquiryRowAction(
        label: 'Call',
        icon: Icons.call_outlined,
        tint: AppColorScheme.phoneCall,
        onSelected: () => onCall(callNumber),
      ),
    );
  }

  final waNumber = (whatsapp ?? phone)?.trim();
  if (waNumber != null && waNumber.isNotEmpty) {
    actions.add(
      EnquiryRowAction(
        label: 'WhatsApp',
        icon: Icons.chat_bubble_outline,
        tint: AppColorScheme.whatsApp,
        onSelected: () => onWhatsApp(waNumber),
      ),
    );
  }

  if (onUpdateStatus != null) {
    actions.add(
      EnquiryRowAction(
        label: 'Update status',
        icon: Icons.swap_horiz_outlined,
        onSelected: () async {
          onUpdateStatus();
        },
      ),
    );
  }

  return actions;
}
