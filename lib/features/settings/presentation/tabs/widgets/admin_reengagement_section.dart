import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/safe_log.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/components/glass_state_message.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../reengagement/data/reengagement_repository.dart';
import '../../../../reengagement/domain/occasion_kind.dart';
import '../../../../reengagement/domain/reengagement_config.dart';
import '../../../../reengagement/domain/reengagement_templates.dart';
import '../../../../reengagement/presentation/reengagement_providers.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

/// Settings → Admin → Re-engagement: yearly reminders on/off, lead time and the
/// WhatsApp templates per occasion kind (`app_config/reengagement`).
class ReengagementConfigTab extends ConsumerStatefulWidget {
  const ReengagementConfigTab({super.key});

  @override
  ConsumerState<ReengagementConfigTab> createState() => _ReengagementConfigTabState();
}

class _ReengagementConfigTabState extends ConsumerState<ReengagementConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _leadDaysController = TextEditingController();
  final Map<OccasionKind, TextEditingController> _templateControllers = {
    for (final kind in OccasionKind.values) kind: TextEditingController(),
  };

  ReengagementConfig? _original;
  bool _enabled = true;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _leadDaysController.dispose();
    for (final c in _templateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(reengagementConfigProvider);
    return configAsync.when(
      data: (config) {
        if (_original == null) {
          _original = config;
          _initialize(config);
        }
        return _buildForm(context);
      },
      loading: () => const GlassLoadingState(),
      error: (error, _) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Re-engagement settings unavailable',
        message: '$error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _initialize(ReengagementConfig config) {
    _enabled = config.enabled;
    _leadDaysController.text = '${config.leadDays}';
    for (final kind in OccasionKind.values) {
      _templateControllers[kind]!.text = config.templateFor(kind);
    }
  }

  /// The config the form currently describes; templates equal to the default are
  /// not stored, so later default improvements reach them.
  ReengagementConfig _fromForm() {
    final templates = <OccasionKind, String>{};
    for (final kind in OccasionKind.values) {
      final text = _templateControllers[kind]!.text.trim();
      if (text.isNotEmpty && text != ReengagementTemplates.defaults[kind]) {
        templates[kind] = text;
      }
    }
    return ReengagementConfig(
      enabled: _enabled,
      leadDays: int.tryParse(_leadDaysController.text.trim()) ?? ReengagementConfig.defaultLeadDays,
      templates: templates,
    );
  }

  bool _differs(ReengagementConfig a, ReengagementConfig b) {
    if (a.enabled != b.enabled || a.leadDays != b.leadDays) return true;
    for (final kind in OccasionKind.values) {
      if (a.templateFor(kind) != b.templateFor(kind)) return true;
    }
    return false;
  }

  void _recompute() {
    final original = _original;
    if (original == null) return;
    setState(() => _hasChanges = _differs(_fromForm(), original));
  }

  Widget _buildForm(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SettingsEditableBody(
      hasChanges: _hasChanges,
      isSaving: _isSaving,
      onSave: _save,
      onDiscard: _discard,
      child: Form(
        key: _formKey,
        onChanged: _recompute,
        child: SettingsScrollBody(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.space1, AppTokens.space5, 0, 0),
              child: SplitHeading(
                light: 'Same time',
                bold: 'Next Year',
                style: t.headlineMedium,
              ),
            ),
            SettingsGroup(
              eyebrow: 'Yearly reminders',
              title: 'Schedule',
              subtitle:
                  'Every completed event comes back as a reminder before its anniversary, '
                  'for the person who handled it (or admins).',
              children: [
                SettingsSwitchTile(
                  title: 'Send yearly reminders',
                  subtitle: 'Checked every morning at 9:00',
                  icon: Icons.event_repeat_outlined,
                  value: _enabled,
                  onChanged: (v) {
                    _enabled = v;
                    _recompute();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: TextFormField(
                    controller: _leadDaysController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Remind this many days before',
                      suffixText: 'days',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    validator: (value) {
                      final days = int.tryParse(value?.trim() ?? '');
                      if (days == null ||
                          days < ReengagementConfig.minLeadDays ||
                          days > ReengagementConfig.maxLeadDays) {
                        return 'Between ${ReengagementConfig.minLeadDays} and '
                            '${ReengagementConfig.maxLeadDays} days';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SettingsGroup(
              eyebrow: 'WhatsApp',
              title: 'Message templates',
              subtitle:
                  'Placeholders: ${ReengagementTemplates.placeholders.join(' ')}. '
                  '{person} may be empty — "{person}\'s birthday" then reads "A birthday".',
              separated: false,
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                for (final kind in OccasionKind.values) ...[
                  _TemplateField(
                    kind: kind,
                    controller: _templateControllers[kind]!,
                    onReset: () {
                      _templateControllers[kind]!.text = ReengagementTemplates.defaults[kind] ?? '';
                      _recompute();
                    },
                  ),
                  if (kind != OccasionKind.values.last) const SizedBox(height: AppTokens.space4),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    final config = _fromForm();
    try {
      await ref.read(reengagementRepositoryProvider).saveConfig(config);
      if (!mounted) return;
      setState(() {
        _original = config;
        _hasChanges = false;
        _isSaving = false;
      });
      _snack('Re-engagement settings saved');
    } catch (e) {
      safeLog('reengagement_config_save_error', {'error': e.toString()});
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Failed to save re-engagement settings', isError: true);
    }
  }

  void _discard() {
    final original = _original;
    if (original == null) return;
    _initialize(original);
    setState(() => _hasChanges = false);
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColorScheme.snackError : AppColorScheme.snackSuccess,
      ),
    );
  }
}

class _TemplateField extends StatelessWidget {
  const _TemplateField({required this.kind, required this.controller, required this.onReset});

  final OccasionKind kind;
  final TextEditingController controller;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      maxLength: 600,
      decoration: InputDecoration(
        labelText: kind.label,
        alignLabelWithHint: true,
        suffixIcon: IconButton(
          tooltip: 'Reset to default',
          icon: const Icon(Icons.restart_alt_rounded),
          onPressed: onReset,
        ),
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Enter a message (or reset to default)' : null,
    );
  }
}
