import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:we_decor_enquiries/core/auth/role_guards.dart';
import 'package:we_decor_enquiries/core/auth/current_user_role_provider.dart';

void main() {
  group('Role Guards - Core Functionality Tests', () {
    test('isAdminValueProvider returns true for admin role', () {
      final container = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
      );

      final result = container.read(isAdminValueProvider);
      expect(result, isTrue);

      container.dispose();
    });

    test('isAdminValueProvider returns false for staff role', () {
      final container = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
      );

      final result = container.read(isAdminValueProvider);
      expect(result, isFalse);

      container.dispose();
    });

    test('isAdminValueProvider returns false for null role', () {
      final container = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => null)],
      );

      final result = container.read(isAdminValueProvider);
      expect(result, isFalse);

      container.dispose();
    });

    test('isStaffValueProvider returns true for staff role', () {
      final container = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
      );

      final result = container.read(isStaffValueProvider);
      expect(result, isTrue);

      container.dispose();
    });

    test('isStaffValueProvider returns false for admin role', () {
      final container = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
      );

      final result = container.read(isStaffValueProvider);
      expect(result, isFalse);

      container.dispose();
    });

    test('role display names are correct', () {
      // Test admin role display
      final adminContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
      );
      final adminRef = _SimpleWidgetRef(adminContainer);
      expect(getRoleDisplayName(adminRef), 'Administrator');
      adminContainer.dispose();

      // Test staff role display
      final staffContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
      );
      final staffRef = _SimpleWidgetRef(staffContainer);
      expect(getRoleDisplayName(staffRef), 'Staff Member');
      staffContainer.dispose();

      // Test unknown role display
      final unknownContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'unknown')],
      );
      final unknownRef = _SimpleWidgetRef(unknownContainer);
      expect(getRoleDisplayName(unknownRef), 'Unknown Role');
      unknownContainer.dispose();
    });

    test('dashboard titles are role-appropriate', () {
      // Test admin dashboard title
      final adminContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
      );
      final adminRef = _SimpleWidgetRef(adminContainer);
      expect(getDashboardTitle(adminRef), 'Admin Dashboard');
      adminContainer.dispose();

      // Test staff dashboard title
      final staffContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
      );
      final staffRef = _SimpleWidgetRef(staffContainer);
      expect(getDashboardTitle(staffRef), 'My Enquiries');
      staffContainer.dispose();
    });

    test('enquiries list titles are role-appropriate', () {
      // Test admin enquiries list title
      final adminContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
      );
      final adminRef = _SimpleWidgetRef(adminContainer);
      expect(getEnquiriesListTitle(adminRef), 'All Enquiries');
      adminContainer.dispose();

      // Test staff enquiries list title
      final staffContainer = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
      );
      final staffRef = _SimpleWidgetRef(staffContainer);
      expect(getEnquiriesListTitle(staffRef), 'My Assigned Enquiries');
      staffContainer.dispose();
    });

    group('Permission Helpers', () {
      test('canViewFinancialData is admin-only', () {
        // Admin case
        final adminContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canViewFinancialData(adminRef), isTrue);
        adminContainer.dispose();

        // Staff case
        final staffContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canViewFinancialData(staffRef), isFalse);
        staffContainer.dispose();
      });

      test('canManageUsers is admin-only', () {
        // Admin case
        final adminContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canManageUsers(adminRef), isTrue);
        adminContainer.dispose();

        // Staff case
        final staffContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canManageUsers(staffRef), isFalse);
        staffContainer.dispose();
      });

      test('canAccessAnalytics is admin-only', () {
        // Admin case
        final adminContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canAccessAnalytics(adminRef), isTrue);
        adminContainer.dispose();

        // Staff case
        final staffContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canAccessAnalytics(staffRef), isFalse);
        staffContainer.dispose();
      });

      test('canConfigureSystem is admin-only', () {
        // Admin case
        final adminContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'admin')],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canConfigureSystem(adminRef), isTrue);
        adminContainer.dispose();

        // Staff case
        final staffContainer = ProviderContainer(
          overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canConfigureSystem(staffRef), isFalse);
        staffContainer.dispose();
      });
    });
  });
}

/// Simple WidgetRef implementation for testing role guards
class _SimpleWidgetRef implements WidgetRef {
  final ProviderContainer container;
  _SimpleWidgetRef(this.container);

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => container.read(provider);

  // Minimal implementations for testing - not used in role guard tests
  @override
  BuildContext get context => throw UnimplementedError('Context not available in unit tests');

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T?, T) listener, {
    void Function(Object, StackTrace)? onError,
  }) {
    throw UnimplementedError('listen not implemented in simple test mock');
  }

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T?, T) listener, {
    void Function(Object, StackTrace)? onError,
    bool fireImmediately = false,
  }) {
    throw UnimplementedError('listenManual not implemented in simple test mock');
  }

  @override
  T refresh<T>(Refreshable<T> provider) => container.refresh(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  bool exists(ProviderBase<Object?> provider) => container.exists(provider);
}
