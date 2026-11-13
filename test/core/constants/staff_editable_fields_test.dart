import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/staff_editable_fields.dart';

void main() {
  test('staffEditableFields in Dart matches staffEditableFields() in firestore.rules', () {
    final rules = File('firestore.rules').readAsStringSync();
    final match = RegExp(
      r'function\s+staffEditableFields\(\)\s*\{\s*return\s*\[([\s\S]*?)\];\s*\}',
    ).firstMatch(rules);
    expect(match, isNotNull, reason: 'staffEditableFields() not found in firestore.rules');

    final rulesFields = RegExp(
      r"'([^']+)'",
    ).allMatches(match!.group(1)!).map((m) => m.group(1)!).toList();

    expect(staffEditableFields.toSet(), equals(rulesFields.toSet()));
    expect(staffEditableFields.length, equals(rulesFields.length));
  });
}
