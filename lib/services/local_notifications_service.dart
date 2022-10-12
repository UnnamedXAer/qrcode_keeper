import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  static const kDailyQrReminderId = 0;
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

  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) {
    assert(
      id != kDailyQrReminderId,
      'id of value: $kDailyQrReminderId is reserved for daily qr reminder',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'kt.qrcode_keeper.instant_notification',
        'QR Keeper Instant Notification',
        channelDescription: 'This is instant notification with any message.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'QR Keeper - instant notification.',
      ),
    );

    return _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showTZScheduled({
    required int id,
    required Time notificationTime,
    String? title,
    String? body,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'kt.qrcode_keeper.daily_remainder_use_qr_code',
        'QR Keeper Daily Remainder: Go use QR code',
        channelDescription: 'This is a daily remainder about using a QR code.',
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
// TODO: here
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    final location = tz.getLocation(timeZoneName!);
    tz.setLocalLocation(location);
    final scheduledDate = tz.TZDateTime.now(location).add(
      Duration(seconds: 10),
    );

    return _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      payload: payload,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
  // Future<void> showScheduled({
  //   required int id,
  //   required Time notificationTime,
  //   String? title,
  //   String? body,
  //   String? payload,
  // }) {
  //   const NotificationDetails notificationDetails = NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       'kt.qrcode_keeper.daily_remainder_use_qr_code',
  //       'QR Keeper Daily Remainder: Go use QR code',
  //       channelDescription: 'This is a daily remainder about using a QR code.',
  //       importance: Importance.max,
  //       priority: Priority.max,
  //       ticker: 'QR Keeper - daily remainder: use QR code.',
  //       autoCancel: true,
  //       audioAttributesUsage: AudioAttributesUsage.notification,
  //       color: Colors.lightGreen,
  //       colorized: true,
  //       category: AndroidNotificationCategory.reminder,
  //       ledColor: Colors.green,
  //       ledOnMs: 250,
  //       ledOffMs: 1000,
  //       enableVibration: true,
  //       visibility: NotificationVisibility.private,
  //       playSound: true,
  //       actions: <AndroidNotificationAction>[
  //         AndroidNotificationAction(
  //           'dismiss',
  //           'Dismiss',
  //           cancelNotification: true,
  //           showsUserInterface: false,
  //           contextual: false,
  //         ),
  //       ],
  //     ),
  //   );

  //   return _localNotificationsPlugin.showDailyAtTime(
  //     id,
  //     title,
  //     body,
  //     notificationTime,
  //     notificationDetails,
  //     payload: payload,
  //   );
  // }

  Future<String> getPendingNotificationRequestText() async {
    final notifs =
        await _localNotificationsPlugin.pendingNotificationRequests();
    String s = '${notifs.length}\n';
    for (var n in notifs) {
      s += ('\n${n.id} / ${n.payload}');
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
}
