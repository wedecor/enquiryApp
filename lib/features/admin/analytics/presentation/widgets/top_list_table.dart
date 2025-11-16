import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../services/dropdown_lookup.dart';
import '../../domain/analytics_models.dart';

/// Reusable table widget for displaying top lists and recent enquiries
class TopListTable extends StatelessWidget {
  final String title;
  final List<CategoryCount> data;
  final int maxItems;
  final bool showPercentage;

  const TopListTable({
    super.key,
    required this.title,
    required this.data,
    this.maxItems = 10,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            data.isEmpty ? _buildEmptyState(context) : _buildTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final displayData = data.take(maxItems).toList();

    return Table(
      columnWidths: showPercentage
          ? const {0: FlexColumnWidth(1), 1: FixedColumnWidth(60), 2: FixedColumnWidth(80)}
          : const {0: FlexColumnWidth(1), 1: FixedColumnWidth(60)},
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
          ),
          children: [
            _buildHeaderCell(context, 'Name'),
            _buildHeaderCell(context, 'Count'),
            if (showPercentage) _buildHeaderCell(context, 'Share'),
          ],
        ),

        // Data rows
        ...displayData.map((item) {
          final label = item.label ?? _formatName(item.key);
          return TableRow(
            children: [
              _buildDataCell(context, label),
              _buildDataCell(context, item.count.toString()),
              if (showPercentage) _buildDataCell(context, '${item.percentage.toStringAsFixed(1)}%'),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.table_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatName(String value) => DropdownLookup.titleCase(value);
}

/// Recent enquiries table with more detailed information
class RecentEnquiriesTable extends ConsumerWidget {
  final List<RecentEnquiry> data;
  final String title;
  final int maxItems;

  const RecentEnquiriesTable({
    super.key,
    required this.data,
    required this.title,
    this.maxItems = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            data.isEmpty ? _buildEmptyState(context) : _buildTable(context, dropdownLookup),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, DropdownLookup? dropdownLookup) {
    final displayData = data.take(maxItems).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Customer',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Event Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Source',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Priority',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Cost',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: displayData
            .map(
              (enquiry) => DataRow(
                cells: [
                  DataCell(
                    Text(_formatDate(enquiry.date), style: Theme.of(context).textTheme.bodySmall),
                  ),
                  DataCell(
                    Text(
                      enquiry.customerName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Text(
                      dropdownLookup?.labelForEventType(enquiry.eventType) ??
                          DropdownLookup.titleCase(enquiry.eventType),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(enquiry.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dropdownLookup?.labelForStatus(enquiry.status) ??
                            _formatStatusName(enquiry.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      dropdownLookup?.labelForSource(enquiry.source) ??
                          DropdownLookup.titleCase(enquiry.source),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(enquiry.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dropdownLookup?.labelForPriority(enquiry.priority) ??
                            _formatPriorityName(enquiry.priority),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      enquiry.totalCost != null ? _formatCurrency(enquiry.totalCost!) : '—',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.table_rows, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No recent enquiries',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a different date range or filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year % 100}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'new':
        return Colors.orange;
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'quote_sent':
        return Colors.blue;
      case 'confirmed':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'closed_lost':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatStatusName(String status) {
    return status
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  String _formatPriorityName(String priority) {
    return priority.isNotEmpty
        ? priority[0].toUpperCase() + priority.substring(1).toLowerCase()
        : priority;
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '—';

    if (amount >= 1000000) {
      return '₹${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
