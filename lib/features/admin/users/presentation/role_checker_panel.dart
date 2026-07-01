import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final warningColor = AppColorScheme.warning;
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: isAdmin ? AppColorScheme.chartGreen : AppColorScheme.chartAmber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Access Check',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip('Email', email ?? 'Unknown', Icons.email),
                _buildInfoChip('UID', _truncateUid(uid), Icons.fingerprint),
                _buildRoleChip(context, role ?? 'unknown'),
              ],
            ),
            const SizedBox(height: 16),
            if (!isAdmin)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorScheme.warningContainerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warningColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: warningColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Limited Access',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You're signed in but not an admin. To access User Management actions, "
                      "make sure your Firestore users/{uid} document has role: 'admin' and active: true, "
                      'or sign in as the seeded admin user.',
                      style: theme.textTheme.bodySmall?.copyWith(color: warningColor),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorScheme.successContainerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorScheme.successLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColorScheme.onSuccessContainerLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Admin access granted. You can manage users.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColorScheme.onSuccessContainerLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (onRefresh != null)
                  FilledButton.tonal(onPressed: onRefresh, child: const Text('Refresh Role')),
                const SizedBox(width: 12),
                if (onSignOut != null)
                  OutlinedButton(onPressed: onSignOut, child: const Text('Sign Out')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    final isAdminRole = role == 'admin';
    final onChip = Theme.of(context).colorScheme.onPrimary;
    return Chip(
      avatar: Icon(
        isAdminRole ? Icons.admin_panel_settings : Icons.person,
        size: 16,
        color: onChip,
      ),
      label: Text(
        'Role: ${role.toUpperCase()}',
        style: TextStyle(fontSize: 12, color: onChip, fontWeight: FontWeight.w600),
      ),
      backgroundColor: isAdminRole ? AppColorScheme.chartGreen : AppColorScheme.chartBlue,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _truncateUid(String? uid) {
    if (uid == null) return 'Unknown';
    if (uid.length <= 12) return uid;
    return '${uid.substring(0, 8)}...';
  }
}
