import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import 'fcm_service.dart';
import 'firestore_service.dart';

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
    await _firestoreService.updateUser(uid, {'name': name, 'phone': phone});
  }

  /// Update user role (admin only)
  Future<void> updateUserRole({required String uid, required UserRole role}) async {
    await _firestoreService.updateUser(uid, {'role': role.name});
  }
}

/// Provider for user sync service
final userFirestoreSyncServiceProvider = Provider<UserFirestoreSyncService>((ref) {
  return UserFirestoreSyncService(FirestoreService());
});

// NOTE: currentUserWithFirestoreProvider, currentUserRoleProvider, currentUserIsAdminProvider,
// and currentUserIsStaffProvider are now provided by lib/core/providers/role_provider.dart
// which uses efficient Firestore snapshots instead of polling.
// Import and use those providers instead of the ones that were here.
