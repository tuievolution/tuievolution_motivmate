import 'dart:ui';
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
  late double _leftN;
  late double _topN;
  late double _widthN;

  static const double _minPx = 80;

  @override
  void initState() {
    super.initState();
    _leftN  = widget.settings.cardLeftN.clamp(0.0, 1.0);
    _topN   = widget.settings.cardTopN.clamp(0.0, 1.0);
    _widthN = widget.settings.cardWidthN.clamp(0.01, 1.0);
  }

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
    _leftN = _leftN.clamp(0.0, (1.0 - _widthN).clamp(0.0, 1.0));
    _topN  = _topN.clamp(0.0, 1.0);
    _widthN  = _widthN.clamp(_minPx / cW, 1.0);
  }

  void _onBodyDrag(DragUpdateDetails d, double cW, double cH) {
    setState(() {
      _leftN += d.delta.dx / cW;
      _topN  += d.delta.dy / cH;
      _clampAll(cW, cH);
    });
  }

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

  Widget _buildNetworkImage(String url, {ColorFilter? filter}) {
    Widget image = Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(color: Colors.white54));
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.blueGrey.shade900,
          child: const Center(
            child: Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 50),
          ),
        );
      },
    );

    if (filter != null) {
      return Opacity(
        opacity: widget.settings.photoFilterIntensity,
        child: ColorFiltered(
          colorFilter: filter,
          child: image,
        ),
      );
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // YÜZEY 1: ARKA PLAN RESMİ VE BULANIKLIK
          Positioned.fill(
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
                    Positioned.fill(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildNetworkImage(widget.appState.quote.imagePath),
                          
                          if (!widget.appState.isOriginalView) ...[
                            if (filter != null)
                              _buildNetworkImage(widget.appState.quote.imagePath, filter: filter),
                              
                            if (widget.settings.blurSigma > 0)
                              Positioned.fill(
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: widget.settings.blurSigma,
                                      sigmaY: widget.settings.blurSigma,
                                    ),
                                    child: Container(color: Colors.transparent),
                                  ),
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

                    // YÜZEY 2: KART GÖVDESİ (Sürüklenebilir)
                    Positioned(
                      left: left,
                      top: top,
                      width: width,
                      child: Stack(
                        children: [
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
                                effectColor:
                                    Color(widget.settings.effectColorValue),
                                opacity: widget.settings.cardOpacity,
                                fontSize: widget.settings.fontSize,
                                fontFamily: widget.settings.fontFamily,
                                textEffectId: widget.settings.textEffectId,
                                showBackground:
                                    widget.settings.showCardBackground,
                                fillContainer: true,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (d) => _onBodyDrag(d, cW, cH),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // YÜZEY 3: YENİDEN BOYUTLANDIRMA TUTAMAÇLARI
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

          // YÜZEY 4 (EN ÜST KATMAN): KORUYUCU MENÜ ÇUBUĞU (Filtrelerin Altında Kalmasını Engeller)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: SafeArea(
                bottom: false,
                child: _buildAppBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Orijinal App Bar Kodun
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

  // Orijinal Handle Kodun
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