import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import '../models/theme_presets.dart';
import 'card_resizer_popup.dart';

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
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.edit),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Düzenle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      widget.appState.updateSettingsTemporary(original);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'Fotoğraf'),
                  Tab(text: 'Kart'),
                  Tab(text: 'Yazı'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPhotoTab(preset),
                    _buildCardTab(),
                    _buildTextTab(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
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
      'mono': 'Mono',
      'vintage': 'Vintage',
      'cinematic': 'Sinema',
    };

    return ListView(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Blurluk'),
          subtitle: Text('${draft.blurSigma.toStringAsFixed(0)}'),
        ),
        Slider(
          value: draft.blurSigma,
          min: 0,
          max: 25,
          divisions: 50,
          label: '${draft.blurSigma.toStringAsFixed(0)}',
          onChanged: (v) {
            _updateDraft(draft.copyWith(blurSigma: v));
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Filtre'),
          subtitle: Text('Arka plana renk efekti'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonFormField<String>(
            value: draft.photoFilterId,
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
        const SizedBox(height: 18),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Yeni arka plan'),
          subtitle: const Text('MotivMate içinden rastgele seçim'),
          trailing: const Icon(Icons.shuffle),
          onTap: () async {
            await widget.appState.refreshQuote();
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Ipu: Kalp butonu yalnizca kart/yazi gorunurlugunu acip kapatir.',
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCardTab() {
    return ListView(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kart gösterilsin'),
          value: widget.appState.isQuoteVisible,
          onChanged: (v) => widget.appState.setQuoteVisibility(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kart arka planı gösterilsin'),
          value: draft.showCardBackground,
          onChanged: (v) => _updateDraft(draft.copyWith(showCardBackground: v)),
        ),
        const SizedBox(height: 8),
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
        ElevatedButton.icon(
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
          label: const Text('Kart Konumu ve Boyutunu Düzenle'),
        ),
        const SizedBox(height: 12),
        Text(
          'Arayüzle sürükleyip köşelerden tam ölçü verebilirsin.',
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: widget.onDownload,
          icon: const Icon(Icons.download),
          label: const Text('İndir'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextTab() {
    final currentColor = Color(draft.textColorValue);
    const fonts = <String>[
      'Georgia',
      'Times New Roman',
      'Courier New',
      'Arial',
      'Roboto',
      'Helvetica',
      'Trebuchet MS',
      'Verdana',
    ];

    return ListView(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Punto (yazı boyutu)'),
          subtitle: Text('${draft.fontSize.toStringAsFixed(0)}'),
        ),
        Slider(
          value: draft.fontSize,
          min: 18,
          max: 42,
          divisions: 48,
          label: '${draft.fontSize.toStringAsFixed(0)}',
          onChanged: (v) => _updateDraft(draft.copyWith(fontSize: v)),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Yazı rengi'),
          subtitle: Text('#${draft.textColorValue.toRadixString(16).padLeft(8, '0')}'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (c) {
              _updateDraft(draft.copyWith(textColorValue: c.value));
            },
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Font'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonFormField<String>(
            value: draft.fontFamily,
            items: fonts
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _updateDraft(draft.copyWith(fontFamily: value));
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

