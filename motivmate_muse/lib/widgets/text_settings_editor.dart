import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/app_settings.dart';
import 'quote_card.dart';

const List<String> _availableFonts = [
  'Comic Neue', 'Roboto', 'Playfair Display', 'Lato', 'Montserrat',
  'Open Sans', 'Raleway', 'Oswald', 'Merriweather', 'Dancing Script',
  'Pacifico', 'Caveat', 'Comfortaa', 'Lobster', 'Satisfy',
];

const List<Map<String, String>> _textEffects = [
  {'id': 'none',        'labelTr': 'Efekt Yok',     'labelEn': 'No Effect'},
  {'id': 'shadow_soft', 'labelTr': 'Yumuşak Gölge', 'labelEn': 'Soft Shadow'},
  {'id': 'shadow_hard', 'labelTr': 'Sert Gölge',    'labelEn': 'Hard Shadow'},
  {'id': 'neon',        'labelTr': 'Neon Parlaması', 'labelEn': 'Neon Glow'},
  {'id': 'cloud',       'labelTr': 'Halo/Bulut',     'labelEn': 'Halo/Cloud'},
  {'id': 'retro',       'labelTr': 'Retro Gölge',    'labelEn': 'Retro Shadow'},
  {'id': 'emboss',      'labelTr': 'Kabartma',        'labelEn': 'Emboss'},
];

const List<Color> _presetColors = [
  Colors.white,
  Colors.black,
  Color(0xFFE53935), // Red
  Color(0xFFD81B60), // Pink
  Color(0xFF8E24AA), // Purple
  Color(0xFF5E35B1), // Deep Purple
  Color(0xFF3949AB), // Indigo
  Color(0xFF1E88E5), // Blue
  Color(0xFF039BE5), // Light Blue
  Color(0xFF00ACC1), // Cyan
  Color(0xFF00897B), // Teal
  Color(0xFF43A047), // Green
  Color(0xFF7CB342), // Light Green
  Color(0xFFFDD835), // Yellow
  Color(0xFFFB8C00), // Orange
];

class TextSettingsEditor extends StatefulWidget {
  final AppSettings initialSettings;
  final String sampleText;
  final String sampleAuthor;
  final String language;

  /// Called in real-time when any value changes.
  final void Function(AppSettings updated) onChanged;

  const TextSettingsEditor({
    super.key,
    required this.initialSettings,
    required this.sampleText,
    required this.sampleAuthor,
    required this.language,
    required this.onChanged,
  });

  @override
  State<TextSettingsEditor> createState() => _TextSettingsEditorState();
}

class _TextSettingsEditorState extends State<TextSettingsEditor> {
  late AppSettings _draft;
  Color? _customTextColor;
  Color? _customEffectColor;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialSettings;
    
    // Initialize custom colors if they are not in the preset list
    final textC = Color(_draft.textColorValue);
    if (!_presetColors.any((c) => c.toARGB32() == textC.toARGB32())) {
      _customTextColor = textC;
    }
    
