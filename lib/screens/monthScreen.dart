import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tribeka/screens/AddShiftScreen.dart';
import 'package:tribeka/screens/aboutMeScreen.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/util/ShiftRepository.dart';
import 'package:tribeka/widgets/MonthSummaryRow.dart';
import 'package:tribeka/widgets/ShiftRow.dart';

import '../widgets/CustomMonthPickerStrip.dart';

// In order to get the application to open as fast as possible the automatic
// authentication is started after the layout is drawn.
class MonthScreen extends StatefulWidget {
  @override
  State createState() => MonthScreenState();
}

class MonthScreenState extends State<MonthScreen> {
  final _session = globals.session;
  final _storage = FlutterSecureStorage();
  final _shiftRepo = ShiftRepository();
  DateFormat dateFormat;
  DateTime _selectedTime = DateTime.now();

  List<Shift> _shifts = List();
  double _totalHours = 0.0;
  bool _loading = true;
  bool _monthEditable = false;
  bool _connected = false;

  Future<Null> _checkLoginType() async {
    if (await _shiftRepo.monthIsPersisted(_selectedTime)) {
      _loadMonthData(refresh: false, showLoading: true);
    } else {
      _loadMonthData(refresh: true, showLoading: true);
    }
  }

  @override
  void initState() {
    initializeDateFormatting();
    dateFormat = DateFormat('MMMM yyyy', 'de');

    super.initState();
    _checkLoginType();
  }

  final placesAvail = [
    PickerItem(text: Text('Grieskai'), value: 'grieskai'),
    PickerItem(text: Text('Kaiserfeldgasse'), value: 'kaiserfeldgasse'),
    PickerItem(text: Text('Reiterkaserne'), value: 'reiterkaserne'),
    PickerItem(text: Text('TU'), value: 'tu'),
    PickerItem(text: Text('Ausliefern'), value: 'ausliefern'),
    PickerItem(text: Text('Büro'), value: 'büro'),
    PickerItem(text: Text('Küche'), value: 'küche'),
    PickerItem(text: Text('Rösten'), value: 'rösten')
  ];

