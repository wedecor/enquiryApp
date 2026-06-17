import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/enquiry.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/widgets/status_inline_control.dart'
    as wid;
import 'package:we_decor_enquiries/shared/models/user_model.dart';

class MockEnquiryRepository extends Mock implements EnquiryRepository {}

UserModel _staffUser(String uid) =>
    UserModel(uid: uid, name: 'Staff', email: '$uid@example.com', phone: '', role: UserRole.staff);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatusInlineControl', () {
    testWidgets('non-assignee staff sees disabled control', (tester) async {
      final repo = MockEnquiryRepository();
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

      final dd = find.byKey(const Key('statusDropdown'));
      expect(dd, findsOneWidget);
      final w = tester.widget<DropdownButton<String>>(dd);
      expect(w.onChanged, isNull);
    });

    testWidgets('assigned staff can change status', (tester) async {
      final repo = MockEnquiryRepository();
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
        status: 'contacted',
        assignedTo: 'staff1',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
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
      await tester.tap(find.text('quoted').last);
      await tester.pump();

      verify(() => repo.updateStatus(id: 'E2', nextStatus: 'quoted', userId: 'staff1')).called(1);
    });
  });
}
