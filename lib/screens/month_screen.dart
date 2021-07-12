import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tribeka/screens/about_me_screen.dart';
import 'package:tribeka/screens/add_shift_screen.dart';
import 'package:tribeka/util/globals.dart' as globals;
import 'package:tribeka/util/shift.dart';
import 'package:tribeka/util/shift_repository.dart';
import 'package:tribeka/widgets/month_summary_row.dart';
import 'package:tribeka/widgets/shift_row.dart';

import '../widgets/custom_month_picker_strip.dart';

// In order to get the application to open as fast as possible the automatic
// authentication is started after the layout is drawn.
class MonthScreen extends StatefulWidget {
  @override
  State createState() => MonthScreenState();
}

class MonthScreenState extends State<MonthScreen> {
  final _session = globals.session;
  final _storage = const FlutterSecureStorage();
  final _shiftRepo = ShiftRepository();
  DateFormat dateFormat;
  DateTime _selectedTime = DateTime.now();

  List<Shift> _shifts = [];
  double _totalHours = 0.0;
  bool _loading = true;
  bool _monthEditable = false;
  bool _connected = false;

  Future<void> _checkLoginType() async {
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
    PickerItem(text: const Text('Grieskai'), value: 'grieskai'),
    PickerItem(text: const Text('Kaiserfeldgasse'), value: 'kaiserfeldgasse'),
    PickerItem(text: const Text('Reiterkaserne'), value: 'reiterkaserne'),
    PickerItem(text: const Text('TU'), value: 'tu'),
    PickerItem(text: const Text('Ausliefern'), value: 'ausliefern'),
    PickerItem(text: const Text('Büro'), value: 'büro'),
    PickerItem(text: const Text('Küche'), value: 'küche'),
    PickerItem(text: const Text('Rösten'), value: 'rösten')
  ];

