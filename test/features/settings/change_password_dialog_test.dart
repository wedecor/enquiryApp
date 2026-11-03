import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/theme/app_theme.dart';
import 'package:we_decor_enquiries/features/settings/presentation/tabs/widgets/change_password_dialog.dart';

void main() {
  group('changePasswordErrorMessage', () {
    test('wrong or invalid credential means the current password is wrong', () {
      expect(changePasswordErrorMessage('wrong-password'), 'Current password is incorrect.');
      expect(changePasswordErrorMessage('invalid-credential'), 'Current password is incorrect.');
    });

    test('known codes get specific messages', () {
      expect(changePasswordErrorMessage('weak-password'), contains('stronger'));
      expect(changePasswordErrorMessage('too-many-requests'), contains('Too many attempts'));
      expect(changePasswordErrorMessage('network-request-failed'), contains('No connection'));
    });

    test('unknown codes fall back to a generic message', () {
      expect(changePasswordErrorMessage('something-else'), contains('Could not change'));
    });
  });

  group('ChangePasswordDialog validation', () {
    var forgotTapped = false;

    Future<void> pumpDialog(WidgetTester tester) async {
      forgotTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: ChangePasswordDialog(onForgotPassword: () => forgotTapped = true)),
        ),
      );
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('empty form asks for the current password and a long enough new one', (
      tester,
    ) async {
      await pumpDialog(tester);
      await tester.tap(find.text('Update'));
      await tester.pump();

      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Use at least $kMinPasswordLength characters'), findsOneWidget);
    });

    testWidgets('new password must differ from the current one', (tester) async {
      await pumpDialog(tester);
      await tester.enterText(field('Current password'), 'secret123');
      await tester.enterText(field('New password'), 'secret123');
      await tester.enterText(field('Confirm new password'), 'secret123');
      await tester.tap(find.text('Update'));
      await tester.pump();

      expect(find.text('Must differ from your current password'), findsOneWidget);
    });

    testWidgets('confirmation must match', (tester) async {
      await pumpDialog(tester);
      await tester.enterText(field('Current password'), 'secret123');
      await tester.enterText(field('New password'), 'newsecret1');
      await tester.enterText(field('Confirm new password'), 'newsecret2');
      await tester.tap(find.text('Update'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('forgot link hands over to the reset email flow', (tester) async {
      await pumpDialog(tester);
      await tester.tap(find.text('Forgot current password? Email me a reset link'));
      await tester.pump();

      expect(forgotTapped, isTrue);
    });
  });
}
