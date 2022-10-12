import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  Future<void> showScheduled({
    required int id,
    required Time notificationTime,
    String? title,
    String? body,
    String? payload,
  }) {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'kt.qrcode_keeper.daily_remainder_use_qr_code',
        'QR Keeper Daily Remainder: Go use QR code',
        channelDescription: 'This is a daily remainder about using a QR code.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'QR Keeper - daily remainder: use QR code.',
      ),
    );

    return _localNotificationsPlugin.showDailyAtTime(
      id,
      title,
      body,
      notificationTime,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> seePendingNotificationRequest() async {
    final notifs =
        await _localNotificationsPlugin.pendingNotificationRequests();
    log('${notifs.length}');
    for (var n in notifs) {
      log('${n.id} / ${n.payload}');
    }
  }

  Future<void> cancelAll() {
    return _localNotificationsPlugin.cancelAll();
  }
}
