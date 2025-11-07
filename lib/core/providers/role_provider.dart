import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

/// Riverpod provider that streams the current user's role information.
///
/// This provider determines the user's role based on their authentication
/// state and user data. It provides a [Stream<UserRole>] that emits the
/// user's role whenever it changes.
///
/// Currently, this provider returns a default role of [UserRole.staff] for
/// all users. In a complete implementation, this would fetch the user's
/// actual role from Firestore based on their UID.
///
/// Returns a [StreamProvider<UserRole>] that emits:
/// - [UserRole.admin] for administrators
/// - [UserRole.staff] for staff members or unauthenticated users
///
/// Usage:
/// ```dart
/// final roleAsync = ref.watch(roleProvider);
/// roleAsync.when(
///   data: (role) {
///     if (role == UserRole.admin) {
///       // Show admin features
///     } else {
///       // Show staff features
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final roleProvider = StreamProvider<UserRole>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return currentUser.when(
    data: (user) {
      if (user == null) {
        return Stream.value(UserRole.staff);
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      return docRef.snapshots().map((snap) {
        final data = snap.data();
        final roleString = (data != null ? (data['role'] as String?) : null) ?? 'staff';
        return roleString == 'admin' ? UserRole.admin : UserRole.staff;
      });
    },
    loading: () => Stream.value(UserRole.staff),
    error: (error, stack) => Stream.value(UserRole.staff),
  );
});

/// Riverpod provider that checks if the current user has admin privileges.
///
/// This provider returns a boolean indicating whether the current user
/// has administrator role. It watches the [roleProvider] and returns
/// `true` if the user's role is [UserRole.admin], `false` otherwise.
///
/// Returns a [Provider<bool>] that provides:
/// - `true` if the user is an administrator
/// - `false` if the user is staff or unauthenticated
///
/// Usage:
/// ```dart
/// final isAdmin = ref.watch(isAdminProvider);
/// if (isAdmin) {
///   // Show admin-only UI elements
///   return AdminPanel();
/// } else {
///   // Show staff UI elements
///   return StaffPanel();
/// }
/// ```
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(roleProvider);
  return role.when(
    data: (userRole) => userRole == UserRole.admin,
    loading: () => false,
    error: (error, stack) => false,
  );
});

/// Riverpod provider that checks if the current user has staff privileges.
///
/// This provider returns a boolean indicating whether the current user
/// has staff role. It watches the [roleProvider] and returns `true`
/// if the user's role is [UserRole.staff], `false` otherwise.
///
/// Returns a [Provider<bool>] that provides:
/// - `true` if the user is staff
/// - `false` if the user is admin or unauthenticated
///
/// Usage:
/// ```dart
/// final isStaff = ref.watch(isStaffProvider);
/// if (isStaff) {
///   // Show staff-specific features
///   return StaffDashboard();
/// }
/// ```
final isStaffProvider = Provider<bool>((ref) {
  final role = ref.watch(roleProvider);
  return role.when(
    data: (userRole) => userRole == UserRole.staff,
    loading: () => false,
    error: (error, stack) => false,
  );
});

/// Alias for isAdminProvider to maintain compatibility with existing code.
///
/// This provider is equivalent to [isAdminProvider] and is used in
/// components that expect this specific name.
final currentUserIsAdminProvider = isAdminProvider;

