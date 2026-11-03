import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/users/data/users_repository.dart';
import 'package:we_decor_enquiries/features/admin/users/domain/user_model.dart';

void main() {
  final user = UserModel(
    uid: 'u1',
    name: 'Staff One',
    email: '',
    role: 'staff',
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('phone and email come from the private profile when present', () {
    final merged = UsersRepository.withPrivateProfile(user, {
      'phone': '9876543210',
      'email': 'staff1@example.com',
    });
    expect(merged.phone, '9876543210');
    expect(merged.email, 'staff1@example.com');
  });

  test('no profile (or blank values) keeps the legacy public values', () {
    final legacy = user.copyWith(email: 'old@example.com', phone: '9111111111');
    expect(UsersRepository.withPrivateProfile(legacy, null), legacy);
    final blank = UsersRepository.withPrivateProfile(legacy, {'phone': ' ', 'email': ''});
    expect(blank.email, 'old@example.com');
    expect(blank.phone, '9111111111');
  });
}
