import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'redaction.dart';

/// Formats optional structured log data with key-aware PII redaction.
String formatLogData(Object? data) {
  if (data == null) return '';
  if (data is Map) {
    final redacted = <String, Object?>{};
    for (final entry in data.entries) {
      redacted[entry.key.toString()] = redactMapEntry(
        entry.key.toString(),
        entry.value,
      );
    }
    return redacted.toString();
  }
  return redactSensitiveText(data.toString());
}

String _withOptionalData(String message, {Object? data}) {
  final redactedMessage = redactSensitiveText(message);
  if (data == null) return redactedMessage;
  return '$redactedMessage | ${formatLogData(data)}';
}

/// Compact logging API used across most of the app.
class Log {
  Log._();

  static void d(String message, {Object? data}) {
    Logger.debug(message, data: data);
  }

  static void i(String message, {Object? data}) {
    Logger.info(message, data: data);
  }

  static void w(String message, {Object? data}) {
    Logger.warn(message, data: data);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    Logger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      data: data ?? error,
    );
  }
}

/// Structured logger with PII redaction and an in-memory buffer for feedback.
class Logger {
  static const String _name = 'WeDecorEnquiries';
  static const int _maxLogBufferSize = 300;

  static const int _debugLevel = 0;
  static const int _infoLevel = 1;
  static const int _warnLevel = 2;
  static const int _errorLevel = 3;

  static final List<String> _logBuffer = [];

  static void _addToBuffer(String level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$level] [${tag ?? _name}] $message';

    _logBuffer.add(logEntry);

    if (_logBuffer.length > _maxLogBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  static void debug(
    String message, {
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final redactedMessage = _withOptionalData(message, data: data);
    _addToBuffer('DEBUG', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _debugLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(
    String message, {
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final redactedMessage = _withOptionalData(message, data: data);
    _addToBuffer('INFO', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _infoLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warn(
    String message, {
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final redactedMessage = _withOptionalData(message, data: data);
    _addToBuffer('WARN', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _warnLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final redactedMessage = _withOptionalData(message, data: data);
    _addToBuffer('ERROR', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _errorLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String collectLogBundle() {
    if (_logBuffer.isEmpty) {
      return 'No recent logs available';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '=== RECENT APP LOGS (LAST ${_logBuffer.length} ENTRIES) ===',
    );
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (final logEntry in _logBuffer) {
      buffer.writeln(logEntry);
    }

    buffer.writeln('');
    buffer.writeln('=== END LOGS ===');

    return buffer.toString();
  }

  static void clearLogBuffer() {
    _logBuffer.clear();
    info('Log buffer cleared');
  }

  static int get logBufferSize => _logBuffer.length;

  static void logEvent(String event, Map<String, dynamic> parameters) {
    if (!kDebugMode) return;

    final redactedParams = <String, dynamic>{};
    for (final entry in parameters.entries) {
      redactedParams[entry.key] = redactMapEntry(entry.key, entry.value);
    }

    developer.log(
      'Event: $event',
      name: '${_name}_Analytics',
      level: _infoLevel,
    );

    for (final entry in redactedParams.entries) {
      developer.log(
        '  ${entry.key}: ${entry.value}',
        name: '${_name}_Analytics',
        level: _infoLevel,
      );
    }
  }

  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    developer.log(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      name: '${_name}_Performance',
      level: _infoLevel,
    );

    if (metadata != null) {
      for (final entry in metadata.entries) {
        developer.log(
          '  ${entry.key}: ${entry.value}',
          name: '${_name}_Performance',
          level: _infoLevel,
        );
      }
    }
  }
}
