import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/auth/current_user_role_provider.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

/// Global test setup for Firebase initialization
/// Call this in setUpAll() for any test that needs Firebase services
Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with test configuration
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
        storageBucket: 'test-storage-bucket',
      ),
    );
  } catch (e) {
    // Firebase already initialized, ignore
  }
}

/// Complete provider overrides for widget tests that need Firebase
/// This prevents Firebase initialization errors in widget tests
List<Override> getCompleteFirebaseMockOverrides({bool isAdmin = false, UserModel? mockUser}) {
  final mockSnapshot = MockDocumentSnapshot();

  // Setup mock document snapshot
  when(() => mockSnapshot.exists).thenReturn(mockUser != null);
  when(() => mockSnapshot.data()).thenReturn(
    mockUser != null
        ? {
            'name': mockUser.name,
            'email': mockUser.email,
            'phone': mockUser.phone,
            'role': isAdmin ? 'admin' : 'staff',
            'active': true,
          }
        : null,
  );

  return [
    // Mock Firebase Auth user stream
    firebaseAuthUserProvider.overrideWith((ref) => Stream.value(null)),

    // Mock current user document
    currentUserDocProvider.overrideWith((ref) => Stream.value(mockSnapshot)),

    // Mock user role providers
    isAdminProvider.overrideWith((ref) => isAdmin),

    // Mock current user role as string
    currentUserRoleProvider.overrideWith((ref) => isAdmin ? 'admin' : 'staff'),
  ];
}
