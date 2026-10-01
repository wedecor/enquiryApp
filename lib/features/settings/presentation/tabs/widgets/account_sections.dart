import 'package:flutter/material.dart';

import '../../../../../ui/components/tinted_icon_badge.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../../ui/components/monogram_avatar.dart';
import '../../widgets/settings_tiles.dart';

/// Monogram + name hero followed by read-only profile rows.
class AccountProfileRows extends StatelessWidget {
  const AccountProfileRows({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final name = user.name.trim().isEmpty ? user.email : user.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Row(
            children: [
              MonogramAvatar(name: name, size: 56),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _ReadOnlyRow(icon: Icons.alternate_email_rounded, label: 'Email', value: user.email),
        const Divider(height: 1, indent: 66, endIndent: AppTokens.space4),
        _ReadOnlyRow(icon: Icons.badge_outlined, label: 'Name', value: user.name),
        const Divider(height: 1, indent: 66, endIndent: AppTokens.space4),
        _ReadOnlyRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: user.phone ?? 'Not provided',
        ),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isEmpty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          TintedIconBadge(icon: icon, color: cs.onSurfaceVariant),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(label),
                const SizedBox(height: 2),
                Text(
                  isEmpty ? 'Not provided' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge?.copyWith(
                    fontWeight: isEmpty ? FontWeight.w300 : FontWeight.w600,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    color: isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Role badge row: tinted icon, uppercase role and what it grants.
class AccountRoleRow extends StatelessWidget {
  const AccountRoleRow({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAdmin = role == 'admin';
    final roleColor = isAdmin ? cs.tertiary : cs.primary;
    return SettingsTile(
      icon: isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline_rounded,
      iconColor: roleColor,
      title: role.toUpperCase(),
      subtitle: isAdmin
          ? 'Full system access and user management'
          : 'Access to assigned enquiries and personal settings',
    );
  }
}

/// Full-width destructive glass pill.
class AccountSignOutButton extends StatelessWidget {
  const AccountSignOutButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.full,
      semanticLabel: 'Sign Out',
      child: GlassPanel(
        borderRadius: AppRadius.full,
        tint: cs.error.withValues(alpha: 0.10),
        borderColor: cs.error.withValues(alpha: 0.30),
        child: SizedBox(
          height: 54,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: cs.error, size: 20),
                const SizedBox(width: AppTokens.space2),
                Text(
                  'Sign Out',
                  style: t.labelLarge?.copyWith(color: cs.error, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
