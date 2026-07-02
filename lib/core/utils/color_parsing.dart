import 'package:flutter/material.dart';

/// Parses hex, `0x`, or `rgb()`/`rgba()` color strings from Firestore dropdowns.
Color? parseDropdownColor(String? input) {
  if (input == null) return null;
  var s = input.trim();
  if (s.isEmpty) return null;

  final rgbRe = RegExp(
    r'^rgba?\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*([0-1]?\.?\d+))?\s*\)$',
    caseSensitive: false,
  );
  final match = rgbRe.firstMatch(s);
  if (match != null) {
    int clampChannel(String v) => int.parse(v).clamp(0, 255);
    final r = clampChannel(match.group(1)!);
    final g = clampChannel(match.group(2)!);
    final b = clampChannel(match.group(3)!);
    final rawAlpha = match.group(4);
    final alpha = rawAlpha != null
        ? (double.tryParse(rawAlpha) ?? 1).clamp(0.0, 1.0)
        : 1.0;
    return Color.fromRGBO(r, g, b, alpha);
  }

  s = s.replaceAll('#', '').trim();
  if (s.startsWith('0x')) {
    try {
      var value = int.parse(s);
      if (value <= 0xFFFFFF) value = 0xFF000000 | value;
      return Color(value);
    } catch (_) {}
  }

  final hexRe = RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$');
  if (hexRe.hasMatch(s)) {
    if (s.length == 6) {
      return Color(int.parse('0xFF${s.toUpperCase()}'));
    }
    if (s.length == 8) {
      final rr = s.substring(0, 2).toUpperCase();
      final gg = s.substring(2, 4).toUpperCase();
      final bb = s.substring(4, 6).toUpperCase();
      final aa = s.substring(6, 8).toUpperCase();
      return Color(int.parse('0x$aa$rr$gg$bb'));
    }
  }

  try {
    final value = int.parse(s);
    if (value <= 0xFFFFFF) return Color(0xFF000000 | value);
    return Color(value);
  } catch (_) {}

  return null;
}
