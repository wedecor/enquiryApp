import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/pipeline_metrics.dart';

void main() {
  Map<String, dynamic> row(String id, String status, {String? area, num? total}) => {
    'id': id,
    'statusValue': status,
    'createdAt': DateTime(2026, 10, 1),
    if (area != null) 'locationArea': area,
    if (total != null) 'totalCost': total,
  };

  group('computeAreaBreakdown', () {
    test('counts approved + completed only, merging case and spacing', () {
      final areas = computeAreaBreakdown([
        row('a', 'approved', area: 'Indiranagar', total: 50000),
        row('b', 'completed', area: 'indiranagar ', total: 20000),
        row('c', 'confirmed', area: 'INDIRANAGAR'), // legacy approved alias
        row('d', 'in_talks', area: 'Indiranagar', total: 99999),
        row('e', 'not_interested', area: 'Whitefield'),
        row('f', 'new', area: 'Whitefield'),
        row('g', 'approved', area: 'whitefield', total: 10000),
      ]);
      expect(areas.map((a) => a.label), ['Indiranagar', 'Whitefield']);
      expect(areas[0].bookings, 3);
      expect(areas[0].bookedValue, 70000);
      expect(areas[1].bookings, 1);
      expect(areas[1].bookedValue, 10000);
    });

    test('Not specified row comes last even when largest', () {
      final areas = computeAreaBreakdown([
        row('a', 'approved'),
        row('b', 'approved', area: '  '),
        row('c', 'completed'),
        row('d', 'approved', area: 'Koramangala', total: 1000),
      ]);
      expect(areas.map((a) => a.label), ['Koramangala', 'Not specified']);
      expect(areas.last.isNotSpecified, isTrue);
      expect(areas.last.bookings, 3);
    });

    test('title-cases labels and keeps short acronyms', () {
      expect(areaDisplayLabel('hsr   layout'), 'Hsr Layout');
      expect(areaDisplayLabel('HSR Layout'), 'HSR Layout');
      expect(areaDisplayLabel('jp NAGAR'), 'Jp Nagar');
      expect(areaKeyOf({'locationArea': ' HSR  Layout '}), 'hsr layout');
      expect(areaKeyOf({'locationArea': 42}), '');
    });

    test('ties sort by booked value, then label', () {
      final areas = computeAreaBreakdown([
        row('a', 'approved', area: 'Yelahanka', total: 100),
        row('b', 'approved', area: 'Hebbal', total: 500),
        row('c', 'approved', area: 'Banashankari', total: 100),
      ]);
      expect(areas.map((a) => a.label), ['Hebbal', 'Banashankari', 'Yelahanka']);
    });

    test('duplicates are left out', () {
      final areas = computeAreaBreakdown([
        {...row('a', 'approved', area: 'Hebbal'), 'mergedInto': 'b'},
      ]);
      expect(areas, isEmpty);
    });

    test('buildPipelineReport exposes areas for the period', () {
      final report = buildPipelineReport(
        allRows: [
          row('a', 'approved', area: 'Hebbal', total: 100),
          {...row('b', 'approved', area: 'Hebbal'), 'createdAt': DateTime(2025, 1, 1)},
        ],
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 11, 1),
        attribution: AnalyticsAttribution.enquiryDate,
        now: DateTime(2026, 10, 15),
      );
      expect(report.areas, hasLength(1));
      expect(report.areas.single.bookings, 1);
    });
  });
}
