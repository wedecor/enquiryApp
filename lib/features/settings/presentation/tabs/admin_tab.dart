import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../domain/app_config.dart';
import '../../providers/settings_providers.dart';
import 'past_enquiry_cleanup_widget.dart';

class AdminTab extends ConsumerStatefulWidget {
  const AdminTab({super.key});

  @override
  ConsumerState<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends ConsumerState<AdminTab> with TickerProviderStateMixin {
  late TabController _adminTabController;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _adminTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _adminTabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Company'),
              Tab(text: 'Notifications'),
              Tab(text: 'Security'),
              Tab(text: 'Data'),
              Tab(text: 'About'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _adminTabController,
            children: const [
              CompanyConfigTab(),
              NotificationConfigTab(),
              SecurityConfigTab(),
              DataIntegrationsTab(),
              AboutTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class CompanyConfigTab extends ConsumerStatefulWidget {
  const CompanyConfigTab({super.key});

  @override
  ConsumerState<CompanyConfigTab> createState() => _CompanyConfigTabState();
}

class _CompanyConfigTabState extends ConsumerState<CompanyConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _currencyController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _vatPercentController = TextEditingController();

  AppGeneralConfig? _originalConfig;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _logoUrlController.dispose();
    _currencyController.dispose();
    _timezoneController.dispose();
    _vatPercentController.dispose();
    _googleReviewLinkController.dispose();
    _instagramHandleController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appGeneralConfigProvider);

    return configAsync.when(
      data: (config) {
        if (_originalConfig == null) {
          _originalConfig = config;
          _initializeControllers(config);
        }

        return _buildCompanyForm(context, config);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading company config: $error')),
    );
  }

  final _googleReviewLinkController = TextEditingController();
  final _instagramHandleController = TextEditingController();
  final _websiteUrlController = TextEditingController();

  void _initializeControllers(AppGeneralConfig config) {
    _companyNameController.text = config.companyName;
    _logoUrlController.text = config.logoUrl ?? '';
    _currencyController.text = config.currency;
    _timezoneController.text = config.timezone;
    _vatPercentController.text = config.vatPercent.toString();
    _googleReviewLinkController.text = config.googleReviewLink;
    _instagramHandleController.text = config.instagramHandle;
    _websiteUrlController.text = config.websiteUrl;
  }

  Widget _buildCompanyForm(BuildContext context, AppGeneralConfig config) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              onChanged: () {
                setState(() {
                  _hasChanges = _hasFormChanges(config);
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company & App Settings', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Company name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _logoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Logo URL (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/logo.png',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final uri = Uri.tryParse(value);
                        if (uri == null || !uri.hasScheme) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency Code',
                      border: OutlineInputBorder(),
                      hintText: 'INR, USD, EUR, etc.',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length != 3) {
                        return 'Currency code must be exactly 3 letters';
                      }
                      return null;
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _timezoneController.text.isNotEmpty
                        ? _timezoneController.text
                        : 'Asia/Kolkata',
                    decoration: const InputDecoration(
                      labelText: 'Default Timezone',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
                      DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                      DropdownMenuItem(
                        value: 'America/New_York',
                        child: Text('America/New_York (EST)'),
                      ),
                      DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London (GMT)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _timezoneController.text = value;
                        setState(() {
                          _hasChanges = _hasFormChanges(config);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _vatPercentController,
                    decoration: const InputDecoration(
                      labelText: 'VAT/Tax Percentage',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'VAT percentage is required';
                      }
                      final percent = double.tryParse(value);
                      if (percent == null || percent < 0 || percent > 50) {
                        return 'VAT percentage must be between 0 and 50';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Review & Social Links',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _googleReviewLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Google Review Link',
                      border: OutlineInputBorder(),
                      hintText: 'https://share.google/...',
                      helperText: 'Used in review request messages',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final uri = Uri.tryParse(value);
                        if (uri == null || !uri.hasScheme) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instagramHandleController,
                    decoration: const InputDecoration(
                      labelText: 'Instagram Handle',
                      border: OutlineInputBorder(),
                      hintText: '@wedecorbangalore',
                      helperText: 'Used in review request messages',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://www.wedecorevents.com/',
                      helperText: 'Used in review request messages',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final uri = Uri.tryParse(value);
                        if (uri == null || !uri.hasScheme) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_hasChanges) _buildSaveSection(context, config),
      ],
    );
  }

  bool _hasFormChanges(AppGeneralConfig config) {
    return _companyNameController.text != config.companyName ||
        _logoUrlController.text != (config.logoUrl ?? '') ||
        _currencyController.text != config.currency ||
        _timezoneController.text != config.timezone ||
        _vatPercentController.text != config.vatPercent.toString() ||
        _googleReviewLinkController.text != config.googleReviewLink ||
        _instagramHandleController.text != config.instagramHandle ||
        _websiteUrlController.text != config.websiteUrl;
  }

  Widget _buildSaveSection(BuildContext context, AppGeneralConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveChanges(config),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _isSaving ? null : () => _discardChanges(config),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges(AppGeneralConfig config) async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newConfig = config.copyWith(
        companyName: _companyNameController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
        currency: _currencyController.text.trim().toUpperCase(),
        timezone: _timezoneController.text,
        vatPercent: double.parse(_vatPercentController.text),
        googleReviewLink: _googleReviewLinkController.text.trim(),
        instagramHandle: _instagramHandleController.text.trim(),
        websiteUrl: _websiteUrlController.text.trim(),
      );

      final updateConfig = ref.read(updateAppGeneralConfigProvider);
      await updateConfig(newConfig);

      setState(() {
        _originalConfig = newConfig;
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        _showSnackBar('Company settings saved successfully');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      safeLog('company_config_save_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      });

      if (mounted) {
        _showSnackBar('Failed to save company settings', isError: true);
      }
    }
  }

  void _discardChanges(AppGeneralConfig config) {
    _initializeControllers(config);
    setState(() {
      _hasChanges = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}

class NotificationConfigTab extends ConsumerWidget {
  const NotificationConfigTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appNotificationConfigProvider);

    return configAsync.when(
      data: (config) => _buildNotificationConfig(context, ref, config),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading notification config: $error')),
    );
  }

  Widget _buildNotificationConfig(
    BuildContext context,
    WidgetRef ref,
    AppNotificationConfig config,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notification Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email Configuration', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('Email Invites'),
                    subtitle: Text(config.emailInvitesEnabled ? 'Enabled' : 'Disabled'),
                    trailing: Switch(
                      value: config.emailInvitesEnabled,
                      onChanged: (value) async {
                        try {
                          final updateConfig = ref.read(updateAppNotificationConfigProvider);
                          await updateConfig(config.copyWith(emailInvitesEnabled: value));
                        } catch (e) {
                          safeLog('notification_config_update_error', {
                            'field': 'emailInvitesEnabled',
                            'error': e.toString(),
                          });
                        }
                      },
                    ),
                  ),

                  ListTile(
                    title: const Text('Reply-To Email'),
                    subtitle: Text(config.replyToEmail),
                    trailing: const Icon(Icons.info_outline),
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Reply-To Email',
                        'This email address will be used as the reply-to address for system emails. '
                            'Configure this in your Cloud Functions environment.',
                      );
                    },
                  ),

                  ListTile(
                    title: const Text('Default Reminder Days'),
                    subtitle: Text('${config.reminderDaysDefault} days'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showReminderDaysDialog(context, ref, config),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'SMTP Status',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SMTP configuration is managed in Cloud Functions environment. '
                    'Email delivery is currently active using Gmail SMTP with app password.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showReminderDaysDialog(BuildContext context, WidgetRef ref, AppNotificationConfig config) {
    final controller = TextEditingController(text: config.reminderDaysDefault.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Reminder Days'),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Days', border: OutlineInputBorder()),
          validator: (value) {
            final days = int.tryParse(value ?? '');
            if (days == null || days < 1 || days > 30) {
              return 'Must be between 1 and 30 days';
            }
            return null;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days >= 1 && days <= 30) {
                try {
                  final updateConfig = ref.read(updateAppNotificationConfigProvider);
                  await updateConfig(config.copyWith(reminderDaysDefault: days));
                  Navigator.of(context).pop();
                } catch (e) {
                  safeLog('reminder_days_update_error', {'error': e.toString()});
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class SecurityConfigTab extends ConsumerWidget {
  const SecurityConfigTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appSecurityConfigProvider);

    return configAsync.when(
      data: (config) => _buildSecurityConfig(context, ref, config),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading security config: $error')),
    );
  }

  Widget _buildSecurityConfig(BuildContext context, WidgetRef ref, AppSecurityConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Allowed Email Domains', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Users can only be invited from these domains',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: config.allowedDomains.map((domain) {
                      return Chip(
                        label: Text(domain),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: config.allowedDomains.length > 1
                            ? () => _removeDomain(ref, config, domain)
                            : null,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () => _showAddDomainDialog(context, ref, config),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Domain'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Login Security', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Require First Login Reset'),
                    subtitle: const Text('Force new users to reset password on first login'),
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
            ),
          ),
        ],
      ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allowed Domain'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Domain (e.g., company.com)',
            border: OutlineInputBorder(),
          ),
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
          TextButton(
            onPressed: () async {
              final domain = controller.text.trim().toLowerCase();
              if (domain.isNotEmpty && !config.allowedDomains.contains(domain)) {
                try {
                  final newDomains = List<String>.from(config.allowedDomains)..add(domain);
                  final updateConfig = ref.read(updateAppSecurityConfigProvider);
                  await updateConfig(config.copyWith(allowedDomains: newDomains));
                  Navigator.of(context).pop();
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

class DataIntegrationsTab extends ConsumerWidget {
  const DataIntegrationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data & Integrations', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Push Notifications', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('VAPID Public Key'),
                    subtitle: const Text(
                      'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text:
                                'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('VAPID key copied to clipboard')),
                        );
                      },
                    ),
                  ),

                  const ListTile(
                    title: Text('Region'),
                    subtitle: Text('asia-south1'),
                    trailing: Icon(Icons.location_on),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Management', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('Dropdown Manager'),
                    subtitle: const Text('Manage event types, sources, and other dropdowns'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).pushNamed('/admin/dropdowns');
                    },
                  ),

                  ListTile(
                    title: const Text('User Management'),
                    subtitle: const Text('Manage users, roles, and permissions'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).pushNamed('/admin/users');
                    },
                  ),

                  ListTile(
                    title: const Text('Analytics'),
                    subtitle: const Text('View detailed analytics and reports'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).pushNamed('/admin/analytics');
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maintenance', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  PastEnquiryCleanupWidget(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Integration Status',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildStatusItem('SMTP Email', 'Active (Gmail)', Icons.email, Colors.green),
                  _buildStatusItem(
                    'Push Notifications',
                    'Active (FCM)',
                    Icons.notifications,
                    Colors.green,
                  ),
                  _buildStatusItem('Cloud Functions', 'Deployed', Icons.cloud, Colors.green),
                  _buildStatusItem('Firestore', 'Connected', Icons.storage, Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String title, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(status, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class AboutTab extends ConsumerWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About WeDecor Events', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.event, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'WeDecor Events Management System',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'A comprehensive enquiry and event management system built with Flutter, Firebase, and modern web technologies.',
                  ),
                  const SizedBox(height: 16),

                  _buildInfoRow('Version', '1.0.0'),
                  _buildInfoRow('Build', 'Release'),
                  _buildInfoRow('Region', 'asia-south1'),
                  _buildInfoRow('Platform', 'Web'),
                  _buildInfoRow('Framework', 'Flutter 3.x'),
                  _buildInfoRow('Backend', 'Firebase'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Features', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  _buildFeatureItem('Enquiry Management', 'Track and manage customer enquiries'),
                  _buildFeatureItem('User Management', 'Role-based access control'),
                  _buildFeatureItem('Analytics', 'Comprehensive reporting and insights'),
                  _buildFeatureItem('Notifications', 'Real-time push and email notifications'),
                  _buildFeatureItem('Settings', 'Customizable user and system preferences'),
                  _buildFeatureItem('Export', 'CSV export for data analysis'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Support', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  const Text(
                    'For technical support or feature requests, please contact your system administrator.',
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'All data is encrypted and securely stored',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
