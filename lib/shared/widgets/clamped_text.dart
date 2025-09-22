import 'package:flutter/material.dart';

/// A text widget that clamps text scaling to prevent overflow in critical UI components.
///
/// This widget is designed for use in dense UI elements like buttons, chips, tabs,
/// and navigation items where text overflow would break the layout.
///
/// It uses a local MediaQuery to clamp text scaling to a narrower range [0.90, 1.10]
/// while maintaining accessibility for reasonable user text scaling.
class ClampedText extends StatelessWidget {
  /// The text to display.
  final String data;

  /// Optional text style to apply.
  final TextStyle? style;

  /// Maximum number of lines to display.
  /// Defaults to 1 for single-line text in dense UI.
  final int? maxLines;

  /// How to handle text overflow.
  /// Defaults to TextOverflow.ellipsis for single-line text.
  final TextOverflow? overflow;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Whether to enable soft wrapping.
  /// Defaults to false for dense UI components.
  final bool? softWrap;

  /// Creates a [ClampedText] widget.
  const ClampedText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Clamp text scaler to a narrower range for critical UI components
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.90,
      maxScaleFactor: 1.10,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Text(
        data,
        style: style,
        maxLines: maxLines ?? 1,
        overflow: overflow ?? TextOverflow.ellipsis,
        textAlign: textAlign,
        softWrap: softWrap ?? false,
      ),
    );
  }
}

/// A variant of ClampedText for multi-line content with more flexible scaling.
///
/// This widget allows more text scaling (up to 1.20) and enables soft wrapping
/// for content that can span multiple lines.
class ClampedTextFlexible extends StatelessWidget {
  /// The text to display.
  final String data;

  /// Optional text style to apply.
  final TextStyle? style;

  /// Maximum number of lines to display.
  /// Defaults to 2 for flexible multi-line content.
  final int? maxLines;

  /// How to handle text overflow.
  /// Defaults to TextOverflow.ellipsis.
  final TextOverflow? overflow;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Whether to enable soft wrapping.
  /// Defaults to true for flexible content.
  final bool? softWrap;

  /// Creates a [ClampedTextFlexible] widget.
  const ClampedTextFlexible(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Clamp text scaler to a slightly wider range for flexible content
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.90,
      maxScaleFactor: 1.20,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Text(
        data,
        style: style,
        maxLines: maxLines ?? 2,
        overflow: overflow ?? TextOverflow.ellipsis,
        textAlign: textAlign,
        softWrap: softWrap ?? true,
      ),
    );
  }
}
