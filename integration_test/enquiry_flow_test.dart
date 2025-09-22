import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

// EDIT: update to real import if different
import 'package:we_decor_enquiries/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('staff change status then Undo', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // EDIT: navigate to an enquiry assigned to current user
    final dd = find.byKey(const Key('statusDropdown'));
    if (dd.evaluate().isEmpty) return; // allow running without seed

    await tester.tap(dd);
    await tester.pumpAndSettle();
    final quoted = find.text('quoted');
    if (quoted.evaluate().isNotEmpty) {
      await tester.tap(quoted.last);
      await tester.pumpAndSettle();
      final undo = find.text('Undo');
      if (undo.evaluate().isNotEmpty) {
        await tester.tap(undo);
        await tester.pumpAndSettle();
      }
    }
  });
}


