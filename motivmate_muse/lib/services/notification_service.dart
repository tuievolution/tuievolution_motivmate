import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/quote.dart';
import '../models/app_settings.dart';

class NotificationService {
  static const _channelId = 'motivmate_channel';
  static const _channelName = 'MotivMood';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _tzConfigured = false;

  Future<void> _configureTimezoneSafely() async {
    if (_tzConfigured) return;
    tzdata.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(localTz.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      }
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }
    _tzConfigured = true;
  }

  Future<void> init() async {
    if (_initialized) return;
    await _configureTimezoneSafely();

    const androidInit = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/motivmoodlogo'),
    );
    final iosInit = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidInit.android, 
      iOS: iosInit
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'MotivMood daily motivation',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showBarNotification(Quote quote, String language) async {
    const id = 999999;
    await _plugin.show(
      id: id,
      title: 'MotivMood',
      body: '"${quote.text(language)}"',
      notificationDetails: _notificationDetails(),
    );
  }

  /// Extracts the universal daily quote using the EXACT SAME formula as QuoteService
  Quote _getUniversalDailyQuote(List<Quote> allQuotes, tz.TZDateTime targetDate) {
    if (allQuotes.isEmpty) throw Exception("Quote list cannot be empty");
    
    // EVRENSEL MATEMATİK: QuoteService ile birebir aynı hesaplama
    final daysSinceEpoch = DateTime(targetDate.year, targetDate.month, targetDate.day)
        .difference(DateTime(2024, 1, 1))
        .inDays;
    
    final universalIndex = daysSinceEpoch % allQuotes.length;
    return allQuotes[universalIndex];
  }

  Future<void> scheduleBarNotifications({
    required AppSettings settings,
    required List<Quote> allQuotes, 
  }) async {
    if (allQuotes.isEmpty) return;

    await _configureTimezoneSafely();
    await _plugin.cancelAll();

    final details = _notificationDetails();
    final now = tz.TZDateTime.now(tz.local);

    if (settings.barTiming == BarTiming.timeOfDay) {
      final targetMinutes = settings.barTimeOfDayMinutes.clamp(0, 24 * 60 - 1);
      final hour = targetMinutes ~/ 60;
      final minute = targetMinutes % 60;

      // Schedule for the next 7 days
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(Duration(days: dayOffset));
        
        if (date.isBefore(now)) continue;

        // Fetch the strict universal quote for this specific calendar day
        final universalQuote = _getUniversalDailyQuote(allQuotes, date);

        try {
          await _plugin.zonedSchedule(
            id: dayOffset + 2000,
            title: 'MotivMood',
            body: '"${universalQuote.text(settings.appLanguage)}"',
            scheduledDate: date,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          await _plugin.zonedSchedule(
            id: dayOffset + 2000,
            title: 'MotivMood',
            body: '"${universalQuote.text(settings.appLanguage)}"',
            scheduledDate: date,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    } else if (settings.barTiming == BarTiming.intervalMinutes) {
        // --- INTERVAL NOTIFICATIONS ---
        // If the user wants notifications every X minutes, we just use today's daily quote
        final targetQuote = _getUniversalDailyQuote(allQuotes, now);
        final intervalMinutes = settings.barIntervalMinutes.clamp(15, 240); // Minimum 15 mins to prevent spam

        for (int i = 1; i <= 8; i++) { // Schedule the next 8 interval occurrences
          final scheduledDate = now.add(Duration(minutes: intervalMinutes * i));
          
          try {
            await _plugin.zonedSchedule(
              id: i + 3000,
              title: 'MotivMood',
              body: '"${targetQuote.text(settings.appLanguage)}"',
              scheduledDate: scheduledDate,
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          } catch (_) {
            await _plugin.zonedSchedule(
              id: i + 3000,
              title: 'MotivMood',
              body: '"${targetQuote.text(settings.appLanguage)}"',
              scheduledDate: scheduledDate,
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
    }
  }
}