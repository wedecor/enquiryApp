import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/admin/analytics/domain/analytics_models.dart';
import '../../features/enquiries/domain/event_functions.dart';
import '../../services/dropdown_lookup.dart';
import '../auth/role_guards.dart';
import '../theme/app_theme.dart';
import '../utils/enquiry_fields.dart';

/// Utility class for exporting data to CSV format
class CsvExport {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _fileNameDateFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Prefixes `'` on cells starting with formula triggers (`=`, `+`, `-`, `@`, `\t`, `\r`)
  /// so spreadsheet apps do not evaluate exported user strings as formulas.
  @visibleForTesting
  static String safeCell(String value) {
    if (value.isEmpty) return value;
    final first = value.codeUnitAt(0);
    if (first == 0x3D || // =
        first == 0x2B || // +
        first == 0x2D || // -
        first == 0x40 || // @
        first == 0x09 || // \t
        first == 0x0D) {
      // \r
      return "'$value";
    }
    return value;
  }

  static List<List<String>> _sanitizeRows(List<List<String>> rows) =>
      rows.map((r) => r.map(safeCell).toList()).toList();

  /// CSV header row for the enquiry export. Staff never get money, customer email
  /// or budget columns.
  static List<String> enquiryHeaders({required bool isAdminUser}) => isAdminUser
      ? const [
          'ID',
          'Customer Name',
          'Customer Email',
          'Customer Phone',
          'Event Type',
          'Event Date',
          'Event Location',
          'Functions',
          'Guest Count',
          'Budget Range',
          'Description',
          'Status',
          'Payment Status',
          'Total Cost',
          'Advance Paid',
          'Assigned To',
          'Priority',
          'Source',
          'Created At',
          'Created By',
          'Updated At',
        ]
      : const [
          'ID',
          'Customer Name',
          'Customer Phone',
          'Event Type',
          'Event Date',
          'Event Location',
          'Functions',
          'Guest Count',
          'Description',
          'Status',
          'Priority',
          'Source',
          'Created At',
        ];

  /// One CSV row for [enquiry]. Admin rows read money from the merged financial
  /// summary ([EnquiryFinancials]); staff rows have no money columns at all.
  static List<String> enquiryRow(
    Map<String, dynamic> enquiry, {
    required bool isAdminUser,
    DropdownLookup? lookup,
  }) {
    if (isAdminUser) {
      return [
        enquiry['id']?.toString() ?? '',
        enquiry['customerName']?.toString() ?? '',
        enquiry['customerEmail']?.toString() ?? '',
        enquiry['customerPhone']?.toString() ?? '',
        _labelOrValue(enquiry, 'eventTypeLabel', 'eventTypeValue', 'eventType'),
        _formatEventDate(enquiry['eventDate']),
        enquiry['eventLocation']?.toString() ?? '',
        _functionsText(enquiry),
        enquiry['guestCount']?.toString() ?? '',
        enquiry['budgetRange']?.toString() ?? '',
        enquiryNotesFrom(enquiry) ?? '',
        DropdownLookup.statusLabelOf(lookup, enquiry['statusValue']?.toString()),
        _labelOrValue(enquiry, 'paymentStatusLabel', 'paymentStatusValue', 'paymentStatus'),
        amountText(enquiry['totalCost']),
        amountText(enquiry['advancePaid']),
        enquiry['assignedTo']?.toString() ?? '',
        _labelOrValue(enquiry, 'priorityLabel', 'priorityValue', 'priority'),
        _labelOrValue(enquiry, 'sourceLabel', 'sourceValue', 'source'),
        _formatTimestamp(enquiry['createdAt']),
        enquiry['createdBy']?.toString() ?? '',
        _formatTimestamp(enquiry['updatedAt']),
      ].map(safeCell).toList();
    }
    return [
      enquiry['id']?.toString() ?? '',
      enquiry['customerName']?.toString() ?? '',
      enquiry['customerPhone']?.toString() ?? '',
      _labelOrValue(enquiry, 'eventTypeLabel', 'eventTypeValue', 'eventType'),
      _formatEventDate(enquiry['eventDate']),
      enquiry['eventLocation']?.toString() ?? '',
      _functionsText(enquiry),
      enquiry['guestCount']?.toString() ?? '',
      enquiryNotesFrom(enquiry) ?? '',
      DropdownLookup.statusLabelOf(lookup, enquiry['statusValue']?.toString()),
      _labelOrValue(enquiry, 'priorityLabel', 'priorityValue', 'priority'),
      _labelOrValue(enquiry, 'sourceLabel', 'sourceValue', 'source'),
      _formatTimestamp(enquiry['createdAt']),
    ].map(safeCell).toList();
  }

