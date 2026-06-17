/// Safe logging utility to prevent accidental exposure of sensitive data.
library;

import 'redaction.dart';
import 'logger.dart';

/// Safely logs a map by redacting sensitive fields and embedded PII.
void safeLog(String label, Map<String, Object?> data) {
  final redacted = data.map((key, value) => MapEntry(key, redactMapEntry(key, value)));
  Log.i(label, data: redacted);
}

/// Safely logs any object by converting to string and redacting PII.
void safeLogObject(String label, Object? object) {
  if (object == null) {
    Log.i(label, data: 'null');
    return;
  }

  Log.i(label, data: redactSensitiveText(object.toString()));
}

/// Returns a copy of [data] with sensitive values redacted.
Map<String, Object?> createSafeLogMap(Map<String, Object?> data) {
  return data.map((key, value) => MapEntry(key, redactMapEntry(key, value)));
}

/// Extension on Map to add safe logging methods.
extension SafeLogMap on Map<String, Object?> {
  /// Returns a copy of this map with sensitive values redacted.
  Map<String, Object?> get redacted => createSafeLogMap(this);

  /// Safely logs this map.
  void logSafely(String label) => safeLog(label, this);
}
