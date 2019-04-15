import 'package:tribeka/util/Shift.dart';

class InitTimeGenerator {
  static int _getBreakMinutes(int i) {
    switch (i) {
      case 30:
        return 0;
      case 45:
        return 15;
      default:
        return i + 30;
    }
  }

  static DateTime workFrom(DateTime time, Shift shift) {
    if (shift.workFrom == '-') {
      if (shift.workTo == '-') {
        return DateTime(time.year, time.month, time.day, 11, 0);
      } else {
        final split = shift.workTo.split(':');
        int hour = int.parse(split[0]) - 7;
        if (hour < 6) {
          hour = 6;
        }
        int minute = _getBreakMinutes(int.parse(split[1]));
        return DateTime(time.year, time.month, time.day, hour, minute);
      }
    } else {
      final split = shift.workFrom.split(':');
      return DateTime(time.year, time.month, time.day, int.parse(split[0]),
          int.parse(split[1]));
    }
  }

  static DateTime workTo(DateTime time, Shift shift) {
    if (shift.workTo == '-') {
      if (shift.workFrom == '-') {
        return DateTime(time.year, time.month, time.day, 15, 0);
      } else {
        final split = shift.workFrom.split(':');
        int hour = int.parse(split[0]) + 7;
        if (hour > 20) {
          hour = 20;
        }
        int minute = _getBreakMinutes(int.parse(split[1]));
        return DateTime(time.year, time.month, time.day, hour, minute);
      }
    } else {
      final split = shift.workTo.split(':');
      return DateTime(time.year, time.month, time.day, int.parse(split[0]),
          int.parse(split[1]));
    }
  }

  static DateTime breakFrom(DateTime time, Shift shift) {
    if (shift.breakFrom == '-') {
      return DateTime(time.year, time.month, time.day, 12, 0);
    } else {
      final split = shift.breakFrom.split(':');
      return DateTime(time.year, time.month, time.day, int.parse(split[0]),
          int.parse(split[1]));
    }
  }

  static DateTime breakTo(DateTime time, Shift shift) {
    if (shift.breakTo == '-') {
      return DateTime(time.year, time.month, time.day, 14, 0);
    } else {
      final split = shift.breakTo.split(':');
      return DateTime(time.year, time.month, time.day, int.parse(split[0]),
          int.parse(split[1]));
    }
  }
}
