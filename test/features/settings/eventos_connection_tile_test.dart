import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/eventos/eventos_auth.dart';
import 'package:we_decor_enquiries/core/eventos/eventos_providers.dart';
import 'package:we_decor_enquiries/features/settings/presentation/tabs/widgets/eventos_connection_tile.dart';

void main() {
  testWidgets('shows disabled state by default when EventOS URL unset', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: EventosConnectionTile())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EventOS connection'), findsOneWidget);
    expect(find.textContaining('Disabled'), findsOneWidget);
    expect(find.text('Test connection'), findsOneWidget);
  });

  testWidgets('shows connected user after controller update', (tester) async {
    final controller = EventosConnectionController(EventosAuth());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventosConnectionProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: EventosConnectionTile())),
      ),
    );
    await tester.pumpAndSettle();

    controller.state = const EventosConnectionSnapshot(
      state: EventosConnectionState.connected,
      environment: 'staging',
      user: EventosUser(id: 'u1', name: 'Ilyas', role: 'owner', permissions: ['bookings:read']),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Connected'), findsOneWidget);
    expect(find.textContaining('Ilyas'), findsOneWidget);
    expect(find.textContaining('owner'), findsOneWidget);
  });

  testWidgets('shows not_linked state', (tester) async {
    final controller = EventosConnectionController(EventosAuth());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventosConnectionProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: EventosConnectionTile())),
      ),
    );
    controller.state = const EventosConnectionSnapshot(
      state: EventosConnectionState.notLinked,
      environment: 'staging',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Not linked'), findsOneWidget);
  });
}
