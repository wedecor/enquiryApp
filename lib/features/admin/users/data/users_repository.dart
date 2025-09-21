import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  /// Stream of users with filtering, search, and pagination
  Stream<List<UserModel>> watchUsers({
    String? search,
    String? role,
    bool? active,
    int limit = 20,
    String? startAfterEmail,
  }) {
    Query query = _firestore.collection(_collection);

    // Apply role filter
    if (role != null && role.isNotEmpty && role != 'All') {
      query = query.where('role', isEqualTo: role);
    }

    // Apply active filter
    if (active != null) {
      query = query.where('active', isEqualTo: active);
    }

    // Order by email for stable pagination
    query = query.orderBy('email');

    // Apply pagination
    if (startAfterEmail != null) {
      query = query.startAfter([startAfterEmail]);
    }

    // Apply limit
    query = query.limit(limit);

    return query
        .snapshots()
        .map((snapshot) {
          List<UserModel> users = [];

          // Process each document with error handling
          for (final doc in snapshot.docs) {
            try {
              final user = UserModel.fromFirestore(doc);
              users.add(user);
            } catch (e) {
              print('Error parsing user document ${doc.id}: $e');
              // Skip invalid documents instead of crashing
              continue;
            }
          }

          // Apply search filter on client side (for name and email)
          if (search != null && search.isNotEmpty) {
            final searchLower = search.toLowerCase();
            users = users.where((user) {
              return user.name.toLowerCase().contains(searchLower) ||
                  user.email.toLowerCase().contains(searchLower);
            }).toList();
          }

          return users;
        })
        .handleError((error) {
          print('Error in users stream: $error');
          return <UserModel>[]; // Return empty list on stream error
        });
  }

  /// Create a new user document
  Future<void> createUserDoc(UserModel input) async {
    final userData = input.toFirestore();

    // Set timestamps
    userData['createdAt'] = FieldValue.serverTimestamp();
    userData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(_collection).doc(input.uid).set(userData);
  }

  /// Update user document with patch
  Future<void> updateUserDoc(String uid, Map<String, dynamic> patch) async {
    patch['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(_collection).doc(uid).update(patch);
  }

  /// Toggle user active status
  Future<void> toggleActive(String uid, bool active) async {
    await updateUserDoc(uid, {'active': active});
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

  /// Get total count of users (for pagination info)
  Future<int> getTotalUsersCount({String? role, bool? active}) async {
    Query query = _firestore.collection(_collection);

    if (role != null && role.isNotEmpty && role != 'All') {
      query = query.where('role', isEqualTo: role);
    }

    if (active != null) {
      query = query.where('active', isEqualTo: active);
    }

    final snapshot = await query.get();
    return snapshot.docs.length;
  }
}
