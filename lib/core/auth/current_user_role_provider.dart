import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';

/// Auth state (FirebaseAuth user)
final firebaseAuthUserProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});

/// Firestore user doc stream for the signed-in user
final currentUserDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final authAsync = ref.watch(firebaseAuthUserProvider);
  return authAsync.when(
    data: (auth) {
      if (auth == null) return const Stream.empty();
      final doc = FirebaseFirestore.instance.collection('users').doc(auth.uid);
      return doc.snapshots();
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

/// Current user role: "admin" | "staff" | null (unknown/not found)
/// Returns null if user is deactivated (AC-User-2)
final currentUserRoleProvider = Provider<String?>((ref) {
  final docAsync = ref.watch(currentUserDocProvider);
  return docAsync.when(
    data: (snap) {
      if (snap == null || !snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      
      // Check if user is active (AC-User-2)
      final isActive = data['active'] as bool? ?? true;
      if (!isActive) {
        return null; // Deactivated users have no role
      }
      
      final role = data['role'];
      if (role is String && (role == 'admin' || role == 'staff')) return role;
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Current user uid (or null)
final currentUserUidProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(firebaseAuthUserProvider);
  return authAsync.when(data: (user) => user?.uid, loading: () => null, error: (_, __) => null);
});

/// Convenience: is admin?
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserRoleProvider) == 'admin';
});

/// Current user document data
final currentUserDataProvider = Provider<Map<String, dynamic>?>((ref) {
  final docAsync = ref.watch(currentUserDocProvider);
  return docAsync.when(
    data: (snap) {
      if (snap == null || !snap.exists) return null;
      return snap.data();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Current user as AsyncValue<UserModel?> for compatibility
final currentUserAsyncProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(firebaseAuthUserProvider);
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      return doc.snapshots().map((snap) {
        if (!snap.exists) return null;
        final data = snap.data();
        if (data == null) return null;

        // Convert to UserModel
        return UserModel(
          uid: snap.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          role: data['role'] == 'admin' ? UserRole.admin : UserRole.staff,
          active: data['active'] as bool? ?? true,
        );
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Current user name
final currentUserNameProvider = Provider<String?>((ref) {
  final data = ref.watch(currentUserDataProvider);
  return data?['name'] as String?;
});

/// Current user email
final currentUserEmailProvider = Provider<String?>((ref) {
  final data = ref.watch(currentUserDataProvider);
  return data?['email'] as String?;
});

/// Current user active status
final currentUserActiveProvider = Provider<bool>((ref) {
  final data = ref.watch(currentUserDataProvider);
  return data?['active'] as bool? ?? true;
});

/// Provider that automatically logs out deactivated users (AC-User-2)
final userDeactivationGuardProvider = Provider<void>((ref) {
  final auth = ref.watch(firebaseAuthUserProvider);
  final isActive = ref.watch(currentUserActiveProvider);
  
  auth.whenData((user) {
    if (user != null && !isActive) {
      // User is signed in but deactivated - log them out
      fb.FirebaseAuth.instance.signOut();
    }
  });
});
