/// Canonical enquiry status vocabulary (D1).
enum StatusCategory { active, won, lost }

enum EnquiryStatus {
  newEnquiry('new', 'New', StatusCategory.active),
  contacted('contacted', 'Contacted', StatusCategory.active),
  inTalks('in_talks', 'In Talks', StatusCategory.active),
  quoteSent('quote_sent', 'Quote Sent', StatusCategory.active),
  approved('approved', 'Approved', StatusCategory.won),
  scheduled('scheduled', 'Scheduled', StatusCategory.won),
  completed('completed', 'Completed', StatusCategory.won),
  notInterested('not_interested', 'Not Interested', StatusCategory.lost),
  closedLost('closed_lost', 'Closed Lost', StatusCategory.lost),
  cancelled('cancelled', 'Cancelled', StatusCategory.lost);

  const EnquiryStatus(this.value, this.label, this.category);

  final String value;
  final String label;
  final StatusCategory category;

  static const Map<String, String> legacyAliases = {
    'in_progress': 'in_talks',
    'confirmed': 'approved',
    'quoted': 'quote_sent',
    'enquired': 'new',
    'assigned': 'in_talks',
  };

  /// Resolves raw Firestore value (incl. legacy) to canonical, or null.
  static EnquiryStatus? fromValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var normalized = raw.trim().toLowerCase().replaceAll(' ', '_');
    normalized = legacyAliases[normalized] ?? normalized;
    for (final status in EnquiryStatus.values) {
      if (status.value == normalized) return status;
    }
    return null;
  }

  static final Map<EnquiryStatus, Set<EnquiryStatus>> staffTransitions = {
    EnquiryStatus.newEnquiry: {
      EnquiryStatus.contacted,
      EnquiryStatus.inTalks,
      EnquiryStatus.cancelled,
      EnquiryStatus.notInterested,
    },
    EnquiryStatus.contacted: {
      EnquiryStatus.inTalks,
      EnquiryStatus.cancelled,
      EnquiryStatus.notInterested,
    },
    EnquiryStatus.inTalks: {
      EnquiryStatus.quoteSent,
      EnquiryStatus.cancelled,
      EnquiryStatus.notInterested,
    },
    EnquiryStatus.quoteSent: {
      EnquiryStatus.approved,
      EnquiryStatus.closedLost,
      EnquiryStatus.notInterested,
    },
    EnquiryStatus.approved: {EnquiryStatus.scheduled, EnquiryStatus.cancelled},
    EnquiryStatus.scheduled: {EnquiryStatus.completed, EnquiryStatus.cancelled},
    EnquiryStatus.completed: {},
    EnquiryStatus.cancelled: {},
    EnquiryStatus.closedLost: {},
    EnquiryStatus.notInterested: {},
  };

  static bool isStaffTransitionAllowed(String? fromRaw, String toRaw) {
    final from = EnquiryStatus.fromValue(fromRaw);
    final to = EnquiryStatus.fromValue(toRaw);
    if (from == null || to == null) return false;
    return staffTransitions[from]?.contains(to) ?? false;
  }

  static Set<String> staffAllowedNextValues(String? currentRaw) {
    final current = EnquiryStatus.fromValue(currentRaw);
    if (current == null) return {};
    return staffTransitions[current]?.map((s) => s.value).toSet() ?? {};
  }
}
