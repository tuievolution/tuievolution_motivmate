import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_settings.dart';

class CardResizerPopup extends StatefulWidget {
  final AppSettings settings;

  const CardResizerPopup({super.key, required this.settings});

  @override
  State<CardResizerPopup> createState() => _CardResizerPopupState();
}

class _CardResizerPopupState extends State<CardResizerPopup> {
  late double _leftN;
  late double _topN;
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    _leftN = widget.settings.cardLeftN;
    _topN = widget.settings.cardTopN;
    _width = widget.settings.cardWidthPx;
    _height = widget.settings.cardHeightPx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.35),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final left = _leftN.clamp(0.0, 1.0) * constraints.maxWidth;
            final top = _topN.clamp(0.0, 1.0) * constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() {
                      _leftN = ((_leftN * constraints.maxWidth) + d.delta.dx) /
                          max(1, constraints.maxWidth);
                      _topN = ((_topN * constraints.maxHeight) + d.delta.dy) /
                          max(1, constraints.maxHeight);
                    }),
                    child: Container(
                      width: _width,
                      height: _height,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.transparent,
                      ),
                      child: Stack(
                        children: [
                          _Handle(
                            alignment: Alignment.bottomRight,
                            onDrag: (delta) => setState(() {
                              _width = (_width + delta.dx).clamp(180, 420);
                              _height = (_height + delta.dy).clamp(150, 520);
                            }),
                          ),
                          _Handle(
                            alignment: Alignment.bottomLeft,
                            onDrag: (delta) => setState(() {
                              _width = (_width - delta.dx).clamp(180, 420);
                              _height = (_height + delta.dy).clamp(150, 520);
                              _leftN += delta.dx / max(1, constraints.maxWidth);
                            }),
                          ),
                          _Handle(
                            alignment: Alignment.topRight,
                            onDrag: (delta) => setState(() {
                              _width = (_width + delta.dx).clamp(180, 420);
                              _height = (_height - delta.dy).clamp(150, 520);
                              _topN += delta.dy / max(1, constraints.maxHeight);
                            }),
                          ),
                          _Handle(
                            alignment: Alignment.topLeft,
                            onDrag: (delta) => setState(() {
                              _width = (_width - delta.dx).clamp(180, 420);
                              _height = (_height - delta.dy).clamp(150, 520);
                              _leftN += delta.dx / max(1, constraints.maxWidth);
                              _topN += delta.dy / max(1, constraints.maxHeight);
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              widget.settings.copyWith(
                                cardLeftN: _leftN.clamp(0.0, 1.0),
                                cardTopN: _topN.clamp(0.0, 1.0),
                                cardWidthPx: _width,
                                cardHeightPx: _height,
                              ),
                            );
                          },
                          child: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final Alignment alignment;
  final ValueChanged<Offset> onDrag;

  const _Handle({required this.alignment, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d.delta),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.open_in_full, size: 12, color: Colors.black87),
        ),
      ),
    );
  }
}
