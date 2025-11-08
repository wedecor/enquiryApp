import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Centralized logging utility with basic redaction for secrets/PII.
class Log {
  Log._();

  static final RegExp _secretLike = RegExp(
    r'(bearer\s+[A-Za-z0-9._-]+|authorization|api[_-]?key|token|session|cookie|password|secret|access[_-]?token)',
    caseSensitive: false,
  );

  static final RegExp _emailLike = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');

  static final RegExp _phoneLike = RegExp(r'\b(?:\+?\d[\d -]{7,}\d)\b');

  static String _redact(String value) {
    var sanitized = value;
    sanitized = sanitized.replaceAllMapped(_secretLike, (match) => _mask(match.group(0) ?? ''));
    sanitized = sanitized.replaceAllMapped(_emailLike, (match) => _mask(match.group(0) ?? ''));
    sanitized = sanitized.replaceAllMapped(_phoneLike, (match) => _mask(match.group(0) ?? ''));
    return sanitized;
  }

  static String _mask(String value) {
    if (value.length <= 6) {
      return '***';
    }
    const keep = 3;
    return '${value.substring(0, keep)}***${value.substring(value.length - keep)}';
  }

  static String _formatMessage(String level, String message, Object? data) {
    final msg = _redact(message);
    if (data == null) return '[$level] $msg';
    return '[$level] $msg | ${_redact(data.toString())}';
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
