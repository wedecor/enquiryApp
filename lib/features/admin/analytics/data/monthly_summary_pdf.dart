import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../services/dropdown_lookup.dart';
import '../../../enquiries/data/quotation_pdf_share.dart';
import '../../../reengagement/domain/occasion_reminder.dart';
import '../../../settings/domain/app_config.dart';
import '../domain/monthly_summary.dart';
import '../presentation/widgets/monthly_summary_sections.dart';
import '../presentation/widgets/pipeline_sections.dart' show formatDurationShort;

/// Monthly summary PDF — same letterhead/fonts as [QuotationPdf], compact tables.
class MonthlySummaryPdf {
  const MonthlySummaryPdf._();

  static final _charcoal = PdfColor.fromHex('#23262B');
  static final _gold = PdfColor.fromHex('#C6A15B');
  static final _goldDeep = PdfColor.fromHex('#9A7B33');
  static final _cream = PdfColor.fromHex('#EFE9DB');
  static final _slate = PdfColor.fromHex('#6E7377');
  static final _rule = PdfColor.fromHex('#D9D2C4');
  static final _ink = PdfColor.fromHex('#23262B');

  static const double _leftRule = 10;
  static const double _footerH = 28;
  static const double _pageMarginLeft = 40;
  static const double _pageMarginRight = 32;
  static const double _pageMarginTop = 28;
  static const double _pageMarginBottom = 42;

  static const _phonePrimary = '+91 88805 44452';
  static const _phoneSecondary = '+91 95912 32166';
  static const _email = 'connect2wedecor@gmail.com';
  static const _addressLine1 = 'Royal Manor, Ranoji Rao Road';
  static const _addressLine2 = 'Basavanagudi, Bengaluru 560004';

  static String fileNameFor(SummaryMonth month) => 'we-decor-summary-${month.fileStamp}.pdf';