  Future<void> _showPlacePickerPrompt() async {
    globals.user.place = 'grieskai';
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
            onWillPop: () {},
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const <Widget>[
                    Text("Lokal auswählen"),
                    Icon(MdiIcons.mapMarkerOutline)
                  ]),
              content:
                  Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                const Text(
                    "Dein Lokal konnte nicht automatisch erkannt werden, bitte wähle aus wo du arbeitest."),
                Picker(
                    textStyle:
                        const TextStyle(fontSize: 24, color: Colors.black),
                    height: 200,
                    hideHeader: true,
                    columnPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    adapter: PickerDataAdapter<String>(data: placesAvail),
                    onSelect: (Picker picker, int i, List value) {
                      globals.user.place =
                          picker.getSelectedValues()[i] as String;
                    }).makePicker()
              ]),
              actions: [
                FlatButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.pop(context);
                      _storage.write(key: 'place', value: globals.user.place);
                    })
              ],
            ));
      },
    );
  }

  Future<void> _prepareUser(List<Shift> shifts) async {
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

  Future<void> _checkForUpdate() async {
    await _session.autoLogin(context);
    List<Shift> onlineShifts =
        await _session.scrapShiftsFromMonth(_selectedTime);
    if (onlineShifts == null) {
      return;
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

  Future<void> _loadMonthData(
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
      _shiftRepo.clearMonthData(_selectedTime.subtract(const Duration(days: 366)));
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
      _shiftRepo.clearMonthData(_selectedTime.subtract(const Duration(days: 366)));
    }
    await _prepareUser(_shifts);
    if (_loading != false) {
      setState(() {
        _loading = false;
      });
    }
    if (_connected) {
      setState(() {
        _monthEditable = edit;
      });
    } else {
      setState(() {
        _monthEditable = false;
      });
    }
    if (_selectedTime.isAfter(DateTime.now().subtract(const Duration(days: 366))) &&
        _selectedTime.isBefore(DateTime.now().add(const Duration(days: 32)))) {
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

    final dynamic result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(
        builder: (context) => AddShiftScreen(_selectedTime, _presentDates)));
    if (result != null) {
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
        margin: const EdgeInsets.all(0),
        child: MonthStrip(
          format: 'MMM yyyy',
          from: DateTime(2012, 1),
          to: DateTime.now().add(const Duration(days: 90)),
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
        duration: const Duration(milliseconds: 400),
        child: FloatingActionButton.extended(
          elevation: 4.0,
          backgroundColor: Colors.grey[850],
          icon: const Icon(MdiIcons.plus),
          label: const Text('Dienst hinzufügen'),
          onPressed: _monthEditable ? () => _addShiftCallback(context) : null,
        ));

    _showLogoutPrompt() {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const <Widget>[
                  Text("Abmelden"),
                  Icon(MdiIcons.arrowCollapseLeft)
                ]),
            content: const Text("Bist du dir sicher, dass du dich abmelden willst?"),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ABBRECHEN")),
              FlatButton(
                  child: const Text("JA"),
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
      Future.delayed(const Duration(milliseconds: 50), () async {
        controller.add(10);
        for (int i = 9; i >= 0; i--) {
          await Future.delayed(const Duration(seconds: 1), () {
            if (!controller.isClosed) {
              controller.add(i);
            }
          });
        }
      });
      showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const <Widget>[
                    Text("Monat fertig stellen"),
                    Icon(MdiIcons.calendarCheck)
                  ]),
              content: StreamBuilder(
                  stream: controller.stream,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    if (snapshot.data == 0) {
                      return const Text(
                          "Bist du dir sicher, dass du diesen Monat fertigstellen willst?\n\nDanach können keine weiteren Änderungen vorgenommen werden!");
                    } else {
                      return Text(
                          "Bist du dir sicher, dass du diesen Monat fertigstellen willst?\nDanach können keine weiteren Änderungen vorgenommen werden!\n\nIn ${snapshot.data} Sekunden wird der 'Ja' Button aktiviert.");
                    }
                  }),
              actions: [
                FlatButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ABBRECHEN")),
                StreamBuilder(
                    stream: controller.stream,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      return FlatButton(
                        child: const Text('JA'),
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
      showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            int from = DateTime.now().day;
            int to = DateTime.now().day;
            return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text("Krank melden"),
                      Icon(MdiIcons.pill)
                    ]),
                content: SizedBox(
                    height: 200,
                    child: Column(children: <Widget>[
                      const Text('In diesem Monat krank melden von: '),
                      Picker(
                          textStyle:
                          const TextStyle(fontSize: 24, color: Colors.black),
                          height: 70,
                          hideHeader: true,
                          columnPadding:
                          const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          adapter: DateTimePickerAdapter(
                              value: DateTime.now(), customColumnType: [2]),
                          onSelect: (Picker picker, int i, List<int> value) {
                            from = value.last + 1;
                          }).makePicker(),
                      const Text('bis:'),
                      Picker(
                          textStyle:
                          const TextStyle(fontSize: 24, color: Colors.black),
                          height: 70,
                          hideHeader: true,
                          columnPadding:
                          const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          adapter: DateTimePickerAdapter(
                              value: DateTime.now(), customColumnType: [2]),
                          onSelect: (Picker picker, int i, List<int> value) {
                            to = value.last + 1;
                          }).makePicker()
                    ])),
                actions: [
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ABBRECHEN")),
                  FlatButton(
                      child: const Text("SENDEN"),
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
            icon: const Icon(MdiIcons.arrowCollapseLeft),
            onPressed: () => _showLogoutPrompt(),
            tooltip: "Abmelden",
          ),
          AnimatedOpacity(
              opacity: _monthEditable ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(MdiIcons.pill),
                    onPressed:
                        _monthEditable ? () => _showCallInSickPrompt() : null,
                    tooltip: "Krank melden",
                  ),
                  IconButton(
                    icon: const Icon(MdiIcons.calendarCheck),
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
                  Navigator.of(context).push<void>(
                      MaterialPageRoute(builder: (context) => AboutMeScreen()));
                },
                child: const Text(
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
            child: SafeArea(
                child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _monthStrip,
                const SizedBox(height: 1),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                          strokeWidth: 5,
                        ))
                      : _shifts.isEmpty
                          ? SizedBox(
                              child: Center(
                                  child: Column(children: <Widget>[
                              Image.asset('assets/no_shift_found.png',
                                  height: 256),
                                    const Text('Keine Dienste',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18))
                            ])))
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(6, 6, 6, 30),
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
