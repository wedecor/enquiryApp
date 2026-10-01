/// Shared PII/secret redaction for all logging paths.
library;

final RegExp _secretLike = RegExp(
  r'(bearer\s+[A-Za-z0-9._-]+|authorization|api[_-]?key|token|session|cookie|password|secret|access[_-]?token)',
  caseSensitive: false,
);

final RegExp _emailLike = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');

final RegExp _phoneLike = RegExp(r'\b(?:\+?\d[\d -]{7,}\d)\b');

const List<String> _sensitiveKeyPatterns = [
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
  'phone',
  'mobile',
  'email',
  'contact',
];

/// Masks a sensitive value while preserving length hints for debugging.
String maskSensitiveValue(String value) {
  if (value.isEmpty) return '(empty)';
  if (value.length <= 4) return '***';
  return '${value.substring(0, 2)}***${value.substring(value.length - 2)} (${value.length} chars)';
}

/// Redacts emails, phone numbers, and secret-like substrings from free text.
String redactSensitiveText(String value) {
  var sanitized = value;
  sanitized = sanitized.replaceAllMapped(_secretLike, (m) => maskSensitiveValue(m.group(0) ?? ''));
  sanitized = sanitized.replaceAllMapped(_emailLike, (m) => maskSensitiveValue(m.group(0) ?? ''));
  sanitized = sanitized.replaceAllMapped(_phoneLike, (m) => maskSensitiveValue(m.group(0) ?? ''));
  return sanitized;
}

bool isSensitiveLogKey(String key) {
  final keyLower = key.toLowerCase();
  return _sensitiveKeyPatterns.any(keyLower.contains);
}

/// Redacts a map entry using key name and embedded PII in the value.
String redactMapEntry(String key, Object? value) {
  if (value == null) return 'null';

  final valueStr = value.toString();
  if (isSensitiveLogKey(key)) {
    return maskSensitiveValue(valueStr);
  }

  return redactSensitiveText(valueStr);
}
