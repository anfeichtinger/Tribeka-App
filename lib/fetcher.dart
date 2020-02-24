import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

export 'dart:async';
export 'dart:io';

class Fetcher {
  Dio _dio;
  String baseURL;

  Future<String> fetch() async {
    _dio = Dio();
    _dio.options.contentType = ContentType.parse(
        "application/x-www-form-urlencoded; charset=ISO-8859-1");
    _dio.options.responseType = ResponseType.plain;
    _dio.interceptors.add(CookieManager(CookieJar()));

    baseURL = "http://tribeka.sytes.net";
    String _result = jsonDecode((await _dio.get(baseURL)).toString());
    return _result;
  }
}
