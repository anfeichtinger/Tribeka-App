import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tribeka/util/shift.dart';
import 'package:tribeka/widgets/custom_selectable_tags.dart';

class ShiftRepository {
  SharedPreferences _prefs;

  Future<void> _createInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  //
  // Related to Tags
  //

  Future<List<Tag>> getTags() async {
    await _createInstance();
    List<Tag> list = [];

    String data = _prefs.getString('templates');
    if (data != null && data.isNotEmpty) {
      final List<dynamic> jsonResult = json.decode(data) as List<dynamic>;
      jsonResult.forEach((value) {
        list.add(Tag(title: value['title'] as String));
      });
    }
    return list;
  }

  Future<List<Tag>> deletePersistedTag(String title) async {
    await _createInstance();
    String data = _prefs.getString("templates");
    if (data == null || data.isEmpty) {
      data = '[]';
    } else {
      List<dynamic> decData = jsonDecode(data) as List<dynamic>;
      decData.removeWhere((e) => e['title'].toString() == title);
      if (decData.toString() == "[]") {
        data = '';
      } else {
        data = jsonEncode(decData);
      }
      _prefs.setString("templates", data);
    }
    return await getTags();
  }

  Future<List<Tag>> persistTag(Shift shift, String title) async {
    await _createInstance();
    String data = _prefs.getString("templates");
    if (data == null || data.isEmpty) {
      data = '[';
    } else {
      data = data.substring(0, data.length - 1);
      data += ', ';
    }

    data +=
        '{"title": "$title","values": {"wFrom": "${shift.workFrom}","wTo": "${shift.workTo}","bFrom": "${shift.breakFrom}","bTo": "${shift.breakTo}"}}]';

    _prefs.setString("templates", data);
    return await getTags();
  }

  void clearTags() async {
    await _createInstance();
    _prefs.setString("templates", "");
  }

  Future<Shift> getPersistedTagShift(String title) async {
    await _createInstance();
    Shift shift;
    String data = _prefs.getString("templates");
    if (data != null && data.isNotEmpty) {
      List<dynamic> decData = jsonDecode(data) as List<dynamic>;
      decData.forEach((elem) {
        if (elem['title'] == title) {
          // We don't need a complete shift
          shift = Shift(
              "1",
              elem['values']['wFrom'] as String,
              elem['values']['wTo'] as String,
              elem['values']['bFrom'] as String,
              elem['values']['bTo'] as String,
              "",
              "");
        }
      });
    }
    return shift;
  }

  //
  // Persisting Shifts
  //

  Future<bool> monthIsPersisted(DateTime dateTime) async {
    await _createInstance();
    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    if (data == null || data.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> monthIsEditable(DateTime dateTime) async {
    await _createInstance();
    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    if (data == null || data.isEmpty) {
      return true;
    } else {
      List<dynamic> jsonData = jsonDecode(data) as List<dynamic>;
      return jsonData[0]['editable'] == 'true';
    }
  }

  Future<void> persistMonthShifts(DateTime dateTime, List<Shift> shifts,
      bool editable, double totalHours) async {
    await _createInstance();

    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    if (data == null || data.isEmpty) {
      data = '';
    } else if (!await monthIsEditable(dateTime)) {
      return;
    }

    data = '[{"editable": "$editable", "totalHours": "$totalHours","days": [';

    shifts.forEach((shift) {
      data +=
          '{"day": "${shift.day}", "values": {"wFrom": "${shift.workFrom}","wTo": "${shift.workTo}",'
          '"bFrom": "${shift.breakFrom}","bTo": "${shift.breakTo}",'
          '"comment": "${shift.comment}","weekday": "${shift.weekday}",'
          '"place": "${shift.place}","hours": "${shift.hours}"}},';
    });

    if (shifts.isNotEmpty) {
      data = data.substring(0, data.length - 1);
    }
    data += ']}]';

    _prefs.setString('${dateTime.year}-${dateTime.month}', data);
  }

  Future<List<Shift>> getPersistedMonthShifts(DateTime dateTime) async {
    await _createInstance();
    //_prefs.setString('${dateTime.year}-${dateTime.month}', '');
    List<Shift> shifts = [];
    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    if (data != null && data.isNotEmpty) {
      List<dynamic> jsonData = jsonDecode(data) as List<dynamic>;
      jsonData[0]['days'].forEach((elem) {
        shifts.add(Shift(
            elem['day'] as String,
            elem['values']['wFrom'] as String,
            elem['values']['wTo'] as String,
            elem['values']['bFrom'] as String,
            elem['values']['bTo'] as String,
            elem['values']['place'] as String,
            elem['values']['comment'] as String,
            elem['values']['hours'] as String,
            elem['values']['weekday'] as String));
      });
    }
    return shifts;
  }

  Future<double> getTotalHoursInMonth(DateTime dateTime) async {
    await _createInstance();
    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    double result = 0.0;
    if (data != null && data.isNotEmpty) {
      List<dynamic> jsonData = jsonDecode(data) as List<dynamic>;
      result = double.parse(jsonData[0]['totalHours'] as String);
    }
    return result;
  }

  void clearMonthData(DateTime dateTime) async {
    await _createInstance();
    _prefs.remove('${dateTime.year}-${dateTime.month}');
  }

  void clearAppData() async {
    await _createInstance();
    Set<String> keys = _prefs.getKeys();
    keys.forEach((key) {
      if (key != 'templates') {
        _prefs.remove(key);
      }
    });
  }
}
