import 'package:flutter/material.dart';

import '../../../../ui/components/tinted_icon_badge.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

class RoleCheckerPanel extends StatelessWidget {
  final String? email;
  final String? uid;
  final bool isAdmin;
  final String? role;
  final VoidCallback? onSignOut;
  final VoidCallback? onRefresh;

  const RoleCheckerPanel({
    super.key,
    required this.email,
    required this.uid,
    required this.isAdmin,
    this.role,
    this.onSignOut,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tone = isAdmin ? AppColorScheme.chartGreen : AppColorScheme.warning;

    return GlassPanel(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TintedIconBadge(
                icon: isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline_rounded,
                color: isAdmin ? AppColorScheme.chartGreen : AppColorScheme.chartAmber,
                size: 34,
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Session', accent: true),
                    Text(
                      'Access Check',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: [
              _InfoPill(icon: Icons.alternate_email_rounded, text: 'Email: ${email ?? 'Unknown'}'),
              _InfoPill(icon: Icons.fingerprint_rounded, text: 'UID: ${_truncateUid(uid)}'),
              _InfoPill(
                icon: (role ?? 'unknown') == 'admin'
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline_rounded,
                text: 'Role: ${(role ?? 'unknown').toUpperCase()}',
                color: (role ?? 'unknown') == 'admin'
                    ? AppColorScheme.chartGreen
                    : AppColorScheme.chartBlue,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.08),
              borderRadius: AppRadius.medium,
              border: Border.all(color: tone.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: isAdmin
                  ? Row(
                      children: [
                        StatusDot(color: tone),
                        const SizedBox(width: AppTokens.space2),
                        Expanded(
                          child: Text(
                            'Admin access granted. You can manage users.',
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: tone, size: 18),
                            const SizedBox(width: AppTokens.space2),
                            Text(
                              'Limited Access',
                              style: t.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: tone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          "You're signed in but not an admin. To access User Management actions, "
                          "make sure your Firestore users/{uid} document has role: 'admin' and active: true, "
                          'or sign in as the seeded admin user.',
                          style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300, height: 1.45),
                        ),
                      ],
                    ),
            ),
          ),
          if (onRefresh != null || onSignOut != null) ...[
            const SizedBox(height: AppTokens.space3),
            Wrap(
              spacing: AppTokens.space3,
              runSpacing: AppTokens.space2,
              children: [
                if (onRefresh != null)
                  FilledButton.tonalIcon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh Role'),
                  ),
                if (onSignOut != null)
                  OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _truncateUid(String? uid) {
    if (uid == null) return 'Unknown';
    if (uid.length <= 12) return uid;
    return '${uid.substring(0, 8)}...';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final tone = color ?? cs.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.10) ?? s.glassFillStrong,
        borderRadius: AppRadius.full,
        border: Border.all(color: color?.withValues(alpha: 0.28) ?? s.microBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tone),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color ?? cs.onSurface,
                  fontWeight: color != null ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
