import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/widgets/CustomSelectableTags.dart';

class TagHandler {
  final _storage = FlutterSecureStorage();
  
  Future<List<Tag>> getTags() async {
    List<Tag> list = [];

    String data = await _storage.read(key: "templates");
    if (data != null && data.isNotEmpty) {
      final List<dynamic> jsonResult = json.decode(data);
      jsonResult.forEach((value) {
        list.add(Tag(title: value['title']));
      });
    }
    return list;
  }

  Future<List<Tag>> deletePersistedTag(String title) async {
    String data = await _storage.read(key: "templates");
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
      _storage.write(key: "templates", value: data);
    }
    return await getTags();
  }

  Future<List<Tag>> persistTag(Shift shift, String title) async {
    String data = await _storage.read(key: "templates");
    if (data == null || data.isEmpty) {
      data = '[';
    } else {
      data = data.substring(0, data.length - 1);
      data += ', ';
    }

    data +=
    '{"title": "$title","values": {"wFrom": "${shift.workFrom}","wTo": "${shift.workTo}","bFrom": "${shift.breakFrom}","bTo": "${shift.breakTo}"}}]';

    _storage.write(key: "templates", value: data);
    return await getTags();
  }

  clearTags() async {
    _storage.write(key: "templates", value: "");
  }

  Future<Shift> getPersistedShift(String title) async {
    Shift shift;
    String data = await _storage.read(key: "templates");
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
