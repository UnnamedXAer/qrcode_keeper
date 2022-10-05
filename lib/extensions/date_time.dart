import 'dart:io';

import 'package:intl/intl.dart';

extension DateParsing on DateTime {
  String format({bool withTime = true}) {
    if (withTime) {
      return DateFormat.yMMMd(Platform.localeName).add_Hm().format(this);
    }
    return DateFormat.yMMMd(Platform.localeName).format(this);
  }

  String monthDesc({bool withYear = true}) {
    if (withYear) return DateFormat.yMMMM(Platform.localeName).format(this);
    return DateFormat.MMMM(Platform.localeName).format(this);
  }
}
