import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuoteCard extends StatelessWidget {
  final String text;
  final String author;
  final Color cardBackgroundColor;
  final Color quoteTextColor;
  final double opacity;
  final double fontSize;
  final String fontFamily;
  final bool showBackground;

  /// When true the card expands to fill its parent box (used in the resizer).
  /// When false (default) the card wraps its content with a max-width cap.
  final bool fillContainer;

  final double borderRadius;
  final double quotePadding;

  const QuoteCard({
    super.key,
    required this.text,
    required this.author,
    required this.cardBackgroundColor,
    required this.quoteTextColor,
    required this.opacity,
    required this.fontSize,
    required this.fontFamily,
    this.showBackground = true,
    this.fillContainer = false,
    this.borderRadius = 16,
    this.quotePadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        cardBackgroundColor.withValues(alpha: opacity.clamp(0.0, 1.0));

    TextStyle textStyle;
    try {
      textStyle = GoogleFonts.getFont(fontFamily);
    } catch (_) {
      textStyle = const TextStyle(fontFamily: 'Roboto');
    }

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fillContainer ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.format_quote_rounded,
          color: quoteTextColor.withValues(alpha: 0.35),
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          '"$text"',
          textAlign: TextAlign.center,
          softWrap: true,
          overflow: TextOverflow.fade,
          style: textStyle.copyWith(
            color: quoteTextColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '- $author',
          textAlign: TextAlign.center,
          style: textStyle.copyWith(
            color: quoteTextColor.withValues(alpha: 0.75),
            fontSize: (fontSize * 0.45).clamp(11, 18),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final decoration = showBackground
        ? BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          )
        : null;

    if (fillContainer) {
      // Fills parent width statically, wraps content vertically
      return Container(
        width: double.infinity,
        decoration: decoration,
        padding: EdgeInsets.all(quotePadding),
        child: content,
      );
    }

    // Default: wrap content, capped at maxWidth
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: decoration,
        padding: EdgeInsets.all(quotePadding),
        child: content,
      ),
    );
  }
}
