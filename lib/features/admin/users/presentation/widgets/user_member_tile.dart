import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../../ui/components/monogram_avatar.dart';
import '../../domain/user_model.dart' as domain;

/// Floating glass member row: monogram avatar, name/email, role pill and
/// active status. [wide] shows phone/dates and inline action buttons; narrow
/// layouts collapse the actions into a menu. Actions are reported through
/// [onAction] as `edit`, `activate` or `deactivate`.
class UserMemberTile extends StatelessWidget {
  const UserMemberTile({
    super.key,
    required this.user,
    required this.isAdmin,
    required this.wide,
    required this.onAction,
  });

  final domain.UserModel user;
  final bool isAdmin;
  final bool wide;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w300,
            color: cs.onSurfaceVariant,
          ),
        ),
        if (!wide && user.phone != null) ...[
          const SizedBox(height: 2),
          Text(
            user.phone!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300),
          ),
        ],
        if (!wide) ...[
          const SizedBox(height: AppTokens.space2),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              UserRolePill(role: user.role),
              UserStatusLabel(active: user.isActive),
            ],
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Admins can tap anywhere on the row to edit the user.
        onTap: isAdmin ? () => onAction('edit') : null,
        child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space3,
          AppTokens.space1,
          AppTokens.space3,
        ),
        child: Row(
          children: [
            MonogramAvatar(name: user.name, dimmed: !user.isActive),
            const SizedBox(width: AppTokens.space3),
            if (wide) ...[
              Expanded(flex: 3, child: identity),
              const SizedBox(width: AppTokens.space3),
              Expanded(flex: 3, child: _WideDetails(user: user)),
              const SizedBox(width: AppTokens.space3),
              UserRolePill(role: user.role),
              const SizedBox(width: AppTokens.space3),
              SizedBox(width: 92, child: UserStatusLabel(active: user.isActive)),
              _InlineActions(user: user, isAdmin: isAdmin, onAction: onAction),
            ] else ...[
              Expanded(child: identity),
              _ActionsMenu(user: user, isAdmin: isAdmin, onAction: onAction),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _WideDetails extends StatelessWidget {
  const _WideDetails({required this.user});

  final domain.UserModel user;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final meta = t.bodySmall?.copyWith(fontWeight: FontWeight.w300, color: cs.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.phone ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          'Created ${_formatDate(user.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: meta,
        ),
        Text(
          'Updated ${_formatDate(user.updatedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: meta,
        ),
      ],
    );
  }
}

class _InlineActions extends StatelessWidget {
  const _InlineActions({required this.user, required this.isAdmin, required this.onAction});

  final domain.UserModel user;
  final bool isAdmin;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: isAdmin ? () => onAction('edit') : null,
          tooltip: isAdmin ? 'Edit' : 'Edit (admin only)',
        ),
        IconButton(
          icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline),
          onPressed: isAdmin ? () => onAction(user.isActive ? 'deactivate' : 'activate') : null,
          tooltip: isAdmin ? (user.isActive ? 'Deactivate' : 'Activate') : 'Admin only',
        ),
      ],
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.user, required this.isAdmin, required this.onAction});

  final domain.UserModel user;
  final bool isAdmin;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: isAdmin ? onAction : null,
      enabled: isAdmin,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: AppTokens.space2),
              Text(isAdmin ? 'Edit' : 'Edit (admin only)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: user.isActive ? 'deactivate' : 'activate',
          enabled: isAdmin,
          child: Row(
            children: [
              Icon(user.isActive ? Icons.block : Icons.check_circle_outline),
              const SizedBox(width: AppTokens.space2),
              Text(isAdmin ? (user.isActive ? 'Deactivate' : 'Activate') : 'Admin only'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tinted pill with the uppercase role name.
class UserRolePill extends StatelessWidget {
  const UserRolePill({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = role == 'admin' ? AppColorScheme.chartPurple : AppColorScheme.chartBlue;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          role.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Status dot plus ACTIVE / INACTIVE micro-label.
class UserStatusLabel extends StatelessWidget {
  const UserStatusLabel({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColorScheme.chartGreen : AppColorScheme.chartRed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, size: 7),
        const SizedBox(width: 6),
        Text(
          active ? 'ACTIVE' : 'INACTIVE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}, '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
