import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/users/domain/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel with all required fields', () {
      final user = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        role: 'admin',
        active: true,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      expect(user.uid, 'test-uid');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '+1234567890');
      expect(user.role, 'admin');
      expect(user.active, true);
      expect(user.createdAt, DateTime(2023, 1, 1));
      expect(user.updatedAt, DateTime(2023, 1, 2));
    });

    test('should create UserModel with defaults', () {
      final user = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'staff',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      expect(user.active, true); // default value
      expect(user.phone, null);
    });

    test('should create empty user for creation', () {
      final user = UserModel.emptyForCreate(email: 'new@example.com');

      expect(user.uid, '');
      expect(user.name, '');
      expect(user.email, 'new@example.com');
      expect(user.phone, null);
      expect(user.role, 'staff');
      expect(user.active, true);
      expect(user.createdAt, isA<DateTime>());
      expect(user.updatedAt, isA<DateTime>());
    });

    test('should identify admin users correctly', () {
      final adminUser = UserModel(
        uid: 'admin-uid',
        name: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final staffUser = UserModel(
        uid: 'staff-uid',
        name: 'Staff User',
        email: 'staff@example.com',
        role: 'staff',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(adminUser.isAdmin, true);
      expect(adminUser.isStaff, false);
      expect(staffUser.isAdmin, false);
      expect(staffUser.isStaff, true);
    });

    test('should convert to Firestore format', () {
      final user = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'admin',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final firestoreData = user.toFirestore();

      expect(firestoreData['uid'], 'test-uid');
      expect(firestoreData['name'], 'John Doe');
      expect(firestoreData['email'], 'john@example.com');
      expect(firestoreData['role'], 'admin');
      expect(firestoreData['active'], true);
      expect(firestoreData['createdAt'], isA<Object>()); // Timestamp
      expect(firestoreData['updatedAt'], isA<Object>()); // Timestamp
    });

    test('should create copyWith correctly', () {
      final original = UserModel(
        uid: 'test-uid',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'staff',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final updated = original.copyWith(
        name: 'Jane Doe',
        role: 'admin',
        active: false,
      );

      expect(updated.uid, 'test-uid'); // unchanged
      expect(updated.name, 'Jane Doe'); // changed
      expect(updated.email, 'john@example.com'); // unchanged
      expect(updated.role, 'admin'); // changed
      expect(updated.active, false); // changed
      expect(updated.createdAt, DateTime(2023, 1, 1)); // unchanged
      expect(updated.updatedAt, DateTime(2023, 1, 2)); // unchanged
    });
  });
}
