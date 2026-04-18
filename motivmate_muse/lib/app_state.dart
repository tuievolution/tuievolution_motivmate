import 'dart:async';

import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'models/quote.dart';
import 'services/notification_service.dart';
import 'services/quote_service.dart';
import 'services/storage_service.dart';
import 'widgets/quote_card.dart';

class AppState extends ChangeNotifier {
  final StorageService storageService;
  final QuoteService quoteService;
  final NotificationService notificationService;

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
    required AppSettings initialSettings,
    required Quote initialQuote,
  })  : settings = initialSettings,
        quote = initialQuote,
        isQuoteVisible = true; // Always start with heart opened on app launch

  Future<void> initialize() async {
    _lastPopupShownAt = await storageService.loadLastPopupShownAt();
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

  Future<void> shuffleBackground() async {
    quote = await quoteService.getRandomQuote(language: settings.appLanguage);
    notifyListeners();
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

  bool _isWithinPopupBetweenHours(DateTime now) {
    final nowMins = now.hour * 60 + now.minute;
    final start = settings.popupBetweenStartMinutes;
    final end = settings.popupBetweenEndMinutes;

    if (start <= end) {
      return nowMins >= start && nowMins <= end;
    }
    // Wraps over midnight.
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
          // Immediate mode should appear whenever the user returns to the app,
          // but avoid spamming during very rapid resume cycles.
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

      // Popup card "over" the current screen.
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
    // Initialize cached popup timestamp.
    _lastPopupShownAt ??= await storageService.loadLastPopupShownAt();

    // Reschedule bar notifications in the background.
    unawaited(() async {
      if (settings.barNotificationsEnabled) {
        await rescheduleBarNotifications();
      }
    }());

    // Pop-up card when the app comes to foreground.
    if (!context.mounted) return;
    await _maybeShowPopup(context);
  }

  // Called from settings/edit screens to refresh the in-app quote and,
  // optionally, influence notifications payload for the next schedule window.
  Future<void> refreshQuote() async {
    quote = await quoteService.getRandomQuote(language: settings.appLanguage);
    notifyListeners();
  }
}

