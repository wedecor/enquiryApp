import 'occasion_kind.dart';
import 'reengagement_templates.dart';

/// `app_config/reengagement` — `{enabled, leadDays, templates: {kind: text}}`.
/// Read by the app (templates) and by the daily `scheduleReengagements` function
/// (enabled, leadDays). Blank / missing templates fall back to the defaults.
class ReengagementConfig {
  const ReengagementConfig({
    this.enabled = true,
    this.leadDays = defaultLeadDays,
    this.templates = const {},
  });

  static const String docId = 'reengagement';
  static const int defaultLeadDays = 30;
  static const int minLeadDays = 1;
  static const int maxLeadDays = 90;

  final bool enabled;

  /// Days before the occasion that the reminder is created.
  final int leadDays;

  /// Custom templates keyed by kind; only non-blank entries are kept.
  final Map<OccasionKind, String> templates;

  factory ReengagementConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ReengagementConfig();
    final rawLead = data['leadDays'];
    final lead = rawLead is num ? rawLead.toInt() : defaultLeadDays;
    final templates = <OccasionKind, String>{};
    final rawTemplates = data['templates'];
    if (rawTemplates is Map) {
      rawTemplates.forEach((key, value) {
        final kind = key is String ? OccasionKind.fromValue(key) : null;
        if (kind != null && value is String && value.trim().isNotEmpty) {
          templates[kind] = value;
        }
      });
    }
    return ReengagementConfig(
      enabled: data['enabled'] != false,
      leadDays: lead >= minLeadDays && lead <= maxLeadDays ? lead : defaultLeadDays,
      templates: templates,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'leadDays': leadDays,
    'templates': {for (final e in templates.entries) e.key.value: e.value},
  };

  /// Template in use for [kind] (custom or default).
  String templateFor(OccasionKind kind) =>
      templates[kind] ?? ReengagementTemplates.defaults[kind] ?? '';

  /// Days ahead the "Upcoming occasions" list covers (at least 30).
  int get windowDays => leadDays > 30 ? leadDays : 30;

  ReengagementConfig copyWith({
    bool? enabled,
    int? leadDays,
    Map<OccasionKind, String>? templates,
  }) {
    return ReengagementConfig(
      enabled: enabled ?? this.enabled,
      leadDays: leadDays ?? this.leadDays,
      templates: templates ?? this.templates,
    );
  }
}
