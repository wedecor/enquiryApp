import 'package:flutter/material.dart';

import '../../features/enquiries/presentation/widgets/enquiry_status_control.dart';

/// Resolves a pipeline status color: Firestore dropdown first, then theme fallback.
Color resolveStatusColor(
  BuildContext context,
  String? status, {
  Map<String, Color>? firestoreColors,
}) {
  final key = (status ?? '').trim().toLowerCase();
  if (key.isNotEmpty) {
    final fromDb = firestoreColors?[key];
    if (fromDb != null) return fromDb;
  }
  return statusColorFor(context, key.isEmpty ? null : key);
}
