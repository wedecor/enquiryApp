/// Shared helpers for canonical vs legacy enquiry Firestore fields.

/// Notes text — prefers `notes`, falls back to legacy `description`.
String? enquiryNotesFrom(Map<String, dynamic> data) {
  final notes = data['notes'] as String?;
  if (notes != null && notes.trim().isNotEmpty) return notes.trim();
  final description = data['description'] as String?;
  if (description != null && description.trim().isNotEmpty)
    return description.trim();
  return null;
}

/// Read a string field with canonical + legacy fallback.
String canonicalFieldString(
  Map<String, dynamic> data,
  String canonicalKey,
  String legacyKey,
) {
  final canonical = data[canonicalKey] as String?;
  if (canonical != null && canonical.trim().isNotEmpty) return canonical.trim();
  final legacy = data[legacyKey] as String?;
  return legacy?.trim() ?? '';
}

/// Notes write map with plain strings (mirrors to legacy `description`).
Map<String, String> enquiryNotesFields(String? text) {
  final trimmed = text?.trim() ?? '';
  if (trimmed.isEmpty) return const {};
  return {'notes': trimmed, 'description': trimmed};
}
