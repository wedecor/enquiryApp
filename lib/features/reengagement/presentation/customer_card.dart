import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../domain/occasion_kind.dart';
import '../domain/reengagement_templates.dart';

/// Layouts drawn by [CustomerCardRenderer].
enum CustomerCardLayout {
  /// Eyebrow / greeting / headline / divider / body / WD sign-off.
  standard,

  /// Horizontal lockup + taglines (first contact / follow-up / no-date reminder).
  brand,
}

/// What a customer WhatsApp card says. Pure data — see factories below.
class CustomerCardContent {
  const CustomerCardContent({
    required this.eyebrow,
    required this.headlineLines,
    required this.bodyLine,
    this.greeting,
    this.layout = CustomerCardLayout.standard,
    this.websiteLine,
  }) : assert(headlineLines.length >= 1 && headlineLines.length <= 2);

  /// Small letter-spaced caps ("WITH GRATITUDE", "COUNTING DOWN").
  final String eyebrow;

  /// "Dear Priya," — null when there is no usable first name (eyebrow moves down).
  final String? greeting;

  /// Gold headline, 1–2 lines.
  final List<String> headlineLines;

  /// Quiet sentence under the divider.
  final String bodyLine;

  final CustomerCardLayout layout;

  /// Brand card only: "wedecorevents.com  ·  @handle" (null = omit).
  final String? websiteLine;

  // ---------------------------------------------------------------------------
  // A — Brand
  // ---------------------------------------------------------------------------

  /// Non-personalised We Decor card (flows 1–2, and flow 3 when date missing).
  static CustomerCardContent brand({String? websiteUrl, String? instagramHandle}) {
    return CustomerCardContent(
      eyebrow: '',
      greeting: null,
      headlineLines: const [''],
      bodyLine: '',
      layout: CustomerCardLayout.brand,
      websiteLine: _formatWebsiteLine(websiteUrl: websiteUrl, instagramHandle: instagramHandle),
    );
  }

  static String? _formatWebsiteLine({String? websiteUrl, String? instagramHandle}) {
    final parts = <String>[];
    final host = _displayHost(websiteUrl);
    if (host != null) parts.add(host);
    final ig = (instagramHandle ?? '').trim();
    if (ig.isNotEmpty) {
      parts.add(ig.startsWith('@') ? ig : '@$ig');
    }
    if (parts.isEmpty) return null;
    return parts.join('  ·  ');
  }

