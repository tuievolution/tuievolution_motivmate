import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/quote.dart';
import '../models/app_settings.dart';

class NotificationService {
  static const _channelId = 'motivmate_channel';
  static const _channelName = 'MotivMate';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    final localTz = await FlutterNativeTimezone.getLocalTimezone();
    final location = tz.getLocation(localTz);
    tz.setLocalLocation(location);

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: initSettings);

    // Android 13+ needs runtime permission for notifications.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'MotivMate bildirimi',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> showBarNotification(Quote quote) async {
    const id = 999999;
    await _plugin.show(
      id: id,
      title: 'MotivMate',
      body: '"${quote.text}"',
      notificationDetails: _notificationDetails(),
    );
  }

  Future<void> scheduleBarNotifications({
    required AppSettings settings,
    required List<Quote> quotesForSchedule,
  }) async {
    // For MVP: pre-schedule next occurrences with already chosen quotes.
    await _plugin.cancelAll();

    const maxNotifications = 48; // safety cap
    final details = _notificationDetails();
    final now = tz.TZDateTime.now(tz.local);

    if (settings.barTiming == BarTiming.intervalMinutes) {
      final interval = settings.barIntervalMinutes.clamp(5, 720);
      final occurrences =
          (24 * 60 / interval).floor().clamp(1, maxNotifications);
      for (var i = 0; i < occurrences; i++) {
        final when = now.add(Duration(minutes: i * interval));
        final quote = quotesForSchedule.isNotEmpty
            ? quotesForSchedule[i % quotesForSchedule.length]
            : quotesForSchedule.first;
        await _plugin.zonedSchedule(
          id: i + 1000,
          title: 'MotivMate',
          body: '"${quote.text}"',
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
      return;
    }

    // Bar time-of-day mode (daily).
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

        await _plugin.zonedSchedule(
          id: day + 2000,
          title: 'MotivMate',
          body: '"${quote.text}"',
          scheduledDate: date,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}

