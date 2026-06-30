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

  // Gün Boyunca Kalıcı Tutulacak Görülen Sözler Listesi
  final List<Quote> _seenQuotes = [];
  
  // İkon Değişimi İçin Senkronize Sayaç Takibi
  int _todayAdCount = 0;
  bool get isLimitReached => _todayAdCount >= 3;

  AppState({
    required this.storageService,
    required this.quoteService,
    required this.notificationService,
    required this.billingService,
    required AppSettings initialSettings,
    required Quote initialQuote,
  })  : settings = initialSettings,
        quote = initialQuote,
        isQuoteVisible = true {
    // İlk açılışta hafızadaki kalıcı verileri yükle
    _loadPersistentSeenQuotes();
  }

  Future<void> initialize() async {
    _lastPopupShownAt = await storageService.loadLastPopupShownAt();
    _todayAdCount = await getAdsWatchedToday();
    await _loadPersistentSeenQuotes();
  }

  // Kalıcı Hafızadan Görülen Sözleri Yükleme Fonksiyonu
  Future<void> _loadPersistentSeenQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final savedDate = prefs.getString('seenQuotesDate');
    
    _seenQuotes.clear();
    if (savedDate == todayStr) {
      final encodedList = prefs.getStringList('seenQuotesList') ?? [];
      for (var item in encodedList) {
        final parts = item.split('|||');
        if (parts.length >= 5) {
          _seenQuotes.add(Quote(
            textTr: parts[0],
            textEn: parts[1],
            authorTr: parts[2],
            authorEn: parts[3],
            imageAsset: parts[4], // DÜZELTİLDİ: imagePath yerine imageAsset
          ));
        } else if (parts.length >= 4) {
          // Eski format yedek uyumluluğu
          _seenQuotes.add(Quote(
            textTr: parts[0],
            textEn: parts[1],
            authorTr: parts[2],
            authorEn: parts[2],
            imageAsset: parts[3], // DÜZELTİLDİ
          ));
        }
      }
    } else {
      await prefs.setString('seenQuotesDate', todayStr);
      await prefs.setStringList('seenQuotesList', []);
    }
    _addCurrentQuoteToSeen();
  }

  // Görülen Sözleri Cihaza Kalıcı Kaydetme Fonksiyonu
  Future<void> _savePersistentSeenQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    
    List<String> encodedList = _seenQuotes.map((q) {
      // DÜZELTİLDİ: Veritabanına kaydederken yolların tam listesi
      return '${q.textTr}|||${q.textEn}|||${q.authorTr}|||${q.authorEn}|||${q.imagePath}';
    }).toList();
    
    await prefs.setString('seenQuotesDate', todayStr);
    await prefs.setStringList('seenQuotesList', encodedList);
  }

  void _addCurrentQuoteToSeen() {
    if (!_seenQuotes.any((q) => q.textTr == quote.textTr)) {
      _seenQuotes.add(quote);
      _savePersistentSeenQuotes();
    }
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
      _todayAdCount = 0;
      notifyListeners();
      return 0;
    }
    _todayAdCount = prefs.getInt('adsWatchedCount') ?? 0;
    return _todayAdCount;
  }

  Future<bool> canWatchAd() async {
    final count = await getAdsWatchedToday();
    return count < 3; 
  }

  Future<void> incrementAdWatchAndRefreshQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getAdsWatchedToday();
    _todayAdCount = count + 1;
    await prefs.setInt('adsWatchedCount', _todayAdCount);
    
    quote = await quoteService.getRandomQuote(language: settings.appLanguage, forceRefresh: true);
    _addCurrentQuoteToSeen();
    notifyListeners();
  }

  void cycleSeenQuotes() {
    if (_seenQuotes.isNotEmpty) {
      // Bulunduğumuz aktif alıntının sıradaki kalıcı dizin indeksini öğreniyoruz
      int currentIndex = _seenQuotes.indexWhere((q) => q.textTr == quote.textTr);
      
      // Eğer listede yoksa veya ilk defa dönüyorsa 0'dan başla, varsa bir sonraki sıraya geç
      int nextIndex = (currentIndex + 1) % _seenQuotes.length;
      
      quote = _seenQuotes[nextIndex];
      notifyListeners();
    }
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

    final allQuotesList = await quoteService.getAllQuotes(
      language: settings.appLanguage,
    );
    
    await notificationService.scheduleBarNotifications(
      settings: settings,
      allQuotes: allQuotesList.isEmpty ? [quote] : allQuotesList,
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

    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('dailyQuoteDate');
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    if (savedDate != todayStr) {
      await refreshQuote(force: false); 
    }

    unawaited(() async {
      // DÜZELTİLDİ: bodyNotificationsEnabled yerine barNotificationsEnabled kullanıldı
      if (settings.barNotificationsEnabled) {
        await rescheduleBarNotifications();
      }
    }());

    if (context.mounted) {
      await _maybeShowPopup(context);
    }
  }

  Future<void> refreshQuote({bool force = false}) async {
    quote = await quoteService.getRandomQuote(language: settings.appLanguage, forceRefresh: force);
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    await prefs.setString('dailyQuoteDate', todayStr);

    _addCurrentQuoteToSeen();
    notifyListeners();
  }
}