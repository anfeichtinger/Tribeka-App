import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/widgets/CustomSelectableTags.dart';

class ShiftRepository {
  static SharedPreferences _prefs;
  final String _encryptionKey = "GEz6dfizuEMU3orMRGRsLtSn3jgKjoQf";
  static Encrypter _encrypter;

  Future<Null> _createInstance() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    if (_encrypter == null) {
      _encrypter = Encrypter(AES(Key.fromUtf8(_encryptionKey)));
    }
  }

  //
  // Autologin
  //

  Future<bool> getAutologin() async {
    await _createInstance();
    return _prefs.getBool("autologin");
  }

  Future<bool> persistAutologin(bool autologin) async {
    await _createInstance();
    await _prefs.setBool("autologin", autologin);
    return getAutologin();
  }

  //
  // Place
  //

  Future<String> getPlace() async {
    await _createInstance();
    return _prefs.getString("place");
  }

  Future<String> persistPlace(String place) async {
    await _createInstance();
    await _prefs.setString("place", place);
    return getPlace();
  }

  //
  // Email & Password
  //

  Future<String> getEmail() async {
    await _createInstance();
    return _prefs.getString("email");
  }

  Future<String> persistEmail(String email) async {
    await _createInstance();
    await _prefs.setString("email", email);
    return getEmail();
  }

  Future<String> getPassword() async {
    await _createInstance();
    return _encrypter.decrypt64(_prefs.getString("pass"));
  }

  Future<String> persistPassword(String pw) async {
    await _createInstance();
    await _prefs.setString("pass", _encrypter.encrypt(pw).base64);
    return getPassword();
  }

  //
  // Related to Tags
  //

  Future<List<Tag>> getTags() async {
    await _createInstance();
    List<Tag> list = [];

    String data = _prefs.getString('templates');
    if (data != null && data.isNotEmpty) {
      final List<dynamic> jsonResult = json.decode(data);
      jsonResult.forEach((value) {
        list.add(Tag(title: value['title']));
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
      List<dynamic> decData = jsonDecode(data);
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
      List<dynamic> decData = jsonDecode(data);
      decData.forEach((elem) {
        if (elem['title'] == title) {
          // We don't need a complete shift
          shift = Shift("1", elem['values']['wFrom'], elem['values']['wTo'],
              elem['values']['bFrom'], elem['values']['bTo'], "", "");
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
      List<dynamic> jsonData = jsonDecode(data);
      return jsonData[0]['editable'] == 'true';
    }
  }

  Future<Null> persistMonthShifts(DateTime dateTime, List<Shift> shifts,
      bool editable, double totalHours) async {
    await _createInstance();

    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    if (data == null || data.isEmpty) {
      data = '';
    } else if (!await monthIsEditable(dateTime)) {
      return null;
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
      List<dynamic> jsonData = jsonDecode(data);
      jsonData[0]['days'].forEach((elem) {
        shifts.add(Shift(
            elem['day'],
            elem['values']['wFrom'],
            elem['values']['wTo'],
            elem['values']['bFrom'],
            elem['values']['bTo'],
            elem['values']['place'],
            elem['values']['comment'],
            elem['values']['hours'],
            elem['values']['weekday']));
      });
    }
    return shifts;
  }

  Future<double> getTotalHoursInMonth(DateTime dateTime) async {
    await _createInstance();
    String data = _prefs.getString('${dateTime.year}-${dateTime.month}');
    double result = 0.0;
    if (data != null && data.isNotEmpty) {
      List<dynamic> jsonData = jsonDecode(data);
      result = double.parse(jsonData[0]['totalHours']);
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

  Future<Null> deleteAll() async {
    await _createInstance();
    await _prefs.clear();
  }
}
