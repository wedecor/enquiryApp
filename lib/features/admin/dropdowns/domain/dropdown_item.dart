import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dropdown_item.freezed.dart';
part 'dropdown_item.g.dart';

/// Enum representing different dropdown groups in the system
enum DropdownGroup {
  statuses,
  eventTypes,
  priorities,
  paymentStatuses,
  sources;

  /// Display name for the dropdown group
  String get displayName {
    switch (this) {
      case DropdownGroup.statuses:
        return 'Statuses';
      case DropdownGroup.eventTypes:
        return 'Event Types';
      case DropdownGroup.priorities:
        return 'Priorities';
      case DropdownGroup.paymentStatuses:
        return 'Payment Statuses';
      case DropdownGroup.sources:
        return 'Lead Sources';
    }
  }

  /// The group stored at `dropdowns/{path}`, or null for an unknown path.
  static DropdownGroup? fromCollectionPath(String path) {
    for (final group in DropdownGroup.values) {
      if (group.collectionPath == path) return group;
    }
    return null;
  }

  /// Firestore collection path for the group
  String get collectionPath {
    switch (this) {
      case DropdownGroup.statuses:
        return 'statuses';
      case DropdownGroup.eventTypes:
        return 'event_types';
      case DropdownGroup.priorities:
        return 'priorities';
      case DropdownGroup.paymentStatuses:
        return 'payment_statuses';
      case DropdownGroup.sources:
        return 'sources';
    }
  }

  /// Corresponding enquiry field names for reference checking and replacement
  List<String> get enquiryFieldNames {
    switch (this) {
      case DropdownGroup.statuses:
        return const ['statusValue'];
      case DropdownGroup.eventTypes:
        return const ['eventTypeValue', 'eventType'];
      case DropdownGroup.priorities:
        return const ['priorityValue', 'priority'];
      case DropdownGroup.paymentStatuses:
        return const ['paymentStatusValue', 'paymentStatus'];
      case DropdownGroup.sources:
        return const ['sourceValue', 'source'];
    }
  }

  /// Corresponding enquiry label field, if one exists for this group.
  String? get enquiryLabelFieldName {
    switch (this) {
      case DropdownGroup.statuses:
        return 'statusLabel';
      case DropdownGroup.eventTypes:
        return 'eventTypeLabel';
      case DropdownGroup.priorities:
        return 'priorityLabel';
      case DropdownGroup.paymentStatuses:
        return 'paymentStatusLabel';
      case DropdownGroup.sources:
        return 'sourceLabel';
    }
  }
}

/// Model representing a dropdown item in the system
@freezed
class DropdownItem with _$DropdownItem {
  const factory DropdownItem({
    required String value,
    required String label,
    required int order,
    required bool active,
    String? color,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DropdownItem;

  factory DropdownItem.fromJson(Map<String, dynamic> json) => _$DropdownItemFromJson(json);

  /// Create a DropdownItem from Firestore document
  factory DropdownItem.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return DropdownItem.fromMap(doc.id, data);
  }

  /// Tolerant parse used by [fromFirestore] and unit tests.
  ///
  /// One bad or half-written item (pending server timestamp, old quick-add
  /// without `updatedAt`, random doc id) must not blank the whole list.
  /// Prefer the stored `value` field so enquiry reference checks and delete
  /// use the semantic value even before [DropdownsRepository.repairGroup]
  /// moves the doc to `items/{value}`.
  factory DropdownItem.fromMap(String docId, Map<String, dynamic> data) {
    DateTime when(Object? raw) =>
        raw is Timestamp ? raw.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
    final storedValue = _asTrimmedString(data['value']);
    final label = _asTrimmedString(data['label']);
    final color = _asTrimmedString(data['color']);
    return DropdownItem(
      value: storedValue != null && storedValue.isNotEmpty ? storedValue : docId,
      label: label == null || label.isEmpty ? (storedValue ?? docId) : label,
      order: _asOrder(data['order']),
      active: _asActive(data['active']),
      color: color,
      createdAt: when(data['createdAt']),
      updatedAt: when(data['updatedAt']),
    );
  }

  static String? _asTrimmedString(Object? raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (raw is num || raw is bool) return raw.toString();
    return null;
  }

  static int _asOrder(Object? raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  /// Missing / unknown `active` counts as active (matches website loadEventTypes).
  static bool _asActive(Object? raw) {
    if (raw is bool) return raw;
    if (raw == 1 || raw == '1' || raw == 'true') return true;
    if (raw == 0 || raw == '0' || raw == 'false') return false;
    return true;
  }

  /// Slug used as the Firestore doc id / `value` for a typed label.
  static String valueFromLabel(String label) {
    return label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

/// Pure helpers for [DropdownsRepository.repairGroup] (unit-tested).
class DropdownRepair {
  DropdownRepair._();

  /// Fields to fill on a half-written item. Empty when the doc is already complete.
  static Map<String, Object> missingFields(Map<String, dynamic> data, String docId) {
    final value = (data['value'] as String?)?.trim();
    return {
      if (data['label'] is! String) 'label': value ?? docId,
      if (data['order'] is! num) 'order': 0,
      if (data['active'] is! bool) 'active': true,
    };
  }

  /// True when the item was saved under a random id and should move to `items/{value}`.
  static bool needsRelocate(String docId, String? value) {
    final v = value?.trim();
    return v != null && v.isNotEmpty && v != docId;
  }
}

/// Input model for creating/updating dropdown items
@freezed
class DropdownItemInput with _$DropdownItemInput {
  const factory DropdownItemInput({
    required String value,
    required String label,
    String? color,
    @Default(true) bool active,
  }) = _DropdownItemInput;
}

/// Extension methods for DropdownItem
extension DropdownItemExtensions on DropdownItem {
  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'value': value,
      'label': label,
      'order': order,
      'active': active,
      if (color != null) 'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with updated timestamp
  DropdownItem copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}

/// Extension methods for DropdownItemInput
extension DropdownItemInputExtensions on DropdownItemInput {
  /// Convert to DropdownItem with order
  DropdownItem toDropdownItem(int order) {
    final now = DateTime.now();
    return DropdownItem(
      value: value,
      label: label,
      order: order,
      active: active,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Validation result for dropdown items
class DropdownItemValidation {
  final bool isValid;
  final String? errorMessage;

  const DropdownItemValidation._(this.isValid, this.errorMessage);

  static const DropdownItemValidation valid = DropdownItemValidation._(true, null);

  static DropdownItemValidation error(String message) => DropdownItemValidation._(false, message);

  /// Validate HEX color format
  static bool isValidHexColor(String? color) {
    if (color == null || color.isEmpty) return true; // Optional field
    return RegExp(r'^#([0-9A-Fa-f]{6})$').hasMatch(color);
  }

  /// Validate dropdown item input
  static DropdownItemValidation validate(DropdownItemInput input) {
    if (input.value.trim().isEmpty) {
      return error('Value is required');
    }
    if (input.label.trim().isEmpty) {
      return error('Label is required');
    }
    if (input.value.contains(' ')) {
      return error('Value cannot contain spaces');
    }
    if (!isValidHexColor(input.color)) {
      return error('Color must be a valid HEX format (#RRGGBB)');
    }
    return valid;
  }
}
