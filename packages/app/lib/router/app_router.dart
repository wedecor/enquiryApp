import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/approval_gate_screen.dart';
import '../features/auth/ui/awaiting_approval_screen.dart';
import '../features/admin/users_screen.dart';
import '../features/enquiries/enquiries_list_screen.dart';
import '../features/enquiries/enquiry_detail_screen.dart';
import '../features/enquiries/enquiry_form_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context) {
    return const EnquiriesListScreen();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/gate'),
      GoRoute(path: '/gate', builder: (_, __) => const ApprovalGateScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen(isSignup: false)),
      GoRoute(path: '/signup', builder: (_, __) => const LoginScreen(isSignup: true)),
      GoRoute(path: '/awaiting', builder: (_, __) => const AwaitingApprovalScreen()),
      GoRoute(path: '/home', builder: (_, __) => const AppShell()),
      GoRoute(path: '/admin/users', builder: (_, __) => const UsersScreen()),
      GoRoute(path: '/enquiries', builder: (_, __) => const EnquiriesListScreen()),
      GoRoute(path: '/enquiries/new', builder: (_, __) => const EnquiryFormScreen()),
      GoRoute(path: '/enquiries/:id', builder: (_, state) => EnquiryDetailScreen(id: state.pathParameters['id']!)),
    ],
  );
});