  /// Builds the CSV text page by page as [pages] arrive (no row cap). Returns the
  /// text and the number of data rows.
  static Future<({String csv, int count})> buildEnquiryCsv(
    Stream<List<Map<String, dynamic>>> pages, {
    required bool isAdminUser,
    DropdownLookup? lookup,
  }) async {
    const converter = ListToCsvConverter();
    final buffer = StringBuffer(converter.convert([enquiryHeaders(isAdminUser: isAdminUser)]));
    var count = 0;
    await for (final page in pages) {
      if (page.isEmpty) continue;
      final rows = [
        for (final enquiry in page) enquiryRow(enquiry, isAdminUser: isAdminUser, lookup: lookup),
      ];
      buffer
        ..write('\r\n')
        ..write(converter.convert(rows));
      count += rows.length;
    }
    return (csv: buffer.toString(), count: count);
  }

  /// Export enquiries to CSV with role-based filtering and column restrictions.
  /// [pages] is [FirestoreService.fetchEnquiriesForRole] (500 rows at a time).
  /// Returns the number of exported rows; nothing is saved when it is 0.
  static Future<int> exportEnquiryPages(
    Stream<List<Map<String, dynamic>>> pages,
    WidgetRef ref,
  ) async {
    final isAdminUser = isAdmin(ref);
    final lookup = ref.read(dropdownLookupProvider).valueOrNull;
    final result = await buildEnquiryCsv(pages, isAdminUser: isAdminUser, lookup: lookup);
    if (result.count == 0) return 0;

    await logAdminAction(ref, 'csv_export_enquiries', {
      'recordCount': result.count,
      'isAdmin': isAdminUser,
      'exportType': isAdminUser ? 'full_access' : 'staff_restricted',
    });

    final bytes = Uint8List.fromList(utf8.encode(result.csv));
    final timestamp = _fileNameDateFormat.format(DateTime.now());
    final rolePrefix = isAdminUser ? 'all' : 'assigned';
    await FileSaver.instance.saveFile(
      name: 'enquiries_${rolePrefix}_$timestamp.csv',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    return result.count;
  }

  /// Export an in-memory list of enquiries (same columns as [exportEnquiryPages]).
  static Future<void> exportEnquiries(List<Map<String, dynamic>> enquiries, WidgetRef ref) async {
    if (enquiries.isEmpty) {
      throw Exception('No data to export');
    }
    await exportEnquiryPages(Stream.value(enquiries), ref);
  }

  /// Export analytics summary data
  static Future<void> exportAnalyticsSummary({
    required KpiSummary kpiSummary,
    required List<CategoryCount> statusBreakdown,
    required List<CategoryCount> eventTypeBreakdown,
    required List<CategoryCount> sourceBreakdown,
    required DateRange dateRange,
  }) async {
    final rows = <List<String>>[];

    // KPI Summary section
    rows.addAll([
      ['WeDecor Analytics Summary'],
      [
        'Date Range',
        '${_dateFormat.format(dateRange.start)} to ${_dateFormat.format(lastIncludedDay(dateRange))}',
      ],
      ['Generated At', _dateFormat.format(DateTime.now())],
      [''],
      ['KPI Summary'],
      ['Metric', 'Value', 'Change %'],
      [
        'Total Enquiries',
        kpiSummary.totalEnquiries.toString(),
        '${kpiSummary.deltas.totalEnquiriesChange.toStringAsFixed(1)}%',
      ],
      [
        'Active Enquiries',
        kpiSummary.activeEnquiries.toString(),
        '${kpiSummary.deltas.activeEnquiriesChange.toStringAsFixed(1)}%',
      ],
      [
        'Won Enquiries',
        kpiSummary.wonEnquiries.toString(),
        '${kpiSummary.deltas.wonEnquiriesChange.toStringAsFixed(1)}%',
      ],
      [
        'Lost Enquiries',
        kpiSummary.lostEnquiries.toString(),
        '${kpiSummary.deltas.lostEnquiriesChange.toStringAsFixed(1)}%',
      ],
      [
        'Conversion Rate',
        '${kpiSummary.conversionRate.toStringAsFixed(1)}%',
        '${kpiSummary.deltas.conversionRateChange.toStringAsFixed(1)}%',
      ],
      [
        'Estimated Revenue',
        '₹${kpiSummary.estimatedRevenue.toStringAsFixed(2)}',
        '${kpiSummary.deltas.estimatedRevenueChange.toStringAsFixed(1)}%',
      ],
      [''],
    ]);

    // Status breakdown section
    if (statusBreakdown.isNotEmpty) {
      rows.addAll([
        ['Status Breakdown'],
        ['Status', 'Count', 'Percentage'],
        ...statusBreakdown.map(
          (item) => [
            DropdownLookup.statusLabelOf(null, item.key),
            item.count.toString(),
            '${item.percentage.toStringAsFixed(1)}%',
          ],
        ),
        [''],
      ]);
    }

    // Event type breakdown section
    if (eventTypeBreakdown.isNotEmpty) {
      rows.addAll([
        ['Event Type Breakdown'],
        ['Event Type', 'Count', 'Percentage'],
        ...eventTypeBreakdown.map(
          (item) => [item.key, item.count.toString(), '${item.percentage.toStringAsFixed(1)}%'],
        ),
        [''],
      ]);
    }

    // Source breakdown section
    if (sourceBreakdown.isNotEmpty) {
      rows.addAll([
        ['Source Breakdown'],
        ['Source', 'Count', 'Percentage'],
        ...sourceBreakdown.map(
          (item) => [item.key, item.count.toString(), '${item.percentage.toStringAsFixed(1)}%'],
        ),
      ]);
    }

    // Generate CSV content
    final csvContent = const ListToCsvConverter().convert(_sanitizeRows(rows));
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    // Generate filename with timestamp
    final timestamp = _fileNameDateFormat.format(DateTime.now());
    final filename = 'analytics_summary_$timestamp.csv';

    // Save file
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  /// Export users list
  static Future<void> exportUsers(List<Map<String, dynamic>> users) async {
    if (users.isEmpty) {
      throw Exception('No users to export');
    }

    // Define CSV headers
    final headers = [
      'UID',
      'Name',
      'Email',
      'Phone',
      'Role',
      'Active',
      'Created At',
      'Updated At',
      'Last Token Update',
    ];

    // Convert users to CSV rows
    final rows = <List<String>>[headers];

    for (final user in users) {
      rows.add([
        user['uid']?.toString() ?? '',
        user['name']?.toString() ?? '',
        user['email']?.toString() ?? '',
        user['phone']?.toString() ?? '',
        user['role']?.toString() ?? '',
        user['isActive']?.toString() ?? '',
        _formatTimestamp(user['createdAt']),
        _formatTimestamp(user['updatedAt']),
        _formatTimestamp(user['lastTokenUpdate']),
      ]);
    }

    // Generate CSV content
    final csvContent = const ListToCsvConverter().convert(_sanitizeRows(rows));
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    // Generate filename with timestamp
    final timestamp = _fileNameDateFormat.format(DateTime.now());
    final filename = 'users_$timestamp.csv';

    // Save file
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  /// Format timestamp for CSV export
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime? dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return timestamp;
      }
    }

    return dateTime != null ? _dateFormat.format(dateTime) : '';
  }

