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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String?,
      role: data['role'] as String,
      active: data['active'] as bool? ?? true,
      // fcmToken removed for security
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
