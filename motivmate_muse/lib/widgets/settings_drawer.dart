import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/motivmoodlogo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  draft.appLanguage == 'en' ? 'Settings' : 'Ayarlar',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ExpansionTile(
              leading: const Icon(Icons.language),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(draft.appLanguage == 'en' ? 'App Language' : 'Uygulama Dili'),
              initiallyExpanded: false,
              children: [
                ListTile(
                  title: Text(draft.appLanguage == 'en' ? 'Selected Language' : 'Seçili Dil'),
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
                      // No refreshQuote() — the current quote already has both
                      // Turkish and English text; changing the language setting
                      // is enough to switch the displayed language.
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.palette_outlined),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(draft.appLanguage == 'en' ? 'Theme Settings' : 'Tema Ayarları'),
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
                }),
                const SizedBox(height: 8),
              ],
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.notifications_outlined),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(draft.appLanguage == 'en' ? 'Notification Settings' : 'Bildirim Ayarları'),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 6),
                const SizedBox(height: 6),
                
                // ── BİLDİRİM İZNİ KONTROLÜ EKLENDİ ──
                SwitchListTile(
                  title: Text(draft.appLanguage == 'en' ? 'Bar Notification' : 'Bar Bildirimi'),
                  value: draft.barNotificationsEnabled,
                  onChanged: (v) async {
                    if (v == true) {
                      final status = await Permission.notification.request();
                      
                      if (status.isGranted) {
                        setState(() => draft = draft.copyWith(barNotificationsEnabled: true));
                        await _commit(rescheduleNotifications: true);
                      } else {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            title: Row(
                              children: [
                                const Icon(Icons.notifications_off_rounded, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(draft.appLanguage == 'en' ? 'Permission Required' : 'İzin Gerekli', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                            content: Text(
                              draft.appLanguage == 'en'
                                ? 'To receive daily motivation notifications, you need to allow notifications from your device settings.'
                                : 'Size günlük motivasyon bildirimleri gönderebilmemiz için cihaz ayarlarından izin vermeniz gerekiyor.',
                              style: const TextStyle(height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(draft.appLanguage == 'en' ? 'Cancel' : 'İptal', style: const TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await openAppSettings();
                                },
                                child: Text(
                                  draft.appLanguage == 'en' ? 'Open Settings' : 'Ayarları Aç', 
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      setState(() => draft = draft.copyWith(barNotificationsEnabled: false));
                      await _commit(rescheduleNotifications: true);
                    }
                  },
                ),
                // ── BİTİŞ ──

                const SizedBox(height: 6),
                if (draft.barNotificationsEnabled) ...[
                  ListTile(
                    dense: true,
                    title: Text(draft.appLanguage == 'en' ? 'Daily Notification Time' : 'Günlük Bildirim Saati'),
                    subtitle: Text(_formatMinutes(draft.barTimeOfDayMinutes)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await _pickTimeMinutes(
                        context,
                        draft.barTimeOfDayMinutes,
                      );
                      if (picked == null) return;
                      setState(
                        () => draft = draft.copyWith(
                          barTiming: BarTiming.timeOfDay,
                          barTimeOfDayMinutes: picked
                        ),
                      );
                      await _commit(rescheduleNotifications: true);
                    },
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
            const Divider(),
            if (!_app.billingService.isPremium) ...[
              ListTile(
                leading: const Icon(Icons.star_border),
                title: Text(draft.appLanguage == 'en' ? 'Subscribe' : 'Abone Ol'),
                subtitle: Text(draft.appLanguage == 'en' ? 'Remove ads & limits' : 'Reklamları ve sınırları kaldır'),
                onTap: () {
                  showDialog(context: context, builder: (ctx) {
                    return AlertDialog(
                      title: Text(draft.appLanguage == 'en' ? 'Premium Subscription' : 'Premium Abonelik'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(draft.appLanguage == 'en' ? 'Monthly' : 'Aylık'),
                            onTap: () {
                              _app.billingService.buyProduct('base_plan_aylik');
                              Navigator.pop(ctx);
                            },
                          ),
                          ListTile(
                            title: Text(draft.appLanguage == 'en' ? 'Yearly' : 'Yıllık'),
                            onTap: () {
                              _app.billingService.buyProduct('base_plan_yillik');
                              Navigator.pop(ctx);
                            },
                          )
                        ]
                      )
                    );
                  });
                },
              ),
              const Divider(),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
                label: Text(draft.appLanguage == 'en' ? 'Close' : 'Kapat'),
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