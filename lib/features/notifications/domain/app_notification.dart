import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Notification types in the app
enum NotificationType {
  enquiryUpdate,
  newEnquiry,
  userInvited,
  systemAlert;

  String get label {
    switch (this) {
      case NotificationType.enquiryUpdate:
        return 'Enquiry Update';
      case NotificationType.newEnquiry:
        return 'New Enquiry';
      case NotificationType.userInvited:
        return 'User Invited';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }
}

/// Application notification model
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

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

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

  /// Convert to Firestore data
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
    case 'userInvited':
    case 'user_invited':
      return NotificationType.userInvited;
    case 'systemAlert':
    case 'system_alert':
      return NotificationType.systemAlert;
    default:
      return NotificationType.systemAlert;
  }
}

/// Notification filter options
enum NotificationFilter {
  all,
  unread,
  archived;

  String get label {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.archived:
        return 'Archived';
    }
  }
}
