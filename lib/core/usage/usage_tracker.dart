import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_state.dart';
import '../logging/logger.dart';
import '../services/session_service.dart';

/// Seconds / opens waiting to be written for one IST day flush.
@immutable
class UsageDelta {
  const UsageDelta({required this.activeSeconds, required this.opens});

  final int activeSeconds;
  final int opens;

  bool get isEmpty => activeSeconds <= 0 && opens <= 0;
}

/// Sink for fire-and-forget usage flushes. Wired to Firestore in Task 3.
abstract class UsageFlushSink {
  Future<void> flush({
    required String uid,
    required int activeSeconds,
    required int opens,
  });
}

/// Optional sink — null until [usageFlushSinkProvider] is wired to a repository.
final usageFlushSinkProvider = Provider<UsageFlushSink?>((ref) => null);

/// Pure, clock-injected usage engine (no Flutter / Firebase).
///
/// Time counts only while [foreground] and the user interacted within
/// [idleTimeout]. Opens: cold start, and resume after [backgroundOpenAfter]
/// in the background. Flushes every [flushEvery] while active, and on pause /
/// sign-out; each flush is capped at [maxFlushSeconds].
class UsageTrackerEngine {
  UsageTrackerEngine({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const Duration idleTimeout = Duration(minutes: 5);
  static const Duration flushEvery = Duration(minutes: 5);
  static const Duration backgroundOpenAfter = Duration(minutes: 30);
  static const int maxFlushSeconds = 330;

  final DateTime Function() _clock;

  bool _signedIn = false;
  bool _foreground = false;
  DateTime? _lastInteractionAt;
  DateTime? _segmentStartedAt;
  DateTime? _backgroundedAt;
  DateTime? _lastPeriodicFlushAt;

  int _pendingSeconds = 0;
  int _pendingOpens = 0;

  bool get isSignedIn => _signedIn;
  bool get isForeground => _foreground;
  int get pendingSeconds => _pendingSeconds;
  int get pendingOpens => _pendingOpens;

  /// Begin a signed-in session (cold start → one open).
  UsageDelta? signIn() {
    final now = _clock();
    _accrue(now);
    _signedIn = true;
    _foreground = true;
    _backgroundedAt = null;
    _pendingOpens += 1;
    _lastPeriodicFlushAt = now;
    // Cold start itself is not an interaction; wait for a pointer (or explicit mark).
    _lastInteractionAt = null;
    _segmentStartedAt = null;
    return _takeFlush();
  }

  /// End tracking; always returns any leftover delta (may be empty → null).
  UsageDelta? signOut() {
    final now = _clock();
    _accrue(now);
    _signedIn = false;
    _foreground = false;
    _backgroundedAt = null;
    _lastInteractionAt = null;
    _segmentStartedAt = null;
    return _takeFlush();
  }

  UsageDelta? onResumed() {
    if (!_signedIn) return null;
    final now = _clock();
    final bg = _backgroundedAt;
    _backgroundedAt = null;
    _foreground = true;
    if (bg != null && now.difference(bg) >= backgroundOpenAfter) {
      _pendingOpens += 1;
    }
    _lastPeriodicFlushAt ??= now;
    _syncSegment(now);
    return null;
  }

  /// Pause / hide / detach: accrue, then flush.
  UsageDelta? onPaused() {
    if (!_signedIn) return null;
    final now = _clock();
    _accrue(now);
    _foreground = false;
    _backgroundedAt = now;
    _segmentStartedAt = null;
    return _takeFlush();
  }

  void onInteraction() {
    if (!_signedIn || !_foreground) return;
    final now = _clock();
    _accrue(now);
    _lastInteractionAt = now;
    _syncSegment(now);
  }

  /// Periodic tick while the host timer runs. Flushes when [flushEvery] elapsed
  /// while active (seconds and/or opens pending).
  UsageDelta? onTick() {
    if (!_signedIn) return null;
    final now = _clock();
    _accrue(now);
    _syncSegment(now);
    final last = _lastPeriodicFlushAt;
    if (last != null &&
        now.difference(last) >= flushEvery &&
        (_pendingSeconds > 0 || _pendingOpens > 0)) {
      return _takeFlush();
    }
    return null;
  }

  void _syncSegment(DateTime now) {
    if (_isCounting(now)) {
      _segmentStartedAt ??= now;
    } else {
      _segmentStartedAt = null;
    }
  }

  bool _isCounting(DateTime now) {
    if (!_signedIn || !_foreground) return false;
    final last = _lastInteractionAt;
    if (last == null) return false;
    return now.difference(last) < idleTimeout;
  }

  /// Accrue seconds from [_segmentStartedAt] up to the earlier of [now] and
  /// idle deadline (last interaction + 5 min).
  void _accrue(DateTime now) {
    final start = _segmentStartedAt;
    if (start == null) return;
    final last = _lastInteractionAt;
    final end = last == null ? now : _min(now, last.add(idleTimeout));
    if (!end.isAfter(start)) {
      _segmentStartedAt = _isCounting(now) ? now : null;
      return;
    }
    _pendingSeconds += end.difference(start).inSeconds;
    _segmentStartedAt = _isCounting(now) ? end : null;
  }

  /// Caps seconds at [maxFlushSeconds] (excess dropped). Never returns an empty delta.
  UsageDelta? _takeFlush() {
    if (_pendingSeconds <= 0 && _pendingOpens <= 0) return null;

    var seconds = _pendingSeconds;
    if (seconds > maxFlushSeconds) {
      seconds = maxFlushSeconds; // drop excess
    }
    if (seconds < 0) seconds = 0;
    final opens = _pendingOpens;
    _pendingSeconds = 0;
    _pendingOpens = 0;
    _lastPeriodicFlushAt = _clock();

    // Never flush zero: need at least one open or one counted second.
    if (seconds <= 0 && opens <= 0) return null;
    return UsageDelta(activeSeconds: seconds, opens: opens);
  }

  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

/// Root host: lifecycle + pointer interaction → [UsageTrackerEngine] → sink.
///
/// Does not rebuild [child]. Started for [SessionAuthenticated], stopped on
/// sign-out / disabled.
class UsageTrackerHost extends ConsumerStatefulWidget {
  const UsageTrackerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UsageTrackerHost> createState() => _UsageTrackerHostState();
}

class _UsageTrackerHostState extends ConsumerState<UsageTrackerHost> with WidgetsBindingObserver {
  final UsageTrackerEngine _engine = UsageTrackerEngine();
  Timer? _tick;
  String? _uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<AsyncValue<SessionState>>(sessionStateProvider, (previous, next) {
      final state = next.valueOrNull;
      if (state is SessionAuthenticated) {
        _start(state.user.uid);
      } else {
        _stop();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _stop();
    super.dispose();
  }

  void _start(String uid) {
    if (_uid == uid && _engine.isSignedIn) return;
    _stop();
    _uid = uid;
    _emit(_engine.signIn());
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      _emit(_engine.onTick());
    });
  }

  void _stop() {
    _tick?.cancel();
    _tick = null;
    final delta = _engine.isSignedIn ? _engine.signOut() : null;
    final uid = _uid;
    _uid = null;
    if (uid != null) _emit(delta, uidOverride: uid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _emit(_engine.onResumed());
      case AppLifecycleState.inactive:
        // Ignore brief inactive (e.g. notification shade); pause handles real background.
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _emit(_engine.onPaused());
    }
  }

  void _onPointerDown(PointerDownEvent _) {
    _engine.onInteraction();
  }

  void _emit(UsageDelta? delta, {String? uidOverride}) {
    if (delta == null || delta.isEmpty) return;
    // Spec: never flush zero — opens-only is allowed (activeSeconds may be 0).
    if (delta.activeSeconds <= 0 && delta.opens <= 0) return;
    final uid = uidOverride ?? _uid;
    if (uid == null || uid.isEmpty) return;
    final sink = ref.read(usageFlushSinkProvider);
    if (sink == null) return;
    final seconds = math.min(delta.activeSeconds, UsageTrackerEngine.maxFlushSeconds);
    unawaited(() async {
      try {
        await sink.flush(uid: uid, activeSeconds: seconds, opens: delta.opens);
      } catch (e) {
        Log.w('Usage flush failed', data: {'error': e.toString()});
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: widget.child,
    );
  }
}
