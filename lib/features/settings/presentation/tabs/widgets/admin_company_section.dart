import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/safe_log.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../domain/app_config.dart';
import '../../../providers/settings_providers.dart';
import '../../../../../ui/components/glass_state_message.dart';
import '../../widgets/settings_layout.dart';

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
  final _googleReviewLinkController = TextEditingController();
  final _instagramHandleController = TextEditingController();
  final _websiteUrlController = TextEditingController();

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
      loading: () => const GlassLoadingState(),
      error: (error, stack) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Company settings unavailable',
        message: 'Error loading company config: $error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

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

  String? _validateOptionalUrl(String? value) {
    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme) {
        return 'Please enter a valid URL';
      }
    }
    return null;
  }

  Widget _buildCompanyForm(BuildContext context, AppGeneralConfig config) {
    const gap = SizedBox(height: AppTokens.space4);
    return SettingsEditableBody(
      hasChanges: _hasChanges,
      isSaving: _isSaving,
      onSave: () => _saveChanges(config),
      onDiscard: () => _discardChanges(config),
      child: Form(
        key: _formKey,
        onChanged: () {
          setState(() {
            _hasChanges = _hasFormChanges(config);
          });
        },
        child: SettingsScrollBody(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.space1, AppTokens.space5, 0, 0),
              child: SplitHeading(
                light: 'Company &',
                bold: 'App Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SettingsGroup(
              eyebrow: 'Brand',
              title: 'Identity',
              separated: false,
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                gap,
                TextFormField(
                  controller: _logoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Logo URL (optional)',
                    hintText: 'https://example.com/logo.png',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  validator: _validateOptionalUrl,
                ),
              ],
            ),
            SettingsGroup(
              eyebrow: 'Billing',
              title: 'Finance & Locale',
              separated: false,
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Code',
                    hintText: 'INR, USD, EUR, etc.',
                    prefixIcon: Icon(Icons.currency_exchange_rounded),
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
                gap,
                DropdownButtonFormField<String>(
                  key: ValueKey('timezone-${_timezoneController.text}'),
                  initialValue: _timezoneController.text.isNotEmpty
                      ? _timezoneController.text
                      : 'Asia/Kolkata',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Default Timezone',
                    prefixIcon: Icon(Icons.schedule_rounded),
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
                gap,
                TextFormField(
                  controller: _vatPercentController,
                  decoration: const InputDecoration(
                    labelText: 'VAT/Tax Percentage',
                    suffixText: '%',
                    prefixIcon: Icon(Icons.percent_rounded),
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
              ],
            ),
            SettingsGroup(
              eyebrow: 'Reviews',
              title: 'Review & Social Links',
              separated: false,
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                TextFormField(
                  controller: _googleReviewLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Google Review Link',
                    hintText: 'https://share.google/...',
                    helperText: 'Used in review request messages',
                    prefixIcon: Icon(Icons.star_outline_rounded),
                  ),
                  validator: _validateOptionalUrl,
                ),
                gap,
                TextFormField(
                  controller: _instagramHandleController,
                  decoration: const InputDecoration(
                    labelText: 'Instagram Handle',
                    hintText: '@wedecorbangalore',
                    helperText: 'Used in review request messages',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                gap,
                TextFormField(
                  controller: _websiteUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Website URL',
                    hintText: 'https://www.wedecorevents.com/',
                    helperText: 'Used in review request messages',
                    prefixIcon: Icon(Icons.language_rounded),
                  ),
                  validator: _validateOptionalUrl,
                ),
              ],
            ),
          ],
        ),
      ),
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
        backgroundColor: isError ? AppColorScheme.snackError : AppColorScheme.snackSuccess,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}
