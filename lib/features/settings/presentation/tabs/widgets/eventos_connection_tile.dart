import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/eventos/eventos_auth.dart';
import '../../../../../core/eventos/eventos_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/settings_tiles.dart';

/// Admin-only EventOS connection status (M5-01). Does not block the app.
class EventosConnectionTile extends ConsumerStatefulWidget {
  const EventosConnectionTile({super.key});

  @override
  ConsumerState<EventosConnectionTile> createState() => _EventosConnectionTileState();
}

class _EventosConnectionTileState extends ConsumerState<EventosConnectionTile> {
  bool _busy = false;

  Future<void> _test() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(eventosConnectionProvider.notifier).testConnection();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusLabel(EventosConnectionState state) {
    switch (state) {
      case EventosConnectionState.disabled:
        return 'Disabled (no EVENTOS_API_URL)';
      case EventosConnectionState.connected:
        return 'Connected';
      case EventosConnectionState.notLinked:
        return 'Not linked (ask an EventOS admin)';
      case EventosConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  Color _statusColor(EventosConnectionState state) {
    switch (state) {
      case EventosConnectionState.connected:
        return AppColorScheme.chartGreen;
      case EventosConnectionState.notLinked:
        return AppColorScheme.chartAmber;
      case EventosConnectionState.disabled:
        return AppColorScheme.brandSlate;
      case EventosConnectionState.disconnected:
        return AppColorScheme.chartRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(eventosConnectionProvider);
    final userLine = snap.user == null
        ? null
        : '${snap.user!.name.isEmpty ? snap.user!.id : snap.user!.name} · ${snap.user!.role}';
    final subtitle = [
      'Environment: ${snap.environment}',
      _statusLabel(snap.state),
      if (userLine != null) userLine,
    ].join('\n');

    return SettingsTile(
      icon: Icons.hub_outlined,
      iconColor: _statusColor(snap.state),
      title: 'EventOS connection',
      subtitle: subtitle,
      subtitleMaxLines: 4,
      trailing: TextButton(
        onPressed: _busy ? null : _test,
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Test connection'),
      ),
    );
  }
}
