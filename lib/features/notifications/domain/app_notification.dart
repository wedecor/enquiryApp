import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Enumeration of notification types
enum NotificationType { enquiryUpdate, newEnquiry, assignment, statusChange, paymentUpdate }

/// Represents an application notification
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    String? enquiryId,
    String? userId,
    required DateTime createdAt,
    @Default(false) bool read,
    @Default(false) bool archived,
    Map<String, dynamic>? metadata,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: _parseNotificationType(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      enquiryId: data['enquiryId'] as String?,
      userId: data['userId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      archived: data['archived'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Extension to convert AppNotification to Firestore data
extension AppNotificationFirestore on AppNotification {
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'enquiryId': enquiryId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'archived': archived,
      'metadata': metadata,
    };
  }
}

/// Helper function to parse notification type from string
NotificationType _parseNotificationType(String? typeString) {
  switch (typeString) {
    case 'enquiryUpdate':
    case 'enquiry_update':
      return NotificationType.enquiryUpdate;
    case 'newEnquiry':
    case 'new_enquiry':
      return NotificationType.newEnquiry;
    case 'assignment':
      return NotificationType.assignment;
    case 'statusChange':
    case 'status_change':
      return NotificationType.statusChange;
    case 'paymentUpdate':
    case 'payment_update':
      return NotificationType.paymentUpdate;
    default:
      return NotificationType.enquiryUpdate;
  }
}
