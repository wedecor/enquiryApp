import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/contacts/contact_launcher.dart';
import 'package:we_decor_enquiries/features/reengagement/presentation/reengagement_actions.dart';

void main() {
  late ContactLauncher launcher;

  setUp(() {
    launcher = ContactLauncher(defaultCountryCode: '+91');
  });

  group('resolveWishPhone', () {
    test('uses customerPhone when it normalizes to 10+ digits', () {
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: '9876543210',
          phoneNormalized: '1111111111',
        ),
        '9876543210',
      );
    });

    test('falls back to phoneNormalized when customerPhone is blank', () {
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: null,
          phoneNormalized: '9876543210',
        ),
        '9876543210',
      );
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: '   ',
          phoneNormalized: '9876543210',
        ),
        '9876543210',
      );
    });

    test('falls back when customerPhone normalizes to fewer than 10 digits', () {
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: '12345',
          phoneNormalized: '9876543210',
        ),
        '9876543210',
      );
    });

    test('returns null only when both are unusable', () {
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: null,
          phoneNormalized: '',
        ),
        isNull,
      );
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: '12',
          phoneNormalized: '34',
        ),
        isNull,
      );
    });

    test('accepts 12-digit 91-prefixed customerPhone after normalize rewrite', () {
      expect(
        ReengagementActions.resolveWishPhone(
          launcher,
          customerPhone: '919876543210',
          phoneNormalized: '',
        ),
        '919876543210',
      );
    });
  });
}
