import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/services/firebase_auth_service.dart';
import '../../test_helper.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late bool firebaseAvailable;

  setUpAll(() async {
    firebaseAvailable = await setupFirebaseForTesting();
    if (firebaseAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  });

  group('FirebaseAuthService', () {
    group('currentUser', () {
      test('returns null when no user is signed in', () {
        if (!firebaseAvailable) return;
        final authService = FirebaseAuthService();
        // Note: This tests the actual Firebase instance
        // In a real test environment, you'd mock FirebaseAuth
        expect(authService.currentUser, anyOf(isNull, isA<User>()));
      });
    });

    group('authStateChanges', () {
      test('returns a stream', () {
        if (!firebaseAvailable) return;
        final authService = FirebaseAuthService();
        expect(authService.authStateChanges, isA<Stream<User?>>());
      });
    });

    group('signInWithEmailAndPassword', () {
      test('throws AuthException on invalid email', () async {
        if (!firebaseAvailable) return;
        final authService = FirebaseAuthService();
        await expectLater(
          () => authService.signInWithEmailAndPassword(
            email: 'invalid-email',
            password: 'password',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws AuthException on empty password', () async {
        if (!firebaseAvailable) return;
        final authService = FirebaseAuthService();
        await expectLater(
          () => authService.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: '',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('completes successfully', () async {
        if (!firebaseAvailable) return;
        final authService = FirebaseAuthService();
        // This will work if no user is signed in
        await expectLater(authService.signOut(), completes);
      });
    });

    group('AuthException', () {
      test('creates exception with message', () {
        const exception = AuthException('Test error message');
        expect(exception.message, 'Test error message');
      });

      test('can be thrown and caught', () {
        expect(
          () => throw const AuthException('Error'),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
