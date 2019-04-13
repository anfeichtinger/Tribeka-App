import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tribeka/services/Session.dart';
import 'package:tribeka/services/Validator.dart';
import 'package:tribeka/util/Globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  @override
  State createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  bool _hasError = false;
  bool _loading = false;
  bool _autovalidateEmail = false;
  bool _autovalidatePw = false;
  bool _autoLoginChecked = true;

  Session _session = globals.session;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  void _setStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
        .copyWith(statusBarIconBrightness: Brightness.dark));
  }

  @override
  void initState() {
    _setStatusBar();
    super.initState();
  }

  login() async {
    bool success = await _session.login(
        _emailController.text, _pwController.text, _autoLoginChecked);
    if (success) {
      setState(() {
        _hasError = false;
        _loading = false;
      });
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/Month', (Route<dynamic> route) => false);
    } else {
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  bool validForm() {
    final form = _formKey.currentState;
    setState(() {
      _autovalidateEmail = true;
      _autovalidatePw = true;
    });
    return form.validate();
  }

  @override
  Widget build(BuildContext context) {
    final page = ModalRoute.of(context);
    page.didPush().then((x) {
      _setStatusBar();
    });
    final _emailFocus = new FocusNode();
    final _pwFocus = new FocusNode();

    final _logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 48.0,
        child: Image.asset('assets/logo.png'),
      ),
    );

    // Will fade in the error Text if _hasError is set to true
    final _errorText = AnimatedOpacity(
      opacity: _hasError ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Text(
        'Die Email oder das Passwort ist falsch!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
    );

    final _email = TextFormField(
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        autovalidate: _autovalidateEmail,
        focusNode: _emailFocus,
        controller: _emailController,
        validator: (value) => Validator.validateEmail(value),
        decoration: InputDecoration(
          hintText: 'E-Mail',
          contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
        ),
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (v) {
          _emailFocus.unfocus();
          FocusScope.of(context).requestFocus(_pwFocus);
        });

    final _password = TextFormField(
        autofocus: false,
        autovalidate: _autovalidatePw,
        obscureText: true,
        focusNode: _pwFocus,
        controller: _pwController,
        validator: (value) => Validator.validatePassword(value),
        decoration: InputDecoration(
          hintText: 'Passwort',
          contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
        ),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (v) {
          _pwFocus.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          if (validForm()) {
            setState(() {
              _loading = true;
            });
            login();
          }
        });

    final _autoLogin = InkWell(
        borderRadius: BorderRadius.all(Radius.circular(32)),
        onTap: () {
          setState(() {
            _autoLoginChecked = !_autoLoginChecked;
          });
        },
        child: Row(
          children: <Widget>[
            Checkbox(
                value: _autoLoginChecked,
                onChanged: (bool value) {
                  setState(() {
                    _autoLoginChecked = !_autoLoginChecked;
                  });
                }),
            Text('Angemeldet bleiben')
          ],
        ));

    final _loginButton = AnimatedContainer(
        duration: Duration(milliseconds: 250),
        child: Container(
            width: _loading ? 70 : double.infinity,
            height: 50,
            child: SizedBox.expand(
              child: RawMaterialButton(
                  shape: _loading
                      ? CircleBorder()
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                  elevation: 0.0,
                  fillColor: Colors.grey[850],
                  child: _loading
                      ? CircularProgressIndicator(
                          valueColor:
                              new AlwaysStoppedAnimation<Color>(Colors.white))
                      : Text('Anmelden',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (validForm()) {
                      setState(() {
                        _loading = true;
                      });
                      login();
                    }
                  }),
            )));

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 32.0),
        children: <Widget>[
          SizedBox(height: 92.0),
          _logo,
          SizedBox(height: 52.0),
          _errorText,
          SizedBox(height: 12.0),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                _email,
                SizedBox(height: 16.0),
                _password,
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _autoLogin,
          SizedBox(height: 16.0),
          _loginButton,
          SizedBox(height: 92.0),
        ],
      ),
    );
  }
}
