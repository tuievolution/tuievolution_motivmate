import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';
import 'quote_card.dart';

const List<String> _availableFonts = [
  'Roboto', 'Playfair Display', 'Lato', 'Montserrat', 'Open Sans',
  'Raleway', 'Oswald', 'Merriweather', 'Dancing Script', 'Pacifico',
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

class TextSettingsEditor extends StatefulWidget {
  final AppSettings initialSettings;
  final String sampleText;
  final String sampleAuthor;
  final String language;
  final bool showPreview;

  /// Called in real-time when any value changes.
  final void Function(AppSettings updated)? onChanged;

  /// Called when the user presses "Onayla" / "Confirm". Optional.
  final void Function(AppSettings updated)? onConfirm;

  /// Called when the user presses "İptal" / "Cancel". Optional.
  final VoidCallback? onCancel;

  const TextSettingsEditor({
    super.key,
    required this.initialSettings,
    required this.sampleText,
    required this.sampleAuthor,
    required this.language,
    this.showPreview = true,
    this.onChanged,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<TextSettingsEditor> createState() => _TextSettingsEditorState();
}

class _TextSettingsEditorState extends State<TextSettingsEditor> {
  late AppSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialSettings;
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
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Color(_draft.textColorValue);
    final cardBg = Color(_draft.cardBackgroundColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Live Preview (Optional) ───────────────────────────────────────
        if (widget.showPreview) ...[
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
              color: Colors.grey.shade200,
            ),
            padding: const EdgeInsets.all(10),
            child: QuoteCard(
              text: widget.sampleText,
              author: widget.sampleAuthor,
              cardBackgroundColor: cardBg,
              quoteTextColor: textColor,
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
          const SizedBox(height: 12),
        ],

        // ── Font Size ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                value: _draft.fontSize.clamp(10, 24),
                min: 10,
                max: 24,
                divisions: 14,
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

        // ── Text Color ────────────────────────────────────────────────────
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
            children: _colorPalette(textColor),
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

        const SizedBox(height: 16),

        // ── Confirm / Cancel (Optional) ───────────────────────────────────
        if (widget.onConfirm != null && widget.onCancel != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text(_l('İptal', 'Cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => widget.onConfirm!(_draft),
                    child: Text(_l('Onayla', 'Confirm')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<Widget> _colorPalette(Color current) {
    final colors = [
      Colors.black,
      Colors.white,
      const Color(0xFF2A1B12),
      const Color(0xFF1A237E),
      const Color(0xFF880E4F),
      const Color(0xFF1B5E20),
      const Color(0xFFBF360C),
      const Color(0xFF37474F),
      const Color(0xFFFFD600),
      const Color(0xFF00BCD4),
    ];

    return colors.map((c) {
      final selected = current.toARGB32() == c.toARGB32();
      return GestureDetector(
        onTap: () => _notify(_draft.copyWith(textColorValue: c.toARGB32())),
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
      );
    }).toList();
  }
}
