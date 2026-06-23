import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Işık şiddeti (slider) ile uyumlu çalışan dinamik gölge ve efekt üreticisi
List<Shadow> _buildShadows(String effectId, Color effectColor) {
  // Slider'dan gelen şeffaflık (şiddet) değerini alıyoruz (0.0 - 1.0)
  final double baseAlpha = effectColor.a;

  // Şiddet oranını bozmadan efekt katmanları oluşturan yardımcı fonksiyon
  Color c(double multiplier) => effectColor.withValues(alpha: (baseAlpha * multiplier).clamp(0.0, 1.0));

  switch (effectId) {
    case 'shadow_soft':
      return [Shadow(color: c(1.0), blurRadius: 8, offset: const Offset(2, 2))];
    case 'shadow_hard':
      return [Shadow(color: c(1.0), blurRadius: 0, offset: const Offset(3, 3))];
    case 'neon':
      return [
        Shadow(color: c(1.0), blurRadius: 4),
        Shadow(color: c(0.8), blurRadius: 12),
        Shadow(color: c(0.6), blurRadius: 24),
      ];
    case 'neon_intense': // YENİ EFEKT
      return [
        Shadow(color: c(1.0), blurRadius: 2),
        Shadow(color: c(0.9), blurRadius: 8),
        Shadow(color: c(0.7), blurRadius: 20),
        Shadow(color: c(0.5), blurRadius: 40),
      ];
    case 'cloud':
      return [
        Shadow(color: c(0.6), blurRadius: 16),
        Shadow(color: c(0.4), blurRadius: 32),
        Shadow(color: c(0.2), blurRadius: 64),
      ];
    case 'retro':
      return List.generate(
        6,
        (i) => Shadow(
          color: c(1.0 - i * 0.15),
          blurRadius: 0,
          offset: Offset((i + 1) * 1.5, (i + 1) * 1.5),
        ),
      );
    case 'outline': // YENİ EFEKT (Dış Çizgi)
      return [
        Shadow(offset: const Offset(-1.5, -1.5), color: c(1.0)),
        Shadow(offset: const Offset(1.5, -1.5), color: c(1.0)),
        Shadow(offset: const Offset(1.5, 1.5), color: c(1.0)),
        Shadow(offset: const Offset(-1.5, 1.5), color: c(1.0)),
      ];
    case 'emboss':
      return [
        Shadow(color: Colors.white.withValues(alpha: baseAlpha * 0.6), blurRadius: 1, offset: const Offset(-1, -1)),
        Shadow(color: Colors.black.withValues(alpha: baseAlpha * 0.8), blurRadius: 1, offset: const Offset(1, 1)),
      ];
    case 'none':
    default:
      return [];
  }
}

/// Garantili Google Fonts Eşleştirici
TextStyle _getGoogleFont(String fontFamily, {TextStyle? textStyle}) {
  switch (fontFamily) {
    case 'Lato': return GoogleFonts.lato(textStyle: textStyle);
    case 'Open Sans': return GoogleFonts.openSans(textStyle: textStyle);
    case 'Montserrat': return GoogleFonts.montserrat(textStyle: textStyle);
    case 'Oswald': return GoogleFonts.oswald(textStyle: textStyle);
    case 'Raleway': return GoogleFonts.raleway(textStyle: textStyle);
    case 'Merriweather': return GoogleFonts.merriweather(textStyle: textStyle);
    case 'Playfair Display': return GoogleFonts.playfairDisplay(textStyle: textStyle);
    case 'Ubuntu': return GoogleFonts.ubuntu(textStyle: textStyle);
    case 'Poppins': return GoogleFonts.poppins(textStyle: textStyle);
    case 'Nunito': return GoogleFonts.nunito(textStyle: textStyle);
    case 'Comic Neue': return GoogleFonts.comicNeue(textStyle: textStyle);
    case 'Pacifico': return GoogleFonts.pacifico(textStyle: textStyle);
    case 'Caveat': return GoogleFonts.caveat(textStyle: textStyle);
    case 'Dancing Script': return GoogleFonts.dancingScript(textStyle: textStyle);
    case 'Roboto':
    default: return GoogleFonts.roboto(textStyle: textStyle);
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
    final effectiveBackground = cardBackgroundColor.withValues(alpha: opacity.clamp(0.0, 1.0));
    final effColor = effectColor ?? Colors.transparent;
    final shadows = _buildShadows(textEffectId, effColor);

    // KİLİT KALDIRILDI: Font büyüklüğü artık 100'e kadar çıkabilir!
    final clampedFontSize = fontSize.clamp(10.0, 100.0);
    final authorFontSize = (clampedFontSize * 0.45).clamp(10.0, 24.0);

    final baseStyle = _getGoogleFont(fontFamily, textStyle: TextStyle(
      color: quoteTextColor,
      fontSize: clampedFontSize,
      fontWeight: FontWeight.w500,
      height: 1.25,
      shadows: shadows.isEmpty ? null : shadows,
    ));

    final authorStyle = _getGoogleFont(fontFamily, textStyle: TextStyle(
      color: quoteTextColor.withValues(alpha: 0.75),
      fontSize: authorFontSize,
      fontWeight: FontWeight.w500,
      shadows: shadows.isEmpty ? null : shadows,
    ));

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
              size: (clampedFontSize * 0.8).clamp(20.0, 40.0),
            ),
            const SizedBox(height: 8),
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
                  style: baseStyle,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '- $author',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: authorStyle,
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