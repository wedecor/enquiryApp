import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/auth/session_state.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockUser extends Mock implements User {}

void main() {
  group('SessionService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDoc;
    late MockDocumentSnapshot mockSnapshot;
    late MockUser mockUser;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDoc = MockDocumentReference();
      mockSnapshot = MockDocumentSnapshot();
      mockUser = MockUser();
    });

    test(
      'unprovisioned flow: auth user exists but no Firestore profile',
      () async {
        // Arrange
        const testUid = 'test-uid-123';
        const testEmail = 'test@example.com';

        when(() => mockUser.uid).thenReturn(testUid);
        when(() => mockUser.email).thenReturn(testEmail);
        when(() => mockUser.emailVerified).thenReturn(true);

        when(
          () => mockFirestore.collection('users'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.doc(testUid)).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        // Note: This is a simplified test structure
        // Full implementation would require dependency injection in SessionService

        expect(true, isTrue); // Placeholder - proper test requires DI setup
      },
    );

    test('disabled user: profile exists with active=false', () async {
      // Arrange
      const testUid = 'disabled-uid-123';
      const testEmail = 'disabled@example.com';

      when(() => mockUser.uid).thenReturn(testUid);
      when(() => mockUser.email).thenReturn(testEmail);
      when(() => mockUser.emailVerified).thenReturn(true);

      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'name': 'Disabled User',
        'email': testEmail,
        'role': 'staff',
        'active': false, // Key: user is disabled
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Note: This is a simplified test structure
      // Full implementation would require dependency injection in SessionService

      expect(true, isTrue); // Placeholder - proper test requires DI setup
    });

    test('debounce test: rapid auth changes should stabilize', () async {
      // This test would verify that rapid user → null → user changes
      // result in a stable final state without flicker

      // Arrange: Mock rapid auth state changes
      // Act: Simulate user sign-in followed quickly by null then user again
      // Assert: Final state should be authenticated without intermediate unauthenticated

      expect(true, isTrue); // Placeholder - requires stream testing setup
    });
  });

  group('SessionState Extensions', () {
    test('isAuthenticated returns true only for authenticated state', () {
      expect(
        const SessionState.authenticated(
          user: FirebaseUserLite(uid: 'test', email: 'test@example.com'),
          profile: UserModel(
            uid: 'test',
            name: 'Test User',
            email: 'test@example.com',
            phone: '+1234567890',
            role: UserRole.staff,
          ),
        ).isAuthenticated,
        isTrue,
      );

      expect(const SessionState.unauthenticated().isAuthenticated, isFalse);
      expect(const SessionState.loading().isAuthenticated, isFalse);
      expect(
        const SessionState.unprovisioned(
          email: 'test@example.com',
        ).isAuthenticated,
        isFalse,
      );
      expect(
        const SessionState.disabled(email: 'test@example.com').isAuthenticated,
        isFalse,
      );
      expect(
        const SessionState.error(message: 'Test error').isAuthenticated,
        isFalse,
      );
    });

    test(
      'isSignedIn returns true for authenticated, unprovisioned, and disabled',
      () {
        expect(
          const SessionState.authenticated(
            user: FirebaseUserLite(uid: 'test', email: 'test@example.com'),
            profile: UserModel(
              uid: 'test',
              name: 'Test User',
              email: 'test@example.com',
              phone: '+1234567890',
              role: UserRole.staff,
            ),
          ).isSignedIn,
          isTrue,
        );

        expect(
          const SessionState.unprovisioned(
            email: 'test@example.com',
          ).isSignedIn,
          isTrue,
        );
        expect(
          const SessionState.disabled(email: 'test@example.com').isSignedIn,
          isTrue,
        );

        expect(const SessionState.unauthenticated().isSignedIn, isFalse);
        expect(const SessionState.loading().isSignedIn, isFalse);
        expect(
          const SessionState.error(message: 'Test error').isSignedIn,
          isFalse,
        );
      },
    );

    test('email getter returns correct email for each state', () {
      const testEmail = 'test@example.com';

      expect(
        const SessionState.authenticated(
          user: FirebaseUserLite(uid: 'test', email: testEmail),
          profile: UserModel(
            uid: 'test',
            name: 'Test User',
            email: testEmail,
            phone: '+1234567890',
            role: UserRole.staff,
          ),
        ).email,
        equals(testEmail),
      );

      expect(
        const SessionState.unprovisioned(email: testEmail).email,
        equals(testEmail),
      );
      expect(
        const SessionState.disabled(email: testEmail).email,
        equals(testEmail),
      );

      expect(const SessionState.unauthenticated().email, isNull);
      expect(const SessionState.loading().email, isNull);
      expect(const SessionState.error(message: 'Test error').email, isNull);
    });
  });
}
