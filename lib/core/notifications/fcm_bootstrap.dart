import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_token_manager.dart';

/// Keeps FCM token in sync whenever auth state becomes non-null.
class FcmBootstrap extends StatefulWidget {
  final Widget child;
  const FcmBootstrap({super.key, required this.child});

  @override
  State<FcmBootstrap> createState() => _FcmBootstrapState();
}

class _FcmBootstrapState extends State<FcmBootstrap> {
  late final Stream<User?> _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseAuth.instance.authStateChanges();
    _sub.listen((u) {
      if (u != null) {
        FcmTokenManager.ensureFcmRegistered();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
