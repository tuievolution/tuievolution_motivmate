import 'package:flutter/material.dart';

class QuoteCard extends StatelessWidget {
  final String text;
  final String author;
  final Color cardBackgroundColor;
  final Color quoteTextColor;
  final double opacity;
  final double fontSize;
  final String fontFamily;
  final bool showBackground;

  final double width;
  final double height;

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
    this.width = 330,
    this.height = 260,
    this.borderRadius = 16,
    this.quotePadding = 18,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        cardBackgroundColor.withOpacity(opacity.clamp(0.0, 1.0));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: showBackground
            ? BoxDecoration(
                color: effectiveBackground,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1,
                ),
              )
            : null,
        padding: EdgeInsets.all(quotePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: quoteTextColor.withOpacity(0.35),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              '"$text"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: quoteTextColor,
                fontSize: fontSize,
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '- $author',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: quoteTextColor.withOpacity(0.75),
                fontSize: (fontSize * 0.26).clamp(10, 18),
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

