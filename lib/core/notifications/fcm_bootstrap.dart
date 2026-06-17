import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
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
        FcmTokenManager.ensureFcmRegistered(ref.read(firestoreServiceProvider));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(FcmTokenManager.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
