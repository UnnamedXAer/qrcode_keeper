import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:qrcode_keeper/exceptions/app_exception.dart';
import 'package:qrcode_keeper/models/notification_info.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

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
      onDidReceiveNotificationResponse: (notificationResponse) {},
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  }

  Future<void> scheduleWeekDaysNotifications({
    required Set<int> days,
    required TimeOfDay notificationTime,
    String? title,
    String? body,
  }) async {
    await _localNotificationsPlugin.cancelAll();

    try {
      for (var day in days) {
        final notificationDetails = _getWeekDayNotificationDetails();
        final scheduledDate = _getInstanceOfDateTimeFromTimeOfDay(
          day,
          notificationTime,
        );

        final payload = WeekDayNotificationInfo(
          time: notificationTime,
          weekDay: day,
        ).toJson();

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
    } on Exception catch (ex) {
      throw AppException('Failed to update notifications.', ex);
    }

    logPendingNotificationRequests();
  }

  Future<List<NotificationInfo>> getPendingNotificationRequests() async {
    // TODO: handle exceptions especially about permissions
    final notifs =
        await _localNotificationsPlugin.pendingNotificationRequests();
    List<NotificationInfo> infos = [];
    for (var n in notifs) {
      if (n.payload == null) {
        // Omit notifications that have no payload, since we cannot do anything with them.
        // We could cancel them but I guess it won't hurt to much if some
        // unexpected notification pops up.
        continue;
      }
      infos.add(NotificationInfo.fromJson(n.payload!));
    }

    return infos;
  }

  Future<List<WeekDayNotificationInfo>>
      getPendingWeekDayNotificationRequests() {
    return getPendingNotificationRequests().then(
      (value) => value.whereType<WeekDayNotificationInfo>().toList(),
    );
  }

  Future<void> logPendingNotificationRequests() async {
    final notifs =
        await _localNotificationsPlugin.pendingNotificationRequests();
    List<String> s = [];
    for (var n in notifs) {
      s.add('${n.id} / ${n.payload}');
    }

    debugPrint(s.join('\n'));
  }

  Future<void> cancelAll() {
    return _localNotificationsPlugin.cancelAll();
  }

  /// Requests permissions on Android 13. On older versions, it is a no-op.
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
          'QR Keeper Daily',
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
