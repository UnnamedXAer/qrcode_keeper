import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:qrcode_keeper/extensions/date_time.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  log(
    '''😐💤 notificationTapBackground:
      now: ${DateTime.now()}
      id: ${notificationResponse.id}, 
      payload: ${notificationResponse.payload}, 
      type: ${notificationResponse.notificationResponseType}
    ''',
  );

  return;
}

class LocalNotificationsService {
  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();
  late final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;

  static Future<bool?> initialize() {
    _instance._localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: null,
      macOS: null,
      linux: null,
    );

    // not awaited for now, if any problems occurs we will have to await that.
    _instance._configureLocalTimeZone();

    return _instance._localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        log(
          '''😐 onDidReceiveNotificationResponse: 
            now: ${DateTime.now()}
            id: ${notificationResponse.id}, 
            payload: ${notificationResponse.payload}, 
            type: ${notificationResponse.notificationResponseType}
          ''',
        );
        return;
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  }

  Future<void> showTZScheduledForDays({
    required Set<int> days,
    required TimeOfDay notificationTime,
    String? title,
    String? body,
    String? payload,
  }) async {
    await _localNotificationsPlugin.cancelAll();

    // TODO: pass days by parameter
    final Set<int> _days = {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    };

    if (_days.isEmpty) {
      return;
    }

    for (var day in _days) {
      final notificationDetails = _getWeekDayNotificationDetails();
      final scheduledDate = _getInstanceOfDateTimeFromTimeOfDay(
        day,
        notificationTime,
      );

      final payload =
          'Notif. scheduled at ${tz.TZDateTime.now(tz.local).format(withSeconds: true)} for 🔔 ${scheduledDate.format()} / $day + ${notificationTime.hour}:${notificationTime.minute}';

      log(payload);

      await _localNotificationsPlugin.zonedSchedule(
        // day as Id ensures we have at most 1 scheduled notification per week day
        day,
        title,
        body,
        payload: payload,
        scheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<List<String>> getPendingNotificationRequestText() async {
    final notifs =
        await _localNotificationsPlugin.pendingNotificationRequests();
    List<String> s = [];
    for (var n in notifs) {
      s.add('${n.id} / ${n.payload}');
    }

    return s;
  }

  Future<void> cancelAll() {
    return _localNotificationsPlugin.cancelAll();
  }

  Future<bool?> requestPermissions() async {
    final imp = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (imp == null) {
      return null;
    }

    final perm = await imp.requestPermission();
    return perm;
  }

  tz.TZDateTime _getInstanceOfDateTimeFromTimeOfDay(
    int weekDay,
    TimeOfDay time,
  ) {
    assert(weekDay >= DateTime.monday && weekDay <= DateTime.sunday);

    // 2022-08 -> start at monday (the "day" is 1) so its nicely work with weekDay(s) where monday is represented as 1.
    // otherwise passing "weekDay" as day would be an error causing incorrect date.
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      2022,
      8,
      weekDay,
      time.hour,
      time.minute,
    );

    return scheduledDate;
  }

  NotificationDetails _getWeekDayNotificationDetails() =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kt.qrcode_keeper.daily_remainder_use_qr_code',
          'QR Keeper Daily Remainder: Go use QR code',
          channelDescription:
              'This is a daily remainder about using a QR code.',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'QR Keeper - daily remainder: use QR code.',
          autoCancel: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
          color: Colors.lightGreen,
          colorized: true,
          category: AndroidNotificationCategory.reminder,
          ledColor: Colors.green,
          ledOnMs: 250,
          ledOffMs: 1000,
          enableVibration: true,
          visibility: NotificationVisibility.private,
          playSound: true,
          onlyAlertOnce: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              cancelNotification: true,
              showsUserInterface: false,
              contextual: false,
            ),
          ],
        ),
      );
}
