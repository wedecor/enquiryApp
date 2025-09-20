import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/admin/analytics/domain/analytics_models.dart';

/// Utility class for exporting data to CSV format
class CsvExport {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _fileNameDateFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Export enquiries to CSV
  static Future<void> exportEnquiries(List<Map<String, dynamic>> enquiries) async {
    if (enquiries.isEmpty) {
      throw Exception('No data to export');
    }

    // Define CSV headers
    final headers = [
      'ID',
      'Customer Name',
      'Customer Email',
      'Customer Phone',
      'Event Type',
      'Event Date',
      'Event Location',
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
      'Staff Notes',
      'Created At',
      'Created By',
      'Updated At',
    ];

    // Convert enquiries to CSV rows
    final rows = <List<String>>[headers];

    for (final enquiry in enquiries) {
      rows.add([
        enquiry['id']?.toString() ?? '',
        enquiry['customerName']?.toString() ?? '',
        enquiry['customerEmail']?.toString() ?? '',
        enquiry['customerPhone']?.toString() ?? '',
        enquiry['eventType']?.toString() ?? '',
        _formatTimestamp(enquiry['eventDate']),
        enquiry['eventLocation']?.toString() ?? '',
        enquiry['guestCount']?.toString() ?? '',
        enquiry['budgetRange']?.toString() ?? '',
        enquiry['description']?.toString() ?? '',
        enquiry['eventStatus']?.toString() ?? '',
        enquiry['paymentStatus']?.toString() ?? '',
        enquiry['totalCost']?.toString() ?? '',
        enquiry['advancePaid']?.toString() ?? '',
        enquiry['assignedTo']?.toString() ?? '',
        enquiry['priority']?.toString() ?? '',
        enquiry['source']?.toString() ?? '',
        enquiry['staffNotes']?.toString() ?? '',
        _formatTimestamp(enquiry['createdAt']),
        enquiry['createdBy']?.toString() ?? '',
        _formatTimestamp(enquiry['updatedAt']),
      ]);
    }

    // Generate CSV content
    final csvContent = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    // Generate filename with timestamp
    final timestamp = _fileNameDateFormat.format(DateTime.now());
    final filename = 'enquiries_$timestamp.csv';

    // Save file
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  /// Export recent enquiries from analytics
  static Future<void> exportRecentEnquiries(List<RecentEnquiry> enquiries) async {
    if (enquiries.isEmpty) {
      throw Exception('No data to export');
    }

    // Define CSV headers
    final headers = [
      'ID',
      'Date',
      'Customer Name',
      'Event Type',
      'Status',
      'Source',
      'Priority',
      'Total Cost',
    ];

    // Convert enquiries to CSV rows
    final rows = <List<String>>[headers];

    for (final enquiry in enquiries) {
      rows.add([
        enquiry.id,
        _dateFormat.format(enquiry.date),
        enquiry.customerName,
        enquiry.eventType,
        enquiry.status,
        enquiry.source,
        enquiry.priority,
        enquiry.totalCost?.toString() ?? '',
      ]);
    }

    // Generate CSV content
    final csvContent = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    // Generate filename with timestamp
    final timestamp = _fileNameDateFormat.format(DateTime.now());
    final filename = 'recent_enquiries_$timestamp.csv';

    // Save file
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
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
        '${_dateFormat.format(dateRange.start)} to ${_dateFormat.format(dateRange.end)}',
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
          (item) => [item.key, item.count.toString(), '${item.percentage.toStringAsFixed(1)}%'],
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
    final csvContent = const ListToCsvConverter().convert(rows);
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
    final csvContent = const ListToCsvConverter().convert(rows);
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

  /// Show export success message
  static void showExportSuccess(BuildContext context, String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported successfully: $filename'),
        backgroundColor: Colors.green,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  /// Show export error message
  static void showExportError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}
