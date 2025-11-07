import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Fail if any code writes fcmToken/webTokens directly into users/{uid}.
/// Allowed: tokens only under users/{uid}/private/notifications/tokens/{token}.
void main() {
  test('No direct writes of fcmToken/webTokens to users/{uid}', () {
    final root = Directory('lib');
    final violations = <String>[];

    final fileList = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart') && !f.path.endsWith('.freezed.dart'))
        .toList();

    final writePattern = RegExp(
      r"collection\(['\x22\x27]users[\x22\x27]\)\s*\.doc\([^\)]*\)\s*\.\s*(set|update)\s*\(\s*\{[\s\S]*?(fcmToken|webTokens)\s*:",
      multiLine: true,
    );

    for (final file in fileList) {
      final text = file.readAsStringSync();
      if (writePattern.hasMatch(text)) {
        violations.add(file.path);
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found direct writes of fcmToken/webTokens into users/{uid} in:\n'
        '${violations.map((p) => '- $p').join('\n')}\n'
        'Store tokens under users/{uid}/private/notifications/tokens/{token} instead.',
      );
    }
  });
}
