import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/app_settings.dart';
import '../models/theme_presets.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late AppState _app;
  late AppSettings draft;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _app = context.read<AppState>();
    draft = _app.settings;
    _initialized = true;
  }

  Future<void> _commit({required bool rescheduleNotifications}) async {
    try {
      _app.updateSettingsTemporary(draft);
      await _app.persistSettings(
        rescheduleNotifications: rescheduleNotifications,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim ayarı uygulanamadı, tekrar deneyin.'),
        ),
      );
    }
  }

  int _clampMinutes(int v) => v.clamp(0, 24 * 60 - 1);

  Future<int?> _pickTimeMinutes(BuildContext context, int initialMinutes) async {
    final hour = initialMinutes ~/ 60;
    final minute = initialMinutes % 60;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeId = draft.themeId;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            const SizedBox(height: 10),
            const Text(
              'Ayarlar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              leading: const Icon(Icons.language),
              title: const Text('Kart Dili'),
              subtitle: const Text('Alıntı ve arayüz dili seçimi'),
              initiallyExpanded: false,
              children: [
                ListTile(
                  title: const Text('Seçili Dil'),
                  trailing: DropdownButton<String>(
                    value: draft.appLanguage,
                    items: const [
                      DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => draft = draft.copyWith(appLanguage: value));
                      await _commit(rescheduleNotifications: true);
                      await _app.refreshQuote();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ExpansionTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema Ayarları'),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                ...themePresets.map((p) {
                  final selected = p.id == currentThemeId;
                  return ListTile(
                    dense: true,
                    onTap: () async {
                      setState(() => draft = draft.copyWith(themeId: p.id));
                      await _commit(rescheduleNotifications: false);
                    },
                    title: Text(p.name),
                    trailing: selected ? const Icon(Icons.check) : null,
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Bildirim Ayarları'),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 6),
                SwitchListTile(
                  title: const Text('Bar bildirimleri'),
                  value: draft.barNotificationsEnabled,
                  onChanged: (v) async {
                    setState(() => draft = draft.copyWith(barNotificationsEnabled: v));
                    await _commit(rescheduleNotifications: true);
                  },
                ),
                SwitchListTile(
                  title: const Text('Uygulama açılışında kart'),
                  value: draft.popupOnOpenEnabled,
                  onChanged: (v) async {
                    setState(() => draft = draft.copyWith(popupOnOpenEnabled: v));
                    await _commit(rescheduleNotifications: false);
                  },
                ),
                const SizedBox(height: 6),
                const Divider(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Bar zamanlaması',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                RadioListTile<BarTiming>(
                  value: BarTiming.intervalMinutes,
                  groupValue: draft.barTiming,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => draft = draft.copyWith(barTiming: v));
                    await _commit(rescheduleNotifications: true);
                  },
                  title: const Text('Zaman aralığı (dakika)'),
                ),
                if (draft.barTiming == BarTiming.intervalMinutes)
                  Column(
                    children: [
                      Slider(
                        value: draft.barIntervalMinutes.toDouble(),
                        min: 15,
                        max: 240,
                        divisions: 45,
                        label: '${draft.barIntervalMinutes} dk',
                        onChanged: (v) {
                          setState(
                            () => draft = draft.copyWith(
                              barIntervalMinutes: v.round(),
                            ),
                          );
                        },
                        onChangeEnd: (_) async {
                          await _commit(rescheduleNotifications: true);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                RadioListTile<BarTiming>(
                  value: BarTiming.timeOfDay,
                  groupValue: draft.barTiming,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => draft = draft.copyWith(barTiming: v));
                    await _commit(rescheduleNotifications: true);
                  },
                  title: const Text('Günlük saat'),
                ),
                if (draft.barTiming == BarTiming.timeOfDay)
                  ListTile(
                    dense: true,
                    title: const Text('Bildirim saati'),
                    subtitle: Text(_formatMinutes(draft.barTimeOfDayMinutes)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await _pickTimeMinutes(
                        context,
                        draft.barTimeOfDayMinutes,
                      );
                      if (picked == null) return;
                      setState(
                        () => draft = draft.copyWith(barTimeOfDayMinutes: picked),
                      );
                      await _commit(rescheduleNotifications: true);
                    },
                  ),
                const Divider(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Kart zamanlaması',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                RadioListTile<PopupTiming>(
                  value: PopupTiming.immediate,
                  groupValue: draft.popupTiming,
                  onChanged: (v) => setState(() => draft = draft.copyWith(popupTiming: v)),
                  title: const Text('Uygulama açılır açılmaz'),
                ),
                RadioListTile<PopupTiming>(
                  value: PopupTiming.timeOfDay,
                  groupValue: draft.popupTiming,
                  onChanged: (v) => setState(() => draft = draft.copyWith(popupTiming: v)),
                  title: const Text('Belirli saat'),
                ),
                if (draft.popupTiming == PopupTiming.timeOfDay)
                  ListTile(
                    dense: true,
                    title: const Text('Kart saati'),
                    subtitle: Text(_formatMinutes(draft.popupTimeOfDayMinutes)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await _pickTimeMinutes(
                        context,
                        draft.popupTimeOfDayMinutes,
                      );
                      if (picked == null) return;
                      setState(
                        () => draft = draft.copyWith(popupTimeOfDayMinutes: picked),
                      );
                      await _commit(rescheduleNotifications: false);
                    },
                  ),
                RadioListTile<PopupTiming>(
                  value: PopupTiming.betweenHours,
                  groupValue: draft.popupTiming,
                  onChanged: (v) => setState(() => draft = draft.copyWith(popupTiming: v)),
                  title: const Text('Aralık saatler'),
                ),
                if (draft.popupTiming == PopupTiming.betweenHours)
                  Column(
                    children: [
                      ListTile(
                        dense: true,
                        title: const Text('Başlangıç'),
                        subtitle: Text(
                          _formatMinutes(draft.popupBetweenStartMinutes),
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final picked = await _pickTimeMinutes(
                            context,
                            draft.popupBetweenStartMinutes,
                          );
                          if (picked == null) return;
                          setState(
                            () => draft = draft.copyWith(
                              popupBetweenStartMinutes: picked,
                            ),
                          );
                          await _commit(rescheduleNotifications: false);
                        },
                      ),
                      ListTile(
                        dense: true,
                        title: const Text('Bitiş'),
                        subtitle: Text(
                          _formatMinutes(draft.popupBetweenEndMinutes),
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final picked = await _pickTimeMinutes(
                            context,
                            draft.popupBetweenEndMinutes,
                          );
                          if (picked == null) return;
                          setState(
                            () => draft = draft.copyWith(
                              popupBetweenEndMinutes: picked,
                            ),
                          );
                          await _commit(rescheduleNotifications: false);
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
                label: const Text('Kapat'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final m = _clampMinutes(minutes);
    final h = m ~/ 60;
    final mm = m % 60;
    final hh = h.toString().padLeft(2, '0');
    final mms = mm.toString().padLeft(2, '0');
    return '$hh:$mms';
  }
}

