import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/enquiry.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/widgets/status_inline_control.dart'
    as wid;
import 'package:we_decor_enquiries/services/dropdown_lookup.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

class MockEnquiryRepository extends Mock implements EnquiryRepository {}

class MockFirestoreService extends Mock implements FirestoreService {}

UserModel _staffUser(String uid) =>
    UserModel(uid: uid, name: 'Staff', email: '$uid@example.com', phone: '', role: UserRole.staff);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatusInlineControl', () {
    testWidgets('non-assignee staff sees read-only status chip', (tester) async {
      final repo = MockEnquiryRepository();
      final firestore = MockFirestoreService();
      when(() => firestore.watchActiveStatusDropdownItems()).thenAnswer(
        (_) => Stream.value(_emptyStatusQuerySnapshot()),
      );
      when(() => firestore.fetchDropdownValueLabelMap(any())).thenAnswer((_) async => {});
      when(() => firestore.fetchActiveDropdownItems(any())).thenAnswer(
        (_) async => _emptyStatusQuerySnapshot(),
      );

      final enquiry = Enquiry(
        id: 'E1',
        customerName: 'Alice',
        eventType: 'Birthday',
        eventDate: DateTime.now().add(const Duration(days: 7)),
        status: 'new',
        assignedTo: 'staff1',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
            firestoreServiceProvider.overrideWithValue(firestore),
            dropdownLookupProvider.overrideWith((ref) async => DropdownLookup(firestore)),
            roleProvider.overrideWith((ref) => Stream.value(UserRole.staff)),
            currentUserWithFirestoreProvider.overrideWith(
              (ref) => Stream.value(_staffUser('staff2')),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: wid.StatusInlineControl(enquiry: enquiry)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('statusDropdown')), findsNothing);
      expect(find.text('new'), findsOneWidget);
    });

    testWidgets('assigned staff can change status to allowed next step', (tester) async {
      final repo = MockEnquiryRepository();
      final firestore = MockFirestoreService();
      when(() => firestore.watchActiveStatusDropdownItems()).thenAnswer(
        (_) => Stream.value(_emptyStatusQuerySnapshot()),
      );
      when(() => firestore.fetchDropdownValueLabelMap(any())).thenAnswer((_) async => {});
      when(() => firestore.fetchActiveDropdownItems(any())).thenAnswer(
        (_) async => _emptyStatusQuerySnapshot(),
      );
      when(
        () => repo.updateStatus(
          id: any(named: 'id'),
          nextStatus: any(named: 'nextStatus'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});

      final enquiry = Enquiry(
        id: 'E2',
        customerName: 'Bob',
        eventType: 'Wedding',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        status: 'in_talks',
        assignedTo: 'staff1',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
            firestoreServiceProvider.overrideWithValue(firestore),
            dropdownLookupProvider.overrideWith((ref) async => DropdownLookup(firestore)),
            roleProvider.overrideWith((ref) => Stream.value(UserRole.staff)),
            currentUserWithFirestoreProvider.overrideWith(
              (ref) => Stream.value(_staffUser('staff1')),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: wid.StatusInlineControl(enquiry: enquiry)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dd = find.byKey(const Key('statusDropdown'));
      expect(tester.widget<DropdownButton<String>>(dd).onChanged, isNotNull);

      await tester.tap(dd);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approved').last);
      await tester.pumpAndSettle();

      expect(find.text('Change Status'), findsWidgets);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Status'));
      await tester.pumpAndSettle();

      verify(
        () => repo.updateStatus(id: 'E2', nextStatus: 'approved', userId: 'staff1'),
      ).called(1);
    });
  });
}

QuerySnapshot<Map<String, dynamic>> _emptyStatusQuerySnapshot() =>
    _FakeQuerySnapshot([]);

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this._docs);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => _docs.length;
}
