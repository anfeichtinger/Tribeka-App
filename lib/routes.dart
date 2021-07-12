import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'screens/index.dart';

class Routes {
  final routes = <String, WidgetBuilder>{
    '/': (BuildContext context) => StarterScreen(),
    '/Login': (BuildContext context) => LoginScreen(),
    '/Month': (BuildContext context) => MonthScreen(),
  };

  final theme = ThemeData(
      primarySwatch: const MaterialColor(
    0xFF333333,
    <int, Color>{
      50: Color(0xFFAAAAAA),
      100: Color(0xFF888888),
      200: Color(0xFF777777),
      300: Color(0xFF666666),
      400: Color(0xFF555555),
      500: Color(0xFF444444),
      600: Color(0xFF333333),
      700: Color(0xFF222222),
      800: Color(0xFF111111),
      900: Color(0xFF000000),
    },
  ));

  Routes() {
    runApp(MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: routes,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child),
    ));
  }
}
