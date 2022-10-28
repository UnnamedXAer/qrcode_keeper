import 'package:flutter/material.dart';

const kWeekDays = <int, String>{
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

String formatTimeOfDay(TimeOfDay t) {
  return '${t.hour < 10 ? '0${t.hour}' : t.hour}:${t.minute < 10 ? '0${t.minute}' : t.minute}';
}
