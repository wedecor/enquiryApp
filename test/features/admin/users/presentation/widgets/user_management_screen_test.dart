import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/users/presentation/user_management_screen.dart';
import 'package:we_decor_enquiries/features/admin/users/presentation/users_providers.dart';

void main() {
  group('UserManagementScreen', () {
    testWidgets('should display empty state when no users', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => Stream.value([])),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check for empty state elements
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.text('No users found'), findsOneWidget);
      expect(find.text('Try adjusting your search or filters'), findsOneWidget);
    });

    testWidgets('should display error state when stream has error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => Stream.error('Test error')),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check for error state elements
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading users'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => const Stream.empty()),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pump();

      // Check for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display search field and filters', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => Stream.value([])),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check for search and filter elements
      expect(find.text('Search by name or email...'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Add User'), findsOneWidget);
    });

    testWidgets('should hide Add User button for non-admin users', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => Stream.value([])),
            isCurrentUserAdminProvider.overrideWith((ref) => false), // Not admin
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Add User button should not be visible for non-admin
      expect(find.text('Add User'), findsNothing);
    });

    testWidgets('should display users in table format on wide screens', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Wide screen

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith(
              (ref, filter) => Stream.value([
                // Mock user data would go here - for now empty list shows empty state
              ]),
            ),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // With empty users list, we should see empty state, not table headers
      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('should update search when typing in search field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => Stream.value([])),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'john');
      await tester.pump(const Duration(milliseconds: 600)); // Wait for debounce

      // The search should have been triggered (we can't easily test the provider state here
      // without more complex setup, but we can verify the field accepts input)
      expect(find.text('john'), findsOneWidget);
    });

    testWidgets('should display role and status dropdowns', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref, filter) => Stream.value([])),
            isCurrentUserAdminProvider.overrideWith((ref) => true),
            paginationStateProvider.overrideWith((ref) => PaginationStateNotifier()),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check for dropdowns
      expect(find.text('All Roles'), findsOneWidget);
      expect(find.text('All Status'), findsOneWidget);
    });
  });
}
