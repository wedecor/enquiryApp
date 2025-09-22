import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A widget for large headlines that automatically scales to fit available space.
///
/// This widget uses AutoSizeText to prevent overflow in large headlines while
/// maintaining readability. It's designed for hero titles, section headers,
/// and other large text elements.
class AutoSizeHeadline extends StatelessWidget {
  /// The text to display.
  final String text;

  /// Optional text style to apply.
  final TextStyle? style;

  /// Maximum number of lines to display.
  /// Defaults to 2 for headlines.
  final int? maxLines;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Minimum font size to scale down to.
  /// Defaults to 12 to maintain readability.
  final double? minFontSize;

  /// Step granularity for font size changes.
  /// Defaults to 0.5 for smooth scaling.
  final double? stepGranularity;

  /// Creates an [AutoSizeHeadline] widget.
  const AutoSizeHeadline(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.minFontSize,
    this.stepGranularity,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style ?? Theme.of(context).textTheme.headlineLarge,
      maxLines: maxLines ?? 2,
      textAlign: textAlign,
      minFontSize: minFontSize ?? 12.0,
      stepGranularity: stepGranularity ?? 0.5,
      overflow: TextOverflow.ellipsis,
      wrapWords: true,
    );
  }
}

/// A variant of AutoSizeHeadline for display text (very large headlines).
class AutoSizeDisplay extends StatelessWidget {
  /// The text to display.
  final String text;

  /// Optional text style to apply.
  final TextStyle? style;

  /// Maximum number of lines to display.
  /// Defaults to 1 for display text.
  final int? maxLines;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Minimum font size to scale down to.
  /// Defaults to 14 for display text.
  final double? minFontSize;

  /// Step granularity for font size changes.
  /// Defaults to 0.5 for smooth scaling.
  final double? stepGranularity;

  /// Creates an [AutoSizeDisplay] widget.
  const AutoSizeDisplay(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.minFontSize,
    this.stepGranularity,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style ?? Theme.of(context).textTheme.displayLarge,
      maxLines: maxLines ?? 1,
      textAlign: textAlign,
      minFontSize: minFontSize ?? 14.0,
      stepGranularity: stepGranularity ?? 0.5,
      overflow: TextOverflow.ellipsis,
      wrapWords: true,
    );
  }
}

/// A variant of AutoSizeHeadline for card titles.
class AutoSizeCardTitle extends StatelessWidget {
  /// The text to display.
  final String text;

  /// Optional text style to apply.
  final TextStyle? style;

  /// Maximum number of lines to display.
  /// Defaults to 2 for card titles.
  final int? maxLines;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Minimum font size to scale down to.
  /// Defaults to 11 for card titles.
  final double? minFontSize;

  /// Step granularity for font size changes.
  /// Defaults to 0.5 for smooth scaling.
  final double? stepGranularity;

  /// Creates an [AutoSizeCardTitle] widget.
  const AutoSizeCardTitle(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.minFontSize,
    this.stepGranularity,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style ?? Theme.of(context).textTheme.titleLarge,
      maxLines: maxLines ?? 2,
      textAlign: textAlign,
      minFontSize: minFontSize ?? 11.0,
      stepGranularity: stepGranularity ?? 0.5,
      overflow: TextOverflow.ellipsis,
      wrapWords: true,
    );
  }
}
