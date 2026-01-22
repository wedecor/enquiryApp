/// Firestore Collections and Schema Definitions
///
/// This file defines the structure of all Firestore collections used in the We Decor Enquiries app.
/// Each collection has a specific purpose and document structure.
library;

/// Collection: users/
/// Purpose: Store user information and roles
/// Document ID: Firebase Auth UID
class FirestoreCollections {
  /// Users collection path
  static const String users = 'users';

  /// Enquiries collection path
  static const String enquiries = 'enquiries';

  /// Dropdowns collection path
  static const String dropdowns = 'dropdowns';

  /// Event types subcollection path
  static const String eventTypes = 'dropdowns/event_types';

  /// Statuses subcollection path
  static const String statuses = 'dropdowns/statuses';

  /// Payment statuses subcollection path
  static const String paymentStatuses = 'dropdowns/payment_statuses';
}

/// Document structure for users collection
/// Collection: users/
/// Document ID: Firebase Auth UID
class UserDocument {
  /// User's full name
  final String name;

  /// User's email address
  final String email;

  /// User's phone number
  final String phone;

  /// User's role in the system (admin/staff)
  final String role;

  /// FCM token for push notifications (optional)
  // fcmToken removed for security - stored in private subcollection

  const UserDocument({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    // fcmToken constructor parameter removed
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      // fcmToken removed for security
    };
  }
}

/// Document structure for enquiries collection
/// Collection: enquiries/
/// Document ID: Auto-generated
class EnquiryDocument {
  /// Customer's full name
  final String customerName;

  /// Customer's phone number
  final String customerPhone;

  /// Event location
  final String location;

  /// Event date
  final DateTime eventDate;

  /// Event type
  final String eventType;

  /// Event status - default: "Enquired" (deprecated, use statusValue)
  @Deprecated('Use statusValue instead')
  final String eventStatus;

  /// Detailed notes
  final String notes;

  /// Reference images (list of Storage URLs)
  final List<String> referenceImages;

  /// Created by user ID (references users collection)
  final String createdBy;

  /// Assigned to user ID (references users collection, optional)
  final String? assignedTo;

  /// When the enquiry was created
  final DateTime createdAt;

  const EnquiryDocument({
    required this.customerName,
    required this.customerPhone,
    required this.location,
    required this.eventDate,
    required this.eventType,
    required this.eventStatus,
    required this.notes,
    required this.referenceImages,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'location': location,
      'eventDate': eventDate,
      'eventType': eventType,
      'statusValue': eventStatus, // Map to statusValue
      'notes': notes,
      'referenceImages': referenceImages,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'createdAt': createdAt,
    };
  }
}

/// Document structure for financial subcollection
/// Collection: enquiries/{enquiryId}/financial/
/// Document ID: Auto-generated
class FinancialDocument {
  /// Total cost
  final double totalCost;

  /// Advance amount paid
  final double advancePaid;

  /// Payment status
  final String paymentStatus;

  const FinancialDocument({
    required this.totalCost,
    required this.advancePaid,
    required this.paymentStatus,
  });

  Map<String, dynamic> toMap() {
    return {'totalCost': totalCost, 'advancePaid': advancePaid, 'paymentStatus': paymentStatus};
  }
}

/// Document structure for history subcollection
/// Collection: enquiries/{enquiryId}/history/
/// Document ID: Auto-generated
class HistoryDocument {
  /// Field that was changed
  final String fieldChanged;

  /// Old value
  final String oldValue;

  /// New value
  final String newValue;

  /// User ID who made the change
  final String changedBy;

  /// When the change was made
  final DateTime timestamp;

  const HistoryDocument({
    required this.fieldChanged,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldChanged': fieldChanged,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedBy': changedBy,
      'timestamp': timestamp,
    };
  }
}

/// Document structure for event types dropdown
/// Collection: dropdowns/event_types/
/// Document ID: Auto-generated or lowercase eventType as ID
class EventTypeDocument {
  /// Event type value
  final String value;

  const EventTypeDocument({required this.value});

  Map<String, dynamic> toMap() {
    return {'value': value};
  }
}

/// Document structure for statuses dropdown
/// Collection: dropdowns/statuses/
/// Document ID: Auto-generated or lowercase status as ID
class StatusDocument {
  /// Status value
  final String value;

  const StatusDocument({required this.value});

  Map<String, dynamic> toMap() {
    return {'value': value};
  }
}

/// Document structure for payment statuses dropdown
/// Collection: dropdowns/payment_statuses/
/// Document ID: Auto-generated or lowercase payment status
class PaymentStatusDocument {
  /// Payment status value
  final String value;

  const PaymentStatusDocument({required this.value});

  Map<String, dynamic> toMap() {
    return {'value': value};
  }
}

/// Default values for dropdown collections
class DefaultDropdownValues {
  /// Default event types
  static const List<String> eventTypes = [
    'Wedding',
    'Birthday Party',
    'Corporate Event',
    'Anniversary',
    'Graduation',
    'Baby Shower',
    'Engagement',
    'Other',
  ];

  /// Default enquiry statuses
  static const List<String> statuses = [
    'Enquired',
    'In Progress',
    'Quote Sent',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  /// Default payment statuses
  static const List<String> paymentStatuses = ['Pending', 'Partial', 'Paid', 'Overdue'];
}
