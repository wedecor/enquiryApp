import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/auth/current_user_role_provider.dart';
import 'package:we_decor_enquiries/core/auth/role_guards.dart';

void main() {
  group('Admin User Management Guards Tests', () {
    group('Role Validation', () {
      test('requireAdmin throws for staff users', () {
        final staffContainer = ProviderContainer(
          overrides: [
            currentUserRoleProvider.overrideWith((ref) => 'staff'),
            isAdminValueProvider.overrideWith((ref) => false),
          ],
        );

        final staffRef = _SimpleWidgetRef(staffContainer);

        expect(() => requireAdmin(staffRef), throwsA(isA<StateError>()));
        staffContainer.dispose();
      });

      test('requireAdmin passes for admin users', () {
        final adminContainer = ProviderContainer(
          overrides: [
            currentUserRoleProvider.overrideWith((ref) => 'admin'),
            isAdminValueProvider.overrideWith((ref) => true),
          ],
        );

        final adminRef = _SimpleWidgetRef(adminContainer);

        expect(() => requireAdmin(adminRef), returnsNormally);
        adminContainer.dispose();
      });

      test('canManageUsers returns correct values', () {
        // Admin case
        final adminContainer = ProviderContainer(
          overrides: [isAdminValueProvider.overrideWith((ref) => true)],
        );
        expect(canManageUsers(_SimpleWidgetRef(adminContainer)), isTrue);
        adminContainer.dispose();

        // Staff case
        final staffContainer = ProviderContainer(
          overrides: [isAdminValueProvider.overrideWith((ref) => false)],
        );
        expect(canManageUsers(_SimpleWidgetRef(staffContainer)), isFalse);
        staffContainer.dispose();
      });
    });

    group('Input Validation', () {
      test('email validation works correctly', () {
        expect(_validateEmail('test@example.com'), isNull);
        expect(_validateEmail('user.name@domain.co.uk'), isNull);
        expect(_validateEmail('invalid-email'), isNotNull);
        expect(_validateEmail(''), isNotNull);
        expect(_validateEmail('test@'), isNotNull);
        expect(_validateEmail('@example.com'), isNotNull);
        expect(_validateEmail('test.example.com'), isNotNull);
      });

      test('role validation works correctly', () {
        expect(_validateRole('admin'), isNull);
        expect(_validateRole('staff'), isNull);
        expect(_validateRole('invalid'), isNotNull);
        expect(_validateRole(''), isNotNull);
        expect(_validateRole('ADMIN'), isNotNull); // Case sensitive
        expect(_validateRole('Staff'), isNotNull); // Case sensitive
      });

      test('name validation works correctly', () {
        expect(_validateName('John Doe'), isNull);
        expect(_validateName('A'), isNull); // Single letter OK
        expect(_validateName(''), isNotNull);
        expect(_validateName('   '), isNotNull);
        expect(_validateName('Very Long Name That Should Still Be Valid'), isNull);
      });

      test('phone validation works correctly', () {
        expect(_validatePhone('+1234567890'), isNull);
        expect(_validatePhone('1234567890'), isNull);
        expect(_validatePhone(''), isNull); // Optional field
        expect(_validatePhone(null), isNull); // Optional field
        expect(_validatePhone('123'), isNotNull); // Too short
        expect(_validatePhone('abc'), isNotNull); // Invalid format
      });
    });

    group('Business Logic Validation', () {
      test('user status change validation', () {
        const currentUserId = 'admin-123';

        // Should allow deactivating others
        expect(_validateStatusChange(currentUserId, 'staff-456', false), isNull);

        // Should prevent self-deactivation
        expect(_validateStatusChange(currentUserId, currentUserId, false), isNotNull);

        // Should allow self-activation (recovery case)
        expect(_validateStatusChange(currentUserId, currentUserId, true), isNull);

        // Should allow activating others
        expect(_validateStatusChange(currentUserId, 'staff-456', true), isNull);
      });

      test('role change validation', () {
        expect(_validateRoleChange('staff', 'admin'), isNull);
        expect(_validateRoleChange('admin', 'staff'), isNull);
        expect(_validateRoleChange('staff', 'staff'), isNotNull); // No change
        expect(_validateRoleChange('admin', 'admin'), isNotNull); // No change
        expect(_validateRoleChange('staff', 'invalid'), isNotNull);
        expect(_validateRoleChange('invalid', 'staff'), isNotNull);
      });

      test('invitation validation', () {
        expect(_validateInvitation('new@example.com', 'staff'), isNull);
        expect(_validateInvitation('admin@example.com', 'admin'), isNull);
        expect(_validateInvitation('', 'staff'), isNotNull);
        expect(_validateInvitation('invalid-email', 'staff'), isNotNull);
        expect(_validateInvitation('test@example.com', ''), isNotNull);
        expect(_validateInvitation('test@example.com', 'invalid'), isNotNull);
      });
    });

    group('Security Boundary Tests', () {
      test('admin action simulation', () {
        expect(() => _simulateAdminAction('admin'), returnsNormally);
        expect(() => _simulateAdminAction('staff'), throwsA(isA<StateError>()));
        expect(() => _simulateAdminAction(null), throwsA(isA<StateError>()));
        expect(() => _simulateAdminAction(''), throwsA(isA<StateError>()));
      });

      test('user management permission checks', () {
        expect(_hasUserManagementPermission('admin'), isTrue);
        expect(_hasUserManagementPermission('staff'), isFalse);
        expect(_hasUserManagementPermission(null), isFalse);
        expect(_hasUserManagementPermission('unknown'), isFalse);
      });

      test('invite permission checks', () {
        expect(_hasInvitePermission('admin'), isTrue);
        expect(_hasInvitePermission('staff'), isFalse);
        expect(_hasInvitePermission(null), isFalse);
      });

      test('role change permission checks', () {
        expect(_hasRoleChangePermission('admin'), isTrue);
        expect(_hasRoleChangePermission('staff'), isFalse);
        expect(_hasRoleChangePermission(null), isFalse);
      });
    });

    group('Data Processing Logic', () {
      test('user filtering by search query', () {
        final users = [
          {'name': 'Alice Admin', 'email': 'alice@admin.com', 'role': 'admin'},
          {'name': 'Bob Staff', 'email': 'bob@staff.com', 'role': 'staff'},
          {'name': 'Charlie Staff', 'email': 'charlie@staff.com', 'role': 'staff'},
        ];

        final nameResults = _filterUsersByQuery(users, 'Alice');
        expect(nameResults.length, 1);

        final emailResults = _filterUsersByQuery(users, 'staff.com');
        expect(emailResults.length, 2);

        final caseResults = _filterUsersByQuery(users, 'ALICE');
        expect(caseResults.length, 1);
      });

      test('user pagination logic', () {
        final users = List.generate(
          25,
          (i) => {'name': 'User $i', 'email': 'user$i@test.com', 'role': 'staff'},
        );

        final page1 = _paginateUsers(users, 0, 10);
        expect(page1.length, 10);

        final page3 = _paginateUsers(users, 2, 10);
        expect(page3.length, 5);

        final emptyPage = _paginateUsers(users, 10, 10);
        expect(emptyPage.length, 0);
      });

      test('user sorting logic', () {
        final users = [
          {'name': 'Charlie', 'email': 'charlie@test.com', 'role': 'staff'},
          {'name': 'Alice', 'email': 'alice@test.com', 'role': 'admin'},
          {'name': 'Bob', 'email': 'bob@test.com', 'role': 'staff'},
        ];

        final sortedByName = _sortUsers(users, 'name', true);
        expect(sortedByName.map((u) => u['name']).toList(), ['Alice', 'Bob', 'Charlie']);

        final sortedByRole = _sortUsers(users, 'role', false);
        expect(sortedByRole.first['role'], 'staff');
      });
    });
  });
}

