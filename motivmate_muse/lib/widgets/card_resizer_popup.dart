import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import 'quote_card.dart';


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
  late double xN;
  late double yN;

  @override
  void initState() {
    super.initState();
    xN = widget.settings.cardLeftN.clamp(0.0, 1.0);
    yN = widget.settings.cardTopN.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
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
                'Kartı ekranda istediğiniz yere sürükleyin',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    // drag moves the card
                    onPanUpdate: (details) {
                      setState(() {
                        xN = (xN + details.delta.dx / constraints.maxWidth).clamp(0.0, 1.0);
                        yN = (yN + details.delta.dy / constraints.maxHeight).clamp(0.0, 1.0);
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Align(
                        alignment: Alignment((xN * 2) - 1, (yN * 2) - 1),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white38,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: QuoteCard(
                            text: widget.appState.quote.text(widget.settings.appLanguage),
                            author: widget.appState.quote.author(widget.settings.appLanguage),
                            cardBackgroundColor: Color(widget.settings.cardBackgroundColorValue),
                            quoteTextColor: Color(widget.settings.textColorValue),
                            opacity: widget.settings.cardOpacity,
                            fontSize: widget.settings.fontSize,
                            fontFamily: widget.settings.fontFamily,
                            showBackground: widget.settings.showCardBackground,
                          ),
                        ),
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
