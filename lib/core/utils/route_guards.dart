import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../providers/role_provider.dart';

/// Route guard utilities for protecting admin-only screens
class RouteGuards {
  /// Prevents access to admin-only screens for non-admin users
  ///
  /// This function checks if the current user has admin privileges.
  /// If not, it shows an access denied dialog and returns false.
  /// If the user is an admin, it returns true to allow access.
  ///
  /// Example usage:
  /// ```dart
  /// if (await RouteGuards.requireAdmin(context, ref)) {
  ///   // Navigate to admin screen
  ///   Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
  /// }
  /// ```
  static Future<bool> requireAdmin(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserWithFirestoreProvider);

    return currentUser.when(
      data: (user) {
        if (user?.role == UserRole.admin) {
          return true;
        } else {
          _showAccessDeniedDialog(context);
          return false;
        }
      },
      loading: () {
        _showLoadingDialog(context);
        return false;
      },
      error: (error, stack) {
        _showErrorDialog(context, error.toString());
        return false;
      },
    );
  }

  /// Prevents access to screens for unauthenticated users
  ///
  /// This function checks if the current user is authenticated.
  /// If not, it shows an authentication required dialog and returns false.
  /// If the user is authenticated, it returns true to allow access.
  ///
  /// Example usage:
  /// ```dart
  /// if (await RouteGuards.requireAuth(context, ref)) {
  ///   // Navigate to protected screen
  ///   Navigator.push(context, MaterialPageRoute(builder: (context) => ProtectedScreen()));
  /// }
  /// ```
  static Future<bool> requireAuth(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserWithFirestoreProvider);

    return currentUser.when(
      data: (user) {
        if (user != null) {
          return true;
        } else {
          _showAuthRequiredDialog(context);
          return false;
        }
      },
      loading: () {
        _showLoadingDialog(context);
        return false;
      },
      error: (error, stack) {
        _showErrorDialog(context, error.toString());
        return false;
      },
    );
  }

  /// Shows access denied dialog for non-admin users
  static void _showAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: const Text(
          'You do not have permission to access this feature. '
          'This feature is only available to administrators.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows authentication required dialog
  static void _showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login, color: Colors.orange),
            SizedBox(width: 8),
            Text('Authentication Required'),
          ],
        ),
        content: const Text(
          'You must be logged in to access this feature. '
          'Please sign in to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows loading dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }

  /// Shows error dialog
  static void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text('An error occurred: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Widget wrapper for admin-only screens
///
/// This widget automatically checks admin permissions and shows
/// an access denied screen if the user is not an admin.
///
/// Example usage:
/// ```dart
/// AdminOnlyScreen(
///   child: AdminManagementScreen(),
/// )
/// ```
class AdminOnlyScreen extends ConsumerWidget {
  final Widget child;

  const AdminOnlyScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);

    return currentUser.when(
      data: (user) {
        if (user?.role == UserRole.admin) {
          return child;
        } else {
          return _buildAccessDeniedScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You do not have permission to access this screen.\n'
              'This feature is only available to administrators.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
