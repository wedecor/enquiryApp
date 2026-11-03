/// Live Firestore data model of the We Decor Enquiries app (Nov 2026).
///
/// Reference only: nothing here builds or validates documents. The rules in
/// `firestore.rules` and the canonical status list in
/// `lib/core/constants/status_vocabulary.dart` are the source of truth; the
/// `Enquiry` model, `FirestoreService`, `EnquiryFinancials` and the Cloud
/// Functions are the write paths. Only [FirestoreCollections.users] and
/// [FirestoreCollections.enquiries] are read at runtime (by FirestoreService).
library;

/// Top-level collections and well-known sub-paths.
class FirestoreCollections {
  /// `users/{uid}` — public profile: `name`, `role` (`admin` | `staff`),
  /// `isActive` (legacy `active`), timestamps. Readable by every active user
  /// (assignment labels). Phone and email are in [userPrivateProfile].
  static const String users = 'users';

  /// `enquiries/{id}` — one event enquiry (see [EnquiryFields]).
  static const String enquiries = 'enquiries';

  /// `dropdowns/{group}/items/{value}` — event types, statuses, sources,
  /// priorities, payment statuses. Group doc only carries `defaultsSeeded`.
  static const String dropdowns = 'dropdowns';

  /// `enquiries/{id}/financial/summary` — booking money (admin only).
  static const String financial = 'financial';
  static const String financialSummaryDoc = 'summary';

  /// `enquiries/{id}/history/{auto}` — append-only audit trail.
  static const String history = 'history';

  /// `enquiries/{id}/contacts/{auto}` — append-only call / WhatsApp log.
  static const String contacts = 'contacts';

  /// `users/{uid}/private/profile` — `phone`, `email`, `updatedAt` (owner + admins).
  static const String userPrivateProfile = 'private/profile';

  /// `users/{uid}/private/notifications/tokens/{tokenId}` — FCM tokens (owner only).
  static const String userTokens = 'private/notifications/tokens';

  /// `users/{uid}/notifications/{id}` — in-app inbox; created by Cloud Functions only.
  static const String userNotifications = 'notifications';

  /// `reminders/{phone}_{kind}_{year}` — yearly re-engagement wish queue.
  static const String reminders = 'reminders';

  /// `customer_prefs/{phoneNormalized}` — `noReminders`; written by the
  /// `setReengagementPref` function only.
  static const String customerPrefs = 'customer_prefs';

  /// `app_config/{general|notifications|security|reengagement|followups_state}`.
  static const String appConfig = 'app_config';

  /// `admin_audit/{auto}` — admin action log (admins only).
  static const String adminAudit = 'admin_audit';
}

/// `enquiries/{id}` fields written by the app, the website lead function and the
/// scheduled jobs. Money is NOT here (see [FinancialSummaryFields]); older
/// documents may still carry it until the 2026_11 migration is applied.
class EnquiryFields {
  // Customer
  static const String customerName = 'customerName';
  static const String customerNameLower = 'customerNameLower';
  static const String customerPhone = 'customerPhone';
  static const String phoneNormalized = 'phoneNormalized'; // customer identity (last 10 digits)
  static const String customerEmail = 'customerEmail';
  static const String whatsappNumber = 'whatsappNumber';

  // Event (multi-function: `functions` array; top-level fields mirror it)
  static const String eventTypeValue = 'eventTypeValue'; // legacy `eventType`
  static const String eventTypeLabel = 'eventTypeLabel';
  static const String eventDate = 'eventDate'; // LAST function day
  static const String eventStartDate = 'eventStartDate'; // FIRST function day
  static const String functions =
      'functions'; // [{id, eventType, eventTypeLabel, date, time?, location?, ...}]
  static const String functionCount = 'functionCount';
  static const String eventLocation = 'eventLocation';
  static const String locationArea = 'locationArea';
  static const String locationPlaceId = 'locationPlaceId';
  static const String guestCount = 'guestCount';
  static const String budgetRange = 'budgetRange';
  static const String notes = 'notes'; // and `description` (same text)

  // Status (canonical values: status_vocabulary.dart)
  static const String statusValue = 'statusValue';
  static const String statusLabel = 'statusLabel';
  static const String statusUpdatedAt = 'statusUpdatedAt';
  static const String statusUpdatedBy = 'statusUpdatedBy';
  static const String inTalksAt = 'inTalksAt';
  static const String approvedAt = 'approvedAt';
  static const String completedAt = 'completedAt';
  static const String lostAt = 'lostAt';
  static const String lostReason = 'lostReason';
  static const String lostReasonNote = 'lostReasonNote';
  static const String mergedInto = 'mergedInto'; // "Mark as duplicate of…"

  // Assignment / attribution
  static const String assignedTo = 'assignedTo';
  static const String assigneeName = 'assigneeName';
  static const String createdBy = 'createdBy'; // uid or `system:website`
  static const String priorityValue = 'priorityValue';
  static const String sourceValue = 'sourceValue'; // `google_website` for the site
  static const String websiteLeadId = 'websiteLeadId'; // doc id `web_{externalId}`

  // Search
  static const String textIndex = 'textIndex';

  // Automatic follow-ups (server-managed; clients may complete / reschedule)
  static const String followUpDueAt = 'followUpDueAt';
  static const String followUpSeq = 'followUpSeq';
  static const String followUpReason = 'followUpReason';
  static const String followUpNotifiedStage = 'followUpNotifiedStage';
  static const String followUpNote = 'followUpNote';
  static const String followUpLastCompletedAt = 'followUpLastCompletedAt';
  static const String pastEventReviewAt = 'pastEventReviewAt';

  // Yearly re-engagement stamp (admin + server)
  static const String occasionKind = 'occasionKind';
  static const String occasionDate = 'occasionDate';

  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// `enquiries/{id}/financial/summary` (admin read / write only).
class FinancialSummaryFields {
  static const String totalCost = 'totalCost';
  static const String advancePaid = 'advancePaid';
  static const String paymentStatusValue =
      'paymentStatusValue'; // pending | partial | paid | overdue
  static const String paymentStatus = 'paymentStatus'; // legacy mirror of the value
  static const String paymentStatusLabel = 'paymentStatusLabel';
  static const String quotedAmount = 'quotedAmount';
  static const String quotedAt = 'quotedAt';
  static const String updatedAt = 'updatedAt';
}

/// `enquiries/{id}/history/{auto}` (AuditService.buildHistoryEntry; functions write
/// `user_id: 'system'`). Append-only.
class HistoryFields {
  static const String fieldChanged = 'field_changed';
  static const String oldValue = 'old_value';
  static const String newValue = 'new_value';
  static const String userId = 'user_id'; // must equal the writer's uid
  static const String userEmail = 'user_email';
  static const String timestamp = 'timestamp';
}

/// `enquiries/{id}/contacts/{auto}`. Append-only.
class ContactFields {
  static const String type = 'type'; // call | whatsapp | reminder | review_request | reengagement
  static const String by = 'by'; // writer's uid
  static const String at = 'at';
}

/// `reminders/{phone}_{kind}_{year}` — created by scheduleReengagements; clients
/// may only change the status bookkeeping.
class ReminderFields {
  static const String status = 'status'; // pending | sent | skipped
  static const String assignedTo = 'assignedTo';
  static const String occasionDate = 'occasionDate';
  static const String sentAt = 'sentAt';
  static const String sentBy = 'sentBy';
  static const String skippedReason = 'skippedReason';
}

/// `users/{uid}/private/profile`.
class UserPrivateProfileFields {
  static const String phone = 'phone';
  static const String email = 'email';
  static const String updatedAt = 'updatedAt';
}
