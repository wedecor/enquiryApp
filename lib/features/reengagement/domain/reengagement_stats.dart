/// A reminder that was sent (from `reminders`, status `sent`).
class SentReminder {
  const SentReminder({required this.phoneNormalized, required this.sentAt});

  final String phoneNormalized;
  final DateTime sentAt;
}

/// An enquiry's customer identity and creation time.
class EnquiryArrival {
  const EnquiryArrival({required this.phoneNormalized, required this.createdAt});

  final String phoneNormalized;
  final DateTime createdAt;
}

/// Re-engagement analytics: reminders sent in the period and how many of those
/// customers came back with a new enquiry within [window] after the wish.
class ReengagementStats {
  const ReengagementStats({required this.sent, required this.customers, required this.cameBack});

  static const Duration window = Duration(days: 60);

  /// Reminders sent in the period.
  final int sent;

  /// Distinct customers (phones) wished in the period.
  final int customers;

  /// Distinct customers with a new enquiry created after a sent wish and no
  /// later than [window] after it.
  final int cameBack;

  /// Share of wished customers who came back (0 when nobody was wished).
  double get comeBackRate => customers == 0 ? 0 : cameBack / customers;

  static ReengagementStats compute({
    required List<SentReminder> sent,
    required List<EnquiryArrival> enquiries,
  }) {
    final byPhone = <String, List<DateTime>>{};
    for (final e in enquiries) {
      if (e.phoneNormalized.isEmpty) continue;
      (byPhone[e.phoneNormalized] ??= []).add(e.createdAt);
    }
    final returned = <String>{};
    final customers = <String>{};
    for (final r in sent) {
      if (r.phoneNormalized.isEmpty) continue;
      customers.add(r.phoneNormalized);
      if (returned.contains(r.phoneNormalized)) continue;
      final until = r.sentAt.add(window);
      final arrivals = byPhone[r.phoneNormalized] ?? const <DateTime>[];
      if (arrivals.any((at) => at.isAfter(r.sentAt) && !at.isAfter(until))) {
        returned.add(r.phoneNormalized);
      }
    }
    return ReengagementStats(
      sent: sent.length,
      customers: customers.length,
      cameBack: returned.length,
    );
  }
}
