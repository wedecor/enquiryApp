import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/services/fcm_service.dart';
import 'package:we_decor_enquiries/core/services/firebase_auth_service.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

/// Service for syncing user data between Firebase Auth and Firestore
class UserFirestoreSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;

  UserFirestoreSyncService(this._firestoreService);

  /// Sync current user data from Firestore
  Future<UserModel?> syncCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final userData = await _firestoreService.getUser(currentUser.uid);
      if (userData == null) return null;

      final userModel = UserModel(
        uid: currentUser.uid,
        name: userData['name'] as String? ?? '',
        email: userData['email'] as String? ?? currentUser.email ?? '',
        phone: userData['phone'] as String? ?? '',
        role: _parseUserRole(userData['role'] as String?),
      );

      // Update FCM topic subscriptions based on user role
      final fcmService = FCMService();
      await fcmService.subscribeToUserTopics(userModel);

      return userModel;
    } catch (e) {
      // If user doesn't exist in Firestore, create them with default role
      if (e.toString().contains('not found') || e.toString().contains('permission')) {
        return await _createDefaultUser(currentUser);
      }
      rethrow;
    }
  }

  /// Create a default user in Firestore when they don't exist
  Future<UserModel?> _createDefaultUser(User firebaseUser) async {
    try {
      await _firestoreService.createUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Unknown User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: 'staff', // Default role
      );

      return UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Unknown User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: UserRole.staff,
      );
    } catch (e) {
      // If creation fails, return a basic user model
      return UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Unknown User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: UserRole.staff,
      );
    }
  }

  /// Parse user role from string to enum
  UserRole _parseUserRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
      default:
        return UserRole.staff;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _firestoreService.updateUser(uid, {
      'name': name,
      'phone': phone,
    });
  }

  /// Update user role (admin only)
  Future<void> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    await _firestoreService.updateUser(uid, {
      'role': role.name,
    });
  }
}

/// Enhanced current user provider that syncs with Firestore
final currentUserWithFirestoreProvider = StreamProvider<UserModel?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final syncService = UserFirestoreSyncService(firestoreService);

  return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return await syncService.syncCurrentUser();
  });
});

/// Provider for user sync service
final userFirestoreSyncServiceProvider = Provider<UserFirestoreSyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserFirestoreSyncService(firestoreService);
});

/// Provider for current user's role
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final currentUser = ref.watch(currentUserWithFirestoreProvider);
  return currentUser.when(
    data: (user) => user?.role ?? UserRole.staff,
    loading: () => UserRole.staff,
    error: (error, stack) => UserRole.staff,
  );
});

/// Provider for checking if current user is admin
final currentUserIsAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.admin;
});

/// Provider for checking if current user is staff
final currentUserIsStaffProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.staff;
}); 