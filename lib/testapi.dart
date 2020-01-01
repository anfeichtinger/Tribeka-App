/// Here lies the main functionality of the server.
/// It is written in this fashion so that it can be run on either a computer, or a mobile device running flutter.

library testapi;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

export 'dart:async';
export 'dart:io';
export 'package:aqueduct/aqueduct.dart';
export 'channel.dart';

Dio _dio;
String baseURL;
Response _response;

Future<Null> _get(String url) async {
  _response = await _dio.get(url);
}

Future<Null> _post(String url, Map<String, String> data) async {
  _response = await _dio.post(url, data: data);
}

double _hoursAsDouble(String hour) {
  final List<String> split = hour.split(',');
  final int main = int.parse(split[0]);
  final int comma = int.parse(split[1]);

  return double.parse('$main.$comma');
}

String _getFullWeekday(String shortWeekday) {
  switch (shortWeekday) {
    case 'mo':
      return 'Montag';
    case 'di':
      return 'Dienstag';
    case 'mi':
      return 'Mittwoch';
    case 'do':
      return 'Donnerstag';
    case 'fr':
      return 'Freitag';
    case 'sa':
      return 'Samstag';
    default:
      return 'Sonntag';
  }
}

String scrapShiftsFromMonth(Response _response) {
  double hoursInMonth = 0;
  final shiftBuffer = StringBuffer();

  final Document doc = parse(_response.data, encoding: 'utf8');
  final Element tableBody = doc.getElementsByTagName("tbody").first;
  final List<Element> tableRows = tableBody.getElementsByTagName("tr");

  for (int i = 0; i < tableRows.length; i++) {
    if (tableRows.elementAt(i).children.first.id == 'add_row') {
      break;
    }

    final _fullDay =
        tableRows.elementAt(i).getElementsByTagName("td").elementAt(0).text;
    final _weekday = _getFullWeekday(_fullDay.substring(0, 2).trim());
    final _day =
        _fullDay.substring(_fullDay.length - 3, _fullDay.length - 1).trim();
    final _workFrom = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(1)
        .text
        .trim();
    final _workTo = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(2)
        .text
        .trim();
    final _breakFrom = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(3)
        .text
        .trim();
    final _breakTo = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(4)
        .text
        .trim();
    final _place = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(5)
        .text
        .trim();
    final _comment = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(6)
        .text
        .trim();
    final _hours = tableRows
        .elementAt(i)
        .getElementsByTagName("td")
        .elementAt(7)
        .text
        .trim();

    hoursInMonth += _hoursAsDouble(_hours);

    shiftBuffer.write('''"$_day": {
          "weekday": "$_weekday", 
          "work-from": "$_workFrom", 
          "work-to": "$_workTo", 
          "break-from": "$_breakFrom", 
          "break-to": "$_breakTo", 
          "place": "$_place", 
          "comment": "$_comment", 
          "hours": "${_hours}"
        },
        ''');
  }
  final temp = shiftBuffer.toString();
  shiftBuffer.clear();
  shiftBuffer.write('''
  {
  "total-hours": "$hoursInMonth", 
  "shifts": {
  ''');
  shiftBuffer.write(temp.substring(0, temp.lastIndexOf("}") + 1));
  shiftBuffer.write("}}");

  // For correct formatting and spacing
  final Map<String, dynamic> shifts =
      jsonDecode(shiftBuffer.toString()) as Map<String, dynamic>;

  return jsonEncode(shifts);
}

Future<String> _doFetch(String _email, String _password) async {
  try {
    await _post("${baseURL}login/",
        {"pEmail": _email, "pPassword": _password, "submit": "jetzt anmelden"});
  } on DioError catch (e) {
    // Correct Credentials, Redirecting
    if (e.response.statusCode == 302) {
      try {
        // Load Next Step
        await _get("${baseURL}stunden/");
        if (_response.statusCode == 200) {
          // Enter October 2019
          await _post("${baseURL}stunden/Default.asp", {
            "pEmpId": "1236",
            "pMonth": "10",
            "pYear": "2019",
            "submit": "jetzt zeigen"
          });
          return scrapShiftsFromMonth(_response);
        } else {
          return "error";
        }
      } on DioError {
        return "error";
      }
    } else {
      return "error";
    }
  }
  return "error";
}

Future<String> fetch() async {
  _dio = Dio();
  _dio.options.contentType = ContentType.parse(
      "application/x-www-form-urlencoded; charset=ISO-8859-1");
  _dio.options.responseType = ResponseType.plain;
  _dio.interceptors.add(CookieManager(CookieJar()));

  baseURL = "http://intra.tribeka.at/";

  // TODO: Add Credentials here
  final result = await _doFetch("email", "password");

  return result;
}
