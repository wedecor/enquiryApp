import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/safe_log.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../domain/app_config.dart';
import '../../../providers/settings_providers.dart';
import '../../../../../ui/components/glass_dialog.dart';
import '../../../../../ui/components/glass_state_message.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

class SecurityConfigTab extends ConsumerWidget {
  const SecurityConfigTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appSecurityConfigProvider);

    return configAsync.when(
      data: (config) => _buildSecurityConfig(context, ref, config),
      loading: () => const GlassLoadingState(),
      error: (error, stack) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Security settings unavailable',
        message: 'Error loading security config: $error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildSecurityConfig(BuildContext context, WidgetRef ref, AppSecurityConfig config) {
    final s = AppSurfaces.of(context);
    return SettingsScrollBody(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.space1, AppTokens.space5, 0, 0),
          child: SplitHeading(
            light: 'Security',
            bold: 'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SettingsGroup(
          eyebrow: 'Invites',
          title: 'Allowed Email Domains',
          subtitle: 'Users can only be invited from these domains',
          separated: false,
          padding: const EdgeInsets.all(AppTokens.space4),
          children: [
            Wrap(
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space2,
              children: config.allowedDomains.map((domain) {
                return Chip(
                  avatar: Icon(Icons.alternate_email_rounded, size: 16, color: s.accentInk),
                  label: Text(domain),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: config.allowedDomains.length > 1
                      ? () => _removeDomain(ref, config, domain)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: AppTokens.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _showAddDomainDialog(context, ref, config),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Domain'),
              ),
            ),
          ],
        ),
        SettingsGroup(
          eyebrow: 'Sign-in',
          title: 'Login Security',
          children: [
            SettingsSwitchTile(
              icon: Icons.password_rounded,
              title: 'Require First Login Reset',
              subtitle: 'Force new users to reset password on first login',
              value: config.requireFirstLoginReset,
              onChanged: (value) async {
                try {
                  final updateConfig = ref.read(updateAppSecurityConfigProvider);
                  await updateConfig(config.copyWith(requireFirstLoginReset: value));
                } catch (e) {
                  safeLog('security_config_update_error', {
                    'field': 'requireFirstLoginReset',
                    'error': e.toString(),
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _removeDomain(WidgetRef ref, AppSecurityConfig config, String domain) async {
    try {
      final newDomains = List<String>.from(config.allowedDomains)..remove(domain);
      final updateConfig = ref.read(updateAppSecurityConfigProvider);
      await updateConfig(config.copyWith(allowedDomains: newDomains));
    } catch (e) {
      safeLog('domain_remove_error', {'domain': domain, 'error': e.toString()});
    }
  }

  void _showAddDomainDialog(BuildContext context, WidgetRef ref, AppSecurityConfig config) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => GlassDialog(
        icon: Icons.domain_add_rounded,
        title: 'Add Allowed Domain',
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Domain (e.g., company.com)'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Domain is required';
            }
            if (!RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
              return 'Invalid domain format';
            }
            return null;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final domain = controller.text.trim().toLowerCase();
              if (domain.isNotEmpty && !config.allowedDomains.contains(domain)) {
                final navigator = Navigator.of(context);
                try {
                  final newDomains = List<String>.from(config.allowedDomains)..add(domain);
                  final updateConfig = ref.read(updateAppSecurityConfigProvider);
                  await updateConfig(config.copyWith(allowedDomains: newDomains));
                  navigator.pop();
                } catch (e) {
                  safeLog('domain_add_error', {'domain': domain, 'error': e.toString()});
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
