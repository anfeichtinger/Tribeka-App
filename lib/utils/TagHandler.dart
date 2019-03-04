import 'dart:convert';

import 'package:flutter_tags/selectable_tags.dart';
import 'package:tribeka/utils/Globals.dart' as globals;
import 'package:tribeka/utils/Shift.dart';

class TagHandler {
  Future<List<Tag>> getTags() async {
    List<Tag> list = [];

    String data = await globals.storage.read(key: "templates");
    if (data != null && data.isNotEmpty) {
      final List<dynamic> jsonResult = json.decode(data);
      jsonResult.forEach((value) {
        list.add(Tag(title: value['title']));
      });
    }
    return list;
  }

  Future<List<Tag>> deletePersistedTag(String title) async {
    String data = await globals.storage.read(key: "templates");
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
      globals.storage.write(key: "templates", value: data);
    }
    return await getTags();
  }

  Future<List<Tag>> persistTag(Shift shift) async {
    String data = await globals.storage.read(key: "templates");
    if (data == null || data.isEmpty) {
      data = '[';
    } else {
      data = data.substring(0, data.length - 1);
      data += ', ';
    }

    data +=
        '{"title": "${shift.comment}","values": {"wFrom": "${shift.workFrom}","wTo": "${shift.workTo}","bFrom": "${shift.breakFrom}","bTo": "${shift.breakTo}"}}]';

    globals.storage.write(key: "templates", value: data);
    return await getTags();
  }

  clearTags() async {
    globals.storage.write(key: "templates", value: "");
  }

  Future<Shift> getPersistedShift(String title) async {
    Shift shift;
    String data = await globals.storage.read(key: "templates");
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
