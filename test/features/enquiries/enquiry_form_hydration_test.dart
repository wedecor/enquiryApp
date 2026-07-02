import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/screens/enquiry_form_screen.dart';
import 'package:we_decor_enquiries/services/dropdown_lookup.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirestoreService mockFirestore;

  setUp(() {
    mockFirestore = MockFirestoreService();
    registerFallbackValue('');
  });

  testWidgets('edit mode disables submit until enquiry data loads (T11)', (tester) async {
    when(() => mockFirestore.getEnquiry(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return {
        'customerName': 'Jane Doe',
        'customerPhone': '9876543210',
        'statusValue': 'new',
        'eventTypeValue': 'wedding',
        'priorityValue': 'medium',
        'paymentStatusValue': 'pending',
        'sourceValue': 'instagram',
      };
    });

    final lookup = DropdownLookup(mockFirestore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(mockFirestore),
          dropdownLookupProvider.overrideWith((ref) async => lookup),
          isAdminProvider.overrideWith((ref) => true),
          currentUserWithFirestoreProvider.overrideWith(
            (ref) => Stream.value(
              UserModel(
                uid: 'admin1',
                name: 'Admin',
                email: 'admin@test.com',
                phone: '',
                role: UserRole.admin,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: EnquiryFormScreen(enquiryId: 'enq123', mode: 'edit'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    final loadedButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(loadedButton.onPressed, isNotNull);
  });
}
