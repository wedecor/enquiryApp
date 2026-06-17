import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'redaction.dart';

/// Structured logger with PII redaction for production safety
class Logger {
  static const String _name = 'WeDecorEnquiries';
  static const int _maxLogBufferSize = 300;

  /// Log levels
  static const int _debugLevel = 0;
  static const int _infoLevel = 1;
  static const int _warnLevel = 2;
  static const int _errorLevel = 3;

  /// In-memory log buffer for feedback collection
  static final List<String> _logBuffer = [];

  /// Add log entry to in-memory buffer for feedback collection
  static void _addToBuffer(String level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$level] [${tag ?? _name}] $message';

    _logBuffer.add(logEntry);

    // Keep buffer size manageable
    if (_logBuffer.length > _maxLogBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  /// Debug logging (only in debug mode)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final redactedMessage = redactSensitiveText(message);
    _addToBuffer('DEBUG', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _debugLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Info logging
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final redactedMessage = redactSensitiveText(message);
    _addToBuffer('INFO', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _infoLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Warning logging
  static void warn(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final redactedMessage = redactSensitiveText(message);
    _addToBuffer('WARN', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _warnLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error logging
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final redactedMessage = redactSensitiveText(message);
    _addToBuffer('ERROR', redactedMessage, tag: tag);

    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _errorLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Collect recent logs for feedback submission (PII-safe)
  static String collectLogBundle() {
    if (_logBuffer.isEmpty) {
      return 'No recent logs available';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== RECENT APP LOGS (LAST ${_logBuffer.length} ENTRIES) ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (final logEntry in _logBuffer) {
      buffer.writeln(logEntry);
    }

    buffer.writeln('');
    buffer.writeln('=== END LOGS ===');

    return buffer.toString();
  }

  /// Clear log buffer (for testing or privacy)
  static void clearLogBuffer() {
    _logBuffer.clear();
    info('Log buffer cleared');
  }

  /// Get current log buffer size
  static int get logBufferSize => _logBuffer.length;

  /// Structured event logging for analytics
  static void logEvent(String event, Map<String, dynamic> parameters) {
    if (!kDebugMode) return;

    // Redact PII from parameters
    final redactedParams = <String, dynamic>{};
    for (final entry in parameters.entries) {
      if (entry.value is String) {
        redactedParams[entry.key] = redactSensitiveText(entry.value as String);
      } else {
        redactedParams[entry.key] = entry.value;
      }
    }

    developer.log('Event: $event', name: '${_name}_Analytics', level: _infoLevel);

    for (final entry in redactedParams.entries) {
      developer.log(
        '  ${entry.key}: ${entry.value}',
        name: '${_name}_Analytics',
        level: _infoLevel,
      );
    }
  }

  /// Performance logging
  static void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
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
