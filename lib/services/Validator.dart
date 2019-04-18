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

  static String _validWork(Shift shift) {
    if (shift.workFrom == '-' || shift.workTo == '-') {
      return 'Es muss Arbeit von und Arbeit bis ausgefüllt werden';
    } else {
      final _pattern = r'([0-9]{2}):([0-9]{2})';
      final _regex = RegExp(_pattern);

      if (!_regex.hasMatch(
          '${shift.workFrom.split(":")[0]}:${shift.workFrom.split(":")[1]}')) {
        return 'Fehlerhafte Arbeits Formartierung';
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
        return 'Arbeit von muss vor Arbeit bis liegen';
      }
    }
    return '';
  }

  static String _validBreak(Shift shift) {
    if (shift.breakFrom == '-' && shift.breakTo != '-' ||
        shift.breakTo == '-' && shift.breakFrom != '-') {
      return 'Es müssen beide/keine Pausen ausgeüllt werden';
    } else if (shift.breakFrom == '-' && shift.breakTo == '-') {
      return '';
    }

    final _pattern = r'([0-9]{2}):([0-9]{2})';
    final _regex = RegExp(_pattern);

    if (!_regex.hasMatch(
        '${shift.breakFrom.split(":")[0]}:${shift.breakTo.split(":")[1]}')) {
      return 'Fehlerhafte Pausen Formartierung';
    }

    final _breakFrom = DateTime(
        0,
        0,
        0,
        int.parse(shift.breakFrom.split(':')[0]),
        int.parse(shift.breakFrom.split(':')[1]));
    final _breakTo = DateTime(0, 0, 0, int.parse(shift.breakTo.split(':')[0]),
        int.parse(shift.breakTo.split(':')[1]));

    if (shift.workFrom != '-' && shift.workTo != '-') {
      final _workFrom = DateTime(
          0,
          0,
          0,
          int.parse(shift.workFrom.split(':')[0]),
          int.parse(shift.workFrom.split(':')[1]));
      final _workTo = DateTime(0, 0, 0, int.parse(shift.workTo.split(':')[0]),
          int.parse(shift.workTo.split(':')[1]));

      if (_breakTo.isAfter(_workTo) || _breakTo.isAtSameMomentAs(_workTo)) {
        return 'Pause darf nicht nach Arbeitsende enden';
      }

      if (_breakFrom.isBefore(_workFrom) ||
          _breakFrom.isAtSameMomentAs(_workFrom)) {
        return 'Pause muss nach Abeitsbeginn liegen';
      } else if (_breakFrom.isAfter(_workTo) ||
          _breakFrom.isAtSameMomentAs(_workTo)) {
        return 'Pause darf nicht nach Arbeitsende liegen';
      }
    }

    if (_breakFrom.isAfter(_breakTo) || _breakFrom.isAtSameMomentAs(_breakTo)) {
      return 'Pausenebeginn muss vor Pausenende liegen';
    }
    return '';
  }

  static String validateShift(Shift shift) {
    String workResult = _validWork(shift);
    String breakResult = _validBreak(shift);
    if (workResult.isEmpty && breakResult.isEmpty) {
      return '';
    } else if (workResult.isNotEmpty) {
      return workResult;
    } else if (breakResult.isNotEmpty) {
      return breakResult;
    } else {
      return 'Test';
    }
  }
}
