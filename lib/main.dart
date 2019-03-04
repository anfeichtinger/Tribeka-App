import 'package:flutter/material.dart';
import 'package:tribeka/screens/LoginScreen.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: MaterialColor(
        0xFF333333,
        const <int, Color>{
          50: const Color(0xFF999999),
          100: const Color(0xFF777777),
          200: const Color(0xFF666666),
          300: const Color(0xFF555555),
          400: const Color(0xFF444444),
          500: const Color(0xFF333333),
          600: const Color(0xFF222222),
          700: const Color(0xFF111111),
          800: const Color(0xFF000000),
          900: const Color(0xFF000000),
        },
      )),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child),
    );
  }
}