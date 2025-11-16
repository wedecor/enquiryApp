import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/status_validator.dart';

void main() {
  group('StatusValidator', () {
    group('canStaffTransition', () {
      test('allows transition from new to contacted', () {
        expect(canStaffTransition('new', 'contacted'), isTrue);
      });

      test('allows transition from new to cancelled', () {
        expect(canStaffTransition('new', 'cancelled'), isTrue);
      });

      test('disallows transition from new to quoted', () {
        expect(canStaffTransition('new', 'quoted'), isFalse);
      });

      test('allows transition from contacted to quoted', () {
        expect(canStaffTransition('contacted', 'quoted'), isTrue);
      });

      test('allows transition from contacted to cancelled', () {
        expect(canStaffTransition('contacted', 'cancelled'), isTrue);
      });

      test('disallows transition from contacted to new', () {
        expect(canStaffTransition('contacted', 'new'), isFalse);
      });

      test('allows transition from quoted to confirmed', () {
        expect(canStaffTransition('quoted', 'confirmed'), isTrue);
      });

      test('allows transition from quoted to cancelled', () {
        expect(canStaffTransition('quoted', 'cancelled'), isTrue);
      });

      test('allows transition from confirmed to in_talks', () {
        expect(canStaffTransition('confirmed', 'in_talks'), isTrue);
      });

      test('allows transition from confirmed to cancelled', () {
        expect(canStaffTransition('confirmed', 'cancelled'), isTrue);
      });

      test('allows transition from in_talks to completed', () {
        expect(canStaffTransition('in_talks', 'completed'), isTrue);
      });

      test('allows transition from in_talks to cancelled', () {
        expect(canStaffTransition('in_talks', 'cancelled'), isTrue);
      });

      test('disallows transition from completed to any status', () {
        expect(canStaffTransition('completed', 'new'), isFalse);
        expect(canStaffTransition('completed', 'contacted'), isFalse);
        expect(canStaffTransition('completed', 'quoted'), isFalse);
      });

      test('disallows transition from cancelled to any status', () {
        expect(canStaffTransition('cancelled', 'new'), isFalse);
        expect(canStaffTransition('cancelled', 'contacted'), isFalse);
        expect(canStaffTransition('cancelled', 'quoted'), isFalse);
      });

      test('disallows invalid transitions', () {
        expect(canStaffTransition('new', 'confirmed'), isFalse);
        expect(canStaffTransition('contacted', 'completed'), isFalse);
        expect(canStaffTransition('quoted', 'in_talks'), isFalse);
      });
    });
  });
}