    final effectC = Color(_draft.effectColorValue);
    if (!_presetColors.any((c) => c.toARGB32() == effectC.toARGB32())) {
      _customEffectColor = effectC;
    }
  }

  @override
  void didUpdateWidget(covariant TextSettingsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSettings != oldWidget.initialSettings) {
      _draft = widget.initialSettings;
    }
  }

  String _l(String tr, String en) => widget.language == 'en' ? en : tr;

  void _notify(AppSettings next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  void _pickCustomColor(bool isTextColor) {
    final initialColor = isTextColor
        ? Color(_draft.textColorValue)
        : Color(_draft.effectColorValue);

    showDialog(
      context: context,
      builder: (context) {
        Color selected = initialColor;
        return AlertDialog(
          title: Text(_l('Özel Renk Seç', 'Pick Custom Color')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (c) => selected = c,
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_l('İptal', 'Cancel')),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (isTextColor) {
                    _customTextColor = selected;
                    _notify(_draft.copyWith(textColorValue: selected.toARGB32()));
                  } else {
                    _customEffectColor = selected;
                    _notify(_draft.copyWith(effectColorValue: selected.toARGB32()));
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(_l('Seç', 'Select')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Color(_draft.textColorValue);
    final effectColor = Color(_draft.effectColorValue);
    final cardBg = Color(_draft.cardBackgroundColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Font Size ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            _l('Yazı Boyutu', 'Font Size'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.text_fields, size: 16),
            Expanded(
              child: Slider(
                value: _draft.fontSize.clamp(10, 28),
                min: 10,
                max: 28,
                divisions: 18,
                label: '${_draft.fontSize.round()}pt',
                onChanged: (v) => _notify(_draft.copyWith(fontSize: v)),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text('${_draft.fontSize.round()}pt',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),

        // ── Text Color (Yazı Rengi) ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Text(
            _l('Yazı Rengi', 'Text Color'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorPalette(textColor, true),
          ),
        ),

        // ── Font Family ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Text(
            _l('Yazı Tipi', 'Font Family'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonFormField<String>(
            initialValue: _draft.fontFamily,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _availableFonts.map((f) {
              TextStyle fs;
              try { fs = GoogleFonts.getFont(f, fontSize: 14); }
              catch (_) { fs = const TextStyle(fontSize: 14); }
              return DropdownMenuItem(value: f, child: Text(f, style: fs));
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              _notify(_draft.copyWith(fontFamily: v));
            },
          ),
        ),

        // ── Text Effect ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Text(
            _l('Yazı Efekti', 'Text Effect'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonFormField<String>(
            initialValue: _draft.textEffectId,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _textEffects.map((e) {
              return DropdownMenuItem(
                value: e['id'],
                child: Text(widget.language == 'en' ? e['labelEn']! : e['labelTr']!),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              _notify(_draft.copyWith(textEffectId: v));
            },
          ),
        ),

        // ── Effect Color (Efekt Rengi) ────────────────────────────────────
        if (_draft.textEffectId != 'none') ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: Text(
              _l('Efekt Rengi', 'Effect Color'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorPalette(effectColor, false),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Yazı Görünümü (Preview Card) ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            _l('Yazı Görünümü', 'Text Preview'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade900.withValues(alpha: 0.8),
          ),
          padding: const EdgeInsets.all(12),
          child: QuoteCard(
            text: widget.sampleText,
            author: widget.sampleAuthor,
            cardBackgroundColor: cardBg,
            quoteTextColor: textColor,
            effectColor: effectColor,
            opacity: _draft.cardOpacity,
            fontSize: _draft.fontSize,
            fontFamily: _draft.fontFamily,
            textEffectId: _draft.textEffectId,
            showBackground: _draft.showCardBackground,
            fillContainer: false,
            borderRadius: 10,
            quotePadding: 12,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _colorPalette(Color current, bool isTextColor) {
    List<Widget> items = [];

    // Render first 15 preset colors
    for (int i = 0; i < _presetColors.length; i++) {
      final c = _presetColors[i];
      final selected = current.toARGB32() == c.toARGB32();
      items.add(
        GestureDetector(
          onTap: () {
            if (isTextColor) {
              _notify(_draft.copyWith(textColorValue: c.toARGB32()));
            } else {
              _notify(_draft.copyWith(effectColorValue: c.toARGB32()));
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.blueAccent : Colors.grey.shade400,
                width: selected ? 2.5 : 1.0,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 6)]
                  : null,
            ),
          ),
        ),
      );
    }

    // 16th item: custom color picker (gökkuşağı renginde / SweepGradient)
    final customColor = isTextColor ? _customTextColor : _customEffectColor;
    final isCustomSelected = customColor != null && current.toARGB32() == customColor.toARGB32();
    
    items.add(
      GestureDetector(
        onTap: () => _pickCustomColor(isTextColor),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCustomSelected
                ? null
                : const SweepGradient(
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
            color: isCustomSelected ? customColor : null,
            border: Border.all(
              color: isCustomSelected ? Colors.blueAccent : Colors.white60,
              width: isCustomSelected ? 2.5 : 1.5,
            ),
            boxShadow: isCustomSelected
                ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 6)]
                : null,
          ),
          child: isCustomSelected
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : const Icon(Icons.colorize_rounded, size: 16, color: Colors.white),
        ),
      ),
    );

    return items;
  }
}
