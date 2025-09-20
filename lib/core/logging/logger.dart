import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Structured logger with PII redaction for production safety
class Logger {
  static const String _name = 'WeDecorEnquiries';

  /// Log levels
  static const int _debugLevel = 0;
  static const int _infoLevel = 1;
  static const int _warnLevel = 2;
  static const int _errorLevel = 3;

  /// Email regex for PII redaction
  static final RegExp _emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');

  /// Phone regex for PII redaction
  static final RegExp _phoneRegex = RegExp(
    r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
  );

  /// Redact PII from log messages
  static String _redactPII(String message) {
    String redacted = message;

    // Redact email addresses
    redacted = redacted.replaceAll(_emailRegex, '[EMAIL_REDACTED]');

    // Redact phone numbers
    redacted = redacted.replaceAll(_phoneRegex, '[PHONE_REDACTED]');

    return redacted;
  }

  /// Debug logging (only in debug mode)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final redactedMessage = _redactPII(message);
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
    final redactedMessage = _redactPII(message);
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
    final redactedMessage = _redactPII(message);
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
    final redactedMessage = _redactPII(message);
    developer.log(
      redactedMessage,
      name: tag ?? _name,
      level: _errorLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Structured event logging for analytics
  static void logEvent(String event, Map<String, dynamic> parameters) {
    if (!kDebugMode) return;

    // Redact PII from parameters
    final redactedParams = <String, dynamic>{};
    for (final entry in parameters.entries) {
      if (entry.value is String) {
        redactedParams[entry.key] = _redactPII(entry.value as String);
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
