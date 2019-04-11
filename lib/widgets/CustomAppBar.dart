import 'package:flutter/material.dart';

class CustomAppBar {
  static final dark = AppBar(
    automaticallyImplyLeading: false,
    brightness: Brightness.dark,
    backgroundColor: Colors.grey[850],
    centerTitle: true,
    title: Text(
      "tribeka",
      style:
          TextStyle(fontFamily: 'Tribeka', fontSize: 30.0, color: Colors.white),
    ),
  );

  static final gone = PreferredSize(
      child: AppBar(
        brightness: Brightness.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      preferredSize: Size.fromHeight(0));
}
