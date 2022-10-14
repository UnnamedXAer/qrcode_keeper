import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:qrcode_keeper/exceptions/app_exception.dart';

enum NotificationType {
  weekDayRemainder,
  monthlyReminder,
}

abstract class NotificationInfo {
  final TimeOfDay time;
  final NotificationType type;
  final int id;

  NotificationInfo({required this.id, required this.time, required this.type});

  NotificationInfo._fromMap(Map<String, dynamic> map)
      : id = map['id'],
        type = NotificationType.values[(map['type'])],
        time = TimeOfDay(
          hour: map['time']['hour'],
          minute: map['time']['minute'],
        );

  String toJson() {
    return convert.jsonEncode(_toMap());
  }

  factory NotificationInfo.fromJson(String data) {
    final map = convert.jsonDecode(data);
    switch (NotificationType.values[(map['type'])]) {
      case NotificationType.weekDayRemainder:
        return WeekDayNotificationInfo._fromMap(map);
      case NotificationType.monthlyReminder:
        return MonthDayNotificationInfo._fromMap(map);
      default:
        throw AppException(
          'Problem with notification.',
          Exception('unknown notification type: ${map['type']}'),
        );
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'id': id,
      'type': type.index,
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      }
    };
  }
}

class WeekDayNotificationInfo extends NotificationInfo {
  // nth day in the week as DateTime.monday~sunday
  final int weekDay;

  @override
  Map<String, dynamic> _toMap() {
    final map = super._toMap();
    map['weekDay'] = weekDay;

    return map;
  }

  WeekDayNotificationInfo({
    required TimeOfDay time,
    required this.weekDay,
  }) : super(
          id: weekDay,
          time: time,
          type: NotificationType.weekDayRemainder,
        );

  WeekDayNotificationInfo._fromMap(Map<String, dynamic> map)
      : weekDay = map['weekDay'],
        super._fromMap(map);
}

class MonthDayNotificationInfo extends NotificationInfo {
  /// nth day in the month 1~(28-31)
  final int day;

  @override
  Map<String, dynamic> _toMap() {
    throw UnimplementedError();
  }

  MonthDayNotificationInfo._fromMap(Map<String, dynamic> map)
      : day = map['day'],
        super._fromMap(map);
}
