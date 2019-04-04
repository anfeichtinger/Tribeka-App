// Implementing the Singelton Pattern
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tribeka/services/Scraper.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Shift.dart';

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
    _dio.options.contentType =
        ContentType.parse("application/x-www-form-urlencoded; charset=utf-8");
    _dio.options.responseType = ResponseType.plain;
    _dio.interceptors.add(CookieManager(CookieJar()));
    //_dio.interceptors.add(LogInterceptor(responseBody: false));
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

  Future<Null> _loginOnExpiration(int month, int year) async {
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
          //success
        } else {}
      } else {}
    }
  }

  void _searchUserPlace(int _month, int _year) {
    if (globals.user.place == null || globals.user.place.isEmpty) {
      if (!_scrapper.generateUserPlace(_response)) {
        int _newMonth = _month - 1;
        if (_newMonth > 0) {
          _enterMonth(_newMonth, _year).then((v) {
            _scrapper.generateUserPlace(_response);
          });
        } else {
          _enterMonth(12, _year).then((v) {
            _scrapper.generateUserPlace(_response);
          }).then((v) {
            _enterMonth(_month, _year);
          });
        }
      }
    }
  }

  Future<Null> _enterMonth(int month, int year) async {
    try {
      return await _post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pMonth": month.toString(),
        "pYear": year.toString(),
        "submit": "jetzt zeigen"
      });
    } on DioError {
      await _loginOnExpiration(month, year);
      return await _enterMonth(month, year);
    }
  }

  bool isMonthEditable() {
    return _scrapper.isMonthEditable(_response);
  }

  Future<List<Shift>> scrapShiftsFromMonth(int month, int year) async {
    await _enterMonth(month, year);
    List<Shift> _shifts = _scrapper.scrapShiftsFromMonth(_response);
    _searchUserPlace(month, year);
    return _shifts;
  }

  double getHoursInMonth() {
    return Scrapper.hoursInMonth;
  }

  void logout() async {
    _storage.write(key: 'autologin', value: '0');
    _storage.write(key: 'email', value: '');
    _storage.write(key: 'password', value: '');
    debugPrint('DEBUG - Logged out');
  }

  Future<Null> sendShift(int month, int year, Shift shift) async {
    try {
      return await globals.session._post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pYear": year.toString(),
        "pMonth": month.toString(),
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
      await _loginOnExpiration(month, year);
      return await sendShift(month, year, shift);
    }
  }

  Future<Null> finishMonth(int month, int year) async {
    try {
      return await globals.session._post(baseURL + 'stunden/' + 'Default.asp', {
        "pEmpId": globals.user.id,
        "pYear": year.toString(),
        "pMonth": month.toString(),
        "submit": "monat jetzt fertigstellen"
      });
    } on DioError {
      await _loginOnExpiration(month, year);
      return await finishMonth(month, year);
    }
  }

  Future<Null> removeShift(DateTime selectedTime, Shift shift) async {
    String _deleteValue;
    try {
      await _enterMonth(selectedTime.month, selectedTime.year).whenComplete(() {
        _deleteValue = _scrapper.getDeleteValue(shift, _response);
        _post(baseURL + 'stunden/' + 'Default.asp', {
          "$_deleteValue": 'l%F6schen',
          "pEmpId": globals.user.id,
          "pYear": selectedTime.year.toString(),
          "pMonth": selectedTime.month.toString(),
        });
      });
    } on DioError {
      await _loginOnExpiration(selectedTime.month, selectedTime.year);
      return await removeShift(selectedTime, shift);
    }
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
      await _loginOnExpiration(selectedTime.month, selectedTime.year);
      return await callInSick(selectedTime, from, to);
    }
  }
