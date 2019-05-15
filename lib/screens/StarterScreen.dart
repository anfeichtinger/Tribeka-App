import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

/// This Screen decides which Screen to start with based on the auto-login value
class StarterScreen extends StatefulWidget {
  @override
  State createState() => StarterScreenState();
}

class StarterScreenState extends State<StarterScreen> {
  final _storage = FlutterSecureStorage();
  bool _autoLogin;

  Future<Null> _tryAutoLogin() async {
    _autoLogin = await _storage.read(key: 'autologin') == '1';
    if (_autoLogin) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/Month', (Route<dynamic> route) => false);
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/Login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'de_DE';

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));

    _tryAutoLogin();
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
