import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../core/logging/redaction.dart';

/// Centralized logging utility with PII redaction.
class Log {
  Log._();

  static String _formatMessage(String level, String message, Object? data) {
    final msg = redactSensitiveText(message);
    if (data == null) return '[$level] $msg';
    return '[$level] $msg | ${redactSensitiveText(data.toString())}';
  }

  static void d(String message, {Object? data}) {
    if (kReleaseMode) {
      return;
    }
    dev.log(_formatMessage('D', message, data), name: 'wedecor');
  }

  static void i(String message, {Object? data}) {
    dev.log(_formatMessage('I', message, data), name: 'wedecor');
  }

  static void w(String message, {Object? data}) {
    dev.log(_formatMessage('W', message, data), name: 'wedecor', level: 900);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace, Object? data}) {
    dev.log(
      _formatMessage('E', message, data ?? error),
      name: 'wedecor',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
