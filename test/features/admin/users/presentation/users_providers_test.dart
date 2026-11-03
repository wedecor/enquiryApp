import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/users/domain/user_model.dart';
import 'package:we_decor_enquiries/features/admin/users/presentation/users_providers.dart';

void main() {
  group('UsersFilter', () {
    late UsersFilter filter;

    setUp(() {
      filter = UsersFilter();
    });

    tearDown(() {
      filter.dispose();
    });

    test('starts with default values', () {
      expect(filter.state.search, '');
      expect(filter.state.role, 'All');
      expect(filter.state.isActive, isNull);
    });

    test('updates each field without touching the others', () {
      filter.updateSearch('ali');
      filter.updateRole('admin');
      filter.updateActive(true);
      expect(filter.state.search, 'ali');
      expect(filter.state.role, 'admin');
      expect(filter.state.isActive, isTrue);

      filter.updateActive(null);
      expect(filter.state.search, 'ali');
      expect(filter.state.role, 'admin');
      expect(filter.state.isActive, isNull);
    });

    test('reset restores defaults', () {
      filter.updateSearch('x');
      filter.updateRole('staff');
      filter.updateActive(false);
      filter.reset();
      expect(filter.state.search, '');
      expect(filter.state.role, 'All');
      expect(filter.state.isActive, isNull);
    });
  });

  group('applyUsersFilter', () {
    final now = DateTime(2026, 10, 1);
    UserModel user(String uid, String name, String email, String role, bool active) => UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
      isActive: active,
      createdAt: now,
      updatedAt: now,
    );

    final users = [
      user('1', 'Ayesha Khan', 'ayesha@wedecor.in', 'admin', true),
      user('2', 'Ravi Kumar', 'ravi@wedecor.in', 'staff', true),
      user('3', 'Old Staff', 'old@wedecor.in', 'staff', false),
    ];

    test('no filters returns everyone', () {
      final r = applyUsersFilter(users, (search: '', role: 'All', isActive: null));
      expect(r.length, 3);
    });

    test('filters by role, active and search together', () {
      expect(
        applyUsersFilter(users, (search: '', role: 'staff', isActive: null)).map((u) => u.uid),
        ['2', '3'],
      );
      expect(
        applyUsersFilter(users, (search: '', role: 'staff', isActive: true)).map((u) => u.uid),
        ['2'],
      );
      expect(
        applyUsersFilter(users, (search: 'AYESHA', role: 'All', isActive: null)).map((u) => u.uid),
        ['1'],
      );
      expect(
        applyUsersFilter(users, (
          search: 'wedecor',
          role: 'All',
          isActive: false,
        )).map((u) => u.uid),
        ['3'],
      );
    });
  });
}
