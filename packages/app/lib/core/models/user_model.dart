import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@JsonEnum(alwaysCreate: true)
enum AppRole { admin, partner, staff, pending }

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    String? displayName,
    String? phone,
    required AppRole role,
    required bool isApproved,
    required bool isActive,
    @Default(<String>[]) List<String> fcmTokens,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}
