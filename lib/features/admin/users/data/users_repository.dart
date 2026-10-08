import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/logging/logger.dart';
import '../domain/user_model.dart';

class UsersRepository {
  UsersRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const String _collection = 'users';

  /// Live stream of every user document, sorted by email.
  ///
  /// The team is small, so the whole collection is streamed and all filtering
  /// (search, role, active) happens on the client. Sorting is also done on the
  /// client so documents without an `email` field are not dropped and no
  /// composite index is needed. Legacy documents that only carry `active` are
  /// handled by [UserModel.fromFirestore] (`isActive ?? active`).
  Stream<List<UserModel>> watchUsers() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          final users = <UserModel>[];

          for (final doc in snapshot.docs) {
            try {
              users.add(UserModel.fromFirestore(doc));
            } catch (e, st) {
              Log.e(
                'UsersRepository: error parsing user document',
                error: e,
                stackTrace: st,
                data: {'docId': doc.id},
              );
              // Skip invalid documents instead of crashing
            }
          }

          users.sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
          return users;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Log.e('UsersRepository: users stream error', error: error, stackTrace: stackTrace);
          // Forward the error so the UI shows the error state instead of
          // spinning forever.
          Error.throwWithStackTrace(error, stackTrace);
        });
  }

  /// Updates a user through the `adminUpdateUser` callable (asia-south1).
  ///
  /// [changes] may contain only `name`, `phone`, `role` and `isActive`. The
  /// function validates the caller (active admin), blocks self role/status
  /// changes and removing the last active admin, syncs Firebase Auth and FCM
  /// tokens on deactivation, and writes the audit trail. Throws
  /// [FirebaseFunctionsException] on failure.
  Future<void> adminUpdateUser(String uid, Map<String, dynamic> changes) async {
    final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
    final callable = functions.httpsCallable('adminUpdateUser');
    await callable.call<dynamic>(<String, dynamic>{...changes, 'uid': uid});
  }

  /// Activates or deactivates a user via [adminUpdateUser].
  Future<void> toggleActive(String uid, bool active) {
    return adminUpdateUser(uid, {'isActive': active});
  }

  /// Get user by UID
  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Check if email exists (for validation)
  Future<bool> emailExists(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }
}