/*
  // Basic HTTP Functionality
  Map<String, String> _header = {};
  http.Response _response;
  String url;

  // Todo: check for timeout
  Future<Null> _get(String url) async {
    _response = await http.get(url, headers: _header);
    _updateCookie();
    this.url = url;
  }

  Future<Null> _post(String url, dynamic data) async {
    _response = await http.post(url, body: data, headers: _header);
    _updateCookie();
    this.url = url;
  }

  void _updateCookie() {
    String rawCookie = _response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      _header['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  // Specific Tribeka Functionality
  final baseURL = "http://intra.tribeka.at/";
  final _storage = FlutterSecureStorage();
  final _scrapper = Scrapper();
  int lastAvailYear;

  Future<bool> login(String _email, String _password, bool _saveLogin) async {
    await _post(baseURL + "login/",
        {"pEmail": _email, "pPassword": _password, "submit": "jetzt anmelden"});
    if (_response.statusCode != 302) {
      debugPrint('DEBUG - Wrong email or password!');
      return false;
    } else {
      await _get(baseURL + 'stunden/');
      if (_response.statusCode != 200) {
        debugPrint('DEBUG - Redirect error!');
        return false;
      } else {
        debugPrint('DEBUG - Login succsessful');
        if (_saveLogin) {
          _storage.write(key: 'autologin', value: '1');
        }
        _storage.write(key: 'email', value: _email);
        _storage.write(key: 'password', value: _password);
        _scrapper.generateUserId(_response);
        return true;
      }
    }
  }

  Future<Null> autoLogin(BuildContext _context) async {
    final _email = await _storage.read(key: 'email');
    final _password = await _storage.read(key: 'password');
    await _post(baseURL + "login/",
        {"pEmail": _email, "pPassword": _password, "submit": "jetzt anmelden"});
    if (_response.statusCode != 302) {
      debugPrint('DEBUG - Autologin authentication error');
      logout();
      Navigator.of(_context)
          .pushNamedAndRemoveUntil('/Login', (Route<dynamic> route) => false);
    } else {
      await _get(baseURL + 'stunden/');
      if (_response.statusCode != 200) {
        debugPrint('DEBUG - Autologin redirect error');
        logout();
        Navigator.of(_context)
            .pushNamedAndRemoveUntil('/Login', (Route<dynamic> route) => false);
      } else
        debugPrint('DEBUG - Autologin succsessful');
      _scrapper.generateUserId(_response);
    }
  }

  void _searchUserPlace(int _month, int _year) {
    if (globals.user.place == null || globals.user.place.isEmpty) {
      if (!_scrapper.generateUserPlace(_response)) {
        int _newMonth = _month - 1;
        if (_newMonth > 0) {
          _enterMonth(_newMonth, _year).then((v) {
            _scrapper.generateUserPlace(_response);
          });
        } else {
          _enterMonth(12, _year).then((v) {
            _scrapper.generateUserPlace(_response);
          }).then((v) {
            _enterMonth(_month, _year);
          });
        }
      }
    }
  }

  Future<bool> _enterMonth(int month, int year) async {
    return await _post(baseURL + 'stunden/' + 'Default.asp', {
      "pEmpId": globals.user.id,
      "pMonth": month.toString(),
      "pYear": year.toString(),
      "submit": "jetzt zeigen"
    });
  }

  bool isMonthEditable() {
    return _scrapper.isMonthEditable(_response);
  }

  Future<List<Shift>> scrapShiftsFromMonth(int month, int year) async {
    await _enterMonth(month, year);
    List<Shift> _shifts = _scrapper.scrapShiftsFromMonth(_response);
    _searchUserPlace(month, year);
    return _shifts;
  }

  double getHoursInMonth() {
    return Scrapper.hoursInMonth;
  }

  void logout() async {
    _storage.write(key: 'autologin', value: '0');
    _storage.write(key: 'email', value: '');
    _storage.write(key: 'password', value: '');
    debugPrint('DEBUG - Logged out');
  }

  Future<Null> sendShift(int month, int year, Shift shift) async {
    return await globals.session._post(baseURL + 'stunden/' + 'Default.asp', {
      "pEmpId": globals.user.id,
      "pYear": year.toString(),
      "pMonth": month.toString(),
      "pWorkDay": shift.day,
      "pWorkFrom": shift.workFrom,
      "pWorkTo": shift.workTo,
      "pWorkBreakFrom": shift.breakFrom == "-" ? "" : shift.breakFrom,
      "pWorkBreakTo": shift.breakTo == "-" ? "" : shift.breakTo,
      "pWorkBranch": globals.user.place,
      "pWorkRemark": shift.comment,
      "submit": "speichern"
    });
  }

  Future<Null> finishMonth(int month, int year) async {
    debugPrint('Month: $month, Year: $year');
    /* Todo: Activate when actually wanting to send data
    Todo: Test it!
    await globals.session._post(baseURL + 'stunden/' + 'Default.asp', {
      "pEmpId": globals.user.id,
      "pYear": year,
      "pMonth": month,
      "submit": "monat jetzt fertigstellen"
    });*/
  }

  Future<Null> removeShift(DateTime selectedTime, Shift shift) async {
    String _deleteValue;
    await _enterMonth(selectedTime.month, selectedTime.year).whenComplete(() {
      _deleteValue = _scrapper.getDeleteValue(shift, _response);
      _post(baseURL + 'stunden/' + 'Default.asp', {
        "$_deleteValue": 'l%F6schen',
        "pEmpId": globals.user.id,
        "pYear": selectedTime.year.toString(),
        "pMonth": selectedTime.month.toString(),
      });
    });
  }

  Future<Null> callInSick(DateTime selectedTime, String from, String to) async {
    debugPrint({
      "pEmpId": globals.user.id,
      "pMonth": selectedTime.month.toString(),
      "pYear": selectedTime.year.toString(),
      "pIllFrom": from,
      "pIllTo": to,
      "submit": "krankmeldung speichern"
    }.toString());
    //Todo: Test this implementation!
    /*return await _post(baseURL + 'stunden/' + 'Default.asp', {
      "pEmpId": globals.user.id,
      "pMonth": selectedTime.month.toString(),
      "pYear": selectedTime.year.toString(),
      "pIllFrom": from,
      "pIllTo": to,
      "krankmeldung speichern": "jetzt zeigen"
    });*/
  }*/
}
