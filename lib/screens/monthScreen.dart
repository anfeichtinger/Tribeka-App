import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tribeka/util/AddShiftScreenArgs.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/widgets/CustomAppBar.dart';
import 'package:tribeka/widgets/MonthSummaryRow.dart';
import 'package:tribeka/widgets/ShiftRow.dart';

import '../widgets/CustomMonthPickerStrip.dart';

// We use the boolean to differentiate auto-login with manual login.
// With auto-login you don't have the right State of Session().
// In order to get the application to open as fast as possible the automatic
// authentication is started after the layout is drawn.
class MonthScreen extends StatefulWidget {
  final bool _automatic;

  MonthScreen(this._automatic);

  @override
  State createState() => MonthScreenState(_automatic);
}

class MonthScreenState extends State<MonthScreen> {
  final bool _automatic;

  MonthScreenState(this._automatic);

  final _session = globals.session;
  DateFormat dateFormat;
  DateTime _selectedTime = DateTime.now();

  List<Shift> _shifts = new List();
  bool _loading = true;
  bool _monthEditable = false;

  @override
  void initState() {
    initializeDateFormatting();
    dateFormat = DateFormat('MMMM yyyy', 'de');

    super.initState();

    if (_automatic) {
      _session.autoLogin(context).then((nullValue) {
        _loadMonthData(_selectedTime.month, _selectedTime.year);
      });
    } else {
      _loadMonthData(_selectedTime.month, _selectedTime.year);
    }
  }

  bool _getIsMonthEditable() {
    _monthEditable = _session.isMonthEditable();
    return _monthEditable;
  }

  Future<Null> _loadMonthData(int _month, int _year) async {
    _shifts.clear();
    setState(() {
      _monthEditable = false;
      _loading = true;
    });
    _session.scrapShiftsFromMonth(_month, _year).then((list) {
      _shifts = list;
    }).whenComplete(() {
      bool edit = _getIsMonthEditable();
      setState(() {
        _loading = false;
        _monthEditable = edit;
      });
    });
  }

