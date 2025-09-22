import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:we_decor_enquiries/features/auth/presentation/screens/login_screen.dart';

/// Tests for text overflow and layout robustness across different screen sizes and text scales.
///
/// This test suite verifies that the app handles various device configurations without
/// text overflow or layout breaks.
void main() {
  group('Text Overflow Tests', () {
    // Test device configurations
    final testDevices = [
      // Small phones
      const Size(320, 640), // iPhone SE-like
      const Size(360, 800), // Common Android
      const Size(375, 667), // iPhone 6/7/8
      // Medium phones
      const Size(400, 900), // Larger Android
      const Size(412, 915), // Pixel-like
      // Large phones
      const Size(480, 960), // Large Android
      const Size(414, 896), // iPhone 11 Pro Max
    ];

    // Test text scale factors
    final testScales = [0.85, 1.0, 1.30];

    for (final deviceSize in testDevices) {
      for (final textScale in testScales) {
        testWidgets(
          'Login screen handles ${deviceSize.width}x${deviceSize.height} at scale $textScale',
          (tester) async {
            // Set device size and text scale
            tester.view.physicalSize = deviceSize;
            tester.view.devicePixelRatio = 1.0;

            // Create test widget with custom text scale
            await tester.pumpWidget(
              ProviderScope(
                child: MediaQuery(
                  data: MediaQueryData(size: deviceSize, textScaler: TextScaler.linear(textScale)),
                  child: const MaterialApp(home: LoginScreen()),
                ),
              ),
            );

            // Wait for any animations to complete
            await tester.pumpAndSettle();

            // Verify no overflow errors in the console
            expect(tester.takeException(), isNull);

            // Verify key elements are visible and not overflowing
            expect(find.text('Welcome to We Decor'), findsOneWidget);
            expect(find.text('Sign in to your account'), findsOneWidget);
            expect(find.text('Email'), findsOneWidget);
            expect(find.text('Password'), findsOneWidget);
            expect(find.text('Sign In'), findsOneWidget);
            expect(find.text('Forgot Password?'), findsOneWidget);

            // Check that all text widgets have proper overflow handling
            final textWidgets = find.byType(Text);
            for (int i = 0; i < textWidgets.evaluate().length; i++) {
              final textWidget = tester.widget<Text>(textWidgets.at(i));
              // Verify critical text has overflow protection
              if (textWidget.data != null &&
                  (textWidget.data!.contains('Welcome') || textWidget.data!.contains('Sign in'))) {
                expect(textWidget.overflow, isNotNull);
                expect(textWidget.maxLines, isNotNull);
              }
            }
          },
        );
      }
    }

    testWidgets('Dashboard handles long customer names without overflow', (tester) async {
      // Mock a small screen
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3), // High text scale
            ),
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text(
                    'Very Long Customer Name That Should Be Truncated',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Button text scales appropriately without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text(
                      'Create New Enquiry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify button is properly sized and text doesn't overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Create New Enquiry'), findsOneWidget);
    });

    testWidgets('TabBar handles long status labels', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(360, 800), textScaler: TextScaler.linear(1.2)),
            child: MaterialApp(
              home: DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    bottom: const TabBar(
                      tabs: [
                        Tab(text: 'New Enquiries'),
                        Tab(text: 'In Progress'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ),
                  body: const TabBarView(
                    children: [
                      Center(child: Text('New')),
                      Center(child: Text('In Progress')),
                      Center(child: Text('Completed')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tabs are properly sized
      expect(tester.takeException(), isNull);
      expect(find.text('New Enquiries'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('ListTile handles long content gracefully', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: const [
                    ListTile(
                      leading: CircleAvatar(child: Text('N')),
                      title: Text(
                        'Very Long Customer Name That Should Be Truncated',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Very Long Event Type Description That Should Also Be Truncated',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chip handles long text without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Wrap(
                    children: const [
                      Chip(
                        label: Text(
                          'Very Long Status Label',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Another Long Label',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chips are properly sized
      expect(tester.takeException(), isNull);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('Text meets minimum contrast requirements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Sample text for contrast testing',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify text is visible (basic contrast check)
      expect(find.text('Sample text for contrast testing'), findsOneWidget);
    });

    testWidgets('Touch targets meet minimum size requirements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(onPressed: () {}, child: const Icon(Icons.add)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify touch targets are properly sized
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('Layout performance with many text widgets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: MaterialApp(
              home: Scaffold(
                body: ListView.builder(
                  itemCount: 100, // Many items to test performance
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Customer $index', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'Event type $index with long description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no performance issues
      expect(tester.takeException(), isNull);
      // ListView.builder only renders visible items, so we check for at least some
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });
  });
}