  static String? _displayHost(String? url) {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) return null;
    var s = raw.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    s = s.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    s = s.split('/').first.trim();
    return s.isEmpty ? null : s;
  }

  // ---------------------------------------------------------------------------
  // B — Countdown (Follow Up tab)
  // ---------------------------------------------------------------------------

  /// Personalised countdown. Returns null when [eventDate] is unusable — caller
  /// should fall back to [brand].
  static CustomerCardContent? countdown({
    required String customerName,
    required String? eventTypeLabel,
    required DateTime? eventDate,
    required DateTime now,
  }) {
    if (eventDate == null || eventDate.year <= 1971) return null;

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final days = day.difference(today).inDays;
    if (days < 0) return null;

    final first = ReengagementTemplates.firstName(customerName);
    final greeting = first == 'there' ? null : 'Dear $first,';
    final event = titleCaseEvent(eventTypeLabel);
    final dateBody = DateFormat('EEEE, d MMMM yyyy').format(day);

    if (days == 0) {
      return CustomerCardContent(
        eyebrow: 'THE DAY IS HERE',
        greeting: greeting,
        headlineLines: _countdownHeadline(prefix: 'Today is', event: event),
        bodyLine: dateBody,
      );
    }
    if (days == 1) {
      return CustomerCardContent(
        eyebrow: 'ALMOST TIME',
        greeting: greeting,
        headlineLines: _countdownHeadline(prefix: 'Tomorrow is', event: event),
        bodyLine: dateBody,
      );
    }
    return CustomerCardContent(
      eyebrow: 'COUNTING DOWN',
      greeting: greeting,
      headlineLines: _countdownHeadline(
        prefix: '${cardinalWord(days)} Days',
        event: event,
        toForm: true,
      ),
      bodyLine: dateBody,
    );
  }

  /// Builds ["{prefix}", "to Your {Event}"] / ["Your {Event}"] with fallbacks
  /// when the event label is unusually long (renderer still shrinks to fit).
  static List<String> _countdownHeadline({
    required String prefix,
    required String event,
    bool toForm = false,
  }) {
    // Prefer the natural line; only drop words for very long event labels.
    final long = event.length > 28;
    if (toForm) {
      if (!long) return [prefix, 'to Your $event'];
      if (event.length <= 36) return [prefix, 'to $event'];
      return [prefix, 'to the Big Day'];
    }
    if (!long) return [prefix, 'Your $event'];
    if (event.length <= 36) return [prefix, event];
    return [prefix, 'the Big Day'];
  }

  // ---------------------------------------------------------------------------
  // C — Thank-you
  // ---------------------------------------------------------------------------

  static CustomerCardContent thankYou({required String customerName, String? eventTypeLabel}) {
    final first = ReengagementTemplates.firstName(customerName);
    final greeting = first == 'there' ? null : 'Dear $first,';
    final rawEvent = eventTypeLabel?.trim() ?? '';
    final event = rawEvent.isEmpty ? 'celebration' : rawEvent.toLowerCase();
    return CustomerCardContent(
      eyebrow: 'WITH GRATITUDE',
      greeting: greeting,
      headlineLines: const ['Thank You'],
      bodyLine: 'It was a joy to be part of your $event.',
    );
  }

  // ---------------------------------------------------------------------------
  // D / E — Yearly wishes
  // ---------------------------------------------------------------------------

  static CustomerCardContent forOccasion({
    required OccasionKind kind,
    required String customerName,
    required int nth,
    required bool enquired,
    String? person,
  }) {
    final who = person?.trim() ?? '';
    final first = ReengagementTemplates.firstName(customerName);
    final dear = first == 'there' ? null : 'Dear $first,';
    final n = nth < 1 ? 1 : nth;
    final nthWord = ordinalWord(n);

    if (enquired) {
      return _enquired(kind: kind, dear: dear, person: who);
    }
    return _past(kind: kind, dear: dear, who: who, nthWord: nthWord);
  }

  static CustomerCardContent _past({
    required OccasionKind kind,
    required String? dear,
    required String who,
    required String nthWord,
  }) {
    switch (kind) {
      case OccasionKind.weddingAnniversary:
        return CustomerCardContent(
          eyebrow: 'WISHING YOU BOTH',
          greeting: dear,
          headlineLines: ['$nthWord Anniversary', 'Wishes'],
          bodyLine: 'Many more happy years together.',
        );
      case OccasionKind.birthday:
        if (who.isNotEmpty) {
          return CustomerCardContent(
            eyebrow: 'WISHING YOU',
            greeting: 'Birthday Wishes',
            headlineLines: [who],
            bodyLine: 'A wonderful year ahead.',
          );
        }
        return CustomerCardContent(
          eyebrow: 'WISHING YOU',
          greeting: dear,
          headlineLines: const ['Birthday', 'Wishes'],
          bodyLine: 'A happy year ahead for the birthday star.',
        );
      case OccasionKind.anniversary:
        return CustomerCardContent(
          eyebrow: 'WISHING YOU BOTH',
          greeting: dear,
          headlineLines: const ['Anniversary', 'Wishes'],
          bodyLine: 'Many more happy years together.',
        );
      case OccasionKind.baby:
        return CustomerCardContent(
          eyebrow: 'WITH LOVE',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Good health and happy days to your family.',
        );
      case OccasionKind.home:
        return CustomerCardContent(
          eyebrow: 'WISHING YOU',
          greeting: dear,
          headlineLines: ['$nthWord Year', 'in Your Home'],
          bodyLine: 'Many more happy years there.',
        );
      case OccasionKind.corporate:
        return CustomerCardContent(
          eyebrow: 'WARM WISHES',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'From all of us at We Decor.',
        );
      case OccasionKind.celebration:
        return CustomerCardContent(
          eyebrow: 'THINKING OF YOU',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Hope this time of year is a lovely one.',
        );
    }
  }

  static CustomerCardContent _enquired({
    required OccasionKind kind,
    required String? dear,
    required String person,
  }) {
    switch (kind) {
      case OccasionKind.weddingAnniversary:
        return CustomerCardContent(
          eyebrow: 'WISHING YOU BOTH',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Happiness and a wonderful year ahead.',
        );
      case OccasionKind.birthday:
        if (person.isNotEmpty) {
          return CustomerCardContent(
            eyebrow: 'WISHING YOU',
            greeting: dear,
            headlineLines: const ['Warm', 'Wishes'],
            bodyLine: 'A happy and healthy year ahead for $person.',
          );
        }
        return CustomerCardContent(
          eyebrow: 'WISHING YOU',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'A happy and healthy year ahead.',
        );
      case OccasionKind.anniversary:
        return CustomerCardContent(
          eyebrow: 'WISHING YOU',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Many happy years ahead.',
        );
      case OccasionKind.baby:
        return CustomerCardContent(
          eyebrow: 'WITH LOVE',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Good health and happy days to your family.',
        );
      case OccasionKind.home:
        return CustomerCardContent(
          eyebrow: 'WISHING YOU',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Many happy years in your home.',
        );
      case OccasionKind.corporate:
        return CustomerCardContent(
          eyebrow: 'WARM WISHES',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'From all of us at We Decor.',
        );
      case OccasionKind.celebration:
        return CustomerCardContent(
          eyebrow: 'THINKING OF YOU',
          greeting: dear,
          headlineLines: const ['Warm', 'Wishes'],
          bodyLine: 'Wishing you a happy year ahead.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  static const List<String> _ordinalWords = [
    '',
    'First',
    'Second',
    'Third',
    'Fourth',
    'Fifth',
    'Sixth',
    'Seventh',
    'Eighth',
    'Ninth',
    'Tenth',
    'Eleventh',
    'Twelfth',
    'Thirteenth',
    'Fourteenth',
    'Fifteenth',
    'Sixteenth',
    'Seventeenth',
    'Eighteenth',
    'Nineteenth',
    'Twentieth',
  ];

  static const List<String> _cardinalWords = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
    'Twenty',
  ];

  /// Ordinals 1–20 as words; above 20 as digits (drawn with lining figures).
  static String ordinalWord(int n) {
    if (n >= 1 && n <= 20) return _ordinalWords[n];
    return OccasionKind.ordinal(n);
  }

  /// Cardinals 0–20 as words; above 20 as digits.
  static String cardinalWord(int n) {
    if (n >= 0 && n <= 20) return _cardinalWords[n];
    return '$n';
  }

  /// Title-cases an event label; blank → "Celebration".
  static String titleCaseEvent(String? label) {
    final raw = (label ?? '').trim();
    if (raw.isEmpty) return 'Celebration';
    return raw
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}

/// Colours for every customer card (nothing hard-coded in drawing paths).
class CustomerCardColors {
  CustomerCardColors._();

  static const Color ground = Color(0xFFFBF7EF);
  static const Color ink = Color(0xFF23262B);
  static const Color gold = Color(0xFFB08A46);
  static const Color goldLine = Color(0xFFC6A15B);
  static const Color body = Color(0xFF4A4E53);
  static const Color slate = Color(0xFF6E7377);
}

/// Draws 1080×1080 logical cards at 2160×2160 PNG (canvas.scale(2)).
class CustomerCardRenderer {
  CustomerCardRenderer._();

  static const double logicalSize = 1080;
  static const int pixelSize = 2160;
  static const double maxTextWidth = 880;
  static const String markAsset = 'assets/brand/wd_mark_ink.png';
  static const String lockupAsset = 'assets/brand/lockup_horizontal_ink.png';

  /// Last headline font size used (logical px) — for shrink reporting.
  static double? lastHeadlineSize;

  static Uint8List? _brandCache;
  static String? _brandCacheKey;

  /// PNG bytes for [content]. Brand layout is cached per session + website line.
  static Future<Uint8List> renderPng(CustomerCardContent content) async {
    if (content.layout == CustomerCardLayout.brand) {
      final key = content.websiteLine ?? '';
      if (_brandCache != null && _brandCacheKey == key) return _brandCache!;
      final png = await _render(content);
      _brandCache = png;
      _brandCacheKey = key;
      return png;
    }
    return _render(content);
  }

  /// Clears the brand session cache (tests).
  static void clearBrandCache() {
    _brandCache = null;
    _brandCacheKey = null;
  }

  static Future<Uint8List> _render(CustomerCardContent content) async {
    lastHeadlineSize = null;
    await GoogleFonts.pendingFonts();

    final recorder = ui.PictureRecorder();
    // Cull in pixel space (after scale(2) logical 1080 → 2160). A 1080 cull
    // clipped the lower half of every card (divider / body / sign-off).
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelSize.toDouble(), pixelSize.toDouble()),
    );
    canvas.scale(2);

    // Fill + frames in logical space (scale already applied).
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, logicalSize, logicalSize),
      Paint()..color = CustomerCardColors.ground,
    );
    canvas.drawRect(
      const Rect.fromLTRB(36, 36, logicalSize - 36, logicalSize - 36),
      Paint()
        ..color = CustomerCardColors.goldLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      const Rect.fromLTRB(52, 52, logicalSize - 52, logicalSize - 52),
      Paint()
        ..color = CustomerCardColors.goldLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (content.layout == CustomerCardLayout.brand) {
      await _drawBrand(canvas, content);
    } else {
      await _drawStandard(canvas, content);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelSize, pixelSize);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    if (bytes == null) throw StateError('Customer card could not be encoded');
    return bytes.buffer.asUint8List();
  }

  static Future<void> _drawBrand(Canvas canvas, CustomerCardContent content) async {
    final lockup = await _loadImage(lockupAsset);
    // Logical width 620 → 1240 px at 2×. Source is 1191×270 — within 2× of source.
    const lockupW = 620.0;
    final lockupH = lockup.height * lockupW / lockup.width;
    const lockupTop = 330.0;
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH((logicalSize - lockupW) / 2, lockupTop, lockupW, lockupH),
      image: lockup,
      filterQuality: FilterQuality.high,
    );
    lockup.dispose();

    final jost = GoogleFonts.jost(fontWeight: FontWeight.w400);
    final jostLight = GoogleFonts.jost(fontWeight: FontWeight.w300);

    _centered(
      canvas,
      'EVENTS · DECOR · CELEBRATIONS',
      jost.copyWith(fontSize: 24, letterSpacing: 6, color: CustomerCardColors.slate, height: 1.0),
      560,
    );

    canvas.drawLine(
      const Offset(logicalSize / 2 - 40, 640),
      const Offset(logicalSize / 2 + 40, 640),
      Paint()
        ..color = CustomerCardColors.goldLine
        ..strokeWidth = 2,
    );

    _centered(
      canvas,
      'BRINGING DREAMS TO LIFE',
      jost.copyWith(fontSize: 26, letterSpacing: 6, color: CustomerCardColors.gold, height: 1.0),
      680,
    );

    final site = content.websiteLine;
    if (site != null && site.isNotEmpty) {
      _centered(
        canvas,
        site,
        jostLight.copyWith(fontSize: 28, color: CustomerCardColors.body, height: 1.0),
        860,
      );
    }
  }

  static Future<void> _drawStandard(Canvas canvas, CustomerCardContent content) async {
    final jost = GoogleFonts.jost(fontWeight: FontWeight.w400);
    final jostLight = GoogleFonts.jost(fontWeight: FontWeight.w300);
    final serifLight = GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300);
    final serifMedium = GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w500);

    final hasGreeting = content.greeting != null && content.greeting!.trim().isNotEmpty;
    final eyebrowTop = hasGreeting ? 195.0 : 250.0;

    _centered(
      canvas,
      content.eyebrow.toUpperCase(),
      jost.copyWith(fontSize: 26, letterSpacing: 7, color: CustomerCardColors.gold, height: 1.0),
      eyebrowTop,
    );

    if (hasGreeting) {
      _centered(
        canvas,
        content.greeting!,
        _fit(
          serifLight,
          preferred: 80,
          min: 72,
          text: content.greeting!,
          color: CustomerCardColors.ink,
          liningFigures: _needsLiningFigures(content.greeting!),
        ),
        250,
      );
    }

    final gold = content.headlineLines.take(2).toList();
    var usedHeadline = 118.0;
    if (gold.length == 1) {
      final style = _fitHeadline(serifMedium, gold.first);
      usedHeadline = style.fontSize ?? 118;
      _centered(canvas, gold.first, style, 420);
    } else {
      var y = 365.0;
      for (final line in gold) {
        final style = _fitHeadline(serifMedium, line);
        final size = style.fontSize ?? 118;
        if (size < usedHeadline) usedHeadline = size;
        _centered(canvas, line, style, y);
        y += 112;
      }
    }
    lastHeadlineSize = usedHeadline;

    canvas.drawLine(
      const Offset(logicalSize / 2 - 40, 650),
      const Offset(logicalSize / 2 + 40, 650),
      Paint()
        ..color = CustomerCardColors.goldLine
        ..strokeWidth = 2,
    );

    _centered(
      canvas,
      content.bodyLine,
      _fit(
        jostLight,
        preferred: 34,
        min: 26,
        text: content.bodyLine,
        color: CustomerCardColors.body,
        liningFigures: _needsLiningFigures(content.bodyLine),
      ),
      684,
      ellipsis: true,
    );

    final mark = await _loadImage(markAsset);
    const logoWidth = 92.0;
    final logoHeight = mark.height * logoWidth / mark.width;
    const logoTop = 812.0;
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH((logicalSize - logoWidth) / 2, logoTop, logoWidth, logoHeight),
      image: mark,
      filterQuality: FilterQuality.high,
    );
    mark.dispose();

    _centered(
      canvas,
      'WE DECOR',
      jost.copyWith(fontSize: 24, letterSpacing: 6, color: CustomerCardColors.slate, height: 1.0),
      logoTop + logoHeight + 14,
    );
    _centered(
      canvas,
      'BRINGING DREAMS TO LIFE',
      jost.copyWith(fontSize: 21, letterSpacing: 5, color: CustomerCardColors.gold, height: 1.0),
      logoTop + logoHeight + 54,
    );
  }

  static TextStyle _fitHeadline(TextStyle base, String text) {
    return _fit(
      base,
      preferred: 118,
      min: 72,
      text: text,
      color: CustomerCardColors.gold,
      liningFigures: _needsLiningFigures(text),
    );
  }

  static bool _needsLiningFigures(String text) => RegExp(r'\d').hasMatch(text);

  static TextStyle _fit(
    TextStyle base, {
    required double preferred,
    required double min,
    required String text,
    required Color color,
    bool liningFigures = false,
  }) {
    var fontSize = preferred;
    while (fontSize > min) {
      final style = base.copyWith(
        fontSize: fontSize,
        color: color,
        height: 1.0,
        fontFeatures: liningFigures ? const [FontFeature.liningFigures()] : null,
      );
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width <= maxTextWidth) return style;
      fontSize -= 4;
    }
    return base.copyWith(
      fontSize: min,
      color: color,
      height: 1.0,
      fontFeatures: liningFigures ? const [FontFeature.liningFigures()] : null,
    );
  }

  static void _centered(
    Canvas canvas,
    String text,
    TextStyle style,
    double top, {
    bool ellipsis = false,
  }) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(height: style.height ?? 1.0),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: ellipsis ? '…' : null,
    )..layout(maxWidth: maxTextWidth);
    final trailing = style.letterSpacing ?? 0;
    painter.paint(canvas, Offset((logicalSize - painter.width + trailing) / 2, top));
  }

  static Future<ui.Image> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
