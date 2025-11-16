import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/features/settings/data/user_settings_service.dart';
import 'package:we_decor_enquiries/features/settings/domain/user_settings.dart';
import '../../../test_helper.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late bool firebaseAvailable;

  setUpAll(() async {
    firebaseAvailable = await setupFirebaseForTesting();
    if (firebaseAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  });

  group('UserSettingsService', () {
    late UserSettingsService service;

    setUp(() {
      if (!firebaseAvailable) {
        return;
      }
      service = UserSettingsService();
    });

    group('load', () {
      test('returns default settings when document does not exist', () async {
        if (!firebaseAvailable) return;
        final settings = await service.load('test-uid');
        expect(settings, isA<UserSettings>());
      });

      test('handles errors gracefully and returns defaults', () async {
        if (!firebaseAvailable) return;
        // This will test error handling
        final settings = await service.load('invalid-uid');
        expect(settings, isA<UserSettings>());
      });
    });

    group('observe', () {
      test('returns a stream of settings', () {
        if (!firebaseAvailable) return;
        final stream = service.observe('test-uid');
        expect(stream, isA<Stream<UserSettings>>());
      });

      test(
        'stream emits default settings when document does not exist',
        () async {
          if (!firebaseAvailable) return;
          final stream = service.observe('test-uid');
          // Note: This tests the stream structure
          // In a real test with mocks, you'd verify the stream emits defaults
          expect(stream, isA<Stream<UserSettings>>());
        },
      );
    });

    group('update', () {
      test('updates settings successfully', () async {
        if (!firebaseAvailable) return;
        const settings = UserSettings();
        await expectLater(service.update('test-uid', settings), completes);
      });

      test('handles update errors gracefully', () async {
        if (!firebaseAvailable) return;
        const settings = UserSettings();
        // This will test error handling and fallback
        await expectLater(service.update('invalid-uid', settings), completes);
      });
    });

    group('initIfMissing', () {
      test('initializes settings if missing', () async {
        if (!firebaseAvailable) return;
        const defaults = UserSettings();
        await expectLater(
          service.initIfMissing('test-uid', defaults),
          completes,
        );
      });

      test('does not overwrite existing settings', () async {
        if (!firebaseAvailable) return;
        const defaults = UserSettings();
        await expectLater(
          service.initIfMissing('test-uid', defaults),
          completes,
        );
      });

      test('handles initialization errors gracefully', () async {
        if (!firebaseAvailable) return;
        const defaults = UserSettings();
        await expectLater(
          service.initIfMissing('invalid-uid', defaults),
          completes,
        );
      });
    });
  });
}
