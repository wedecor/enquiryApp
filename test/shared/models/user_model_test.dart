import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create a UserModel with all required fields', () {
      const user = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        role: UserRole.admin,
      );

      expect(user.uid, 'test-uid');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '+1234567890');
      expect(user.role, UserRole.admin);
    });

    test('should default to staff role when not specified', () {
      const user = UserModel(
        uid: 'test-uid',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1234567890',
      );

      expect(user.role, UserRole.staff);
    });

    test('should serialize and deserialize correctly', () {
      const user = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        role: UserRole.admin,
      );

      final json = user.toJson();
      final deserializedUser = UserModel.fromJson(json);

      expect(deserializedUser, user);
      expect(json['uid'], 'test-uid');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['phone'], '+1234567890');
      expect(json['role'], 'admin');
    });

    test('should support copyWith functionality', () {
      const user = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        role: UserRole.staff,
      );

      final updatedUser = user.copyWith(name: 'Jane Doe', role: UserRole.admin);

      expect(updatedUser.uid, 'test-uid');
      expect(updatedUser.name, 'Jane Doe');
      expect(updatedUser.email, 'john@example.com');
      expect(updatedUser.phone, '+1234567890');
      expect(updatedUser.role, UserRole.admin);
    });
  });
}
