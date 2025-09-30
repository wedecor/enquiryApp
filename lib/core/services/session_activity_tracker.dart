import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_service.dart';

/// Service to track user activity and update session timeout
class SessionActivityTracker extends WidgetsBindingObserver {
  final SessionService _sessionService;

  SessionActivityTracker(this._sessionService);

  /// Initialize activity tracking
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Dispose activity tracking
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Update activity when app becomes active
    if (state == AppLifecycleState.resumed) {
      _sessionService.updateActivity();
    }
  }

  /// Track user interaction (call this on user actions)
  void trackUserInteraction() {
    _sessionService.updateActivity();
  }
}

/// Riverpod provider for session activity tracker
final sessionActivityTrackerProvider = Provider<SessionActivityTracker>((ref) {
  final sessionService = ref.read(sessionServiceProvider);
  return SessionActivityTracker(sessionService);
});

/// Mixin for widgets to easily track user activity
mixin SessionActivityMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  SessionActivityTracker? _activityTracker;

  @override
  void initState() {
    super.initState();
    _activityTracker = ref.read(sessionActivityTrackerProvider);
    _activityTracker?.initialize();
  }

  @override
  void dispose() {
    _activityTracker?.dispose();
    super.dispose();
  }

  /// Track user interaction
  void trackActivity() {
    _activityTracker?.trackUserInteraction();
  }
}
