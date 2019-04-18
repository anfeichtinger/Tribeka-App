import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tribeka/services/Scraper.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Latin1Transformer.dart';
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/util/ShiftRepository.dart';

// Implementing the Singelton Pattern
class Session {
  static final Session _instance = Session.internal();

  factory Session() {
    return _instance;
  }

  // Basic functionality
  static Dio _dio;
  static Response _response;

  Session.internal() {
    _dio = Dio();
    _dio.options.contentType = ContentType.parse(
        "application/x-www-form-urlencoded; charset=ISO-8859-1");
    _dio.options.responseType = ResponseType.plain;
    _dio.interceptors.add(CookieManager(CookieJar()));
    _dio.transformer = Latin1Transformer();
    // For debugging only
    // _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<Null> _get(String url) async {
    _response = await _dio.get(url);
  }

  Future<Null> _post(String url, Map<String, String> data) async {
    _response = await _dio.post(url, data: data);
  }

  // Tribeka specific functionality
  final baseURL = "http://intra.tribeka.at/";
  final _storage = FlutterSecureStorage();
  final _scrapper = Scrapper();
  int lastAvailYear;

  // Post-Redirect-Get Pattern
  Future<bool> login(String _email, String _password, bool _saveLogin) async {
    try {
      await _post(baseURL + "login/", {
        "pEmail": _email,
        "pPassword": _password,
        "submit": "jetzt anmelden"
      });
    } on DioError catch (e) {
      if (e.response.statusCode == 302) {
        try {
          await _get(baseURL + 'stunden/');
          if (_response.statusCode == 200) {
            if (_saveLogin) {
              _storage.write(key: 'autologin', value: '1');
            }
            _storage.write(key: 'email', value: _email);
            _storage.write(key: 'password', value: _password);
            _scrapper.generateUserId(_response);
            return true;
          } else {
            return false;
          }
        } on DioError {
          return false;
        }
      } else {
        return false;
      }
    }
    return false;
  }

  Future<Null> autoLogin(BuildContext _context) async {
    final _email = await _storage.read(key: 'email');
    final _password = await _storage.read(key: 'password');
    try {
      await _post(baseURL + "login/", {
        "pEmail": _email,
        "pPassword": _password,
        "submit": "jetzt anmelden"
      });
    } on DioError catch (e) {
      if (e.response.statusCode == 302) {
        try {
          await _get(baseURL + 'stunden/');
        } on DioError {}
        if (_response.statusCode == 200) {
          _scrapper.generateUserId(_response);
        } else {
          logout();
          Navigator.of(_context).pushNamedAndRemoveUntil(
              '/Login', (Route<dynamic> route) => false);
        }
      } else {
        logout();
        Navigator.of(_context)
            .pushNamedAndRemoveUntil('/Login', (Route<dynamic> route) => false);
      }
    }
  }

  // When there is a Session Timeout, automatically login and go into correct month again
  Future<Null> _loginOnExpiration() async {
    final _email = await _storage.read(key: 'email');
    final _password = await _storage.read(key: 'password');
    try {
      await _post(baseURL + "login/", {
        "pEmail": _email,
        "pPassword": _password,
        "submit": "jetzt anmelden"
      });
    } on DioError catch (e) {
      if (e.response.statusCode == 302) {
        try {
          await _get(baseURL + 'stunden/');
        } on DioError {}
        if (_response.statusCode == 200) {
          _scrapper.generateUserId(_response);
          //success
        }
      }
    }
  }

  Future<Null> _enterMonth(DateTime selectedTime) async {
    try {
      return await _post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pMonth": selectedTime.month.toString(),
        "pYear": selectedTime.year.toString(),
        "submit": "jetzt zeigen"
      });
    } on DioError {
      await _loginOnExpiration();
      return await _enterMonth(selectedTime);
    }
  }

  // You have to be inside a month to do that
  bool isMonthEditable() {
    return _scrapper.isMonthEditable(_response);
  }

  Future<List<Shift>> scrapShiftsFromMonth(DateTime selectedTime) async {
    await _enterMonth(selectedTime);
    List<Shift> _shifts = _scrapper.scrapShiftsFromMonth(_response);
    return _shifts;
  }

  double getTotalHoursInMonth() {
    return Scrapper.hoursInMonth;
  }

  void logout() async {
    await _get(baseURL);
    ShiftRepository().clearAppData();
    debugPrint('DEBUG - Logged out');
  }

  Future<Null> sendShift(DateTime selectedTime, Shift shift) async {
    try {
      return await _post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pYear": selectedTime.year.toString(),
        "pMonth": selectedTime.month.toString(),
        "pWorkDay": shift.day,
        "pWorkFrom": shift.workFrom,
        "pWorkTo": shift.workTo,
        "pWorkBreakFrom": shift.breakFrom == "-" ? "" : shift.breakFrom,
        "pWorkBreakTo": shift.breakTo == "-" ? "" : shift.breakTo,
        "pWorkBranch": globals.user.place,
        "pWorkRemark": shift.comment,
        "submit": "speichern"
      });
    } on DioError {
      await _loginOnExpiration();
      return await sendShift(selectedTime, shift);
    }
  }

  Future<Null> finishMonth(DateTime selectedTime) async {
    try {
      return await _post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pYear": selectedTime.year.toString(),
        "pMonth": selectedTime.month.toString(),
        "submit": "monat jetzt fertigstellen"
      });
    } on DioError {
      await _loginOnExpiration();
      return await finishMonth(selectedTime);
    }
  }

  Future<Null> removeShift(DateTime selectedTime, Shift shift) async {
    String _deleteValue;
    try {
      await _enterMonth(selectedTime).whenComplete(() {
        _deleteValue = _scrapper.getDeleteValue(shift, _response);
        _post(baseURL + 'stunden/' + 'Default.asp', {
          "$_deleteValue": 'l%F6schen',
          "pEmpId": globals.user.id,
          "pYear": selectedTime.year.toString(),
          "pMonth": selectedTime.month.toString(),
        });
      });
    } on DioError {
      await _loginOnExpiration();
      return await removeShift(selectedTime, shift);
    }
  }

  Future<Null> updateShift(DateTime selectedTime, Shift shift) async {
    await removeShift(selectedTime, shift);
    await sendShift(selectedTime, shift);
  }

  Future<Null> callInSick(DateTime selectedTime, int from, int to) async {
    try {
      return await _post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pYear": selectedTime.year.toString(),
        "pMonth": selectedTime.month.toString(),
        "pIllFrom": from.toString(),
        "pIllTo": to.toString(),
        "submit": "krankmeldung speichern"
      });
    } on DioError {
      await _loginOnExpiration();
      return await callInSick(selectedTime, from, to);
    }
  }
}
