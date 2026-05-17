import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import '../models/theme_presets.dart';
import 'card_resizer_popup.dart';
import 'text_settings_editor.dart';

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
                      'Düzenle',
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
                tabs: const [
                  Tab(text: 'Fotoğraf'),
                  Tab(text: 'Kart'),
                  Tab(text: 'Yazı'),
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
                      ),
                      onPressed: () async {
                        widget.appState.updateSettingsTemporary(original);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: () async {
                        draft = draft.copyWith(showCard: widget.appState.isQuoteVisible);
                        widget.appState.updateSettingsTemporary(draft);
                        await widget.appState.persistSettings(
                          rescheduleNotifications: false,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Uygula'),
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
    const filters = <String, String>{
      'none': 'Varsayılan',
      'sepia': 'Sepya',
      'mono': 'Siyah Beyaz',
      'vintage': 'Vintage',
      'warm': 'Sıcak',
      'cool': 'Soğuk',
      'rosy': 'Pembe Ton',
    };

    return ListView(
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Blurluk'),
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
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Fotoğraf Filtresi'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonFormField<String>(
            initialValue: draft.photoFilterId,
            items: filters.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _updateDraft(draft.copyWith(photoFilterId: value));
            },
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Filtre Yoğunluğu'),
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
        // ── Card background toggle ──────────────────────────────────────
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kart gösterilsin'),
          subtitle: const Text('Kapalıyken yazı görünür kalır'),
          activeThumbColor: cs.primary,
          value: draft.showCardBackground,
          onChanged: (v) {
            _updateDraft(draft.copyWith(showCardBackground: v));
            widget.appState.setQuoteVisibility(true);
          },
        ),
        const SizedBox(height: 6),

        // ── Card background COLOR — collapsible ─────────────────────────
        _colorExpansionTile(
          cs: cs,
          title: 'Kart Arka Plan Rengi',
          hexValue: draft.cardBackgroundColorValue,
          pickerColor: Color(draft.cardBackgroundColorValue),
          enableAlpha: true,
          onColorChanged: (c) =>
              _updateDraft(draft.copyWith(cardBackgroundColorValue: c.toARGB32())),
        ),

        // ── Overlay opacity ─────────────────────────────────────────────
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Arka plan opaklığı'),
          subtitle: Text('${(draft.backgroundOverlayOpacity * 100).toStringAsFixed(0)}%'),
        ),
        Slider(
          value: draft.backgroundOverlayOpacity,
          min: 0,
          max: 1,
          divisions: 100,
          onChanged: (v) => _updateDraft(draft.copyWith(backgroundOverlayOpacity: v)),
        ),

        // ── Card opacity ────────────────────────────────────────────────
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kart opaklığı'),
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

        // ── Resize button ────────────────────────────────────────────────
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
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
          label: const Text('Kart Konumunu Düzenle'),
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
        onConfirm: (updated) async {
          _updateDraft(updated);
          draft = draft.copyWith(showCard: widget.appState.isQuoteVisible);
          widget.appState.updateSettingsTemporary(draft);
          await widget.appState.persistSettings(
            rescheduleNotifications: true,
          );
          if (mounted) Navigator.of(context).pop();
        },
        onCancel: () {
          widget.appState.updateSettingsTemporary(original);
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── Reusable collapsible color-picker tile ────────────────────────────────
  Widget _colorExpansionTile({
    required ColorScheme cs,
    required String title,
    required int hexValue,
    required Color pickerColor,
    required bool enableAlpha,
    required void Function(Color) onColorChanged,
  }) {
    final hexStr = '#${hexValue.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    // Preview swatch
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
      // Collapsed by default so user doesn't accidentally change colour
      // while scrolling
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
