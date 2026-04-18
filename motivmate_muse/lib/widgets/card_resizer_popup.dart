import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import 'quote_card.dart';

/// Full-screen editor that lets the user:
///  • Drag the card body  → move in any direction (X and Y)
///  • Drag any of the 8 resize handles → resize freely
///
/// All positions/sizes are normalised to [0..1] fractions of the
/// available canvas so they stay correct on any screen size.
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
  // Normalised position of the card's top-left corner (0..1)
  late double _leftN;
  late double _topN;
  // Normalised size (0..1 fraction of canvas)
  late double _widthN;
  late double _heightN;

  // Minimum card size in logical pixels (prevents collapsing to zero)
  static const double _minPx = 80;

  @override
  void initState() {
    super.initState();
    _leftN  = widget.settings.cardLeftN.clamp(0.0, 1.0);
    _topN   = widget.settings.cardTopN.clamp(0.0, 1.0);
    _widthN = widget.settings.cardWidthN.clamp(0.01, 1.0);
    _heightN = widget.settings.cardHeightN.clamp(0.01, 1.0);
  }

  // ── helpers ─────────────────────────────────────────────────────────────
  void _clampAll(double cW, double cH) {
    // keep card within canvas
    _leftN = _leftN.clamp(0.0, (1.0 - _widthN).clamp(0.0, 1.0));
    _topN  = _topN.clamp(0.0,  (1.0 - _heightN).clamp(0.0, 1.0));
    _widthN  = _widthN.clamp(_minPx / cW, 1.0);
    _heightN = _heightN.clamp(_minPx / cH, 1.0);
  }

  // ── drag body → move ─────────────────────────────────────────────────────
  void _onBodyDrag(DragUpdateDetails d, double cW, double cH) {
    setState(() {
      _leftN += d.delta.dx / cW;
      _topN  += d.delta.dy / cH;
      _clampAll(cW, cH);
    });
  }

  // ── drag handles → resize ─────────────────────────────────────────────────
  void _onHandleDrag({
    required DragUpdateDetails d,
    required double cW,
    required double cH,
    bool left = false,
    bool right = false,
    bool top = false,
    bool bottom = false,
  }) {
    setState(() {
      final dx = d.delta.dx / cW;
      final dy = d.delta.dy / cH;

      if (right)  _widthN += dx;
      if (bottom) _heightN += dy;
      if (left) {
        _widthN -= dx;
        _leftN  += dx;
      }
      if (top) {
        _heightN -= dy;
        _topN    += dy;
      }
      _clampAll(cW, cH);
    });
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Text(
                'Kartı taşımak için sürükleyin • Köşe/kenar tutamaçlarından boyutlandırın',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cW = constraints.maxWidth;
                  final cH = constraints.maxHeight;

                  final left   = _leftN   * cW;
                  final top    = _topN    * cH;
                  final width  = _widthN  * cW;
                  final height = _heightN * cH;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── transparent tap-to-move background ──────────────
                      Positioned.fill(
                        child: Container(color: Colors.transparent),
                      ),

                      // ── card body (draggable) ────────────────────────────
                      Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (d) => _onBodyDrag(d, cW, cH),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white54,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: OverflowBox(
                                maxWidth: double.infinity,
                                maxHeight: double.infinity,
                                alignment: Alignment.topCenter,
                                child: QuoteCard(
                                  text: widget.appState.quote
                                      .text(widget.settings.appLanguage),
                                  author: widget.appState.quote
                                      .author(widget.settings.appLanguage),
                                  cardBackgroundColor: Color(
                                      widget.settings.cardBackgroundColorValue),
                                  quoteTextColor:
                                      Color(widget.settings.textColorValue),
                                  opacity: widget.settings.cardOpacity,
                                  fontSize: widget.settings.fontSize,
                                  fontFamily: widget.settings.fontFamily,
                                  showBackground:
                                      widget.settings.showCardBackground,
                                  // let it fill the container
                                  fillContainer: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── 8 resize handles ────────────────────────────────
                      // corners
                      _handle(
                        left: left - 10, top: top - 10,
                        cursor: SystemMouseCursors.resizeUpLeftDownRight,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, left: true,  top: true),
                      ),
                      _handle(
                        left: left + width - 6, top: top - 10,
                        cursor: SystemMouseCursors.resizeUpRightDownLeft,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, right: true, top: true),
                      ),
                      _handle(
                        left: left - 10, top: top + height - 6,
                        cursor: SystemMouseCursors.resizeUpRightDownLeft,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, left: true,  bottom: true),
                      ),
                      _handle(
                        left: left + width - 6, top: top + height - 6,
                        cursor: SystemMouseCursors.resizeUpLeftDownRight,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, right: true, bottom: true),
                      ),
                      // edges
                      _handle(
                        left: left + width / 2 - 10, top: top - 10,
                        wide: true,
                        cursor: SystemMouseCursors.resizeRow,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, top: true),
                      ),
                      _handle(
                        left: left + width / 2 - 10, top: top + height - 6,
                        wide: true,
                        cursor: SystemMouseCursors.resizeRow,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, bottom: true),
                      ),
                      _handle(
                        left: left - 10, top: top + height / 2 - 10,
                        tall: true,
                        cursor: SystemMouseCursors.resizeColumn,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, left: true),
                      ),
                      _handle(
                        left: left + width - 6, top: top + height / 2 - 10,
                        tall: true,
                        cursor: SystemMouseCursors.resizeColumn,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, right: true),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── app bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
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
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            onPressed: () {
              final updated = widget.settings.copyWith(
                cardLeftN:  _leftN,
                cardTopN:   _topN,
                cardWidthN: _widthN,
                cardHeightN: _heightN,
              );
              Navigator.of(context).pop(updated);
            },
            child: const Text(
              'Uygula',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // Reset to defaults
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white60),
            onPressed: () {
              final d = AppSettings.defaults();
              setState(() {
                _leftN   = d.cardLeftN;
                _topN    = d.cardTopN;
                _widthN  = d.cardWidthN;
                _heightN = d.cardHeightN;
              });
            },
            child: const Text('Sıfırla', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── single resize handle widget ───────────────────────────────────────────
  Widget _handle({
    required double left,
    required double top,
    required MouseCursor cursor,
    required void Function(DragUpdateDetails) onDrag,
    bool wide = false,
    bool tall = false,
  }) {
    final w = wide ? 24.0 : 16.0;
    final h = tall ? 24.0 : 16.0;
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onDrag,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(wide || tall ? 3 : 8),
              border: Border.all(color: Colors.black38, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
