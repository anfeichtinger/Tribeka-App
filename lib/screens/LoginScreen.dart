import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tribeka/screens/monthScreen.dart';
import 'package:tribeka/utils/Globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  @override
  State createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';
  String _status = '';
  FocusNode _emailFocus = FocusNode();
  FocusNode _passwordFocus = FocusNode();
  final _emailInputController = TextEditingController();
  final _passwordInputController = TextEditingController();
  String storageEmail;
  String storagePassword;

  @override
  void initState() {
    super.initState();
    _fetchStorageData();
  }

  _fetchStorageData() async {
    debugPrint("Fetching stored email and password");
    try {
      storageEmail = await globals.storage.read(key: "email");
      storagePassword = await globals.storage.read(key: "password");
      globals.autoLogin =
          await globals.storage.read(key: "autoLogin") == "true";
      if (storageEmail == null ||
          storagePassword == null ||
          globals.autoLogin == null) {
        debugPrint("Keystore was null, setting empty value...");
        globals.storage.write(key: "email", value: "");
        globals.storage.write(key: "password", value: "");
        globals.storage.write(key: "autoLogin", value: "");
        storageEmail = "";
        storagePassword = "";
        globals.autoLogin = false;
      }
    } catch (err) {
      debugPrint("Keystore was null, setting empty value...");
      globals.storage.write(key: "email", value: "");
      globals.storage.write(key: "password", value: "");
      globals.storage.write(key: "autoLogin", value: "");
      storageEmail = "";
      storagePassword = "";
      globals.autoLogin = false;
    }

    if (globals.autoLogin) {
      if (storageEmail.isNotEmpty && storagePassword.isNotEmpty) {
        _emailInputController.text = storageEmail;
        _passwordInputController.text = storagePassword;
        _onLogin();
      }
    }
  }

  _onLogin() async {
    setState(() {
      _email = Text(_emailInputController.text).data;
      _password = Text(_passwordInputController.text).data;
    });
    if (validateEmail(_email) != null) {
      FocusScope.of(context).requestFocus(_emailFocus);
    } else {
      if (_passwordInputController.text.isNotEmpty) {
        setState(() {
          _status = "Verbindet...";
        });
        http.Response response = await globals.session.post(
            globals.baseURL + globals.loginURL, {
          "pEmail": _email,
          "pPassword": _password,
          "submit": "jetzt anmelden"
        });
        debugPrint(globals.session.url);
        setState(() {
          _status = "Korrektes Passwort, weiterleitung";
        });
        if (response.statusCode == 302) {
          debugPrint("Authentication success...");
          response = await globals.session
              .get("http://intra.tribeka.at/" + "stunden/");
          debugPrint(globals.session.url);
          if (response.statusCode == 200) {
            debugPrint("Login Response Code: ${response.statusCode}");
            debugPrint("You are logged in.");

            if (storageEmail == "" ||
                storagePassword == "" ||
                storageEmail != _email ||
                storagePassword != _password) {
              await globals.storage.write(key: "email", value: _email);
              await globals.storage.write(key: "password", value: _password);
              debugPrint("Saved Email and Password");
            }
            setState(() {
              _status = "Du bist Angemeldet!";
            });
            globals.autoLogin = true;
            await globals.storage.write(key: "autoLogin", value: "true");
            await globals.session.startPing();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MonthScreen()),
            );
          } else {
            debugPrint("Login Response Code: ${response.statusCode}");
            debugPrint(
                "Login Error Message: ${globals.session.getErrorMessage()}");
            setState(() {
              _status = "Fehler bei der Weiterleitung!";
            });
          }
        } else {
          debugPrint("Login Response Code: ${response.statusCode}");
          debugPrint(
              "Login Error Message: ${globals.session.getErrorMessage()}");
          setState(() {
            _status = "Email / Passwort stimmen nicht überein!";
          });
        }
      } else {
        FocusScope.of(context).requestFocus(_passwordFocus);
      }
    }
  }

  String validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(_emailInputController.text)) {
      setState(() {
        _status = "Ungültige Email-Addresse";
      });
      return "Ungültige Email-Addresse";
    } else
      setState(() {
        _status = "";
      });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
        behavior: MyBehavior(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
              child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(
                left: 24.0, right: 24.0, top: 12.0, bottom: 12.0),
            children: <Widget>[
              Hero(
                tag: 'hero',
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 36.0,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
              SizedBox(height: 30.0),
              Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: new Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Email',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                ),
                keyboardType: TextInputType.emailAddress,
                controller: _emailInputController,
                focusNode: _emailFocus,
                validator: validateEmail,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(_passwordFocus);
                },
                onSaved: (String val) {
                  _email = val;
                },
              ),
              SizedBox(height: 24.0),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Passwort',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                ),
                obscureText: true,
                keyboardType: TextInputType.text,
                controller: _passwordInputController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (v) {
                  _onLogin();
                },
                onSaved: (String val) {
                  _password = '';
                },
                focusNode: _passwordFocus,
              ),
              SizedBox(height: 22.0),
              ButtonTheme(
                height: 48.0,
                child: RaisedButton(
                  onPressed: _onLogin,
                  child: Text(
                    'Anmelden',
                    style: TextStyle(color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  color: const Color(0xFF333333),
                ),
              )
            ],
          )),
        ));
  }
}
