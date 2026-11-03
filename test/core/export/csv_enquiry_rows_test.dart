import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/export/csv_export.dart';

void main() {
  final row = {
    'id': 'e1',
    'customerName': 'Priya Sharma',
    'customerEmail': 'priya@example.com',
    'customerPhone': '9876543210',
    'statusValue': 'approved',
    'totalCost': 90000,
    'advancePaid': 20000,
    'paymentStatusValue': 'partial',
    'budgetRange': '50k-1L',
  };

  test('staff rows and headers have no money, email or budget columns', () {
    final headers = CsvExport.enquiryHeaders(isAdminUser: false);
    expect(headers, isNot(contains('Total Cost')));
    expect(headers, isNot(contains('Advance Paid')));
    expect(headers, isNot(contains('Payment Status')));
    expect(headers, isNot(contains('Customer Email')));
    final cells = CsvExport.enquiryRow(row, isAdminUser: false);
    expect(cells.length, headers.length);
    expect(cells.join('|'), isNot(contains('90000')));
    expect(cells.join('|'), isNot(contains('priya@example.com')));
  });

  test('admin rows include money from the (merged) row', () {
    final headers = CsvExport.enquiryHeaders(isAdminUser: true);
    final cells = CsvExport.enquiryRow(row, isAdminUser: true);
    expect(cells.length, headers.length);
    expect(cells[headers.indexOf('Total Cost')], isNotEmpty);
    expect(cells[headers.indexOf('Advance Paid')], isNotEmpty);
  });

  test('pages are streamed into one CSV with no row cap', () async {
    Stream<List<Map<String, dynamic>>> pages() async* {
      for (var p = 0; p < 3; p++) {
        yield [
          for (var i = 0; i < 500; i++) {...row, 'id': 'p${p}_$i'},
        ];
      }
      yield [
        {...row, 'id': 'last'},
      ];
    }

    final result = await CsvExport.buildEnquiryCsv(pages(), isAdminUser: false);
    expect(result.count, 1501);
    final lines = result.csv.split('\r\n');
    expect(lines.length, 1502); // header + rows
    expect(lines.first, startsWith('ID,Customer Name'));
    expect(lines.last, startsWith('last,'));
  });

  test('an empty export has only the header and count 0', () async {
    final result = await CsvExport.buildEnquiryCsv(const Stream.empty(), isAdminUser: true);
    expect(result.count, 0);
  });
}
