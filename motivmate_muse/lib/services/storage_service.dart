import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class StorageService {
  static const _settingsKey = 'motivmate_settings_v1';
  static const _lastPopupKey = 'motivmate_last_popup_shown_at';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings.defaults();
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppSettings.fromJson(decoded);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, raw);
  }

  Future<DateTime?> loadLastPopupShownAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastPopupKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> saveLastPopupShownAt(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPopupKey, at.millisecondsSinceEpoch);
  }
}

