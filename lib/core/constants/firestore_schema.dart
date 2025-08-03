/// Firestore Collections and Schema Definitions
/// 
/// This file defines the structure of all Firestore collections used in the We Decor Enquiries app.
/// Each collection has a specific purpose and document structure.

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
  
  /// When the user was created
  final DateTime createdAt;
  
  /// When the user was last updated
  final DateTime updatedAt;
  
  /// Whether the user account is active
  final bool isActive;
  
  /// User's profile image URL (optional)
  final String? profileImageUrl;
  
  /// Additional user metadata
  final Map<String, dynamic>? metadata;

  const UserDocument({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.profileImageUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'metadata': metadata,
    };
  }
}

/// Document structure for enquiries collection
/// Collection: enquiries/
/// Document ID: Auto-generated
class EnquiryDocument {
  /// Unique enquiry ID
  final String id;
  
  /// Customer's full name
  final String customerName;
  
  /// Customer's email address
  final String customerEmail;
  
  /// Customer's phone number
  final String customerPhone;
  
  /// Event type (references dropdowns/event_types)
  final String eventType;
  
  /// Event date
  final DateTime eventDate;
  
  /// Event location
  final String eventLocation;
  
  /// Number of guests
  final int guestCount;
  
  /// Budget range
  final String budgetRange;
  
  /// Detailed description of requirements
  final String description;
  
  /// Current status (references dropdowns/statuses)
  final String status;
  
  /// Payment status (references dropdowns/payment_statuses)
  final String paymentStatus;
  
  /// Assigned staff member ID (references users collection)
  final String? assignedTo;
  
  /// When the enquiry was created
  final DateTime createdAt;
  
  /// When the enquiry was last updated
  final DateTime updatedAt;
  
  /// Created by user ID (references users collection)
  final String createdBy;
  
  /// Additional notes from staff
  final String? staffNotes;
  
  /// Priority level (high, medium, low)
  final String priority;
  
  /// Source of enquiry (website, phone, referral, etc.)
  final String source;

  const EnquiryDocument({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.eventType,
    required this.eventDate,
    required this.eventLocation,
    required this.guestCount,
    required this.budgetRange,
    required this.description,
    required this.status,
    required this.paymentStatus,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.staffNotes,
    required this.priority,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'eventType': eventType,
      'eventDate': eventDate,
      'eventLocation': eventLocation,
      'guestCount': guestCount,
      'budgetRange': budgetRange,
      'description': description,
      'status': status,
      'paymentStatus': paymentStatus,
      'assignedTo': assignedTo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'staffNotes': staffNotes,
      'priority': priority,
      'source': source,
    };
  }
}

/// Document structure for event types dropdown
/// Collection: dropdowns/event_types/
/// Document ID: Auto-generated
class EventTypeDocument {
  /// Unique event type ID
  final String id;
  
  /// Event type name
  final String name;
  
  /// Event type description
  final String description;
  
  /// Whether this event type is active
  final bool isActive;
  
  /// Sort order for display
  final int sortOrder;
  
  /// When the event type was created
  final DateTime createdAt;
  
  /// When the event type was last updated
  final DateTime updatedAt;

  const EventTypeDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Document structure for statuses dropdown
/// Collection: dropdowns/statuses/
/// Document ID: Auto-generated
class StatusDocument {
  /// Unique status ID
  final String id;
  
  /// Status name
  final String name;
  
  /// Status description
  final String description;
  
  /// Status color for UI display
  final String color;
  
  /// Whether this status is active
  final bool isActive;
  
  /// Sort order for display
  final int sortOrder;
  
  /// When the status was created
  final DateTime createdAt;
  
  /// When the status was last updated
  final DateTime updatedAt;

  const StatusDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Document structure for payment statuses dropdown
/// Collection: dropdowns/payment_statuses/
/// Document ID: Auto-generated
class PaymentStatusDocument {
  /// Unique payment status ID
  final String id;
  
  /// Payment status name
  final String name;
  
  /// Payment status description
  final String description;
  
  /// Payment status color for UI display
  final String color;
  
  /// Whether this payment status is active
  final bool isActive;
  
  /// Sort order for display
  final int sortOrder;
  
  /// When the payment status was created
  final DateTime createdAt;
  
  /// When the payment status was last updated
  final DateTime updatedAt;

  const PaymentStatusDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Default values for dropdown collections
class DefaultDropdownValues {
  /// Default event types
  static const List<Map<String, dynamic>> eventTypes = [
    {
      'name': 'Wedding',
      'description': 'Wedding ceremonies and receptions',
      'color': '#FF6B6B',
      'sortOrder': 1,
    },
    {
      'name': 'Birthday Party',
      'description': 'Birthday celebrations',
      'color': '#4ECDC4',
      'sortOrder': 2,
    },
    {
      'name': 'Corporate Event',
      'description': 'Business and corporate functions',
      'color': '#45B7D1',
      'sortOrder': 3,
    },
    {
      'name': 'Anniversary',
      'description': 'Anniversary celebrations',
      'color': '#96CEB4',
      'sortOrder': 4,
    },
    {
      'name': 'Other',
      'description': 'Other special events',
      'color': '#FFEAA7',
      'sortOrder': 5,
    },
  ];

  /// Default enquiry statuses
  static const List<Map<String, dynamic>> statuses = [
    {
      'name': 'New',
      'description': 'New enquiry received',
      'color': '#FF6B6B',
      'sortOrder': 1,
    },
    {
      'name': 'In Progress',
      'description': 'Enquiry being processed',
      'color': '#4ECDC4',
      'sortOrder': 2,
    },
    {
      'name': 'Quote Sent',
      'description': 'Quote has been sent to customer',
      'color': '#45B7D1',
      'sortOrder': 3,
    },
    {
      'name': 'Confirmed',
      'description': 'Enquiry confirmed by customer',
      'color': '#96CEB4',
      'sortOrder': 4,
    },
    {
      'name': 'Completed',
      'description': 'Event completed successfully',
      'color': '#FFEAA7',
      'sortOrder': 5,
    },
    {
      'name': 'Cancelled',
      'description': 'Enquiry cancelled',
      'color': '#DDA0DD',
      'sortOrder': 6,
    },
  ];

  /// Default payment statuses
  static const List<Map<String, dynamic>> paymentStatuses = [
    {
      'name': 'Pending',
      'description': 'Payment pending',
      'color': '#FF6B6B',
      'sortOrder': 1,
    },
    {
      'name': 'Partial',
      'description': 'Partial payment received',
      'color': '#FFA500',
      'sortOrder': 2,
    },
    {
      'name': 'Paid',
      'description': 'Full payment received',
      'color': '#96CEB4',
      'sortOrder': 3,
    },
    {
      'name': 'Overdue',
      'description': 'Payment overdue',
      'color': '#FF0000',
      'sortOrder': 4,
    },
  ];
} 
