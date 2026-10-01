import 'package:flutter/material.dart';

import '../../core/constants/status_vocabulary.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

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
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => _ActionsSheet(customerName: customerName, actions: actions),
  );
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({required this.customerName, required this.actions});

  final String customerName;
  final List<EnquiryRowAction> actions;

  Future<void> _run(BuildContext context, EnquiryRowAction action) async {
    Navigator.pop(context);
    await action.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final columns = actions.length == 4 ? 2 : actions.length.clamp(1, 3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space2, 0, AppTokens.space2, AppTokens.space2),
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.xxLarge,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space5,
              AppTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space5),
                const Eyebrow('Quick actions', accent: true),
                const SizedBox(height: AppTokens.space1),
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.space5),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = AppTokens.space3;
                    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < actions.length; i++)
                          SizedBox(
                            width: width,
                            child: StaggerIn(
                              index: i,
                              child: _ActionTile(
                                action: actions[i],
                                onTap: () => _run(context, actions[i]),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppTokens.space3),
                Pressable(
                  onTap: () => Navigator.pop(context),
                  borderRadius: AppRadius.large,
                  child: Container(
                    height: AppTokens.minTapTarget + 4,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.large,
                      border: Border.all(color: s.microBorder),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final EnquiryRowAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final tint = action.tint ?? s.accentInk;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.large,
      pressedScale: 0.95,
      semanticLabel: action.label,
      child: GlassPanel(
        borderRadius: AppRadius.large,
        tint: tint.withValues(alpha: 0.06),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space3,
          AppTokens.space4,
          AppTokens.space3,
          AppTokens.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
                border: Border.all(color: tint.withValues(alpha: 0.22)),
              ),
              child: Icon(action.icon, size: 20, color: tint),
            ),
            const SizedBox(height: AppTokens.space3),
            // Reserve two lines so tiles in a row share one height.
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.textScalerOf(context).scale(AppTokens.fontSizeBody) * 2.8,
              ),
              child: Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  String? statusValue,
  Future<void> Function()? onAddNote,
  Future<void> Function()? onShare,
  Future<void> Function()? onMarkNotInterested,
  Future<void> Function(String phone)? onRequestReview,
}) {
  final status = EnquiryStatus.fromValue(statusValue);
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

  if (onAddNote != null) {
    actions.add(
      EnquiryRowAction(label: 'Add note', icon: Icons.note_add_outlined, onSelected: onAddNote),
    );
  }

  if (onShare != null) {
    actions.add(EnquiryRowAction(label: 'Share', icon: Icons.share_outlined, onSelected: onShare));
  }

  if (onMarkNotInterested != null &&
      (status == EnquiryStatus.newEnquiry || status == EnquiryStatus.inTalks)) {
    actions.add(
      EnquiryRowAction(
        label: 'Mark not interested',
        icon: Icons.block,
        onSelected: onMarkNotInterested,
      ),
    );
  }

  if (onRequestReview != null &&
      status == EnquiryStatus.completed &&
      callNumber != null &&
      callNumber.isNotEmpty) {
    actions.add(
      EnquiryRowAction(
        label: 'Request review',
        icon: Icons.star_outline_rounded,
        onSelected: () => onRequestReview(callNumber),
      ),
    );
  }

  return actions;
}
