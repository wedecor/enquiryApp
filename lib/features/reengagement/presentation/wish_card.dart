import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/occasion_kind.dart';
import '../domain/reengagement_templates.dart';

/// What a yearly wish card says. Pure — see [WishCardContent.forOccasion].
///
/// Two layouts:
/// - **named** (birthday with a person): eyebrow, cream title, the name in gold.
/// - **greeting**: eyebrow, "Dear Neha,", two gold lines.
class WishCardContent {
  const WishCardContent({
    required this.eyebrow,
    required this.creamLine,
    required this.goldLines,
    required this.line,
    required this.named,
  });

  /// Small letter-spaced caps at the top ("WISHING YOU").
  final String eyebrow;

  /// "Happy Birthday" (named) or "Dear Neha," (greeting).
  final String creamLine;

  /// The name (named, one line) or the wish (greeting, two lines).
  final List<String> goldLines;

  /// One quiet sentence under the divider.
  final String line;

  final bool named;

  /// Card text for an occasion. Numbers appear only where we know them: the
  /// wedding anniversary and the home anniversary (counted from the event we
  /// decorated or quoted). Birthdays never show an age.
  static WishCardContent forOccasion({
    required OccasionKind kind,
    required String customerName,
    required int nth,
    String? person,
  }) {
    final who = person?.trim() ?? '';
    final first = ReengagementTemplates.firstName(customerName);
    final dear = 'Dear ${who.isNotEmpty ? who : first},';
    final ordinal = OccasionKind.ordinal(nth < 1 ? 1 : nth);

    switch (kind) {
      case OccasionKind.birthday:
        if (who.isNotEmpty) {
          return WishCardContent(
            eyebrow: 'WISHING YOU',
            creamLine: 'Happy Birthday',
            goldLines: [who],
            line: 'A year full of good moments ahead.',
            named: true,
          );
        }
        return WishCardContent(
          eyebrow: 'WISHING YOU',
          creamLine: 'Dear $first,',
          goldLines: const ['Birthday', 'Wishes'],
          line: 'A happy year ahead for the birthday star.',
          named: false,
        );
      case OccasionKind.weddingAnniversary:
        return WishCardContent(
          eyebrow: 'WISHING YOU BOTH',
          creamLine: dear,
          goldLines: ['Happy $ordinal', 'Anniversary'],
          line: 'Many more happy years together.',
          named: false,
        );
      case OccasionKind.anniversary:
        return WishCardContent(
          eyebrow: 'WISHING YOU BOTH',
          creamLine: dear,
          goldLines: const ['Happy', 'Anniversary'],
          line: 'Many more happy years together.',
          named: false,
        );
      case OccasionKind.baby:
        return WishCardContent(
          eyebrow: 'WITH LOVE',
          creamLine: 'Dear $first,',
          goldLines: const ['Warm', 'Wishes'],
          line: 'Hope the little one is bringing you lots of joy.',
          named: false,
        );
      case OccasionKind.home:
        return WishCardContent(
          eyebrow: 'WISHING YOU',
          creamLine: 'Dear $first,',
          goldLines: ['Happy $ordinal Year', 'in Your Home'],
          line: 'Many more happy years there.',
          named: false,
        );
      case OccasionKind.corporate:
      case OccasionKind.celebration:
        return WishCardContent(
          eyebrow: 'THINKING OF YOU',
          creamLine: dear,
          goldLines: const ['Warm', 'Wishes'],
          line: 'Hope this time of year is a lovely one.',
          named: false,
        );
    }
  }
}

/// Draws the 1080 × 1080 wish card on the device (no server): charcoal ground,
/// thin gold frame, Cormorant Garamond + Jost, the gold WD mark, WE DECOR and
/// the tagline. Matches the approved sample (Nov 2026).
class WishCardRenderer {
  WishCardRenderer._();

  static const double size = 1080;
  static const String logoAsset = 'assets/brand/wd_mark_gold.png';