/// Provider that provides the current user with Firestore data.
///
/// This provider combines authentication state with Firestore user data
/// to provide a complete user profile. It watches the authentication
/// state and fetches corresponding user data from Firestore.
///
/// Returns a [StreamProvider<UserModel?>] that provides:
/// - [UserModel] with complete user data if authenticated
/// - `null` if not authenticated
///
/// Usage:
/// ```dart
/// final userAsync = ref.watch(currentUserWithFirestoreProvider);
/// userAsync.when(
///   data: (user) {
///     if (user != null) {
///       return Text('Welcome, ${user.name}');
///     } else {
///       return Text('Please sign in');
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final currentUserWithFirestoreProvider = StreamProvider<UserModel?>((ref) {
  final authUserAsync = ref.watch(currentUserProvider);

  return authUserAsync.when(
    data: (authUser) {
      if (authUser == null) {
        return Stream.value(null);
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(authUser.uid);
      return docRef.snapshots().map((snap) {
        final data = snap.data();
        if (data == null) {
          return UserModel(
            uid: authUser.uid,
            name: authUser.displayName ?? 'User',
            email: authUser.email ?? '',
            phone: authUser.phoneNumber ?? '',
            role: UserRole.staff,
          );
        }

        final roleString = (data['role'] as String?) ?? 'staff';
        return UserModel(
          uid: authUser.uid,
          name: (data['name'] as String?) ?? (authUser.displayName ?? 'User'),
          email: (data['email'] as String?) ?? (authUser.email ?? ''),
          phone: (data['phone'] as String?) ?? (authUser.phoneNumber ?? ''),
          role: roleString == 'admin' ? UserRole.admin : UserRole.staff,
        );
      });
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});

/// Provider for Firestore service.
///
/// This provider provides access to the Firestore service for database
/// operations. It creates a singleton instance of the service that can
/// be used throughout the application.
///
/// Returns a [Provider<FirestoreService>] that provides the Firestore service.
///
/// Usage:
/// ```dart
/// final firestoreService = ref.read(firestoreServiceProvider);
/// final enquiries = await firestoreService.getEnquiries();
/// ```
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Riverpod provider that provides comprehensive user permissions.
///
/// This provider aggregates all user permissions into a single [UserPermissions]
/// object, making it easy to check multiple permissions at once. It combines
/// the user's role information to determine what actions they can perform
/// in the application.
///
/// Returns a [Provider<UserPermissions>] containing all permission flags
/// for the current user.
///
/// Usage:
/// ```dart
/// final permissions = ref.watch(userPermissionsProvider);
/// if (permissions.canCreateEnquiries) {
///   return FloatingActionButton(
///     onPressed: () => createEnquiry(),
///     child: Icon(Icons.add),
///   );
/// }
///
/// if (permissions.canViewAnalytics) {
///   return AnalyticsWidget();
/// }
/// ```
final userPermissionsProvider = Provider<UserPermissions>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  final isStaff = ref.watch(isStaffProvider);

  return UserPermissions(
    canViewEnquiries: isAdmin || isStaff,
    canCreateEnquiries: isAdmin || isStaff,
    canEditEnquiries: isAdmin,
    canDeleteEnquiries: isAdmin,
    canViewAnalytics: isAdmin,
    canManageUsers: isAdmin,
  );
});

/// Immutable class representing user permissions in the application.
///
/// This class encapsulates all the permissions a user has within the
/// system. It provides a clean way to check what actions a user can
/// perform without having to check multiple role-based conditions
/// throughout the codebase.
///
/// Permissions are determined based on the user's role:
/// - **Admin users** have all permissions enabled
/// - **Staff users** have limited permissions (view/create enquiries only)
/// - **Unauthenticated users** have no permissions
///
/// Example usage:
/// ```dart
/// final permissions = UserPermissions(
///   canViewEnquiries: true,
///   canCreateEnquiries: true,
///   canEditEnquiries: false,
///   canDeleteEnquiries: false,
///   canViewAnalytics: false,
///   canManageUsers: false,
/// );
///
/// if (permissions.canCreateEnquiries) {
///   // Show create enquiry button
/// }
///
/// if (permissions.canViewAnalytics) {
///   // Show analytics dashboard
/// }
/// ```
class UserPermissions {
  /// Creates a [UserPermissions] instance with the specified permission flags.
  ///
  /// All parameters are required and should be set based on the user's
  /// role and specific permissions granted to them.
  ///
  /// Parameters:
  /// - [canViewEnquiries]: Whether the user can view enquiry lists and details
  /// - [canCreateEnquiries]: Whether the user can create new enquiries
  /// - [canEditEnquiries]: Whether the user can modify existing enquiries
  /// - [canDeleteEnquiries]: Whether the user can delete enquiries
  /// - [canViewAnalytics]: Whether the user can access analytics and reports
  /// - [canManageUsers]: Whether the user can manage other users
  const UserPermissions({
    required this.canViewEnquiries,
    required this.canCreateEnquiries,
    required this.canEditEnquiries,
    required this.canDeleteEnquiries,
    required this.canViewAnalytics,
    required this.canManageUsers,
  });

  /// Whether the user can view enquiry lists and details.
  ///
  /// This permission allows users to:
  /// - View the main enquiry dashboard
  /// - See enquiry details and information
  /// - Access enquiry history and status
  ///
  /// Typically granted to both admin and staff users.
  final bool canViewEnquiries;

  /// Whether the user can create new enquiries.
  ///
  /// This permission allows users to:
  /// - Add new customer enquiries
  /// - Fill out enquiry forms
  /// - Submit enquiry data to the system
  ///
  /// Typically granted to both admin and staff users.
  final bool canCreateEnquiries;

  /// Whether the user can modify existing enquiries.
  ///
  /// This permission allows users to:
  /// - Update enquiry information
  /// - Change enquiry status
  /// - Modify customer details
  /// - Update assignment information
  ///
  /// Typically restricted to admin users only.
  final bool canEditEnquiries;

  /// Whether the user can delete enquiries.
  ///
  /// This permission allows users to:
  /// - Remove enquiries from the system
  /// - Permanently delete enquiry records
  /// - Clean up duplicate or invalid entries
  ///
  /// Typically restricted to admin users only.
  final bool canDeleteEnquiries;

  /// Whether the user can access analytics and reports.
  ///
  /// This permission allows users to:
  /// - View performance metrics
  /// - Access business intelligence dashboards
  /// - Generate reports and insights
  /// - Monitor system usage statistics
  ///
  /// Typically restricted to admin users only.
  final bool canViewAnalytics;

  /// Whether the user can manage other users.
  ///
  /// This permission allows users to:
  /// - Create new user accounts
  /// - Modify user roles and permissions
  /// - Deactivate user accounts
  /// - Manage user access levels
  ///
  /// Typically restricted to admin users only.
  final bool canManageUsers;
}
