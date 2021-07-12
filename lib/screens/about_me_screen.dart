import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:tribeka/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutMeScreen extends StatefulWidget {
  @override
  State createState() => AboutMeScreenState();
}

class AboutMeScreenState extends State<AboutMeScreen> {
  PackageInfo _packageInfo;
  bool _loading = true;
  bool _smallScreen;
  final String _platform = Platform.isAndroid ? 'Android' : 'iOS';
  String _appName;
  String _packageName;
  String _version;
  String _buildNumber;

  void _loadPackageInfo() async {
    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
    _appName = _packageInfo.appName;
    _packageName = _packageInfo.packageName;
    _version = _packageInfo.version;
    _buildNumber = _packageInfo.buildNumber;
    setState(() {
      _loading = false;
    });
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_smallScreen == null) {
      _smallScreen = MediaQuery.of(context).size.width < 380;
    }
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar.gone,
        bottomNavigationBar: BottomAppBar(
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
              IconButton(
                icon: const Icon(MdiIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: "Zurück",
              )
            ])),
        body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: <Widget>[
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Text('Kontakt',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold))),
              Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              CircleAvatar(
                                  child: Image.asset('assets/author.png'),
                                  maxRadius: 52),
                              SizedBox(width: _smallScreen ? 8 : 16),
                              Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    const Text('Andreas Feichtinger',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        children: <Widget>[
                                          Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF222222)),
                                              child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                      onTap: () {
                                                        _launchURL(
                                                            'tel:+436649297454');
                                                      },
                                                      customBorder:
                                                          const CircleBorder(),
                                                      splashColor: Colors.grey,
                                                      child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          child: Icon(
                                                              MdiIcons
                                                                  .phoneOutline,
                                                              color: Colors
                                                                  .white))))),
                                          SizedBox(
                                              width: _smallScreen ? 8 : 16),
                                          Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF222222)),
                                              child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                      onTap: () {
                                                        if (_loading) {
                                                          _launchURL(
                                                              'mailto:anfeichtingers@gmail.com?subject=TribekaApp%20-%20Unknown%20Version%20($_platform)');
                                                        } else {
                                                          _launchURL(
                                                              'mailto:anfeichtingers@gmail.com?subject=TribekaApp%20-%20v$_version%2B$_buildNumber%20($_platform)');
                                                        }
                                                      },
                                                      customBorder:
                                                          const CircleBorder(),
                                                      splashColor: Colors.grey,
                                                      child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          child: Icon(
                                                              MdiIcons
                                                                  .emailOutline,
                                                              color: Colors
                                                                  .white))))),
                                          SizedBox(
                                              width: _smallScreen ? 8 : 16),
                                          Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF222222)),
                                              child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                      onTap: () {
                                                        _launchURL(
                                                            'sms:+436649297454');
                                                      },
                                                      customBorder:
                                                          const CircleBorder(),
                                                      splashColor: Colors.grey,
                                                      child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          child: Icon(
                                                              MdiIcons
                                                                  .messageTextOutline,
                                                              color: Colors
                                                                  .white))))),
                                        ]),
                                    SizedBox(height: _smallScreen ? 8 : 16),
                                  ])
                            ]),
                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.left,
                          softWrap: true,
                          text: const TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: "Danke dass du diese App verwendest!\n\n",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            TextSpan(
                                text:
                                    "Falls du Fragen, Anregungen oder Kommentare hast, oder dir irgendwelche Fehler untergekommen sind, melde dich doch bei mir indem du einen der oberen Buttons verwendest.\n",
                                style: TextStyle(color: Colors.black)),
                          ]),
                        ),
                      ]))),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text('Info',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: <Widget>[
                    ListTile(
                        title: const Text('App Name',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        trailing: _loading
                            ? const CircularProgressIndicator()
                            : Text(_appName)),
                    ListTile(
                        title: const Text('Package Name',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        trailing: _loading
                            ? const CircularProgressIndicator()
                            : Text(_packageName)),
                    ListTile(
                        title: const Text('Version',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        trailing: _loading
                            ? const CircularProgressIndicator()
                            : Text('$_version+$_buildNumber'))
                  ]))
            ]));
  }
}
