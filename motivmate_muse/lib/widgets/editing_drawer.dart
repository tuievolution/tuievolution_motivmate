import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import '../models/theme_presets.dart';
import 'card_resizer_popup.dart';
import 'quote_card.dart'; 

class EditingDrawer extends StatefulWidget {
  final AppState appState;
  final Future<void> Function() onDownload;

  const EditingDrawer({
    super.key,
    required this.appState,
    required this.onDownload,
  });

  @override
  State<EditingDrawer> createState() => _EditingDrawerState();
}

class _EditingDrawerState extends State<EditingDrawer> {
  late AppSettings draft;
  late final AppSettings original;

  @override
  void initState() {
    super.initState();
    original = widget.appState.settings;
    draft = widget.appState.settings;
  }

  void _updateDraft(AppSettings next) {
    setState(() => draft = next);
    widget.appState.updateSettingsTemporary(draft);
  }

  String _l(String tr, String en) => draft.appLanguage == 'en' ? en : tr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preset = themePresets
        .firstWhere((e) => e.id == draft.themeId, orElse: () => themePresets.first);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.edit, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _l('Düzenle', 'Edit'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      widget.appState.updateSettingsTemporary(original);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close, color: cs.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                tabs: [
                  Tab(text: _l('Fotoğraf', 'Photo')),
                  Tab(text: _l('Kart', 'Card')),
                  Tab(text: _l('Yazı', 'Text')),
                ],
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
                indicatorColor: cs.primary,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPhotoTab(preset),
                    _buildCardTab(cs),
                    _buildTextTab(cs),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        widget.appState.updateSettingsTemporary(original);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(_l('İptal', 'Cancel'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        draft = draft.copyWith(showCard: widget.appState.isQuoteVisible);
                        widget.appState.updateSettingsTemporary(draft);
                        await widget.appState.persistSettings(
                          rescheduleNotifications: true,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(_l('Uygula', 'Apply'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTab(ThemePreset preset) {
    final filters = <String, Map<String, String>>{
      'none':    {'tr': 'Varsayılan',   'en': 'Default'},
      'sepia':   {'tr': 'Sepya',        'en': 'Sepia'},
      'mono':    {'tr': 'Siyah Beyaz',  'en': 'Black & White'},
      'vintage': {'tr': 'Vintage',      'en': 'Vintage'},
      'warm':    {'tr': 'Sıcak',        'en': 'Warm'},
      'cool':    {'tr': 'Soğuk',        'en': 'Cool'},
      'rosy':    {'tr': 'Pembe Ton',    'en': 'Rosy'},
    };

    return ListView(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l('Blurluk', 'Blur Intensity')),
        ),
        Slider(
          value: draft.blurSigma,
          min: 0,
          max: 25,
          divisions: 50,
          label: draft.blurSigma.toStringAsFixed(0),
          onChanged: (v) {
            _updateDraft(draft.copyWith(blurSigma: v));
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l('Fotoğraf Filtresi', 'Photo Filter')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonFormField<String>(
            initialValue: draft.photoFilterId,
            items: filters.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(draft.appLanguage == 'en' ? e.value['en']! : e.value['tr']!),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _updateDraft(draft.copyWith(photoFilterId: value));
            },
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l('Filtre Yoğunluğu', 'Filter Intensity')),
        ),
        Slider(
          value: draft.photoFilterIntensity,
          min: 0,
          max: 1,
          divisions: 20,
          label: '${(draft.photoFilterIntensity * 100).toStringAsFixed(0)}%',
          onChanged: (v) {
            _updateDraft(draft.copyWith(photoFilterIntensity: v));
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCardTab(ColorScheme cs) {
    return ListView(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l('Kartı Göster', 'Show Card')),
          subtitle: Text(_l('Kapalıyken yazı görünür kalır', 'Text remains visible when closed')),
          activeThumbColor: cs.primary,
          value: draft.showCardBackground,
          onChanged: (v) {
            _updateDraft(draft.copyWith(showCardBackground: v));
            widget.appState.setQuoteVisibility(true);
          },
        ),
        const SizedBox(height: 6),

        _colorExpansionTile(
          cs: cs,
          title: _l('Kart Arka Plan Rengi', 'Card Background Color'),
          hexValue: draft.cardBackgroundColorValue,
          pickerColor: Color(draft.cardBackgroundColorValue),
          enableAlpha: true,
          onColorChanged: (c) =>
              _updateDraft(draft.copyWith(cardBackgroundColorValue: c.toARGB32())),
        ),

        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l('Arka plan opaklığı', 'Overlay Opacity')),
          subtitle: Text('${(draft.backgroundOverlayOpacity * 100).toStringAsFixed(0)}%'),
        ),
        Slider(
          value: draft.backgroundOverlayOpacity,
          min: 0,
          max: 1,
          divisions: 100,
          onChanged: (v) => _updateDraft(draft.copyWith(backgroundOverlayOpacity: v)),
        ),

        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l('Kart opaklığı', 'Card Opacity')),
          subtitle: Text('${(draft.cardOpacity * 100).toStringAsFixed(0)}%'),
        ),
        Slider(
          value: draft.cardOpacity,
          min: 0.2,
          max: 1,
          divisions: 60,
          onChanged: (v) => _updateDraft(draft.copyWith(cardOpacity: v)),
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final updated = await Navigator.of(context).push<AppSettings>(
              MaterialPageRoute(
                builder: (_) => CardResizerPopup(
                  settings: draft,
                  appState: widget.appState,
                ),
                fullscreenDialog: true,
              ),
            );
            if (updated != null) {
              _updateDraft(updated);
            }
          },
          icon: const Icon(Icons.crop_free),
          label: Text(_l('Kart Konumunu Düzenle', 'Adjust Card Position')),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextTab(ColorScheme cs) {
    final quote = widget.appState.quote;
    final lang = draft.appLanguage;
    return SingleChildScrollView(
      child: TextSettingsEditor(
        initialSettings: draft,
        sampleText: quote.text(lang),
        sampleAuthor: quote.author(lang),
        language: lang,
        onChanged: (updated) {
          _updateDraft(updated);
        },
      ),
    );
  }

  Widget _colorExpansionTile({
    required ColorScheme cs,
    required String title,
    required int hexValue,
    required Color pickerColor,
    required bool enableAlpha,
    required void Function(Color) onColorChanged,
  }) {
    final hexStr = '#${hexValue.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final swatch = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: pickerColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
    );

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: false,
      leading: swatch,
      title: Text(title),
      subtitle: Text(hexStr, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: onColorChanged,
            enableAlpha: enableAlpha,
            displayThumbColor: true,
          ),
        ),
      ],
    );
  }
}

