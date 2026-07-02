/// Canonical enquiry status vocabulary — simplified for We Decor workflow.
///
/// Flow: New → In Talks → Approved → Completed
/// ("Approved" = customer confirmed / booking locked — event date lives on the enquiry.)
enum StatusCategory { active, won, lost }

enum EnquiryStatus {
  newEnquiry('new', 'New', StatusCategory.active),
  inTalks('in_talks', 'In Talks', StatusCategory.active),
  approved('approved', 'Approved', StatusCategory.won),
  completed('completed', 'Completed', StatusCategory.won),
  notInterested('not_interested', 'Not Interested', StatusCategory.lost),
  closedLost('closed_lost', 'Closed Lost', StatusCategory.lost),
  cancelled('cancelled', 'Cancelled', StatusCategory.lost);

  const EnquiryStatus(this.value, this.label, this.category);

  final String value;
  final String label;
  final StatusCategory category;

  /// Legacy Firestore values → canonical slug (tolerant reads + migration).
  static const Map<String, String> legacyAliases = {
    'contacted': 'in_talks',
    'quote_sent': 'in_talks',
    'quoted': 'in_talks',
    'in_progress': 'in_talks',
    'assigned': 'in_talks',
    'confirmed': 'approved',
    'scheduled': 'approved',
    'enquired': 'new',
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
      EnquiryStatus.inTalks,
      EnquiryStatus.notInterested,
      EnquiryStatus.cancelled,
    },
    EnquiryStatus.inTalks: {
      EnquiryStatus.approved,
      EnquiryStatus.notInterested,
      EnquiryStatus.closedLost,
      EnquiryStatus.cancelled,
    },
    EnquiryStatus.approved: {EnquiryStatus.completed, EnquiryStatus.cancelled},
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

  /// Canonical slug for reads/filters, or null if unknown.
  static String? canonicalValue(String? raw) => fromValue(raw)?.value;

  /// True when [a] and [b] resolve to the same canonical status.
  static bool statusesMatch(String? a, String? b) {
    final ca = canonicalValue(a);
    final cb = canonicalValue(b);
    if (ca == null || cb == null) return false;
    return ca == cb;
  }

  /// Booked enquiries (incl. legacy confirmed/scheduled).
  static bool isApproved(String? raw) =>
      fromValue(raw) == EnquiryStatus.approved;

  /// Active pipeline discussion (incl. legacy contacted/quote_sent).
  static bool isInTalks(String? raw) => fromValue(raw) == EnquiryStatus.inTalks;

  /// Terminal lost states.
  static bool isLost(String? raw) =>
      fromValue(raw)?.category == StatusCategory.lost;
}
