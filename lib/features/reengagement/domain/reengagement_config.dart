import 'occasion_kind.dart';
import 'reengagement_templates.dart';

/// `app_config/reengagement` — `{enabled, leadDays, templates: {kind: text},
/// templatesEnquired: {kind: text}}` (past customers / people who only enquired).
/// Read by the app (templates) and by the daily `scheduleReengagements` function
/// (enabled, leadDays). Blank / missing templates fall back to the defaults.
class ReengagementConfig {
  const ReengagementConfig({
    this.enabled = true,
    this.leadDays = defaultLeadDays,
    this.templates = const {},
    this.enquiredTemplates = const {},
  });

  static const String docId = 'reengagement';

  /// A week ahead: early enough to plan, close enough to read as a wish.
  static const int defaultLeadDays = 7;
  static const int minLeadDays = 1;
  static const int maxLeadDays = 90;

  final bool enabled;

  /// Days before the occasion that the reminder is created.
  final int leadDays;

  /// Custom past-customer templates keyed by kind; only non-blank entries are kept.
  final Map<OccasionKind, String> templates;

  /// Custom templates for people who only enquired.
  final Map<OccasionKind, String> enquiredTemplates;

  factory ReengagementConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ReengagementConfig();
    final rawLead = data['leadDays'];
    final lead = rawLead is num ? rawLead.toInt() : defaultLeadDays;
    Map<OccasionKind, String> readTemplates(Object? raw) {
      final out = <OccasionKind, String>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          final kind = key is String ? OccasionKind.fromValue(key) : null;
          if (kind != null && value is String && value.trim().isNotEmpty) {
            out[kind] = value;
          }
        });
      }
      return out;
    }

    return ReengagementConfig(
      enabled: data['enabled'] != false,
      leadDays: lead >= minLeadDays && lead <= maxLeadDays ? lead : defaultLeadDays,
      templates: readTemplates(data['templates']),
      enquiredTemplates: readTemplates(data['templatesEnquired']),
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'leadDays': leadDays,
    'templates': {for (final e in templates.entries) e.key.value: e.value},
    'templatesEnquired': {for (final e in enquiredTemplates.entries) e.key.value: e.value},
  };

  /// Template in use for [kind] (custom or default): the past-customer version, or
  /// the version for someone who only [enquired].
  String templateFor(OccasionKind kind, {bool enquired = false}) =>
      (enquired ? enquiredTemplates : templates)[kind] ??
      ReengagementTemplates.defaultFor(kind, enquired: enquired);

  /// Days ahead the "Upcoming occasions" list covers: the lead time, so the list
  /// shows exactly what Settings → Lead days says (it used to be at least 30).
  int get windowDays => leadDays;

  ReengagementConfig copyWith({
    bool? enabled,
    int? leadDays,
    Map<OccasionKind, String>? templates,
    Map<OccasionKind, String>? enquiredTemplates,
  }) {
    return ReengagementConfig(
      enabled: enabled ?? this.enabled,
      leadDays: leadDays ?? this.leadDays,
      templates: templates ?? this.templates,
      enquiredTemplates: enquiredTemplates ?? this.enquiredTemplates,
    );
  }
}
