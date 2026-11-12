import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/domain/app_config.dart';
import '../domain/quotation.dart';

/// Quotation PDF styled like the We Decor letterhead (brand kit).
///
/// Cream page, gold left rule, horizontal ink lockup, charcoal footer.
/// Official kit colours: charcoal #23262B · gold #C6A15B · cream #EFE9DB · slate #6E7377.
class QuotationPdf {
  const QuotationPdf._();

  static final _charcoal = PdfColor.fromHex('#23262B');
  static final _gold = PdfColor.fromHex('#C6A15B');
  static final _goldDeep = PdfColor.fromHex('#9A7B33');
  static final _cream = PdfColor.fromHex('#EFE9DB');
  static final _slate = PdfColor.fromHex('#6E7377');
  static final _rule = PdfColor.fromHex('#D9D2C4');
  static final _ink = PdfColor.fromHex('#23262B');
  static final _rowAlt = PdfColor.fromHex('#F7F3EA');

  static const double _leftRule = 10;
  static const double _footerH = 28;
  static const double _pageMarginLeft = 40;
  static const double _pageMarginRight = 32;
  static const double _pageMarginTop = 28;
  static const double _pageMarginBottom = 42;

  /// Letterhead contact (from wedecorevents.com).
  static const _phonePrimary = '+91 88805 44452';
  static const _phoneSecondary = '+91 95912 32166';
  static const _email = 'connect2wedecor@gmail.com';
  static const _addressLine1 = 'Royal Manor, Ranoji Rao Road';
  static const _addressLine2 = 'Basavanagudi, Bengaluru 560004';

  static Future<Uint8List> build({
    required Quotation quotation,
    required AppGeneralConfig company,
    required String customerName,
    String? customerPhone,
    String? eventLabel,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final lockupData = await rootBundle.load('assets/brand/lockup_horizontal_ink.png');
    final lockup = pw.MemoryImage(lockupData.buffer.asUint8List());

    final currency = company.currency == 'INR' ? '₹' : company.currency;
    final money = NumberFormat.currency(locale: 'en_IN', symbol: currency, decimalDigits: 0);
    final day = DateFormat('d MMM yyyy');
    final totals = QuotationTotals.of(quotation.items);
    final issueDate = quotation.sentAt ?? quotation.createdAt ?? DateTime.now();
    final showGst = totals.gstTotal > 0 || quotation.items.any((i) => i.gstPercent > 0);
    final website = company.websiteUrl
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
    final footerSite = website.isEmpty ? 'WEDECOREVENTS.COM' : website.toUpperCase();

    final metaParts = <String>[
      day.format(issueDate),
      'Ref ${quotation.reference ?? quotation.id}',
      if (quotation.validUntil != null) 'Valid until ${day.format(quotation.validUntil!)}',
    ];

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
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
                      'EVENTS · DECOR · CELEBRATIONS  •  $footerSite',
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        build: (context) => [
          // ── Letterhead: lockup left, all contact stacked top-right ───
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Image(
                    lockup,
                    height: 38,
                    fit: pw.BoxFit.contain,
                    alignment: pw.Alignment.centerLeft,
                  ),
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
          ),

          pw.SizedBox(height: 14),
          pw.Container(height: 0.7, color: _rule),
          pw.SizedBox(height: 16),

          // ── Quiet meta + modest title ────────────────────────────────
          pw.Text(metaParts.join('  ·  '), style: pw.TextStyle(color: _slate, fontSize: 8)),
          pw.SizedBox(height: 8),
          pw.Text(
            'QUOTATION',
            style: pw.TextStyle(
              color: _charcoal,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Prepared for ─────────────────────────────────────────────
          _eyebrow('PREPARED FOR'),
          pw.SizedBox(height: 4),
          pw.Text(
            customerName,
            style: pw.TextStyle(color: _ink, fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (customerPhone != null && customerPhone.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(customerPhone, style: pw.TextStyle(color: _slate, fontSize: 9)),
            ),
          if (eventLabel != null && eventLabel.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                eventLabel,
                style: pw.TextStyle(color: _goldDeep, fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),

          pw.SizedBox(height: 18),

          // ── Line items ───────────────────────────────────────────────
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
              bottom: pw.BorderSide(color: _rule, width: 0.8),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(4.6),
              1: const pw.FlexColumnWidth(0.9),
              2: const pw.FlexColumnWidth(1.5),
              if (showGst) 3: const pw.FlexColumnWidth(1.0),
              (showGst ? 4 : 3): const pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _charcoal),
                children: [
                  _th('Description'),
                  _th('Qty', align: pw.TextAlign.right),
                  _th('Rate', align: pw.TextAlign.right),
                  if (showGst) _th('GST%', align: pw.TextAlign.right),
                  _th('Amount', align: pw.TextAlign.right),
                ],
              ),
              for (var i = 0; i < quotation.items.length; i++)
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : _rowAlt),
                  children: [
                    _td(quotation.items[i].description),
                    _td(
                      quotation.items[i].quantity.toStringAsFixed(
                        quotation.items[i].quantity % 1 == 0 ? 0 : 1,
                      ),
                      align: pw.TextAlign.right,
                    ),
                    _td(money.format(quotation.items[i].unitPrice), align: pw.TextAlign.right),
                    if (showGst)
                      _td(
                        quotation.items[i].gstPercent.toStringAsFixed(0),
                        align: pw.TextAlign.right,
                      ),
                    _td(
                      money.format(quotation.items[i].amount),
                      align: pw.TextAlign.right,
                      bold: true,
                    ),
                  ],
                ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Totals (single block, right) ─────────────────────────────
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 200,
              child: pw.Column(
                children: [
                  _total('Subtotal', money.format(totals.subtotal)),
                  if (totals.discountTotal > 0)
                    _total('Discount', '- ${money.format(totals.discountTotal)}'),
                  if (showGst) _total('GST', money.format(totals.gstTotal)),
                  pw.SizedBox(height: 6),
                  pw.Container(height: 0.7, color: _rule),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          color: _goldDeep,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      pw.Text(
                        money.format(totals.total),
                        style: pw.TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (quotation.notes != null && quotation.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _eyebrow('NOTES'),
            pw.SizedBox(height: 4),
            pw.Text(
              quotation.notes!.trim(),
              style: pw.TextStyle(color: _ink, fontSize: 9, lineSpacing: 2.5),
            ),
          ],

          pw.SizedBox(height: 28),
          pw.Center(
            child: pw.Text(
              'Thank you for considering We Decor.',
              style: pw.TextStyle(color: _slate, fontSize: 8.5, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.TextStyle _contactStyle() =>
      pw.TextStyle(color: _slate, fontSize: 7.5, lineSpacing: 1.4);

  static pw.Widget _eyebrow(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      color: _goldDeep,
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 1.4,
    ),
  );

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: _gold,
        letterSpacing: 0.5,
      ),
    ),
  );

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9,
            color: _ink,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _total(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: _slate, fontSize: 9)),
        pw.Text(
          value,
          style: pw.TextStyle(color: _ink, fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}