  static Future<Uint8List> build({
    required MonthlySummary summary,
    required AppGeneralConfig company,
    DateTime? generatedAt,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final lockupData = await rootBundle.load('assets/brand/lockup_horizontal_ink.png');
    final lockup = pw.MemoryImage(lockupData.buffer.asUint8List());
    final generated = generatedAt ?? DateTime.now();
    final day = DateFormat('d MMM yyyy');
    final website = company.websiteUrl
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');

    final pdf = pw.Document();
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(
        _pageMarginLeft,
        _pageMarginTop,
        _pageMarginRight,
        _pageMarginBottom,
      ),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      buildBackground: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            pw.Positioned.fill(child: pw.Container(color: _cream)),
            pw.Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: pw.Container(width: _leftRule, color: _gold),
            ),
            pw.Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: pw.Container(
                height: _footerH,
                color: _charcoal,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Internal — We Decor Events',
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final hasPage2 = summary.team.isNotEmpty || summary.monthAhead != null;

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _letterhead(lockup, company.companyName, website),
            pw.SizedBox(height: 10),
            pw.Container(height: 0.7, color: _rule),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated ${day.format(generated)}',
              style: pw.TextStyle(color: _slate, fontSize: 8),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Monthly summary — ${summary.month.label}',
              style: pw.TextStyle(color: _charcoal, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            if (summary.sentences.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              for (final s in summary.sentences)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(s, style: pw.TextStyle(color: _ink, fontSize: 8.5)),
                ),
            ],
            pw.SizedBox(height: 8),
            ..._pageOneSections(summary),
          ],
        ),
      ),
    );

    if (hasPage2) {
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _letterhead(lockup, company.companyName, website),
              pw.SizedBox(height: 10),
              pw.Container(height: 0.7, color: _rule),
              pw.SizedBox(height: 10),
              pw.Text(
                'Monthly summary — ${summary.month.label} (continued)',
                style: pw.TextStyle(color: _charcoal, fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              if (summary.team.isNotEmpty) ...[
                _heading('Team'),
                _table(
                  ['Name', 'Enquiries', 'Bookings', 'Median response', 'Contacts logged'],
                  [
                    for (final m in summary.team)
                      [
                        m.name,
                        '${m.enquiriesAssigned}',
                        '${m.bookingsConfirmed}',
                        formatDurationShort(m.medianFirstResponse),
                        '${m.contactsLogged}',
                      ],
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
              if (summary.monthAhead != null) ...[
                _heading('The month ahead'),
                pw.Text(
                  'In Talks with a date next month: ${summary.monthAhead!.inTalksWithDate}',
                  style: pw.TextStyle(color: _ink, fontSize: 8),
                ),
                pw.SizedBox(height: 4),
                _table(
                  ['Week', 'Confirmed events'],
                  [
                    for (final w in summary.monthAhead!.weeks)
                      [_weekLabel(w), '${w.confirmedEvents}'],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Builds and shares/downloads like quotations. Returns page count used.
  static Future<({Uint8List bytes, int pages, String filename})> buildAndShare({
    required MonthlySummary summary,
    required AppGeneralConfig company,
    DateTime? generatedAt,
  }) async {
    final bytes = await build(summary: summary, company: company, generatedAt: generatedAt);
    final filename = fileNameFor(summary.month);
    await shareQuotationPdf(bytes: bytes, filename: filename);
    final pages = summary.team.isNotEmpty || summary.monthAhead != null ? 2 : 1;
    return (bytes: bytes, pages: pages, filename: filename);
  }

  static String _weekLabel(WeekAheadRow w) {
    final a = IstDate.calendar(w.weekStart);
    final b = IstDate.calendar(w.weekEnd.subtract(const Duration(days: 1)));
    return '${a.day}/${a.month}–${b.day}/${b.month}';
  }

  static pw.Widget _letterhead(pw.MemoryImage lockup, String companyName, String website) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(
                lockup,
                height: 32,
                fit: pw.BoxFit.contain,
                alignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                companyName,
                style: pw.TextStyle(color: _charcoal, fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(_addressLine1, style: _contactStyle()),
              pw.Text(_addressLine2, style: _contactStyle()),
              pw.Text('$_phonePrimary  ·  $_phoneSecondary', style: _contactStyle()),
              pw.Text(_email, style: _contactStyle()),
              if (website.isNotEmpty) pw.Text(website, style: _contactStyle()),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TextStyle _contactStyle() => pw.TextStyle(color: _slate, fontSize: 7, lineSpacing: 1.2);

  static pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4, top: 2),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: _goldDeep,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.4,
      ),
    ),
  );

  static List<pw.Widget> _pageOneSections(MonthlySummary s) {
    final out = <pw.Widget>[
      _heading('Headline'),
      _table(
        ['Metric', 'Value', 'vs last month', 'vs last year'],
        [
          _headlineCells('New enquiries', s.newEnquiries, 'count'),
          _headlineCells('Bookings confirmed', s.bookingsConfirmed, 'count'),
          _headlineCells('Events completed', s.eventsCompleted, 'count'),
          _headlineCells('Win rate', s.winRate, 'rate'),
          _headlineCells('Median first response', s.medianFirstResponse, 'duration'),
        ],
      ),
      pw.SizedBox(height: 6),
      _heading('Sources'),
      if (s.sources.isEmpty)
        pw.Text('—', style: pw.TextStyle(color: _slate, fontSize: 8))
      else
        _table(
          ['Source', 'Enquiries', 'Bookings', 'Note'],
          [
            for (final r in s.sources)
              [
                DropdownLookup.titleCase(r.source),
                '${r.enquiries}',
                '${r.bookings}',
                r.isBestConverting ? 'Best conversion' : '',
              ],
          ],
        ),
      pw.SizedBox(height: 6),
      _heading('What was booked'),
      pw.Text(
        'Returning ${s.returningCustomers} · New ${s.newCustomers}',
        style: pw.TextStyle(color: _ink, fontSize: 8),
      ),
      pw.SizedBox(height: 3),
      _compactPairs('By event type', s.bookingsByEventType),
      _compactPairs('By area', s.bookingsByArea),
      pw.SizedBox(height: 6),
      _heading('Lost'),
      pw.Text(
        '${s.lost.total} lost · before conversation ${s.lost.beforeConversation} · after talks ${s.lost.afterTalks}',
        style: pw.TextStyle(color: _ink, fontSize: 8),
      ),
      if (s.lost.topReasons.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        _table(
          ['Reason', 'Count'],
          [
            for (final r in s.lost.topReasons) [r.label, '${r.count}'],
          ],
        ),
      ],
      pw.SizedBox(height: 6),
      _heading('Events delivered'),
      pw.Text(
        [
          '${s.eventsDelivered.total} events',
          if (s.eventsDelivered.busiestDate != null)
            'busiest ${IstDate.short(s.eventsDelivered.busiestDate!)} (${s.eventsDelivered.busiestCount})',
          'days with 2+: ${s.eventsDelivered.daysWithTwoOrMore}',
        ].join(' · '),
        style: pw.TextStyle(color: _ink, fontSize: 8),
      ),
      pw.SizedBox(height: 6),
      _heading('Timing'),
      pw.Text(
        'Most enquiries: ${s.timing.busiestEnquiryWeekday ?? '—'} · '
        'Most events: ${s.timing.busiestEventWeekday ?? '—'}',
        style: pw.TextStyle(color: _ink, fontSize: 8),
      ),
      pw.SizedBox(height: 6),
      _heading('Wishes'),
      pw.Text(
        '${s.wishes.sent} sent · ${s.wishes.cameBack} came back',
        style: pw.TextStyle(color: _ink, fontSize: 8),
      ),
    ];
    if (s.stillOpen != null) {
      out.addAll([
        pw.SizedBox(height: 6),
        _heading('Still open'),
        pw.Text(
          '${s.stillOpen!.openNow} open · older than 30 days ${s.stillOpen!.olderThan30Days} · '
          'event date passed ${s.stillOpen!.eventDatePassed}',
          style: pw.TextStyle(color: _ink, fontSize: 8),
        ),
      ]);
    }
    return out;
  }

  static List<String> _headlineCells(String label, HeadlineMetric m, String kind) {
    return [
      label,
      formatHeadlineValue(m, kind: kind),
      formatMetricComparison(m.vsPreviousMonth, asPercentPoints: kind == 'rate'),
      formatMetricComparison(m.vsSameMonthLastYear, asPercentPoints: kind == 'rate'),
    ];
  }

  static pw.Widget _compactPairs(String title, List<CountLabelRow> rows) {
    if (rows.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text('$title: —', style: pw.TextStyle(color: _slate, fontSize: 7.5)),
      );
    }
    final text = rows.map((r) => '${DropdownLookup.titleCase(r.label)} ${r.count}').join(' · ');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text('$title: $text', style: pw.TextStyle(color: _ink, fontSize: 7.5)),
    );
  }

  static pw.Widget _table(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _rule, width: 0.4),
        bottom: pw.BorderSide(color: _rule, width: 0.6),
      ),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _charcoal),
          children: [
            for (final h in headers)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _gold),
                ),
              ),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              for (final cell in row)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: pw.Text(cell, style: pw.TextStyle(fontSize: 7.5, color: _ink)),
                ),
            ],
          ),
      ],
    );
  }
}
