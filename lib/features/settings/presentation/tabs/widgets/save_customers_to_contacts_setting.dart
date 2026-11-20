import 'package:flutter/material.dart';

import '../../../../../core/contacts/whatsapp_contacts.dart';
import '../../../../../core/theme/tokens.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

/// Device-local switch: allow saving customers as contacts for one-tap cards.
class SaveCustomersToContactsSetting extends StatefulWidget {
  const SaveCustomersToContactsSetting({super.key});

  @override
  State<SaveCustomersToContactsSetting> createState() => _SaveCustomersToContactsSettingState();
}

class _SaveCustomersToContactsSettingState extends State<SaveCustomersToContactsSetting> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await WhatsAppContacts.isFeatureEnabled();
    if (!mounted) return;
    setState(() => _enabled = on);
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _enabled = value;
    });
    await WhatsAppContacts.setFeatureEnabled(value);
    if (value && mounted) {
      // Re-prompt if needed so staff can grant permission without waiting for a send.
      await WhatsAppContacts.ensurePermission(context);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final value = _enabled;
    if (value == null) {
      return const SizedBox.shrink();
    }

    return SettingsGroup(
      eyebrow: 'WhatsApp',
      title: 'Customer contacts',
      subtitle: 'On this phone only — not synced to Google',
      separated: false,
      padding: const EdgeInsets.all(AppTokens.space4),
      children: [
        SettingsSwitchTile(
          title: 'Save customers to contacts',
          subtitle:
              'Lets We Decor send the card straight to their WhatsApp chat. '
              'Turn off to skip saving numbers.',
          icon: Icons.contact_page_outlined,
          value: value,
          onChanged: _busy ? null : _onChanged,
        ),
      ],
    );
  }
}
