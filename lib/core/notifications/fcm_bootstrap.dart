import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_state.dart';
import '../services/firestore_service.dart';
import '../services/session_service.dart';
import 'fcm_token_manager.dart';

/// Keeps FCM token in sync whenever auth state becomes non-null.
class FcmBootstrap extends ConsumerStatefulWidget {
  const FcmBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FcmBootstrap> createState() => _FcmBootstrapState();
}

class _FcmBootstrapState extends ConsumerState<FcmBootstrap> {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // ensureFcmRegistered never throws; listeners are wired before the token.
        unawaited(FcmTokenManager.ensureFcmRegistered(ref.read(firestoreServiceProvider)));
      } else {
        unawaited(FcmTokenManager.dispose());
      }
    });
    // Deactivation deletes this device's token server-side while the user stays signed
    // in; when the account is reactivated the session turns authenticated again and the
    // token must be saved anew.
    ref.listenManual<AsyncValue<SessionState>>(sessionStateProvider, (previous, next) {
      final state = next.valueOrNull;
      if (state is SessionDisabled) {
        unawaited(FcmTokenManager.dispose());
      } else if (state is SessionAuthenticated) {
        unawaited(FcmTokenManager.ensureFcmRegistered(ref.read(firestoreServiceProvider)));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(FcmTokenManager.cancelListeners());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
