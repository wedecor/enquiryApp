import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_round_button.dart';
import 'enquiry_status_control.dart';

/// Sticky footer for enquiry detail: primary status action + contact shortcuts.
/// Rendered inside an [EnquiryGlassBar] by the screen.
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
    final s = AppSurfaces.of(context);
    final phone = customerPhone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final isAdmin = userRole == UserRole.admin;
    final isAssignee = (enquiryData['assignedTo'] as String?) == currentUserId;
    final canUpdateStatus = isAdmin || isAssignee;

    return Row(
      children: [
        if (hasPhone && onCall != null)
          EnquiryRoundButton(
            icon: Icons.call_outlined,
            tooltip: 'Call',
            iconColor: AppColorScheme.phoneCall,
            onTap: () => onCall!(),
          ),
        if (hasPhone && onWhatsApp != null) ...[
          const SizedBox(width: AppTokens.space2),
          EnquiryRoundButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'WhatsApp',
            iconColor: AppColorScheme.whatsApp,
            onTap: () => onWhatsApp!(),
          ),
        ],
        const SizedBox(width: AppTokens.space2),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.full,
              boxShadow: canUpdateStatus ? AppShadows.glow(s.shadow, strength: 0.16) : null,
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(AppTokens.minTapTarget + 4),
              ),
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
              label: const Text('Update status', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        if (isAdmin && onEdit != null) ...[
          const SizedBox(width: AppTokens.space2),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'edit') onEdit!();
            },
            shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit enquiry')),
            ],
            child: SizedBox.square(
              dimension: AppTokens.minTapTarget,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.glassFillStrong,
                  border: Border.all(color: s.microBorder),
                ),
                child: Icon(Icons.more_horiz_rounded, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => _StatusSheet(
        statusLabel: statusLabel,
        statusColor: AppColorScheme.statusColorFor(statusValue),
        child: EnquiryStatusControl(
          enquiryId: enquiryId,
          enquiryData: enquiryData,
          currentStatusValue: statusValue,
          currentStatusLabel: statusLabel,
          isAdmin: isAdmin,
          isAssignee: isAssignee,
          layout: EnquiryStatusLayout.list,
          onStatusChanged: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

/// Frosted sheet chrome around the status options.
class _StatusSheet extends StatelessWidget {
  const _StatusSheet({required this.child, required this.statusLabel, required this.statusColor});

  final Widget child;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space2,
        media.padding.top + AppTokens.space8,
        AppTokens.space2,
        media.padding.bottom + AppTokens.space2,
      ),
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.xxLarge,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space5,
            AppTokens.space3,
            AppTokens.space5,
            AppTokens.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: s.microBorderStrong,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space5),
              Row(
                children: [
                  StatusDot(color: statusColor),
                  const SizedBox(width: AppTokens.space2),
                  Flexible(child: Eyebrow('Currently · $statusLabel')),
                ],
              ),
              const SizedBox(height: AppTokens.space1),
              SplitHeading(light: 'Update', bold: 'status', style: t.headlineMedium, maxLines: 1),
              const SizedBox(height: AppTokens.space5),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
