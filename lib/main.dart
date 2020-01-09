import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tribeka_app/fetcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Scraping Prototype',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF333333,
          <int, Color>{
            50: Color(0xFFFAFAFA),
            100: Color(0xFFF5F5F5),
            200: Color(0xFFEEEEEE),
            300: Color(0xFFE0E0E0),
            350: Color(0xFFD6D6D6),
            // only for raised button while pressed in light theme
            400: Color(0xFFBDBDBD),
            500: Color(0xFF333333),
            600: Color(0xFF757575),
            700: Color(0xFF616161),
            800: Color(0xFF424242),
            850: Color(0xFF303030),
            // only for background color in dark theme
            900: Color(0xFF212121),
          },
        ),
      ),
      home: MyHomePage(title: 'Web Scraping Prototype'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Duration _fetchTime = Duration();
  Map<String, dynamic> _result = HashMap();
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Time to fetch:',
            ),
            _showError
                ? Text('Error', style: TextStyle(color: Colors.red))
                : Text(
                    _fetchTime.toString(),
                    style: Theme.of(context).textTheme.display1,
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Fetcher fetcher = Fetcher();
          Stopwatch stopwatch = Stopwatch();
          stopwatch.start();
          _result = jsonDecode(await fetcher.fetch());
          if (_result.isEmpty) {
            // Error
            setState(() {
              _showError = true;
            });
          } else {
            // Success
            stopwatch.stop();
            setState(() {
              _fetchTime = stopwatch.elapsed;
            });
            debugPrint(_result.toString(), wrapWidth: 1024);
          }
        },
        tooltip: 'Fetch Data',
        child: Icon(
          Icons.cloud_download,
          color: Colors.white,
        ),
      ),
    );
  }
}
