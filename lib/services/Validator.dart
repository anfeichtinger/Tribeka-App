import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/widgets/CustomSelectableTags.dart';

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

  static ShiftStatus _validWork(Shift shift) {
    if (shift.workFrom == '-' || shift.workTo == '-') {
      return ShiftStatus.workMissing;
    } else {
      final _pattern = r'([0-9]{2}):([0-9]{2})';
      final _regex = RegExp(_pattern);

      if (!_regex.hasMatch(
          '${shift.workFrom.split(":")[0]}:${shift.workFrom.split(":")[1]}')) {
        return ShiftStatus.wrongFormat;
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
        return ShiftStatus.workToBeforeWorkFrom;
      }
    }
    return ShiftStatus.valid;
  }

  static ShiftStatus _validBreak(Shift shift) {
    if (shift.breakFrom == '-' && shift.breakTo != '-') {
      return ShiftStatus.breakFromMissing;
    } else if (shift.breakTo == '-' && shift.breakFrom != '-') {
      return ShiftStatus.breakToMissing;
    } else if (shift.breakFrom == '-' && shift.breakTo == '-') {
      return ShiftStatus.valid;
    }

    final _pattern = r'([0-9]{2}):([0-9]{2})';
    final _regex = RegExp(_pattern);

    if (!_regex.hasMatch(
        '${shift.breakFrom.split(":")[0]}:${shift.breakTo.split(":")[1]}')) {
      return ShiftStatus.wrongFormat;
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

      if (_breakFrom.isAfter(_breakTo) ||
          _breakFrom.isAtSameMomentAs(_breakTo)) {
        return ShiftStatus.breakFromAfterBreakTo;
      }

      if (_breakFrom.isBefore(_workFrom) ||
          _breakFrom.isAtSameMomentAs(_workFrom)) {
        return ShiftStatus.breakFromBeforeWorkFrom;
      } else if (_breakFrom.isAfter(_workTo) ||
          _breakFrom.isAtSameMomentAs(_workTo)) {
        return ShiftStatus.breakFromAfterWorkTo;
      }

      if (_breakTo.isAfter(_workTo) || _breakTo.isAtSameMomentAs(_workTo)) {
        return ShiftStatus.breakToBeforeWorkTo;
      }
    }

    return ShiftStatus.valid;
  }

  static ShiftStatus validateShift(Shift shift) {
    ShiftStatus workResult = _validWork(shift);
    ShiftStatus breakResult = _validBreak(shift);
    if (workResult == ShiftStatus.valid && breakResult == ShiftStatus.valid) {
      return ShiftStatus.valid;
    } else if (workResult != ShiftStatus.valid) {
      return workResult;
    } else if (breakResult != ShiftStatus.valid) {
      return breakResult;
    } else {
      return ShiftStatus.genericError;
    }
  }

  static String tagExists(List<Tag> tags, String title) {
    if (title == null || title.isEmpty) {
      return 'Name darf nicht leer sein';
    }
    if (tags.any((tag) => tag.title == title)) {
      return 'So eine Vorlage existiert bereits';
    }
    return null;
  }
}

enum ShiftStatus {
  genericError,
  valid,
  workMissing,
  breakFromMissing,
  breakToMissing,
  wrongFormat,
  workToBeforeWorkFrom,
  breakToAfterWorkTo,
  breakToBeforeWorkTo,
  breakFromBeforeWorkFrom,
  breakFromAfterWorkTo,
  breakFromAfterBreakTo,
}
