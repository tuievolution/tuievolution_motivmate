import 'dart:async';

import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'models/quote.dart';
import 'services/notification_service.dart';
import 'services/quote_service.dart';
import 'services/storage_service.dart';
import 'services/billing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final StorageService storageService;
  final QuoteService quoteService;
  final NotificationService notificationService;
  final BillingService billingService;

  AppSettings settings;
  Quote quote;
  bool isQuoteVisible;

  bool isOriginalView = false;

  AppState({
    required this.storageService,
    required this.quoteService,
    required this.notificationService,
    required this.billingService,
    required AppSettings initialSettings,
    required Quote initialQuote,
  })  : settings = initialSettings,
        quote = initialQuote,
        isQuoteVisible = true; // Always start with heart opened on app launch

  Future<void> initialize() async {
    // no-op initialization kept for compatibility
  }

  // --- Photo / card actions ---

  void toggleOriginalView() {
    isOriginalView = !isOriginalView;
    notifyListeners();
  }

  void toggleQuoteVisibility() {
    isQuoteVisible = !isQuoteVisible;
    notifyListeners();
  }

  void setQuoteVisibility(bool visible) {
    isQuoteVisible = visible;
    notifyListeners();
  }

  Future<void> shuffleBackground({bool force = false}) async {
    quote = await quoteService.getRandomQuote(language: settings.appLanguage, forceRefresh: force);
    notifyListeners();
  }

  Future<int> getAdsWatchedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final savedDate = prefs.getString('adWatchDate');
    if (savedDate != todayStr) {
      await prefs.setString('adWatchDate', todayStr);
      await prefs.setInt('adsWatchedCount', 0);
      return 0;
    }
    return prefs.getInt('adsWatchedCount') ?? 0;
  }

  Future<bool> canWatchAd() async {
    if (billingService.isPremium) return true;
    final count = await getAdsWatchedToday();
    return count < 3;
  }

  Future<void> incrementAdWatchAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    if (!billingService.isPremium) {
      final count = await getAdsWatchedToday();
      await prefs.setInt('adsWatchedCount', count + 1);
    }
    await shuffleBackground(force: true);
  }

  // Update settings for UI preview only; call persistSettings() when done.
  void updateSettingsTemporary(AppSettings newSettings) {
    final languageChanged = settings.appLanguage != newSettings.appLanguage;
    settings = newSettings;
    if (languageChanged) {
      quoteService.clearCache();
    }
    notifyListeners();
  }

  Future<void> persistSettings({bool rescheduleNotifications = false}) async {
    await storageService.saveSettings(settings);
    if (rescheduleNotifications) {
      await rescheduleBarNotifications();
    }
  }

  // --- Notifications ---

  Future<void> rescheduleBarNotifications() async {
    if (!settings.barNotificationsEnabled) {
      // Cancel all pending notifications when disabled.
      await notificationService.cancelAll();
      return;
    }

    final allQuotes = await quoteService.getAllQuotes(
      language: settings.appLanguage,
    );
    final scheduleQuotes = allQuotes.isEmpty ? [quote] : allQuotes.take(8).toList();
    await notificationService.scheduleBarNotifications(
      settings: settings,
      quotesForSchedule: scheduleQuotes,
    );
  }



  Future<void> handleAppResumed(BuildContext context) async {
    // Reschedule bar notifications in the background.
    unawaited(() async {
      if (settings.barNotificationsEnabled) {
        await rescheduleBarNotifications();
      }
    }());
  }

  // Called from settings/edit screens to refresh the in-app quote and,
  // optionally, influence notifications payload for the next schedule window.
  Future<void> refreshQuote({bool force = false}) async {
    quote = await quoteService.getRandomQuote(language: settings.appLanguage, forceRefresh: force);
    notifyListeners();
  }
}

