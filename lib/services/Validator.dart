import 'package:tribeka/util/Shift.dart';

class Validator {
  static String validateEmail(String value) {
    final pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    final regex = RegExp(pattern);
    if (regex.hasMatch(value)) {
      return null;
    } else {
      return 'Ungültige Email Adresse';
    }
  }

  static String validatePassword(String value) {
    if (value.length > 2) {
      return null;
    } else {
      return 'Ungültiges Passwort';
    }
  }

  static bool _validWork(Shift shift) {
    if (shift.workFrom == '-' || shift.workTo == '-') {
      return false;
    } else {
      final _pattern = r'([0-9]{2}):([0-9]{2})';
      final _regex = RegExp(_pattern);

      if (!_regex.hasMatch(
          '${shift.workFrom.split(":")[0]}:${shift.workFrom.split(":")[1]}')) {
        return false;
      }

      final _workFrom = DateTime(
          0,
          0,
          0,
          int.parse(shift.workFrom.split(':')[0]),
          int.parse(shift.workFrom.split(':')[1]));
      final _workTo = DateTime(0, 0, 0, int.parse(shift.workTo.split(':')[0]),
          int.parse(shift.workTo.split(':')[1]));

      if (_workFrom.isAfter(_workTo) || _workFrom.isAtSameMomentAs(_workTo)) {
        return false;
      }
    }
    return true;
  }

  static bool _validBreak(Shift shift) {
    if (shift.breakFrom == '-' && shift.breakTo != '-' ||
        shift.breakTo == '-' && shift.breakFrom != '-') {
      return false;
    } else if (shift.breakFrom == '-' && shift.breakTo == '-') {
      return true;
    }

    final _pattern = r'([0-9]{2}):([0-9]{2})';
    final _regex = RegExp(_pattern);

    if (!_regex.hasMatch(
        '${shift.breakFrom.split(":")[0]}:${shift.breakTo.split(":")[1]}')) {
      return false;
    }

    final _breakFrom = DateTime(
        0,
        0,
        0,
        int.parse(shift.breakFrom.split(':')[0]),
        int.parse(shift.breakFrom.split(':')[1]));
    final _breakTo = DateTime(0, 0, 0, int.parse(shift.breakTo.split(':')[0]),
        int.parse(shift.breakTo.split(':')[1]));

    if (_breakFrom.isAfter(_breakTo) || _breakFrom.isAtSameMomentAs(_breakTo)) {
      return false;
    }
    return true;
  }

  static bool validShift(Shift shift) {
    if (_validWork(shift) && _validBreak(shift)) {
      return true;
    } else {
      return false;
    }
  }
}
