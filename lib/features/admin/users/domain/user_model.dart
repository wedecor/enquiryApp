import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String email,
    String? phone,
    required String role, // 'admin' or 'staff'
    @Default(true) bool active,
    // fcmToken removed for security - now stored in private subcollection
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('User document ${doc.id} has no data');
    }

    // Safe type casting with null checks and defaults
    final name = data['name'] as String? ?? 'Unknown User';
    final email = data['email'] as String? ?? '';
    final phone = data['phone'] as String?;
    final role = data['role'] as String? ?? 'staff';
    final active = data['active'] as bool? ?? true;

    // Handle timestamp fields safely
    DateTime createdAt;
    DateTime updatedAt;

    try {
      final createdAtData = data['createdAt'];
      if (createdAtData is Timestamp) {
        createdAt = createdAtData.toDate();
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    try {
      final updatedAtData = data['updatedAt'];
      if (updatedAtData is Timestamp) {
        updatedAt = updatedAtData.toDate();
      } else {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      updatedAt = DateTime.now();
    }

    return UserModel(
      uid: doc.id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserModel.emptyForCreate({required String email}) {
    final now = DateTime.now();
    return UserModel(
      uid: '', // Will be set when creating the document
      name: '',
      email: email,
      phone: null,
      role: 'staff',
      active: true,
      // fcmToken removed for security
      createdAt: now,
      updatedAt: now,
    );
  }
}

extension UserModelX on UserModel {
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'active': active,
      // fcmToken removed for security - stored in private subcollection
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
}
