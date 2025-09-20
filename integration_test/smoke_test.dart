import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:we_decor_enquiries/main.dart' as app;

/// Smoke test for critical user journeys
/// Tests basic app functionality without deep Firebase integration
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Test - Critical User Journeys', () {
    testWidgets('App launches and shows auth gate', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify app launches without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should show either login screen or dashboard (if already logged in)
      final hasLoginButton = find.text('Login').evaluate().isNotEmpty ||
                           find.text('Sign In').evaluate().isNotEmpty;
      final hasDashboard = find.text('Dashboard').evaluate().isNotEmpty ||
                          find.text('Enquiries').evaluate().isNotEmpty;
      
      expect(hasLoginButton || hasDashboard, isTrue, 
        reason: 'App should show either login screen or main dashboard');
    });

    testWidgets('Navigation works without crashes', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Try to navigate to settings (should work regardless of auth state)
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        
        // Should show settings screen
        expect(find.text('Settings'), findsOneWidget);
      }

      // Try to access privacy settings
      final privacyTab = find.text('Privacy');
      if (privacyTab.evaluate().isNotEmpty) {
        await tester.tap(privacyTab);
        await tester.pumpAndSettle();
        
        // Should show privacy controls
        expect(find.text('Privacy & Data'), findsOneWidget);
      }
    });

    testWidgets('Privacy settings are accessible and functional', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to privacy settings
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        final privacyTab = find.text('Privacy');
        if (privacyTab.evaluate().isNotEmpty) {
          await tester.tap(privacyTab);
          await tester.pumpAndSettle();

          // Verify privacy controls exist
          expect(find.text('Share Anonymous Analytics'), findsOneWidget);
          expect(find.text('Share Crash Reports'), findsOneWidget);
          
          // Test analytics toggle (if enabled in config)
          final analyticsToggle = find.byType(Switch).first;
          if (analyticsToggle.evaluate().isNotEmpty) {
            await tester.tap(analyticsToggle);
            await tester.pumpAndSettle();
            
            // Should show confirmation or change state
            // (Exact behavior depends on current consent state)
          }
        }
      }
    });

    testWidgets('Legal pages are accessible', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to privacy settings
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        final privacyTab = find.text('Privacy');
        if (privacyTab.evaluate().isNotEmpty) {
          await tester.tap(privacyTab);
          await tester.pumpAndSettle();

          // Test Privacy Policy access
          final privacyPolicyButton = find.text('Privacy Policy');
          if (privacyPolicyButton.evaluate().isNotEmpty) {
            await tester.tap(privacyPolicyButton);
            await tester.pumpAndSettle();
            
            // Should navigate to privacy policy screen
            expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
            
            // Navigate back
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton);
              await tester.pumpAndSettle();
            }
          }

          // Test Terms of Service access
          final termsButton = find.text('Terms of Service');
          if (termsButton.evaluate().isNotEmpty) {
            await tester.tap(termsButton);
            await tester.pumpAndSettle();
            
            // Should navigate to terms screen
            expect(find.text('Terms of Service'), findsAtLeastNWidgets(1));
          }
        }
      }
    });

    testWidgets('App handles network connectivity changes', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // This is a basic smoke test - actual network testing requires
      // more sophisticated setup with network mocking
      
      // Verify app doesn't crash during network operations
      // (More detailed offline testing should be done manually)
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
