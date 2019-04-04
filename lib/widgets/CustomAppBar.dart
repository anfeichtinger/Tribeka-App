import 'package:flutter/material.dart';

class CustomAppBar {
  static final get = AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.grey[850],
    centerTitle: true,
    title: Text(
      "tribeka",
      style:
          TextStyle(fontFamily: 'Tribeka', fontSize: 30.0, color: Colors.white),
    ),
  );
}
