/// Safe logging utility to prevent accidental exposure of sensitive data
///
/// This utility automatically redacts sensitive fields from log output
/// to prevent tokens, passwords, and other secrets from appearing in logs.
library;

/// Redacts sensitive values based on key names
String _redact(String key, Object? value) {
  final keyLower = key.toLowerCase();

  // List of sensitive key patterns
  const sensitivePatterns = [
    'token',
    'authorization',
    'cookie',
    'secret',
    'key',
    'password',
    'auth',
    'bearer',
    'jwt',
    'session',
    'credential',
    'private',
    'fcm',
    'vapid',
  ];

  // Check if key contains any sensitive patterns
  final isSensitive = sensitivePatterns.any((pattern) => keyLower.contains(pattern));

  if (isSensitive) {
    if (value == null) return 'null';

    final valueStr = value.toString();
    if (valueStr.isEmpty) return '(empty)';

    // Show type and length instead of actual value
    if (valueStr.length <= 4) {
      return '***';
    } else {
      return '${valueStr.substring(0, 2)}***${valueStr.substring(valueStr.length - 2)} (${valueStr.length} chars)';
    }
  }

  return (value ?? 'null').toString();
}

/// Safely logs a map by redacting sensitive fields
///
/// Example:
/// ```dart
/// safeLog('Push summary', {
///   'uid': 'user123',
///   'tokens': ['token1', 'token2'],  // Will be redacted
///   'success': 2,
/// });
/// ```
///
/// Output: `Push summary {uid: user123, tokens: to***en (6 chars), success: 2}`
void safeLog(String label, Map<String, Object?> data) {
  final redacted = data.map((key, value) => MapEntry(key, _redact(key, value)));

  // ignore: avoid_print
  print('$label $redacted');
}

/// Safely logs any object by converting to string and checking for sensitive patterns
///
/// Example:
/// ```dart
/// safeLogObject('User data', userObject);
/// ```
void safeLogObject(String label, Object? object) {
  if (object == null) {
    // ignore: avoid_print
    print('$label null');
    return;
  }

  final objectStr = object.toString();

  // Check if the string representation contains sensitive patterns
  const sensitivePatterns = ['token', 'authorization', 'secret', 'key', 'password'];

  final containsSensitive = sensitivePatterns.any(
    (pattern) => objectStr.toLowerCase().contains(pattern),
  );

  if (containsSensitive) {
    // ignore: avoid_print
    print('$label [REDACTED - contains sensitive data] (${objectStr.length} chars)');
  } else {
    // ignore: avoid_print
    print('$label $objectStr');
  }
}

/// Creates a safe version of a map for logging
///
/// Returns a new map with sensitive values redacted
Map<String, Object?> createSafeLogMap(Map<String, Object?> data) {
  return data.map((key, value) => MapEntry(key, _redact(key, value)));
}

/// Extension on Map to add safe logging methods
extension SafeLogMap on Map<String, Object?> {
  /// Returns a copy of this map with sensitive values redacted
  Map<String, Object?> get redacted => createSafeLogMap(this);

  /// Safely logs this map
  void logSafely(String label) => safeLog(label, this);
}