  // Navigator.push returns a Future that will complete after we call
  // Navigator.pop on the Selection Screen!
  void _newShiftCallback(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed('/Month/AddShift',
        arguments: AddShiftScreenArgs(_selectedTime));
    if (result) {
      _loadMonthData(_selectedTime.month, _selectedTime.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _monthStrip = Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        margin: EdgeInsets.all(0),
        child: MonthStrip(
          format: 'MMM yyyy',
          from: DateTime(2014, 1),
          to: DateTime(DateTime.now().year + 1, 12),
          initialMonth: _selectedTime,
          height: 48.0,
          viewportFraction: 0.25,
          onMonthChanged: (newTime) {
            _selectedTime = newTime;
            _loadMonthData(newTime.month, newTime.year);
          },
        ));

    final _fab = AnimatedOpacity(
        opacity: _monthEditable ? 1.0 : 0.0,
        duration: Duration(milliseconds: 400),
        child: FloatingActionButton.extended(
          elevation: 4.0,
          backgroundColor: Colors.grey[850],
          icon: Icon(Icons.add),
          label: Text('Dienst hinzufügen'),
          onPressed: _monthEditable ? () => _newShiftCallback(context) : null,
        ));

    _showLogoutPrompt() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            title: Text("Abmelden"),
            content: Text("Bist du dir sicher, dass du dich abmelden willst?"),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("ABBRECHEN")),
              FlatButton(
                  child: Text("JA"),
                  onPressed: () {
                    _session.logout();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/Login', (Route<dynamic> route) => false);
                  })
            ],
          );
        },
      );
    }

    _showFinishMonthPrompt() {
      StreamController<bool> controller = StreamController<bool>.broadcast();
      Future.delayed(Duration(seconds: 5), () {
        if (!controller.isClosed) {
          controller.add(true);
        }
      });
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              title: Text("Monat fertig stellen"),
              content: Text(
                  "Bist du dir sicher, dass du diesen Monat fertigstellen willst? Dies kann nicht rückgängig gemacht werden!\n\nIn 5 Sekunden wird der 'Ja' Button aktiviert."),
              actions: [
                FlatButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("ABBRECHEN")),
                StreamBuilder(
                    stream: controller.stream,
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      return FlatButton(
                        child: Text('JA'),
                        onPressed: snapshot.hasData
                            ? () async {
                                await _session.finishMonth(
                                    _selectedTime.month, _selectedTime.year);
                                Navigator.pop(context);
                                _loadMonthData(
                                    _selectedTime.month, _selectedTime.year);
                              }
                            : null,
                      );
                    })
              ],
            );
          }).whenComplete(() {
        controller.close();
      });
      /*showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            title: Text("Monat fertig stellen"),
            content: Text(
                "Bist du dir sicher, dass du diesen Monat fertigstellen willst?\n\nDies kann nicht rückgängig gemacht werden!"),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("ABBRECHEN")),
              FlatButton(
                  child: Text("JA"),
                  onPressed: () async {
                    await _session.finishMonth(
                        _selectedTime.month, _selectedTime.year);
                    Navigator.pop(context);
                    _loadMonthData(_selectedTime.month, _selectedTime.year);
                  })
            ],
          );
        },
      );*/
    }

    _showCallInSickPrompt() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          int from = DateTime.now().day;
          int to = DateTime.now().day;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            title: Text("Krank melden"),
            content: Container(
              height: 198,
              child: Column(
                children: <Widget>[
                  Text('In diesem Monat krank melden von: '),
                  Picker(
                      textStyle: TextStyle(fontSize: 24, color: Colors.black),
                      height: 80,
                      hideHeader: true,
                      columnPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      adapter: DateTimePickerAdapter(
                        value: DateTime.now(),
                        customColumnType: [2],
                      ),
                      onSelect: (Picker picker, int i, List value) {
                        from = value.last + 1;
                      }).makePicker(),
                  Text('bis:'),
                  Picker(
                      textStyle: TextStyle(fontSize: 24, color: Colors.black),
                      height: 80,
                      hideHeader: true,
                      columnPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      adapter: DateTimePickerAdapter(
                        value: DateTime.now(),
                        customColumnType: [2],
                      ),
                      onSelect: (Picker picker, int i, List value) {
                        to = value.last + 1;
                      }).makePicker()
                ],
              ),
            ),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("ABBRECHEN")),
              FlatButton(
                  child: Text("SENDEN"),
                  onPressed: () async {
                    await _session.callInSick(_selectedTime, from, to);
                    Navigator.pop(context);
                    _loadMonthData(_selectedTime.month, _selectedTime.year);
                  })
            ],
          );
        },
      );
    }

    final _bottomNavBar = BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back),
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
                    icon: Icon(Icons.mood_bad),
                    onPressed:
                        _monthEditable ? () => _showCallInSickPrompt() : null,
                    tooltip: "Krank melden",
                  ),
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed:
                        _monthEditable ? () => _showFinishMonthPrompt() : null,
                    tooltip: "Monat fertigstellen",
                  ),
                ],
              ))
        ],
      ),
    );

    Future<Null> _deleteCallback(Shift shift) async {
      Future.value(await _session.removeShift(_selectedTime, shift))
          .whenComplete(() {
        return _loadMonthData(_selectedTime.month, _selectedTime.year);
      });
    }

    void _showDeletePrompt(Shift shift) {
      if (_monthEditable) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  title: Text("Dienst löschen"),
                  content: RichText(
                    text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                            text:
                                'Bist du dir sicher, dass du den Dienst vom '),
                        TextSpan(
                            text: '${shift.day}.${_selectedTime.month} ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: 'löschen willst?'),
                      ],
                    ),
                  ),
                  actions: [
                    FlatButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("ABBRECHEN")),
                    FlatButton(
                        child: Text("JA"),
                        onPressed: () {
                          _deleteCallback(shift);
                          Navigator.pop(context);
                        })
                  ]);
            });
      }
    }

    return Scaffold(
        appBar: CustomAppBar.get,
        backgroundColor: Colors.grey[100],
        floatingActionButton: _fab,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _bottomNavBar,
        body: SafeArea(
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
                          Image.asset('assets/no_shift_found.png', height: 256),
                          Text('Keine Dienste',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18))
                        ])))
                      : ListView.builder(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(6, 6, 6, 30),
                          itemCount: _shifts.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            bool _last = index == _shifts.length;
                            return _last
                                ? MonthSummaryRow(_session.getHoursInMonth())
                                : ShiftRow(
                                    _shifts.elementAt(index), _selectedTime,
                                    (time, shift) async {
                                    _showDeletePrompt(shift);
                                  });
                          }),
            )
          ],
        )));
  }
}
