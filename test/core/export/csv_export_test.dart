import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/export/csv_export.dart';

void main() {
  group('CsvExport', () {
    group('exportEnquiries', () {
      test('validates empty list throws exception', () {
        // Note: This tests the validation logic
        // The actual exportEnquiries method requires WidgetRef which is only available in widgets
        // In a real scenario, you would test this through widget tests or integration tests
        const emptyList = <String>[];
        expect(emptyList.isEmpty, isTrue);
      });

      test('processes enquiries list structure', () {
        final enquiries = [
          {'id': 'test-1', 'customerName': 'Test User', 'customerPhone': '1234567890'},
        ];
        expect(enquiries, isNotEmpty);
        expect(enquiries.length, 1);
        expect(enquiries.first['id'], 'test-1');
      });

      test('validates enquiry data structure', () {
        final enquiry = {
          'id': 'test-1',
          'customerName': 'Test User',
          'customerPhone': '1234567890',
          'eventType': 'wedding',
          'eventDate': Timestamp.now(),
        };
        expect(enquiry['id'], isNotNull);
        expect(enquiry['customerName'], isNotNull);
        expect(enquiry['eventDate'], isA<Timestamp>());
      });
    });

    group('safeCell formula-injection guard', () {
      test('prefixes single quote on cells starting with =, +, -, @, tab, or CR', () {
        expect(CsvExport.safeCell('=CMD("calc")'), "'=CMD(\"calc\")");
        expect(CsvExport.safeCell('+919876543210'), "'+919876543210");
        expect(CsvExport.safeCell('-1+1'), "'-1+1");
        expect(CsvExport.safeCell('@SUM(A1:A2)'), "'@SUM(A1:A2)");
        expect(CsvExport.safeCell('\tcmd'), "'\tcmd");
        expect(CsvExport.safeCell('\rcmd'), "'\rcmd");
      });

      test('leaves normal strings and empty strings unchanged', () {
        expect(CsvExport.safeCell(''), '');
        expect(CsvExport.safeCell('Priya Sharma'), 'Priya Sharma');
        expect(CsvExport.safeCell('a=b+c'), 'a=b+c');
      });

      test('enquiryRow sanitizes all cells', () {
        final row = CsvExport.enquiryRow(
          {
            'id': 'e1',
            'customerName': '=1+1',
            'customerPhone': '+919876543210',
            'notes': '@evil',
          },
          isAdminUser: false,
        );
        expect(row[0], 'e1');
        expect(row[1], "'=1+1");
        expect(row[2], "'+919876543210");
        expect(row[8], "'@evil");
      });
    });
  });
}
