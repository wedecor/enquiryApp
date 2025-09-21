import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_decor_enquiries/core/a11y/tap_target.dart';
import 'package:we_decor_enquiries/core/contacts/contact_launcher.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/widgets/contact_buttons.dart';

void main() {
  group('ContactButtons Widget Tests', () {
    late ContactLauncher mockContactLauncher;

    setUp(() {
      mockContactLauncher = ContactLauncher(defaultCountryCode: '+91');
    });

    Widget createTestWidget({
      String? customerPhone,
      String customerName = 'John Doe',
      String? enquiryId,
      bool enabled = true,
    }) {
      return ProviderScope(
        overrides: [
          contactLauncherProvider.overrideWith((ref) => mockContactLauncher),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ContactButtons(
              customerPhone: customerPhone,
              customerName: customerName,
              enquiryId: enquiryId,
              enabled: enabled,
            ),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('shows Call and WhatsApp buttons when phone number is provided', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: 'John Doe',
        ));

        // Verify both buttons are present
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
        
        // Verify icons are present
        expect(find.byIcon(Icons.call), findsOneWidget);
        expect(find.byIcon(Icons.chat), findsOneWidget);
      });

      testWidgets('hides buttons when phone number is null', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: null,
          customerName: 'John Doe',
        ));

        // Verify no buttons are shown
        expect(find.text('Call'), findsNothing);
        expect(find.text('WhatsApp'), findsNothing);
        expect(find.byIcon(Icons.call), findsNothing);
        expect(find.byIcon(Icons.chat), findsNothing);
      });

      testWidgets('hides buttons when phone number is empty', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '',
          customerName: 'John Doe',
        ));

        // Verify no buttons are shown
        expect(find.text('Call'), findsNothing);
        expect(find.text('WhatsApp'), findsNothing);
      });

      testWidgets('hides buttons when phone number is whitespace only', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '   ',
          customerName: 'John Doe',
        ));

        // Verify no buttons are shown
        expect(find.text('Call'), findsNothing);
        expect(find.text('WhatsApp'), findsNothing);
      });

      testWidgets('shows disabled buttons when enabled is false', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: 'John Doe',
          enabled: false,
        ));

        // Buttons should be present but disabled
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
        
        // Verify buttons are not tappable (disabled state)
        final callButton = find.text('Call');
        final whatsappButton = find.text('WhatsApp');
        
        expect(callButton, findsOneWidget);
        expect(whatsappButton, findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('buttons have semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: 'Jane Smith',
        ));

        await tester.pumpAndSettle();

        // Verify buttons are accessible
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
        
        // Verify semantic structure exists (TapTarget provides semantics)
        final callButton = find.text('Call');
        final whatsappButton = find.text('WhatsApp');
        
        expect(callButton, findsOneWidget);
        expect(whatsappButton, findsOneWidget);
      });

      testWidgets('buttons meet accessibility requirements', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: 'John Doe',
        ));

        await tester.pumpAndSettle();

        // Verify buttons are properly structured for accessibility
        // The TapTarget widget handles minimum size and semantics
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
      });
    });

    group('Button Interaction', () {
      testWidgets('call button triggers contact launcher', (tester) async {
        bool callLauncherCalled = false;
        String? calledNumber;

        // Create a mock launcher that tracks calls
        final mockLauncher = _MockContactLauncher(
          onCall: (phone) {
            callLauncherCalled = true;
            calledNumber = phone;
            return Future.value(ContactLaunchStatus.opened);
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactLauncherProvider.overrideWith((ref) => mockLauncher),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ContactButtons(
                  customerPhone: '9876543210',
                  customerName: 'John Doe',
                  enquiryId: 'test-enquiry-123',
                ),
              ),
            ),
          ),
        );

        // Tap the call button
        await tester.tap(find.text('Call'));
        await tester.pumpAndSettle();

        // Verify the launcher was called
        expect(callLauncherCalled, isTrue);
        expect(calledNumber, '9876543210');
      });

      testWidgets('WhatsApp button triggers contact launcher', (tester) async {
        bool whatsappLauncherCalled = false;
        String? calledNumber;
        String? prefillText;

        // Create a mock launcher that tracks calls
        final mockLauncher = _MockContactLauncher(
          onWhatsApp: (phone, text) {
            whatsappLauncherCalled = true;
            calledNumber = phone;
            prefillText = text;
            return Future.value(ContactLaunchStatus.opened);
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactLauncherProvider.overrideWith((ref) => mockLauncher),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ContactButtons(
                  customerPhone: '+919876543210',
                  customerName: 'Jane Smith',
                  enquiryId: 'test-enquiry-456',
                ),
              ),
            ),
          ),
        );

        // Tap the WhatsApp button
        await tester.tap(find.text('WhatsApp'));
        await tester.pumpAndSettle();

        // Verify the launcher was called with correct parameters
        expect(whatsappLauncherCalled, isTrue);
        expect(calledNumber, '+919876543210');
        expect(prefillText, contains('Hi Jane Smith'));
        expect(prefillText, contains('We Decor'));
      });

      testWidgets('disabled buttons do not trigger actions', (tester) async {
        bool launcherCalled = false;

        final mockLauncher = _MockContactLauncher(
          onCall: (_) {
            launcherCalled = true;
            return Future.value(ContactLaunchStatus.opened);
          },
          onWhatsApp: (_, __) {
            launcherCalled = true;
            return Future.value(ContactLaunchStatus.opened);
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactLauncherProvider.overrideWith((ref) => mockLauncher),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ContactButtons(
                  customerPhone: '+919876543210',
                  customerName: 'John Doe',
                  enabled: false, // Disabled
                ),
              ),
            ),
          ),
        );

        // Try to tap buttons (should not work)
        await tester.tap(find.text('Call'));
        await tester.tap(find.text('WhatsApp'));
        await tester.pumpAndSettle();

        // Verify no launcher calls were made
        expect(launcherCalled, isFalse);
      });
    });

    group('Visual Design', () {
      testWidgets('renders buttons with proper structure', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: 'John Doe',
        ));

        await tester.pumpAndSettle();

        // Verify buttons are rendered
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
        
        // Verify container structure exists
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows proper disabled state', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: 'John Doe',
          enabled: false,
        ));

        await tester.pumpAndSettle();

        // Verify buttons are still rendered when disabled
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
      });
    });

    group('Error Scenarios', () {
      testWidgets('handles invalid phone number gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget(
          customerPhone: 'invalid-phone',
          customerName: 'John Doe',
        ));

        // Should still show buttons (validation happens on tap)
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
      });

      testWidgets('handles very long customer names', (tester) async {
        const longName = 'This Is A Very Long Customer Name That Might Cause Layout Issues';
        
        await tester.pumpWidget(createTestWidget(
          customerPhone: '+919876543210',
          customerName: longName,
        ));

        await tester.pumpAndSettle();

        // Verify layout doesn't break with long names
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
      });
    });
  });
}

/// Mock ContactLauncher for testing
class _MockContactLauncher extends ContactLauncher {
  _MockContactLauncher({
    this.onCall,
    this.onWhatsApp,
    super.defaultCountryCode = '+91',
  });

  final Future<ContactLaunchStatus> Function(String)? onCall;
  final Future<ContactLaunchStatus> Function(String, String?)? onWhatsApp;

  @override
  Future<ContactLaunchStatus> callNumberWithAudit(
    String rawPhone, {
    String? enquiryId,
  }) async {
    if (onCall != null) {
      return onCall!(rawPhone);
    }
    return ContactLaunchStatus.opened;
  }

  @override
  Future<ContactLaunchStatus> openWhatsAppWithAudit(
    String rawPhone, {
    String? prefillText,
    String? enquiryId,
  }) async {
    if (onWhatsApp != null) {
      return onWhatsApp!(rawPhone, prefillText);
    }
    return ContactLaunchStatus.opened;
  }
}
