import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'eventos_auth.dart';
import 'eventos_client.dart';
import 'eventos_config.dart';

final eventosAuthProvider = Provider<EventosAuth>((ref) {
  final auth = EventosAuth();
  ref.onDispose(() {
    // No long-lived subscriptions; secure storage writes are fine to leave.
  });
  return auth;
});

final eventosClientProvider = Provider<EventosClient>((ref) {
  return EventosClient(auth: ref.watch(eventosAuthProvider));
});

/// Snapshot for the admin status tile. Lazy — does not hit the network until
/// [EventosConnectionController.refresh] / testConnection is called.
class EventosConnectionSnapshot {
  const EventosConnectionSnapshot({
    required this.state,
    required this.environment,
    this.user,
    this.lastError,
  });

  final EventosConnectionState state;
  final String environment;
  final EventosUser? user;
  final String? lastError;

  factory EventosConnectionSnapshot.initial() => EventosConnectionSnapshot(
    state: EventosConfig.isEnabled
        ? EventosConnectionState.disconnected
        : EventosConnectionState.disabled,
    environment: EventosConfig.environmentLabel,
  );
}

class EventosConnectionController extends StateNotifier<EventosConnectionSnapshot> {
  EventosConnectionController(this._auth) : super(EventosConnectionSnapshot.initial());

  final EventosAuth _auth;

  Future<void> testConnection() async {
    if (!EventosConfig.isEnabled) {
      state = EventosConnectionSnapshot(
        state: EventosConnectionState.disabled,
        environment: EventosConfig.environmentLabel,
      );
      return;
    }
    final session = await _auth.testConnection();
    state = EventosConnectionSnapshot(
      state: _auth.state,
      environment: EventosConfig.environmentLabel,
      user: session?.user ?? _auth.user,
    );
  }

  void syncFromAuth() {
    state = EventosConnectionSnapshot(
      state: _auth.state,
      environment: EventosConfig.environmentLabel,
      user: _auth.user,
    );
  }
}

final eventosConnectionProvider =
    StateNotifierProvider<EventosConnectionController, EventosConnectionSnapshot>((ref) {
      return EventosConnectionController(ref.watch(eventosAuthProvider));
    });
