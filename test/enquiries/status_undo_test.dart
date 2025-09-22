import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:we_decor_enquiries/lib/features/enquiries/presentation/widgets/status_inline_control.dart' as wid;
import 'package:we_decor_enquiries/lib/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/lib/features/enquiries/domain/enquiry.dart';
import 'package:we_decor_enquiries/lib/core/auth/current_user_role_provider.dart';

class MockEnquiryRepository extends Mock implements EnquiryRepository {}

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

      await tester.pumpWidget(ProviderScope(
        overrides: [
          enquiryRepositoryProvider.overrideWithValue(repo),
          currentUserRoleProvider.overrideWithValue('staff'),
          currentUserUidProvider.overrideWithValue('staff2'),
        ],
        child: MaterialApp(home: Scaffold(body: wid.StatusInlineControl(enquiry: enquiry))),
      ));

      final dd = find.byKey(const Key('statusDropdown'));
      expect(dd, findsOneWidget);
      final w = tester.widget<DropdownButton<String>>(dd);
      expect(w.onChanged, isNull);
    });

    testWidgets('assigned staff: change + Undo => two writes', (tester) async {
      final repo = MockEnquiryRepository();
      when(() => repo.updateStatus(id: any(named: 'id'), nextStatus: any(named: 'nextStatus'), userId: any(named: 'userId'), prevStatus: any(named: 'prevStatus')))
          .thenAnswer((_) async {});

      final enquiry = Enquiry(
        id: 'E2',
        customerName: 'Bob',
        eventType: 'Wedding',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        status: 'contacted',
        assignedTo: 'staff1',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          enquiryRepositoryProvider.overrideWithValue(repo),
          currentUserRoleProvider.overrideWithValue('staff'),
          currentUserUidProvider.overrideWithValue('staff1'),
        ],
        child: MaterialApp(home: Scaffold(body: wid.StatusInlineControl(enquiry: enquiry))),
      ));

      await tester.tap(find.byKey(const Key('statusDropdown')));
      await tester.pumpAndSettle();
      // pick 'quoted' from menu
      await tester.tap(find.text('quoted').last);
      await tester.pump();

      verify(() => repo.updateStatus(id: 'E2', nextStatus: 'quoted', userId: 'staff1', prevStatus: 'contacted')).called(1);

      if (find.text('Undo').evaluate().isNotEmpty) {
        await tester.tap(find.text('Undo'));
        await tester.pump();
        verify(() => repo.updateStatus(id: 'E2', nextStatus: 'contacted', userId: 'staff1', prevStatus: 'quoted')).called(1);
      }
    });
  });
}


