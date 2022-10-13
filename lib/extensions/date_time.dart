import 'package:intl/intl.dart';

extension DateParsing on DateTime {
  String format({
    bool withTime = true,
    withSeconds = false,
  }) {
    if (withTime) {
      if (withSeconds) {
        return DateFormat.yMMMd().add_Hms().format(this);
      }
      return DateFormat.yMMMd().add_Hm().format(this);
    }
    return DateFormat.yMMMd().format(this);
  }

  String monthDesc({bool withYear = true}) {
    if (withYear) return DateFormat.yMMMM().format(this);
    return DateFormat.MMMM().format(this);
  }
}
