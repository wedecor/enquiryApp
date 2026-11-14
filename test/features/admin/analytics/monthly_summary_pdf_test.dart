import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/monthly_summary_pdf.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/monthly_summary.dart';
import 'package:we_decor_enquiries/features/settings/domain/app_config.dart';

int _pdfPageCount(Uint8List bytes) {
  // Count page objects, not the /Pages tree node.
  return RegExp(r'/Type\s*/Page(?!\s*s)').allMatches(String.fromCharCodes(bytes)).length;
}

MonthlySummary _summaryFor({
  required SummaryMonth month,
  required DateTime now,
  required List<Map<String, dynamic>> rows,
  Map<String, String> teamNames = const {},
}) {
  return buildMonthlySummary(
    rows: rows,
    month: month,
    now: now,
    wishReminders: const [],
    teamNames: teamNames,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 11, 15, 9);
  final oct = const SummaryMonth(2026, 10);
  const company = AppGeneralConfig(companyName: 'WeDecor Events');

  test('normal month PDF is non-empty and at most two pages', () async {
    final mid = DateTime.utc(2026, 10, 10, 6);
    final rows = [
      for (var i = 0; i < 8; i++)
        {
          'id': 'e$i',
          'statusValue': i < 3 ? 'approved' : 'new',
          'createdAt': mid,
          if (i < 3) 'approvedAt': mid,
          if (i < 3) 'eventDate': DateTime.utc(2026, 10, 20 + i),
          'sourceValue': 'instagram',
          'eventTypeValue': 'wedding',
          'assignedTo': 'u1',
          'contactCount': 1,
          'firstContactAt': mid.add(Duration(hours: i + 1)),
          'customerName': 'Customer $i',
          'phoneNormalized': '900000000$i',
        },
    ];
    final summary = _summaryFor(month: oct, now: now, rows: rows, teamNames: {'u1': 'Asha'});
    final bytes = await MonthlySummaryPdf.build(summary: summary, company: company);
    expect(bytes, isNotEmpty);
    expect(_pdfPageCount(bytes), lessThanOrEqualTo(2));
    expect(MonthlySummaryPdf.fileNameFor(oct), 'we-decor-summary-2026-10.pdf');
  });

  test('empty month PDF is non-empty and at most two pages', () async {
    final summary = _summaryFor(month: oct, now: now, rows: const []);
    expect(summary.isEmpty, isTrue);
    final bytes = await MonthlySummaryPdf.build(summary: summary, company: company);
    expect(bytes, isNotEmpty);
    // Last-complete month still includes "The month ahead" on page 2.
    expect(_pdfPageCount(bytes), lessThanOrEqualTo(2));
  });

  test('heavy month (300 enquiries, 8 team) stays within two pages', () async {
    final mid = DateTime.utc(2026, 10, 12, 6);
    final teamNames = {for (var t = 0; t < 8; t++) 'u$t': 'Member $t'};
    final rows = <Map<String, dynamic>>[
      for (var i = 0; i < 300; i++)
        {
          'id': 'h$i',
          'statusValue': i % 10 == 0 ? 'approved' : (i % 7 == 0 ? 'not_interested' : 'new'),
          'createdAt': mid.add(Duration(hours: i % 48)),
          if (i % 10 == 0) 'approvedAt': mid.add(Duration(hours: i % 24)),
          if (i % 10 == 0) 'eventDate': DateTime.utc(2026, 10, 15 + (i % 10)),
          if (i % 7 == 0 && i % 10 != 0) 'lostAt': mid,
          if (i % 7 == 0 && i % 10 != 0) 'lostReason': 'no_response',
          'sourceValue': i.isEven ? 'instagram' : 'referral',
          'eventTypeValue': i % 3 == 0 ? 'wedding' : 'birthday',
          'locationArea': i % 2 == 0 ? 'Jayanagar' : 'HSR',
          'assignedTo': 'u${i % 8}',
          'contactCount': i % 5,
          'firstContactAt': mid.add(Duration(hours: (i % 5) + 1)),
          'customerName': 'Heavy Customer $i',
          'phoneNormalized': '${9000000000 + i}',
        },
    ];
    final summary = _summaryFor(month: oct, now: now, rows: rows, teamNames: teamNames);
    expect(summary.team.length, 8);
    final bytes = await MonthlySummaryPdf.build(summary: summary, company: company);
    expect(bytes, isNotEmpty);
    expect(_pdfPageCount(bytes), lessThanOrEqualTo(2));
  });
}
