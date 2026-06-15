import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Computes a contrasting shadow color for an effect as default.
Color _contrastColor(Color base) {
  final luminance = base.computeLuminance();
  return luminance > 0.4 ? Colors.black : Colors.white;
}

/// Returns a list of [Shadow]s for the given effect ID.
List<Shadow> _buildShadows(String effectId, Color textColor, Color effectColor) {
  final contrast = effectColor;
  switch (effectId) {
    // ── Subtle drop shadow ─────────────────────────────────────
    case 'shadow_soft':
      return [
        Shadow(color: contrast.withValues(alpha: 0.75), blurRadius: 6, offset: const Offset(1, 2)),
      ];

    // ── Solid hard shadow ────────────────────────────────
    case 'shadow_hard':
      return [
        Shadow(color: contrast, blurRadius: 0, offset: const Offset(2, 2)),
      ];

    // ── Neon glow ────────────────────────────────────
    case 'neon':
      return [
        Shadow(color: contrast.withValues(alpha: 0.95), blurRadius: 4),
        Shadow(color: contrast.withValues(alpha: 0.75), blurRadius: 12),
        Shadow(color: contrast.withValues(alpha: 0.55), blurRadius: 24),
      ];

    // ── Cloud / glowing halo ───────────────────────────────────────────────
    case 'cloud':
      return [
        Shadow(color: contrast.withValues(alpha: 0.45), blurRadius: 14),
        Shadow(color: contrast.withValues(alpha: 0.30), blurRadius: 28),
        Shadow(color: contrast.withValues(alpha: 0.15), blurRadius: 48),
      ];

    // ── Retro long shadow ──────────────────────────────
    case 'retro':
      return List.generate(
        8,
        (i) => Shadow(
          color: contrast.withValues(alpha: 0.25 - i * 0.02),
          blurRadius: 0,
          offset: Offset((i + 1).toDouble(), (i + 1).toDouble()),
        ),
      );

    // ── Emboss ────────────────────────────────
    case 'emboss':
      return [
        Shadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 0, offset: const Offset(-1, -1)),
        Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 0, offset: const Offset(1, 1)),
      ];

    case 'none':
    default:
      return [];
  }
}

class QuoteCard extends StatelessWidget {
  final String text;
  final String author;
  final Color cardBackgroundColor;
  final Color quoteTextColor;
  final Color? effectColor;
  final double opacity;
  final double fontSize;
  final String fontFamily;
  final String textEffectId;
  final bool showBackground;

  /// When true the card expands to fill its parent box.
  final bool fillContainer;

  final double borderRadius;
  final double quotePadding;

  const QuoteCard({
    super.key,
    required this.text,
    required this.author,
    required this.cardBackgroundColor,
    required this.quoteTextColor,
    this.effectColor,
    required this.opacity,
    required this.fontSize,
    required this.fontFamily,
    this.textEffectId = 'none',
    this.showBackground = true,
    this.fillContainer = false,
    this.borderRadius = 16,
    this.quotePadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        cardBackgroundColor.withValues(alpha: opacity.clamp(0.0, 1.0));

    TextStyle baseStyle;
    try {
      baseStyle = GoogleFonts.getFont(fontFamily);
    } catch (_) {
      baseStyle = const TextStyle(fontFamily: 'Roboto');
    }

    final effColor = effectColor ?? _contrastColor(quoteTextColor);
    final shadows = _buildShadows(textEffectId, quoteTextColor, effColor);

    // Font size is capped to avoid overflow (max 28pt)
    final clampedFontSize = fontSize.clamp(10.0, 28.0);
    final authorFontSize = (clampedFontSize * 0.45).clamp(10.0, 16.0);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fillContainer ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: quoteTextColor.withValues(alpha: 0.35),
              size: 20,
            ),
            const SizedBox(height: 8),
            // FittedBox auto-shrinks text if it would still overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 0
                      ? constraints.maxWidth - quotePadding * 2
                      : 320,
                ),
                child: Text(
                  '"$text"',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: baseStyle.copyWith(
                    color: quoteTextColor,
                    fontSize: clampedFontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    shadows: shadows.isEmpty ? null : shadows,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '- $author',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: baseStyle.copyWith(
                color: quoteTextColor.withValues(alpha: 0.75),
                fontSize: authorFontSize,
                fontWeight: FontWeight.w500,
                shadows: shadows.isEmpty ? null : shadows,
              ),
            ),
          ],
        );
      },
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
      return Container(
        width: double.infinity,
        decoration: decoration,
        padding: EdgeInsets.all(quotePadding),
        child: content,
      );
    }

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
