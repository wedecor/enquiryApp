import 'package:intl/intl.dart';

import '../../../../../services/dropdown_lookup.dart';
import '../../domain/analytics_models.dart';

String formatAnalyticsDateRange(DateRange range) {
  final fmt = DateFormat('d MMM yyyy');
  return '${fmt.format(range.start)} – ${fmt.format(lastIncludedDay(range))}';
}

String formatAnalyticsCurrency(double amount) {
  if (amount == 0) return '—';
  if (amount >= 1000000) return '₹${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
  return '₹${amount.toStringAsFixed(0)}';
}

String formatStatusName(String status) {
  return status
      .split('_')
      .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
      .join(' ');
}

String categoryLabel(CategoryCount item) => item.label ?? DropdownLookup.titleCase(item.key);

String statusCategoryLabel(CategoryCount item) => item.label ?? formatStatusName(item.key);

/// Sums [values] into at most [maxBuckets] consecutive groups so dense series
/// stay legible as slim bars.
List<double> bucketValues(List<double> values, {int maxBuckets = 24}) {
  if (values.length <= maxBuckets) return values;
  final size = (values.length / maxBuckets).ceil();
  return [
    for (var i = 0; i < values.length; i += size)
      values.skip(i).take(size).fold<double>(0, (a, b) => a + b),
  ];
}
