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

    const androidInit =
        AndroidInitializationSettings('@mipmap/motivmoodlogo');
    final iosInit = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

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
      channelDescription: 'MotivMood bildirimi',
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

  Future<void> scheduleBarNotifications({
    required AppSettings settings,
    required List<Quote> quotesForSchedule,
  }) async {
    await _configureTimezoneSafely();
    await _plugin.cancelAll();

    final details = _notificationDetails();
    final now = tz.TZDateTime.now(tz.local);

    if (settings.barTiming == BarTiming.timeOfDay) {
      final targetMinutes = settings.barTimeOfDayMinutes.clamp(0, 24 * 60 - 1);
      final hour = targetMinutes ~/ 60;
      final minute = targetMinutes % 60;

      for (var day = 0; day < 7; day++) {
        final date = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(Duration(days: day));
        if (date.isBefore(now)) continue;

        final quote = quotesForSchedule.isNotEmpty
            ? quotesForSchedule[day % quotesForSchedule.length]
            : quotesForSchedule.first;

        try {
          await _plugin.zonedSchedule(
            id: day + 2000,
            title: 'MotivMood',
            body: '"${quote.text(settings.appLanguage)}"',
            scheduledDate: date,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          await _plugin.zonedSchedule(
            id: day + 2000,
            title: 'MotivMood',
            body: '"${quote.text(settings.appLanguage)}"',
            scheduledDate: date,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }
  }
}