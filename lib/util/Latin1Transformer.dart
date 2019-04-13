import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

// Overrides some Functions of the Dio DefaultTransformer in order to
// use Latin1 encoding instead of utf-8.
// The server only handles ö,ä,ü correctly with latin1.
class Latin1Transformer extends DefaultTransformer {
  // Added encoding to all Uri.encodeQueryComponent() calls.
  static String urlEncodeMap(data) {
    StringBuffer urlData = new StringBuffer("");
    bool first = true;
    void urlEncode(dynamic sub, String path) {
      if (sub is List) {
        for (int i = 0; i < sub.length; i++) {
          urlEncode(sub[i],
              "$path%5B${(sub[i] is Map || sub[i] is List) ? i : ''}%5D");
        }
      } else if (sub is Map) {
        sub.forEach((k, v) {
          if (path == "") {
            urlEncode(v,
                "${Uri.encodeQueryComponent(k, encoding: Encoding.getByName('latin1'))}");
          } else {
            urlEncode(v,
                "$path%5B${Uri.encodeQueryComponent(k, encoding: Encoding.getByName('latin1'))}%5D");
          }
        });
      } else {
        if (!first) {
          urlData.write("&");
        }
        first = false;
        urlData.write(
            "$path=${Uri.encodeQueryComponent(sub.toString(), encoding: Encoding.getByName('latin1'))}");
      }
    }

    urlEncode(data, "");
    return urlData.toString();
  }

  @override
  Future<String> transformRequest(RequestOptions options) async {
    var data = options.data ?? "";
    if (data is! String) {
      if (options.contentType.mimeType == ContentType.json.mimeType) {
        return json.encode(options.data);
      } else if (data is Map) {
        // Was Transformer.urlEncodeMap(data);
        return urlEncodeMap(data);
      }
    }
    return data.toString();
  }
}
