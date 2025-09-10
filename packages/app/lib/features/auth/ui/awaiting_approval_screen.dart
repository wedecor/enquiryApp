import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../logic/auth_providers.dart';

class AwaitingApprovalScreen extends ConsumerWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userDoc = ref.watch(userDocProvider).value?.data();
    
    print('⏳ AwaitingApprovalScreen: user = ${user?.uid}');
    print('⏳ AwaitingApprovalScreen: userDoc = $userDoc');
    
            // If user is not authenticated, redirect to login
            if (user == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/login');
              });
              return const Scaffold(body: SizedBox());
            }
    
    // If user document is loaded, check approval status
    if (userDoc != null) {
      final role = (userDoc['role'] ?? 'pending') as String;
      final approved = (userDoc['isApproved'] ?? false) as bool;
      final active = (userDoc['isActive'] ?? false) as bool;
      
      print('⏳ AwaitingApprovalScreen: role=$role, approved=$approved, active=$active');
      
              // If user is approved and active, redirect to home
              if (approved && active && role != 'pending') {
                print('⏳ AwaitingApprovalScreen: User is approved, redirecting to home');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/home');
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Awaiting Approval',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is pending admin approval',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

