import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/auth_providers.dart';

/// Gate that reads the user doc and routes:
/// - pending / !approved / !active -> /awaiting
/// - else -> /home
class ApprovalGateScreen extends ConsumerWidget {
  const ApprovalGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userDoc = ref.watch(userDocProvider).value?.data();
    
    print('🚪 ApprovalGateScreen: user = ${user?.uid}');
    print('🚪 ApprovalGateScreen: userDoc = $userDoc');
    
            if (user == null) {
              print('🚪 ApprovalGateScreen: No user, redirecting to login');
              // not signed in -> login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/login');
              });
              return const Scaffold(body: SizedBox());
            }

    if (userDoc == null) {
      print('🚪 ApprovalGateScreen: User exists but no userDoc, showing loading');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = (userDoc['role'] ?? 'pending') as String;
    final approved = (userDoc['isApproved'] ?? false) as bool;
    final active = (userDoc['isActive'] ?? false) as bool;

    print('🚪 ApprovalGateScreen: role=$role, approved=$approved, active=$active');

    // subscribe topics (best-effort)
    ref.read(authRepoProvider).subscribeTopics(uid: user.uid, role: role);

    final shouldAwait = role == 'pending' || !approved || !active;
    print('🚪 ApprovalGateScreen: shouldAwait=$shouldAwait, redirecting to ${shouldAwait ? '/awaiting' : '/home'}');
    
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              print('🚪 ApprovalGateScreen: Executing navigation to ${shouldAwait ? '/awaiting' : '/home'}');
              context.go(shouldAwait ? '/awaiting' : '/home');
            });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