/// Simple WidgetRef for testing
class _SimpleWidgetRef implements WidgetRef {
  final ProviderContainer container;
  _SimpleWidgetRef(this.container);

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  BuildContext get context => throw UnimplementedError();

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T?, T) listener, {
    void Function(Object, StackTrace)? onError,
  }) {}

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T?, T) listener, {
    void Function(Object, StackTrace)? onError,
    bool fireImmediately = false,
  }) {
    throw UnimplementedError();
  }

  @override
  T refresh<T>(Refreshable<T> provider) => container.refresh(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  bool exists(ProviderBase<Object?> provider) => container.exists(provider);
}

/// Helper functions for testing business logic

String? _validateEmail(String email) {
  if (email.trim().isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) return 'Invalid email format';
  return null;
}

String? _validateRole(String role) {
  if (role.trim().isEmpty) return 'Role is required';
  if (!['admin', 'staff'].contains(role)) return 'Invalid role';
  return null;
}

String? _validateName(String name) {
  if (name.trim().isEmpty) return 'Name is required';
  return null;
}

String? _validatePhone(String? phone) {
  if (phone == null || phone.trim().isEmpty) return null; // Optional
  if (phone.replaceAll(RegExp(r'[^\d]'), '').length < 10) return 'Phone too short';
  if (!RegExp(r'^[\d\s\-\+\(\)\.]+$').hasMatch(phone)) return 'Invalid phone format';
  return null;
}

String? _validateStatusChange(String currentUserId, String targetUserId, bool newStatus) {
  if (currentUserId == targetUserId && !newStatus) {
    return 'Cannot deactivate your own account';
  }
  return null;
}

String? _validateRoleChange(String currentRole, String newRole) {
  if (currentRole == newRole) return 'No change in role';
  if (!['admin', 'staff'].contains(currentRole)) return 'Invalid current role';
  if (!['admin', 'staff'].contains(newRole)) return 'Invalid new role';
  return null;
}

String? _validateInvitation(String email, String role) {
  final emailError = _validateEmail(email);
  if (emailError != null) return emailError;

  final roleError = _validateRole(role);
  if (roleError != null) return roleError;

  return null;
}

void _simulateAdminAction(String? role) {
  if (role != 'admin') {
    throw StateError('Admin access required');
  }
}

bool _hasUserManagementPermission(String? role) => role == 'admin';
bool _hasInvitePermission(String? role) => role == 'admin';
bool _hasRoleChangePermission(String? role) => role == 'admin';

List<Map<String, dynamic>> _filterUsersByQuery(List<Map<String, dynamic>> users, String query) {
  final lowercaseQuery = query.toLowerCase();
  return users
      .where(
        (user) =>
            user['name'].toString().toLowerCase().contains(lowercaseQuery) ||
            user['email'].toString().toLowerCase().contains(lowercaseQuery),
      )
      .toList();
}

List<Map<String, dynamic>> _paginateUsers(
  List<Map<String, dynamic>> users,
  int page,
  int pageSize,
) {
  final startIndex = page * pageSize;
  if (startIndex >= users.length) return [];

  final endIndex = (startIndex + pageSize).clamp(0, users.length);
  return users.sublist(startIndex, endIndex);
}

List<Map<String, dynamic>> _sortUsers(
  List<Map<String, dynamic>> users,
  String sortBy,
  bool ascending,
) {
  final sorted = List<Map<String, dynamic>>.from(users);

  sorted.sort((a, b) {
    final comparison = a[sortBy].toString().compareTo(b[sortBy].toString());
    return ascending ? comparison : -comparison;
  });

  return sorted;
}
