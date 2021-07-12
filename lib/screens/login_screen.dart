import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:tribeka/services/session.dart';
import 'package:tribeka/services/validator.dart';
import 'package:tribeka/util/globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  @override
  State createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  bool _hasError = false;
  bool _connected = false;
  bool _loading = false;
  bool _autovalidateEmail = false;
  bool _autovalidatePw = false;
  bool _autoLoginChecked = true;

  final Session _session = globals.session;
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

  void login() async {
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
    final _emailFocus = FocusNode();
    final _pwFocus = FocusNode();

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
      duration: const Duration(milliseconds: 300),
      child: const Text(
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
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
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
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
        ),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (v) {
          _pwFocus.unfocus();
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          if (_connected) {
            if (validForm()) {
              setState(() {
                _loading = true;
              });
              login();
            }
          }
        });

    final _autoLogin = InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(32)),
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
            const Text('Angemeldet bleiben')
          ],
        ));

    Widget _getLoginButton() {
      return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          child: SizedBox(
              width: _loading ? 70 : double.infinity,
              height: 50,
              child: SizedBox.expand(
                child: RawMaterialButton(
                    shape: _loading
                        ? const CircleBorder()
                        : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                    elevation: 0.0,
                    fillColor: _connected ? Colors.grey[850] : Colors.grey[600],
                    child: _loading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))
                        : const Text('Anmelden',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                    onPressed: _connected
                        ? () {
                            if (validForm()) {
                              setState(() {
                                _loading = true;
                              });
                              login();
                            }
                          }
                        : null),
              )));
    }

    _getBody() {
      return ListView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        children: <Widget>[
          const SizedBox(height: 92.0),
          _logo,
          const SizedBox(height: 52.0),
          _errorText,
          const SizedBox(height: 12.0),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                _email,
                const SizedBox(height: 16.0),
                _password,
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          _autoLogin,
          const SizedBox(height: 16.0),
          _getLoginButton(),
          const SizedBox(height: 92.0),
        ],
      );
    }

    return Scaffold(
        backgroundColor: Colors.white,
        body: OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child,
            ) {
              _connected = connectivity != ConnectivityResult.none;
              return Stack(
                alignment: Alignment.bottomCenter,
                fit: StackFit.expand,
                children: [
                  _getBody(),
                  _connected
                      ? const SizedBox(height: 0)
                      : Positioned(
                          height: 32.0,
                          left: 0.0,
                          right: 0.0,
                          child: Container(
                              color: const Color(0xFFEE4400),
                              child: const Center(
                                  child: Text('Keine Internetverbindung',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white)))),
                        ),
                ],
              );
            },
            child: const Text('')));
  }
}