  static const Color _charcoal = Color(0xFF23262B);
  static const Color _cream = Color(0xFFEFE9DB);
  static const Color _gold = Color(0xFFC6A15B);
  static const Color _slate = Color(0xFF9A9EA2);

  /// Widest a text line may be inside the frame.
  static const double _maxTextWidth = 880;

  /// PNG bytes of the card for [content].
  static Future<Uint8List> renderPng(WishCardContent content) async {
    final logo = await _loadLogo();

    final eyebrow = GoogleFonts.jost(fontSize: 26, fontWeight: FontWeight.w400, letterSpacing: 7);
    final serifLight = GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300);
    final serifMedium = GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w500);
    final body = GoogleFonts.jost(fontSize: 34, fontWeight: FontWeight.w300);
    final brand = GoogleFonts.jost(fontWeight: FontWeight.w400);
    // Fonts download on first use; wait so the card never draws in a fallback face.
    await GoogleFonts.pendingFonts();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = _charcoal);
    canvas.drawRect(
      const Rect.fromLTRB(40, 40, size - 41, size - 41),
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    double dividerY;
    if (content.named) {
      _centered(canvas, content.eyebrow, eyebrow.copyWith(color: _slate), 210);
      _centered(canvas, content.creamLine, _fit(serifLight, 96, content.creamLine, _cream), 280);
      _centered(
        canvas,
        content.goldLines.first,
        _fit(serifMedium, 132, content.goldLines.first, _gold),
        405,
      );
      dividerY = 600;
    } else {
      _centered(canvas, content.eyebrow, eyebrow.copyWith(color: _slate), 195);
      _centered(canvas, content.creamLine, _fit(serifLight, 78, content.creamLine, _cream), 260);
      var y = 360.0;
      for (final goldLine in content.goldLines.take(2)) {
        _centered(canvas, goldLine, _fit(serifMedium, 116, goldLine, _gold), y);
        y += 110;
      }
      dividerY = 645;
    }

    canvas.drawLine(
      Offset(size / 2 - 40, dividerY),
      Offset(size / 2 + 40, dividerY),
      Paint()
        ..color = _gold
        ..strokeWidth = 2,
    );
    _centered(canvas, content.line, _fit(body, 34, content.line, _cream), dividerY + 36);

    // Sign-off: WD mark, WE DECOR, tagline (sized to stay readable in a chat preview).
    final logoTop = content.named ? 808.0 : 812.0;
    const logoWidth = 92.0;
    final logoHeight = logo.height * logoWidth / logo.width;
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH((size - logoWidth) / 2, logoTop, logoWidth, logoHeight),
      image: logo,
      filterQuality: FilterQuality.high,
    );
    _centered(
      canvas,
      'WE DECOR',
      brand.copyWith(fontSize: 24, letterSpacing: 6, color: _slate),
      logoTop + logoHeight + 14,
    );
    _centered(
      canvas,
      'BRINGING DREAMS TO LIFE',
      brand.copyWith(fontSize: 21, letterSpacing: 5, color: _gold),
      logoTop + logoHeight + 54,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    if (bytes == null) throw StateError('Wish card could not be encoded');
    return bytes.buffer.asUint8List();
  }

  static Future<ui.Image> _loadLogo() async {
    final data = await rootBundle.load(logoAsset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// [base] at [preferred] size, shrunk until [text] fits the frame (long names).
  static TextStyle _fit(TextStyle base, double preferred, String text, Color color) {
    var fontSize = preferred;
    while (fontSize > 28) {
      final style = base.copyWith(fontSize: fontSize, color: color, height: 1.0);
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width <= _maxTextWidth) return style;
      fontSize -= 4;
    }
    return base.copyWith(fontSize: fontSize, color: color, height: 1.0);
  }

  static void _centered(Canvas canvas, String text, TextStyle style, double top) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(height: style.height ?? 1.0),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: _maxTextWidth);
    // letterSpacing adds space after the last glyph too; centre on the visible text.
    final trailing = style.letterSpacing ?? 0;
    painter.paint(canvas, Offset((size - painter.width + trailing) / 2, top));
  }
}
