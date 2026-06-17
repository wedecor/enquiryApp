import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/auth/role_guards.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

void main() {
  group('Role Guards - Core Functionality Tests', () {
    test('isAdminValueProvider returns true for admin role', () {
      final container = ProviderContainer(overrides: [isAdminProvider.overrideWithValue(true)]);

      final result = container.read(isAdminValueProvider);
      expect(result, isTrue);

      container.dispose();
    });

    test('isAdminValueProvider returns false for staff role', () {
      final container = ProviderContainer(overrides: [isAdminProvider.overrideWithValue(false)]);

      final result = container.read(isAdminValueProvider);
      expect(result, isFalse);

      container.dispose();
    });

    test('isAdminValueProvider returns false for null role', () {
      final container = ProviderContainer(overrides: [isAdminProvider.overrideWithValue(false)]);

      final result = container.read(isAdminValueProvider);
      expect(result, isFalse);

      container.dispose();
    });

    test('isStaffValueProvider returns true for staff role', () {
      final container = ProviderContainer(overrides: [isStaffProvider.overrideWithValue(true)]);

      final result = container.read(isStaffValueProvider);
      expect(result, isTrue);

      container.dispose();
    });

    test('isStaffValueProvider returns false for admin role', () {
      final container = ProviderContainer(overrides: [isStaffProvider.overrideWithValue(false)]);

      final result = container.read(isStaffValueProvider);
      expect(result, isFalse);

      container.dispose();
    });

    test('role display names are correct', () async {
      final adminContainer = ProviderContainer(
        overrides: [roleProvider.overrideWith((ref) => Stream.value(UserRole.admin))],
      );
      await adminContainer.read(roleProvider.future);
      final adminRef = _SimpleWidgetRef(adminContainer);
      expect(getRoleDisplayName(adminRef), 'Administrator');
      adminContainer.dispose();

      final staffContainer = ProviderContainer(
        overrides: [roleProvider.overrideWith((ref) => Stream.value(UserRole.staff))],
      );
      await staffContainer.read(roleProvider.future);
      final staffRef = _SimpleWidgetRef(staffContainer);
      expect(getRoleDisplayName(staffRef), 'Staff Member');
      staffContainer.dispose();
    });

    test('dashboard titles are role-appropriate', () {
      final adminContainer = ProviderContainer(
        overrides: [isAdminProvider.overrideWithValue(true)],
      );
      final adminRef = _SimpleWidgetRef(adminContainer);
      expect(getDashboardTitle(adminRef), 'Admin Dashboard');
      adminContainer.dispose();

      final staffContainer = ProviderContainer(
        overrides: [isAdminProvider.overrideWithValue(false)],
      );
      final staffRef = _SimpleWidgetRef(staffContainer);
      expect(getDashboardTitle(staffRef), 'My Enquiries');
      staffContainer.dispose();
    });

    test('enquiries list titles are role-appropriate', () {
      final adminContainer = ProviderContainer(
        overrides: [isAdminProvider.overrideWithValue(true)],
      );
      final adminRef = _SimpleWidgetRef(adminContainer);
      expect(getEnquiriesListTitle(adminRef), 'All Enquiries');
      adminContainer.dispose();

      final staffContainer = ProviderContainer(
        overrides: [isAdminProvider.overrideWithValue(false)],
      );
      final staffRef = _SimpleWidgetRef(staffContainer);
      expect(getEnquiriesListTitle(staffRef), 'My Assigned Enquiries');
      staffContainer.dispose();
    });

    group('Permission Helpers', () {
      test('canViewFinancialData is admin-only', () {
        final adminContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canViewFinancialData(adminRef), isTrue);
        adminContainer.dispose();

        final staffContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(false)],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canViewFinancialData(staffRef), isFalse);
        staffContainer.dispose();
      });

      test('canManageUsers is admin-only', () {
        final adminContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canManageUsers(adminRef), isTrue);
        adminContainer.dispose();

        final staffContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(false)],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canManageUsers(staffRef), isFalse);
        staffContainer.dispose();
      });

      test('canAccessAnalytics is admin-only', () {
        final adminContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canAccessAnalytics(adminRef), isTrue);
        adminContainer.dispose();

        final staffContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(false)],
        );
        final staffRef = _SimpleWidgetRef(staffContainer);
        expect(canAccessAnalytics(staffRef), isFalse);
        staffContainer.dispose();
      });

      test('canConfigureSystem is admin-only', () {
        final adminContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        final adminRef = _SimpleWidgetRef(adminContainer);
        expect(canConfigureSystem(adminRef), isTrue);
        adminContainer.dispose();

        final staffContainer = ProviderContainer(
          overrides: [isAdminProvider.overrideWithValue(false)],
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
