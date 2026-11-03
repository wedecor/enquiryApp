import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/dropdowns/domain/dropdown_item.dart';

void main() {
  group('DropdownGroup.fromCollectionPath', () {
    test('maps known paths', () {
      expect(DropdownGroup.fromCollectionPath('event_types'), DropdownGroup.eventTypes);
      expect(DropdownGroup.fromCollectionPath('sources'), DropdownGroup.sources);
      expect(DropdownGroup.fromCollectionPath('statuses'), DropdownGroup.statuses);
    });

    test('returns null for unknown paths', () {
      expect(DropdownGroup.fromCollectionPath('nope'), isNull);
      expect(DropdownGroup.fromCollectionPath(''), isNull);
    });
  });

  group('DropdownItem.valueFromLabel', () {
    test('slugifies labels like quickAdd', () {
      expect(DropdownItem.valueFromLabel('Corporate Event'), 'corporate_event');
      expect(DropdownItem.valueFromLabel('  Eng  '), 'eng');
      expect(DropdownItem.valueFromLabel('Baby Welcome!!!'), 'baby_welcome');
    });
  });

  group('DropdownItem.fromMap', () {
    test('uses defaults when fields are missing', () {
      final item = DropdownItem.fromMap('CGTtISmlgSp7Fnas5HKa', {
        'value': 'eng',
        'label': 'Eng',
        'order': 35,
        'active': true,
        // no createdAt / updatedAt — old quick-add
      });
      expect(item.value, 'eng');
      expect(item.label, 'Eng');
      expect(item.order, 35);
      expect(item.active, isTrue);
      expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(item.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('falls back to doc id when value/label missing', () {
      final item = DropdownItem.fromMap('wedding', const {});
      expect(item.value, 'wedding');
      expect(item.label, 'wedding');
      expect(item.order, 0);
      expect(item.active, isTrue);
    });

    test('reads Timestamps when present', () {
      final when = DateTime(2026, 10, 1, 12, 0);
      final ts = Timestamp.fromDate(when);
      final item = DropdownItem.fromMap('haldi', {
        'value': 'haldi',
        'label': 'Haldi',
        'order': 4,
        'active': true,
        'createdAt': ts,
        'updatedAt': ts,
      });
      expect(item.createdAt, when);
      expect(item.updatedAt, when);
    });
  });

  group('DropdownRepair', () {
    test('needsRelocate when doc id is not the value', () {
      expect(DropdownRepair.needsRelocate('CGTtISmlgSp7Fnas5HKa', 'eng'), isTrue);
      expect(DropdownRepair.needsRelocate('eng', 'eng'), isFalse);
      expect(DropdownRepair.needsRelocate('eng', null), isFalse);
      expect(DropdownRepair.needsRelocate('eng', '  '), isFalse);
    });

    test('missingFields fills only what is absent', () {
      expect(
        DropdownRepair.missingFields({
          'value': 'eng',
          'label': 'Eng',
          'order': 1,
          'active': true,
        }, 'x'),
        isEmpty,
      );
      expect(DropdownRepair.missingFields({'value': 'eng'}, 'CGTt'), {
        'label': 'eng',
        'order': 0,
        'active': true,
      });
    });
  });
}
