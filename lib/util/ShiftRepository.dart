import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/widgets/CustomSelectableTags.dart';

class TagHandler {
  SharedPreferences _prefs;

  Future<Null> _createInstance() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  TagHandler() {}

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

  clearTags() async {
    await _createInstance();
    _prefs.setString("templates", "");
  }

  Future<Shift> getPersistedShift(String title) async {
    await _createInstance();
    Shift shift;
    String data = _prefs.getString("templates");
    if (data != null && data.isNotEmpty) {
      List<dynamic> decData = jsonDecode(data);
      decData.forEach((elem) {
        if (elem['title'] == title) {
          shift = Shift("1", elem['values']['wFrom'], elem['values']['wTo'],
              elem['values']['bFrom'], elem['values']['bTo'], "tu", "");
        }
      });
    }
    return shift;
  }
}
