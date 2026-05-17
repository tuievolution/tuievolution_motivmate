import 'dart:ui';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import 'quote_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cache_limit.dart';

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
  // Normalised width fraction
  late double _widthN;

  // Minimum card size in logical pixels (prevents collapsing to zero)
  static const double _minPx = 80;

  @override
  void initState() {
    super.initState();
    _leftN  = widget.settings.cardLeftN.clamp(0.0, 1.0);
    _topN   = widget.settings.cardTopN.clamp(0.0, 1.0);
    _widthN = widget.settings.cardWidthN.clamp(0.01, 1.0);
  }

  // ── helpers ─────────────────────────────────────────────────────────────
  ColorFilter? _buildColorFilter(String id) {
    switch (id) {
      case 'sepia':
        return const ColorFilter.mode(Color(0xFF7A4D2A), BlendMode.color);
      case 'mono':
        return ColorFilter.matrix(const <double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vintage':
        return const ColorFilter.mode(Color(0xFFB08968), BlendMode.softLight);
      case 'warm':
        return const ColorFilter.mode(Color(0xFFFF9800), BlendMode.softLight);
      case 'cool':
        return const ColorFilter.mode(Color(0xFF4264FB), BlendMode.softLight);
      case 'rosy':
        return const ColorFilter.mode(Color(0xFFE91E63), BlendMode.softLight);
      case 'none':
      default:
        return null;
    }
  }

  void _clampAll(double cW, double cH) {
    // keep card horizontally within canvas
    _leftN = _leftN.clamp(0.0, (1.0 - _widthN).clamp(0.0, 1.0));
    _topN  = _topN.clamp(0.0, 1.0);
    _widthN  = _widthN.clamp(_minPx / cW, 1.0);
  }

  // ── drag body → move ─────────────────────────────────────────────────────
  void _onBodyDrag(DragUpdateDetails d, double cW, double cH) {
    setState(() {
      _leftN += d.delta.dx / cW;
      _topN  += d.delta.dy / cH;
      _clampAll(cW, cH);
    });
  }

  // ── drag handles → resize width ──────────────────────────────────────────
  void _onHandleDrag({
    required DragUpdateDetails d,
    required double cW,
    required double cH,
    bool left = false,
    bool right = false,
  }) {
    setState(() {
      final dx = d.delta.dx / cW;

      if (right)  _widthN += dx;
      if (left) {
        _widthN -= dx;
        _leftN  += dx;
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
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cW = constraints.maxWidth;
                  final cH = constraints.maxHeight;

                  final left   = _leftN   * cW;
                  final top    = _topN    * cH;
                  final width  = _widthN  * cW;
                  final filter = _buildColorFilter(widget.settings.photoFilterId);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── 1) Background Image exactly like Home Screen ─────
                      Positioned.fill(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.appState.quote.imagePath,
                              cacheManager: customCacheManager,
                              fit: BoxFit.cover,
                            ),
                            if (!widget.appState.isOriginalView) ...[
                              if (filter != null)
                                Opacity(
                                  opacity: widget.settings.photoFilterIntensity,
                                  child: ColorFiltered(
                                    colorFilter: filter,
                                    child: CachedNetworkImage(
                                      imageUrl: widget.appState.quote.imagePath,
                                      cacheManager: customCacheManager,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (widget.settings.blurSigma > 0)
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: widget.settings.blurSigma,
                                      sigmaY: widget.settings.blurSigma,
                                    ),
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(
                                    alpha: widget.appState.isOriginalView
                                        ? 0
                                        : widget.settings.backgroundOverlayOpacity,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── 2) card body (draggable) ────────────────────────────
                      Positioned(
                        left: left,
                        top: top,
                        width: width,
                        child: Stack(
                          children: [
                            // Card visual
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white54,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
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
                            // Hit snatcher layer to capture pure drags
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (d) => _onBodyDrag(d, cW, cH),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 3) Width resize handles ─────────────────────
                      // We place them at a reasonably fixed offset from the top
                      // since height is organic.
                      _handle(
                        left: left - 10,
                        top: top + 40, 
                        tall: true,
                        cursor: SystemMouseCursors.resizeColumn,
                        onDrag: (d) => _onHandleDrag(d: d, cW: cW, cH: cH, left: true),
                      ),
                      _handle(
                        left: left + width - 6,
                        top: top + 40,
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 24),
              tooltip: 'Uygula',
              onPressed: () {
                final updated = widget.settings.copyWith(
                  cardLeftN:  _leftN,
                  cardTopN:   _topN,
                  cardWidthN: _widthN,
                );
                Navigator.of(context).pop(updated);
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.restore_rounded, color: Colors.white, size: 24),
              tooltip: 'Sıfırla',
              onPressed: () {
                final d = AppSettings.defaults();
                setState(() {
                  _leftN   = d.cardLeftN;
                  _topN    = d.cardTopN;
                  _widthN  = d.cardWidthN;
                });
              },
            ),
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
    bool tall = false,
  }) {
    final w = 16.0;
    final h = tall ? 32.0 : 16.0;
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
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black38, width: 1),
            ),
            child: const Center(
              child: Icon(Icons.drag_indicator, size: 8, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
