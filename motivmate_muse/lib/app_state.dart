import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_settings.dart';
import 'models/quote.dart';
import 'services/notification_service.dart';
import 'services/quote_service.dart';
import 'services/storage_service.dart';
import 'services/billing_service.dart';
import 'widgets/quote_card.dart';

class AppState extends ChangeNotifier {
  final StorageService storageService;
  final QuoteService quoteService;
  final NotificationService notificationService;
  final BillingService billingService;

  AppSettings settings;
  Quote quote;
  bool isQuoteVisible;

  bool isOriginalView = false;

  DateTime? _lastPopupShownAt;
  bool _popupInFlight = false;

  AppState({
    required this.storageService,
    required this.quoteService,
    required this.notificationService,
    required this.billingService,
    required AppSettings initialSettings,
    required Quote initialQuote,
  })  : settings = initialSettings,
        quote = initialQuote,
        isQuoteVisible = true;

  Future<void> initialize() async {
    _lastPopupShownAt = await storageService.loadLastPopupShownAt();
  }

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

  Future<void> incrementAdWatchAndRefreshQuote() async {
    if (!billingService.isPremium) {
      final prefs = await SharedPreferences.getInstance();
      final count = await getAdsWatchedToday();
      await prefs.setInt('adsWatchedCount', count + 1);
    }
    
    quote = await quoteService.getRandomQuote(language: settings.appLanguage, forceRefresh: true);
    notifyListeners();
  }

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

  Future<void> rescheduleBarNotifications() async {
    if (!settings.barNotificationsEnabled) {
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

  bool _isWithinPopupBetweenHours(DateTime now) {
    final nowMins = now.hour * 60 + now.minute;
    final start = settings.popupBetweenStartMinutes;
    final end = settings.popupBetweenEndMinutes;

    if (start <= end) {
      return nowMins >= start && nowMins <= end;
    }
    return nowMins >= start || nowMins <= end;
  }

  bool _isWithinPopupTimeOfDay(DateTime now, {int toleranceMinutes = 15}) {
    final target = settings.popupTimeOfDayMinutes;
    final nowMins = now.hour * 60 + now.minute;
    final diff = (nowMins - target).abs();
    return diff <= toleranceMinutes;
  }

  Future<void> _maybeShowPopup(BuildContext context) async {
    if (_popupInFlight) return;
    if (!settings.popupOnOpenEnabled) return;

    _popupInFlight = true;
    try {
      _lastPopupShownAt ??= await storageService.loadLastPopupShownAt();
      final now = DateTime.now();

      final last = _lastPopupShownAt;
      final sameDay = last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;

      var shouldShow = false;
      switch (settings.popupTiming) {
        case PopupTiming.immediate:
          shouldShow = last == null || now.difference(last) > const Duration(minutes: 15);
          break;
        case PopupTiming.timeOfDay:
          if (sameDay) break;
          shouldShow = _isWithinPopupTimeOfDay(now);
          break;
        case PopupTiming.betweenHours:
          if (sameDay) break;
          shouldShow = _isWithinPopupBetweenHours(now);
          break;
      }

      if (!shouldShow) return;

      _lastPopupShownAt = now;
      await storageService.saveLastPopupShownAt(now);

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuoteCard(
                      text: quote.text(settings.appLanguage),
                      author: quote.author(settings.appLanguage),
                      cardBackgroundColor: Color(settings.cardBackgroundColorValue),
                      quoteTextColor: Color(settings.textColorValue),
                      opacity: settings.cardOpacity,
                      fontSize: settings.fontSize,
                      fontFamily: settings.fontFamily,
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Kapat'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _popupInFlight = false;
    }
  }

  Future<void> handleAppResumed(BuildContext context) async {
    _lastPopupShownAt ??= await storageService.loadLastPopupShownAt();

    unawaited(() async {
      if (settings.barNotificationsEnabled) {
        await rescheduleBarNotifications();
      }
    }());

    if (!context.mounted) return;
    await _maybeShowPopup(context);
  }

  Future<void> refreshQuote({bool force = false}) async {
    quote = await quoteService.getRandomQuote(language: settings.appLanguage, forceRefresh: force);
    notifyListeners();
  }
}