// ── TEXT SETTINGS EDITOR ──

const List<String> _availableFonts = [
  'Roboto', 'Lato', 'Open Sans', 'Montserrat', 'Oswald',
  'Raleway', 'Merriweather', 'Playfair Display', 'Ubuntu',
  'Poppins', 'Nunito', 'Comic Neue', 'Pacifico', 'Caveat', 'Dancing Script'
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
    
    final textC = Color(_draft.textColorValue);
    if (!_presetColors.any((c) => c.toARGB32() == textC.toARGB32())) {
      _customTextColor = textC;
    }

    final effectC = Color(_draft.effectColorValue).withValues(alpha: 1.0); // Compare pure RGB
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

  void _pickCustomColor({required bool isText}) {
    final initialColor = isText ? Color(_draft.textColorValue) : Color(_draft.effectColorValue).withValues(alpha: 1.0);

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
                  if (isText) {
                    _customTextColor = selected;
                    _notify(_draft.copyWith(textColorValue: selected.toARGB32()));
                  } else {
                    _customEffectColor = selected;
                    final currentAlpha = Color(_draft.effectColorValue).a;
                    _notify(_draft.copyWith(effectColorValue: selected.withValues(alpha: currentAlpha).toARGB32()));
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
    final cardBg = Color(_draft.cardBackgroundColorValue);
    final effectColor = Color(_draft.effectColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                value: _draft.fontSize.clamp(10, 100), // Max limit increased to 100
                min: 10,
                max: 100,
                divisions: 90,
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
            children: _buildPalette(textColor, isText: true),
          ),
        ),

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
              switch (f) {
                case 'Lato': fs = GoogleFonts.lato(fontSize: 14); break;
                case 'Open Sans': fs = GoogleFonts.openSans(fontSize: 14); break;
                case 'Montserrat': fs = GoogleFonts.montserrat(fontSize: 14); break;
                case 'Oswald': fs = GoogleFonts.oswald(fontSize: 14); break;
                case 'Raleway': fs = GoogleFonts.raleway(fontSize: 14); break;
                case 'Merriweather': fs = GoogleFonts.merriweather(fontSize: 14); break;
                case 'Playfair Display': fs = GoogleFonts.playfairDisplay(fontSize: 14); break;
                case 'Ubuntu': fs = GoogleFonts.ubuntu(fontSize: 14); break;
                case 'Poppins': fs = GoogleFonts.poppins(fontSize: 14); break;
                case 'Nunito': fs = GoogleFonts.nunito(fontSize: 14); break;
                case 'Comic Neue': fs = GoogleFonts.comicNeue(fontSize: 14); break;
                case 'Pacifico': fs = GoogleFonts.pacifico(fontSize: 14); break;
                case 'Caveat': fs = GoogleFonts.caveat(fontSize: 14); break;
                case 'Dancing Script': fs = GoogleFonts.dancingScript(fontSize: 14); break;
                case 'Roboto':
                default: fs = GoogleFonts.roboto(fontSize: 14); break;
              }
              return DropdownMenuItem(value: f, child: Text(f, style: fs));
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              _notify(_draft.copyWith(fontFamily: v));
            },
          ),
        ),
        
        // ── METİN EFEKTİ VE PARLAMA BÖLÜMÜ BAŞLANGICI ──
        const SizedBox(height: 16),
        const Divider(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            _l('Metin Efekti', 'Text Effect'),
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
            items: [
              DropdownMenuItem(value: 'none', child: Text(_l('Efekt Yok', 'No Effect'))),
              DropdownMenuItem(value: 'shadow_soft', child: Text(_l('Yumuşak Gölge', 'Soft Shadow'))),
              DropdownMenuItem(value: 'shadow_hard', child: Text(_l('Keskin Gölge', 'Hard Shadow'))),
              DropdownMenuItem(value: 'outline', child: Text(_l('Dış Çizgi (Outline)', 'Outline'))),
              DropdownMenuItem(value: 'neon', child: Text(_l('Hafif Neon Parlama', 'Soft Neon Glow'))),
              DropdownMenuItem(value: 'neon_intense', child: Text(_l('Yoğun Neon', 'Intense Neon'))),
              DropdownMenuItem(value: 'cloud', child: Text(_l('Bulut (Geniş Işık)', 'Cloud Glow'))),
              DropdownMenuItem(value: 'retro', child: Text(_l('Retro / 3D', 'Retro 3D'))),
              DropdownMenuItem(value: 'emboss', child: Text(_l('Kabarık (Emboss)', 'Emboss'))),
            ],
            onChanged: (v) {
              if (v == null) return;
              _notify(_draft.copyWith(textEffectId: v));
            },
          ),
        ),

        if (_draft.textEffectId != 'none') ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.light_mode_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(_l('Işık Şiddeti', 'Glow Intensity'), style: const TextStyle(fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: effectColor.a.clamp(0.1, 1.0),
                    min: 0.1,
                    max: 1.0,
                    activeColor: effectColor.withValues(alpha: 1.0),
                    onChanged: (val) {
                      _notify(_draft.copyWith(
                        effectColorValue: effectColor.withValues(alpha: val).toARGB32(), 
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Text(
              _l('Parlama Rengi', 'Glow Color'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildPalette(effectColor.withValues(alpha: 1.0), isText: false),
            ),
          ),
        ],
        // ── BİTİŞ ──

        const SizedBox(height: 20),

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
            opacity: _draft.cardOpacity,
            fontSize: _draft.fontSize,
            fontFamily: _draft.fontFamily,
            textEffectId: _draft.textEffectId,
            effectColor: effectColor,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildPalette(Color current, {required bool isText}) {
    List<Widget> items = [];

    for (int i = 0; i < _presetColors.length; i++) {
      final c = _presetColors[i];
      final selected = current.toARGB32() == c.toARGB32();
      
      items.add(
        GestureDetector(
          onTap: () {
            if (isText) {
              _notify(_draft.copyWith(textColorValue: c.toARGB32()));
            } else {
              final currentAlpha = Color(_draft.effectColorValue).a;
              _notify(_draft.copyWith(effectColorValue: c.withValues(alpha: currentAlpha).toARGB32()));
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

    final customColor = isText ? _customTextColor : _customEffectColor;
    final isCustomSelected = customColor != null && current.toARGB32() == customColor.toARGB32();
    
    items.add(
      GestureDetector(
        onTap: () => _pickCustomColor(isText: isText),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCustomSelected
                ? null
                : const SweepGradient(
                    colors: [
                      Colors.red, Colors.orange, Colors.yellow, 
                      Colors.green, Colors.blue, Colors.indigo, 
                      Colors.purple, Colors.red,
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