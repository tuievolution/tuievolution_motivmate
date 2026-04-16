import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import '../models/theme_presets.dart';
import 'quote_card.dart';

// The insets must match home_screen.dart so positioning is identical
const _cardTopInset = 84.0;
const _cardBottomInset = 170.0;

class CardResizerPopup extends StatefulWidget {
  final AppSettings settings;
  final AppState appState;

  const CardResizerPopup({
    super.key,
    required this.settings,
    required this.appState,
  });

  @override
  State<CardResizerPopup> createState() => _CardResizerPopupState();
}

class _CardResizerPopupState extends State<CardResizerPopup> {
  late double w;
  late double h;
  late double xN;
  late double yN;

  @override
  void initState() {
    super.initState();
    w = widget.settings.cardWidthPx.clamp(180.0, 420.0);
    h = widget.settings.cardHeightPx.clamp(150.0, 520.0);
    xN = widget.settings.cardLeftN.clamp(0.0, 1.0);
    yN = widget.settings.cardTopN.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final preset = themePresets.firstWhere(
      (e) => e.id == widget.settings.themeId,
      orElse: () => themePresets.first,
    );

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Kart Konumu ve Boyutu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final updated = widget.settings.copyWith(
                        cardWidthPx: w,
                        cardHeightPx: h,
                        cardLeftN: xN,
                        cardTopN: yN,
                      );
                      Navigator.of(context).pop(updated);
                    },
                    child: const Text(
                      'Uygula',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Kartı sürükleyin • Mavi köşeden boyutlandırın',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),

            // ── Canvas (same inset logic as home_screen) ───────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pw = constraints.maxWidth;
                  final ph = constraints.maxHeight;

                  // Replicate home_screen.dart coordinate maths exactly
                  final leftMaxPx = (pw - w).clamp(0.0, pw);
                  final topAreaHeight = (ph - h - _cardTopInset - _cardBottomInset).clamp(0.0, ph);

                  final cardLeft = xN * leftMaxPx;
                  final cardTop = _cardTopInset + yN * topAreaHeight;

                  return GestureDetector(
                    // drag moves the card
                    onPanUpdate: (details) {
                      setState(() {
                        final denomW = leftMaxPx == 0.0 ? 1.0 : leftMaxPx;
                        final denomH = topAreaHeight == 0.0 ? 1.0 : topAreaHeight;
                        xN = (xN + details.delta.dx / denomW).clamp(0.0, 1.0);
                        yN = (yN + details.delta.dy / denomH).clamp(0.0, 1.0);
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Card preview
                          Positioned(
                            left: cardLeft,
                            top: cardTop,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white38,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: QuoteCard(
                                width: w,
                                height: h,
                                text: widget.appState.quote.text(widget.settings.appLanguage),
                                author: widget.appState.quote.author(widget.settings.appLanguage),
                                cardBackgroundColor: preset.cardBackgroundColor,
                                quoteTextColor: Color(widget.settings.textColorValue),
                                opacity: widget.settings.cardOpacity,
                                fontSize: widget.settings.fontSize,
                                fontFamily: widget.settings.fontFamily,
                                showBackground: widget.settings.showCardBackground,
                              ),
                            ),
                          ),

                          // Resize handle (bottom-right of card)
                          Positioned(
                            left: cardLeft + w - 22,
                            top: cardTop + h - 22,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                setState(() {
                                  w = (w + d.delta.dx).clamp(180.0, pw - 30);
                                  h = (h + d.delta.dy).clamp(150.0, ph - 30);
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blueAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.open_with,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
