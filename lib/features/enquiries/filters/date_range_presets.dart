import 'filters_state.dart';

/// Relative date-range presets ("Today", "This Week").
///
/// Saved views store the preset key (`dateRangePreset`) next to the frozen range so the
/// view resolves to the *current* day/week when it is loaded, not the day it was saved.
class DateRangePreset {
  DateRangePreset._();

  static const String today = 'today';
  static const String thisWeek = 'this_week';

  /// Firestore key written next to the serialized [SavedView].
  static const String savedViewField = 'dateRangePreset';

  static FilterDateRange todayRange([DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day);
    return FilterDateRange(start: start, end: start.add(const Duration(days: 1)));
  }

  static FilterDateRange thisWeekRange([DateTime? now]) {
    final n = now ?? DateTime.now();
    final startOfWeek = n.subtract(Duration(days: n.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return FilterDateRange(start: start, end: start.add(const Duration(days: 7)));
  }

  static bool _same(FilterDateRange a, FilterDateRange b) =>
      a.start.isAtSameMomentAs(b.start) && a.end.isAtSameMomentAs(b.end);

  /// The preset key [range] currently matches, or null for a custom range.
  static String? keyFor(FilterDateRange? range) {
    if (range == null) return null;
    if (_same(range, todayRange())) return today;
    if (_same(range, thisWeekRange())) return thisWeek;
    return null;
  }

  /// The current range for a stored preset key, or null if unknown.
  static FilterDateRange? resolve(String? key) {
    switch (key) {
      case today:
        return todayRange();
      case thisWeek:
        return thisWeekRange();
      default:
        return null;
    }
  }
}
