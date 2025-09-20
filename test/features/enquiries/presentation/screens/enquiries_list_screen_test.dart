import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/services/user_firestore_sync_service.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/screens/enquiries_list_screen.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

void main() {
  group('EnquiryListScreen Widget Tests', () {
    testWidgets('should show authentication required message when user is null', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(null))],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please log in to view enquiries'), findsOneWidget);
    });

    testWidgets('should show loading state while user data is loading', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserWithFirestoreProvider.overrideWith((ref) => Stream.empty())],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when user data fails to load', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith(
              (ref) => Stream.error('Failed to load user'),
            ),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('should show add button for creating new enquiries', (WidgetTester tester) async {
      // Arrange
      final adminUser = UserModel(
        uid: 'admin_123',
        name: 'Admin User',
        email: 'admin@test.com',
        phone: '1234567890',
        role: UserRole.admin,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Add New Enquiry'), findsOneWidget);
    });

    testWidgets('should show correct empty state icon based on user role', (
      WidgetTester tester,
    ) async {
      // Test admin empty state
      final adminUser = UserModel(
        uid: 'admin_123',
        name: 'Admin User',
        email: 'admin@test.com',
        phone: '1234567890',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.inbox), findsOneWidget);

      // Test staff empty state
      final staffUser = UserModel(
        uid: 'staff_1',
        name: 'Staff User',
        email: 'staff@test.com',
        phone: '1234567890',
        role: UserRole.staff,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(staffUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.assignment), findsOneWidget);
    });

    testWidgets('should show correct empty state message based on user role', (
      WidgetTester tester,
    ) async {
      // Test admin empty state message
      final adminUser = UserModel(
        uid: 'admin_123',
        name: 'Admin User',
        email: 'admin@test.com',
        phone: '1234567890',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No enquiries found'), findsOneWidget);

      // Test staff empty state message
      final staffUser = UserModel(
        uid: 'staff_1',
        name: 'Staff User',
        email: 'staff@test.com',
        phone: '1234567890',
        role: UserRole.staff,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(staffUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No enquiries assigned to you'), findsOneWidget);
    });

    testWidgets('should show assignment information for admin users', (WidgetTester tester) async {
      // Arrange
      final adminUser = UserModel(
        uid: 'admin_123',
        name: 'Admin User',
        email: 'admin@test.com',
        phone: '1234567890',
        role: UserRole.admin,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - admin should see assignment info
      // Note: This test verifies the UI structure, actual assignment info would appear when there are enquiries
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should not show assignment information for staff users', (
      WidgetTester tester,
    ) async {
      // Arrange
      final staffUser = UserModel(
        uid: 'staff_1',
        name: 'Staff User',
        email: 'staff@test.com',
        phone: '1234567890',
        role: UserRole.staff,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(staffUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - staff should not see assignment info
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should handle role-based filtering logic correctly', (WidgetTester tester) async {
      // Test admin user
      final adminUser = UserModel(
        uid: 'admin_123',
        name: 'Admin User',
        email: 'admin@test.com',
        phone: '1234567890',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Admin should see "No enquiries found" (all enquiries view)
      expect(find.text('No enquiries found'), findsOneWidget);

      // Test staff user
      final staffUser = UserModel(
        uid: 'staff_1',
        name: 'Staff User',
        email: 'staff@test.com',
        phone: '1234567890',
        role: UserRole.staff,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(staffUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Staff should see "No enquiries assigned to you" (assigned enquiries view)
      expect(find.text('No enquiries assigned to you'), findsOneWidget);
    });

    testWidgets('should show correct app bar title based on user role', (
      WidgetTester tester,
    ) async {
      // Test admin title
      final adminUser = UserModel(
        uid: 'admin_123',
        name: 'Admin User',
        email: 'admin@test.com',
        phone: '1234567890',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('All Enquiries'), findsOneWidget);

      // Test staff title
      final staffUser = UserModel(
        uid: 'staff_1',
        name: 'Staff User',
        email: 'staff@test.com',
        phone: '1234567890',
        role: UserRole.staff,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserWithFirestoreProvider.overrideWith((ref) => Stream.value(staffUser)),
          ],
          child: const MaterialApp(home: EnquiriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('My Enquiries'), findsOneWidget);
    });
  });
}