  /// "Haldi 10 Dec; Mehendi 11 Dec; …" — one row per booking, every function listed.
  static String _functionsText(Map<String, dynamic> enquiry) =>
      functionsSummary(functionsOf(enquiry));

  static String _formatEventDate(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime? dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return timestamp;
      }
    }

    if (dateTime == null || dateTime.year <= 1971) return '—';
    return _dateFormat.format(dateTime);
  }

  static String _labelOrValue(
    Map<String, dynamic> enquiry,
    String labelKey,
    String valueKey, [
    String? legacyKey,
  ]) {
    final label = enquiry[labelKey]?.toString();
    if (label != null && label.isNotEmpty) return label;

    final value = enquiry[valueKey]?.toString();
    if (value != null && value.isNotEmpty) return value;

    if (legacyKey != null) {
      final legacy = enquiry[legacyKey]?.toString();
      if (legacy != null && legacy.isNotEmpty) return legacy;
    }

    return '';
  }

  /// Show export success message
  static void showExportSuccess(BuildContext context, String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported successfully: $filename'),
        backgroundColor: AppColorScheme.snackSuccess,
        action: SnackBarAction(
          label: 'OK',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show export error message
  static void showExportError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $error'),
        backgroundColor: AppColorScheme.snackError,
        action: SnackBarAction(
          label: 'OK',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {},
        ),
      ),
    );
  }
}