  Future<Null> _showPlacePickerPrompt() async {
    globals.user.place = 'grieskai';
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
            onWillPop: () {},
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Lokal auswählen"),
                    Icon(MdiIcons.mapMarkerOutline)
                  ]),
              content:
                  Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text(
                    "Dein Lokal konnte nicht automatisch erkannt werden, bitte wähle aus wo du arbeitest."),
                Picker(
                    textStyle: TextStyle(fontSize: 24, color: Colors.black),
                    height: 200,
                    hideHeader: true,
                    columnPadding:
                        EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    adapter: PickerDataAdapter(data: placesAvail),
                    onSelect: (Picker picker, int i, List value) {
                      globals.user.place = picker.getSelectedValues()[i];
                    }).makePicker()
              ]),
              actions: [
                FlatButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.pop(context);
                      _storage.write(key: 'place', value: globals.user.place);
                    })
              ],
            ));
      },
    );
  }

  Future<Null> _prepareUser(List<Shift> shifts) async {
    if (globals.user.place == null || globals.user.place.isEmpty) {
      String place = await _storage.read(key: 'place');
      if (place == null || place.isEmpty) {
        if (shifts.isNotEmpty) {
          List<String> places = [];
          shifts
              .takeWhile(
                  (shift) => shift.place != 'krank' && shift.place.isNotEmpty)
              .forEach((shift) {
            if (!places.contains(shift.place)) {
              places.add(shift.place);
            }
          });
          if (places.length == 1) {
            globals.user.place = places[0];
            if (await _storage.read(key: 'place') != globals.user.place) {
              _storage.write(key: 'place', value: globals.user.place);
            }
          } else {
            await _showPlacePickerPrompt();
          }
        } else {
          await _showPlacePickerPrompt();
        }
      } else {
        globals.user.place = place;
      }
    }
  }

  Future<Null> _checkForUpdate() async {
    await _session.autoLogin(context);
    List<Shift> onlineShifts =
        await _session.scrapShiftsFromMonth(_selectedTime);
    if (onlineShifts == null) {
      return null;
    } else if (_shifts.length != onlineShifts.length) {
      _loadMonthData(refresh: true, showLoading: false);
    } else {
      for (int i = 0; i < onlineShifts.length; i++) {
        if (onlineShifts[i] != _shifts[i]) {
          _loadMonthData(refresh: true, showLoading: false);
        }
      }
    }
  }

  Future<Null> _loadMonthData(
      {@required bool refresh, @required bool showLoading}) async {
    if (showLoading) {
      _shifts.clear();
      setState(() {
        _monthEditable = false;
        _loading = true;
      });
    }
    bool edit;
    if (!_connected) {
      refresh = false;
    }
    if (refresh) {
      _shifts = await _session.scrapShiftsFromMonth(_selectedTime);
      edit = _session.isMonthEditable();
      _totalHours = _session.getTotalHoursInMonth();
      _shiftRepo.clearMonthData(_selectedTime.subtract(Duration(days: 366)));
    } else if (await _shiftRepo.monthIsPersisted(_selectedTime)) {
      _shifts = await _shiftRepo.getPersistedMonthShifts(_selectedTime);
      edit = await _shiftRepo.monthIsEditable(_selectedTime);
      _totalHours = await _shiftRepo.getTotalHoursInMonth(_selectedTime);
      if (_connected) {
        _checkForUpdate();
      }
    } else {
      _shifts = await _session.scrapShiftsFromMonth(_selectedTime);
      edit = _session.isMonthEditable();
      _totalHours = _session.getTotalHoursInMonth();
      _shiftRepo.clearMonthData(_selectedTime.subtract(Duration(days: 366)));
    }
    await _prepareUser(_shifts);
    if (_loading != false)
      setState(() {
        _loading = false;
      });
    if (_connected) {
      setState(() {
        _monthEditable = edit;
      });
    } else {
      setState(() {
        _monthEditable = false;
      });
    }
    if (_selectedTime.isAfter(DateTime.now().subtract(Duration(days: 366))) &&
        _selectedTime.isBefore(DateTime.now().add(Duration(days: 32)))) {
      _shiftRepo.persistMonthShifts(_selectedTime, _shifts, edit, _totalHours);
    }
  }

  // Navigator.push returns a Future that will complete after we call
  // Navigator.pop on the Selection Screen!
  void _addShiftCallback(BuildContext context) async {
    List<int> _presentDates = [];
    _shifts.forEach((s) {
      _presentDates.add(int.parse(s.day));
    });

    final result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AddShiftScreen(_selectedTime, _presentDates)));
    if (result) {
      _loadMonthData(refresh: true, showLoading: false);
    }
  }

  void _deleteCallback(Shift shift) async {
    setState(() {
      _shifts.remove(shift);
    });
    await globals.session.removeShift(_selectedTime, shift);
    _shiftRepo.persistMonthShifts(_selectedTime, _shifts, true, _totalHours);
  }

  @override
  Widget build(BuildContext context) {
    final _monthStrip = Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        margin: EdgeInsets.all(0),
        child: MonthStrip(
          format: 'MMM yyyy',
          from: DateTime(2012, 1),
          to: DateTime.now().add(Duration(days: 90)),
          initialMonth: _selectedTime,
          height: 48.0,
          viewportFraction: 0.25,
          onMonthChanged: (newTime) {
            _selectedTime = newTime;
            _loadMonthData(refresh: false, showLoading: true);
          },
        ));

    final _fab = AnimatedOpacity(
        opacity: _monthEditable ? 1.0 : 0.0,
        duration: Duration(milliseconds: 400),
        child: FloatingActionButton.extended(
          elevation: 4.0,
          backgroundColor: Colors.grey[850],
          icon: Icon(MdiIcons.plus),
          label: Text('Dienst hinzufügen'),
          onPressed: _monthEditable ? () => _addShiftCallback(context) : null,
        ));

    _showLogoutPrompt() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Abmelden"),
                  Icon(MdiIcons.arrowCollapseLeft)
                ]),
            content: Text("Bist du dir sicher, dass du dich abmelden willst?"),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("ABBRECHEN")),
              FlatButton(
                  child: Text("JA"),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/Login', (Route<dynamic> route) => false);
                    globals.user.place = null;
                    _session.logout();
                  })
            ],
          );
        },
      );
    }

    _showFinishMonthPrompt() {
      StreamController<int> controller = StreamController<int>.broadcast();
      Future.delayed(Duration(milliseconds: 50), () async {
        controller.add(10);
        for (int i = 9; i >= 0; i--) {
          await Future.delayed(Duration(seconds: 1), () {
            if (!controller.isClosed) {
              controller.add(i);
            }
          });
        }
      });
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Monat fertig stellen"),
                    Icon(MdiIcons.calendarCheck)
                  ]),
              content: StreamBuilder(
                  stream: controller.stream,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    if (snapshot.data == 0) {
                      return Text(
                          "Bist du dir sicher, dass du diesen Monat fertigstellen willst?\n\nDanach können keine weiteren Änderungen vorgenommen werden!");
                    } else {
                      return Text(
                          "Bist du dir sicher, dass du diesen Monat fertigstellen willst?\nDanach können keine weiteren Änderungen vorgenommen werden!\n\nIn ${snapshot.data} Sekunden wird der 'Ja' Button aktiviert.");
                    }
                  }),
              actions: [
                FlatButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("ABBRECHEN")),
                StreamBuilder(
                    stream: controller.stream,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      return FlatButton(
                        child: Text('JA'),
                        onPressed: snapshot.data == 0
                            ? () async {
                                Navigator.pop(context);
                                await _session.finishMonth(_selectedTime);
                                _loadMonthData(
                                    refresh: true, showLoading: false);
                              }
                            : null,
                      );
                    })
              ],
            );
          }).whenComplete(() {
        controller.close();
      });
    }

    _showCallInSickPrompt() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            int from = DateTime
                .now()
                .day;
            int to = DateTime
                .now()
                .day;
            return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Krank melden"),
                      Icon(MdiIcons.pill)
                    ]),
                content: Container(
                    height: 180,
                    child: Column(children: <Widget>[
                      Text('In diesem Monat krank melden von: '),
                      Picker(
                          textStyle:
                          TextStyle(fontSize: 24, color: Colors.black),
                          height: 70,
                          hideHeader: true,
                          columnPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          adapter: DateTimePickerAdapter(
                              value: DateTime.now(), customColumnType: [2]),
                          onSelect: (Picker picker, int i, List value) {
                            from = value.last + 1;
                          }).makePicker(),
                      Text('bis:'),
                      Picker(
                          textStyle:
                          TextStyle(fontSize: 24, color: Colors.black),
                          height: 70,
                          hideHeader: true,
                          columnPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          adapter: DateTimePickerAdapter(
                              value: DateTime.now(), customColumnType: [2]),
                          onSelect: (Picker picker, int i, List value) {
                            to = value.last + 1;
                          }).makePicker()
                    ])),
                actions: [
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("ABBRECHEN")),
                  FlatButton(
                      child: Text("SENDEN"),
                      onPressed: () async {
                        if (from <= to) {
                          Navigator.pop(context);
                          setState(() {
                            _loading = true;
                            _monthEditable = false;
                          });
                          await _session.callInSick(_selectedTime, from, to);
                          _loadMonthData(refresh: true, showLoading: false);
                        }
                      })
                ]);
          });
    }

    final _bottomNavBar = BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(MdiIcons.arrowCollapseLeft),
            onPressed: () => _showLogoutPrompt(),
            tooltip: "Abmelden",
          ),
          AnimatedOpacity(
              opacity: _monthEditable ? 1.0 : 0.0,
              duration: Duration(milliseconds: 400),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: Icon(MdiIcons.pill),
                    onPressed:
                        _monthEditable ? () => _showCallInSickPrompt() : null,
                    tooltip: "Krank melden",
                  ),
                  IconButton(
                    icon: Icon(MdiIcons.calendarCheck),
                    onPressed:
                        _monthEditable ? () => _showFinishMonthPrompt() : null,
                    tooltip: "Monat fertigstellen",
                  ),
                ],
              ))
        ],
      ),
    );

    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            brightness: Brightness.dark,
            backgroundColor: Colors.grey[850],
            centerTitle: true,
            title: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => AboutMeScreen()));
                },
                child: Text(
                  "tribeka",
                  style: TextStyle(
                      fontFamily: 'Tribeka',
                      fontSize: 30.0,
                      color: Colors.white),
                ))),
        backgroundColor: Colors.grey[100],
        floatingActionButton: _fab,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _bottomNavBar,
        body: OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child,
            ) {
              final _newConnected = connectivity != ConnectivityResult.none;
              if (_connected != _newConnected) {
                _connected = _newConnected;
                _loadMonthData(refresh: false, showLoading: false);
              }
              return Stack(
                alignment: Alignment.bottomCenter,
                fit: StackFit.expand,
                children: [
                  child,
                  _connected
                      ? SizedBox(height: 0)
                      : Positioned(
                          height: 32.0,
                          left: 0.0,
                          right: 0.0,
                          child: Container(
                              color: Color(0xFFEE4400),
                              child: Center(
                                  child: Text('Keine Internetverbindung',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white)))),
                        ),
                ],
              );
            },
            child: SafeArea(
                child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _monthStrip,
                SizedBox(height: 1),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                          strokeWidth: 5,
                        ))
                      : _shifts.isEmpty
                          ? Container(
                              child: Center(
                                  child: Column(children: <Widget>[
                              Image.asset('assets/no_shift_found.png',
                                  height: 256),
                              Text('Keine Dienste',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18))
                            ])))
                          : ListView.builder(
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(6, 6, 6, 30),
                              itemCount: _shifts.length + 1,
                              itemBuilder: (BuildContext context, int index) {
                                bool _last = index == _shifts.length;
                                return _last
                                    ? MonthSummaryRow(_totalHours)
                                    : ShiftRow(
                                        _shifts.elementAt(index),
                                        _selectedTime,
                                        _monthEditable,
                                    _loadMonthData,
                                    _deleteCallback);
                              }),
                )
              ],
            ))));
  }
}
