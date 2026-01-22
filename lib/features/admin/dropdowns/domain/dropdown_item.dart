import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dropdown_item.freezed.dart';
part 'dropdown_item.g.dart';

/// Enum representing different dropdown groups in the system
enum DropdownGroup {
  statuses,
  eventTypes,
  priorities,
  paymentStatuses;

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
    }
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
    }
  }

  /// Corresponding enquiry field name for reference checking
  String get enquiryFieldName {
    switch (this) {
      case DropdownGroup.statuses:
        return 'statusValue'; // Use statusValue instead of eventStatus
      case DropdownGroup.eventTypes:
        return 'eventType';
      case DropdownGroup.priorities:
        return 'priority';
      case DropdownGroup.paymentStatuses:
        return 'paymentStatus';
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
    final data = doc.data() as Map<String, dynamic>;
    return DropdownItem(
      value: doc.id,
      label: data['label'] as String,
      order: data['order'] as int,
      active: data['active'] as bool,
      color: data['color'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
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
