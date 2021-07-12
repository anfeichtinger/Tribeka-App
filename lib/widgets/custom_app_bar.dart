import 'package:flutter/material.dart';

class CustomAppBar {
  // Reliable Way to color status bar icons grey
  static final gone = PreferredSize(
      child: AppBar(
        brightness: Brightness.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      preferredSize: Size.fromHeight(0));
}
