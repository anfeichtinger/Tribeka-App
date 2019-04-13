import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tribeka/services/InitTimeGenerator.dart';
import 'package:tribeka/services/Validator.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/widgets/CustomAppBar.dart';

class ShiftScreen extends StatefulWidget {
  final Shift _shift;
  final bool _editable;
  final DateTime _selectedTime;

  ShiftScreen(this._shift, this._editable, this._selectedTime);

  @override
  State createState() {
    return ShiftScreenState(_shift, _editable, _selectedTime);
  }
}

class ShiftScreenState extends State<ShiftScreen> {
  final Shift _initialShift;
  final bool _editable;
  final DateTime _selectedTime;
  final _commentController = TextEditingController();
  static bool _dataSent = false;
  Shift _newShift;
  bool _modified = false;
  bool _valid = true;

  ShiftScreenState(this._initialShift, this._editable, this._selectedTime);

  void _checkModified() {
    if (_newShift == _initialShift) {
      setState(() {
        _modified = false;
      });
    } else {
      setState(() {
        _modified = true;
      });
    }
  }

  void _checkValid() {
    if (_modified) {
      if (Validator.validateShift(_newShift)) {
        setState(() {
          _valid = true;
        });
      } else {
        setState(() {
          _valid = false;
        });
      }
    }
  }

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
        .copyWith(statusBarIconBrightness: Brightness.dark));
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));

    _modified = false;
    _valid = true;
    _newShift = Shift.copy(_initialShift);
    _commentController.text = _newShift.comment;
    _commentController.addListener(() {
      _newShift.comment = _commentController.text;
      _checkModified();
      _checkValid();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Hide the FAB when the keyboard is open to avoid clipping
    final bool _showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;

    Widget _buildBottomPicker(Widget picker) {
      return Container(
        height: 200.0,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.white,
        child: DefaultTextStyle(
          style: const TextStyle(
            color: CupertinoColors.black,
            fontSize: 22.0,
          ),
          child: GestureDetector(
            // Blocks taps from propagating to the modal sheet and popping.
            onTap: () {},
            child: SafeArea(
              top: false,
              child: picker,
            ),
          ),
        ),
      );
    }

    _setBreakToValue(DateTime time) {
      switch (time.minute) {
        case 0:
        case 15:
          setState(() {
            _newShift.breakTo =
                '${time.hour.toString().padLeft(2, '0')}:${(time.minute + 30).toString().padLeft(2, '0')}';
          });
          break;
        case 30:
          setState(() {
            _newShift.breakTo =
                '${(time.hour + 1).toString().padLeft(2, '0')}:00';
          });
          break;
        case 45:
          setState(() {
            _newShift.breakTo =
                '${(time.hour + 1).toString().padLeft(2, '0')}:15';
          });
          break;
      }
    }

    final _header = Padding(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_newShift.weekday,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22)),
                    Text(DateFormat('MMMM, yyyy').format(_selectedTime),
                        style: TextStyle(fontSize: 14)),
                  ]),
              Hero(
                  tag: _newShift.day,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[850],
                    child: Text('${_newShift.day}.',
                        style: TextStyle(
                            fontFamily: 'Tribeka',
                            fontSize: 28.0,
                            color: Colors.white)),
                    minRadius: 24,
                    maxRadius: 24,
                  )),
            ]),
        padding: EdgeInsets.symmetric(horizontal: 16));

    final _workFromTile = ListTile(
        onLongPress: _editable
            ? () {
                setState(() {
                  _newShift.workFrom = '-';
                });
                _checkValid();
              }
            : () {},
        onTap: _editable
            ? () {
                final _initial =
                    InitTimeGenerator.workFrom(_selectedTime, _newShift);
                setState(() {
                  _newShift.workFrom =
                      '${_initial.hour.toString().padLeft(2, '0')}:${_initial.minute.toString().padLeft(2, '0')}';
                });
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _initial,
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            _newShift.workFrom =
                                '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                          });
                          _checkModified();
                          _checkValid();
                        },
                      ));
                    });
              }
            : () {},
        leading: Icon(Icons.work, color: Colors.grey[800]),
        title: Text('Arbeit von', style: TextStyle(fontSize: 16)),
        trailing: Text(_newShift.workFrom,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _workToTile = ListTile(
        onLongPress: _editable
            ? () {
                setState(() {
                  _newShift.workTo = '-';
                });
                _checkValid();
              }
            : () {},
        onTap: _editable
            ? () {
                final _initial =
                    InitTimeGenerator.workTo(_selectedTime, _newShift);
                setState(() {
                  _newShift.workTo =
                      '${_initial.hour.toString().padLeft(2, '0')}:${_initial.minute.toString().padLeft(2, '0')}';
                });
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _initial,
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            _newShift.workTo =
                                '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                          });
                          _checkModified();
                          _checkValid();
                        },
                      ));
                    });
              }
            : () {},
        leading: Icon(null),
        title: Text('Arbeit bis', style: TextStyle(fontSize: 16)),
        trailing: Text(_newShift.workTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _breakFromTile = ListTile(
        onLongPress: _editable
            ? () {
                setState(() {
                  _newShift.breakFrom = '-';
                });
                _checkValid();
              }
            : () {},
        onTap: _editable
            ? () {
                final _initial =
                    InitTimeGenerator.breakFrom(_selectedTime, _newShift);
                setState(() {
                  _newShift.breakFrom =
                      '${_initial.hour.toString().padLeft(2, '0')}:${_initial.minute.toString().padLeft(2, '0')}';
                });
                _setBreakToValue(_initial);
                _checkValid();
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _initial,
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            _newShift.breakFrom =
                                '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                          });
                          _setBreakToValue(newDateTime);
                          _checkModified();
                          _checkValid();
                        },
                      ));
                    });
              }
            : () {},
        leading: Icon(Icons.free_breakfast, color: Colors.grey[800]),
        title: Text('Pause von', style: TextStyle(fontSize: 16)),
        trailing: Text(_newShift.breakFrom,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _breakToTile = ListTile(
        onLongPress: _editable
            ? () {
                setState(() {
                  _newShift.breakTo = '-';
                });
                _checkModified();
                _checkValid();
              }
            : () {},
        onTap: _editable
            ? () {
                final _initial =
                    InitTimeGenerator.breakTo(_selectedTime, _newShift);
                setState(() {
                  _newShift.breakTo =
                      '${_initial.hour.toString().padLeft(2, '0')}:${_initial.minute.toString().padLeft(2, '0')}';
                });
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _initial,
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            _newShift.breakTo =
                                '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                          });
                          _checkModified();
                          _checkValid();
                        },
                      ));
                    });
              }
            : () {},
        leading: Icon(null),
        title: Text('Pause bis', style: TextStyle(fontSize: 16)),
        trailing: Text(_newShift.breakTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _comment = Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
            enabled: _editable,
            controller: _commentController,
            keyboardType: TextInputType.text,
            autofocus: false,
            decoration: InputDecoration(
              hintText: _editable ? 'Kommentar' : '',
              icon: Icon(Icons.comment, color: Colors.grey[800]),
              contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
            )));

    final _hoursTile = ListTile(
        leading: Icon(Icons.hourglass_full, color: Colors.grey[800]),
        title: Text('Stunden', style: TextStyle(fontSize: 16)),
        trailing: Text('${_newShift.hours} h',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _placeTile = ListTile(
        leading: Icon(Icons.place, color: Colors.grey[800]),
        title: Text('Lokal', style: TextStyle(fontSize: 16)),
        trailing: Text(_newShift.place,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _divider = SizedBox(
        height: 1.0,
        child: Center(
            child: Container(
                margin: EdgeInsetsDirectional.only(start: 40.0, end: 40.0),
                height: 1.0,
                color: Colors.grey[500])));

    final _fab = _editable
        ? _showFab
            ? FloatingActionButton.extended(
                elevation: 4.0,
                backgroundColor: _modified
                    ? _valid ? Colors.grey[850] : Colors.grey[600]
                    : Colors.grey[600],
                icon: Icon(Icons.check),
                label: Text('Änderungen speichern'),
                onPressed: _modified
                    ? _valid
                        ? () async {
                            await globals.session
                                .updateShift(_selectedTime, _newShift);
                            _dataSent = true;
                            Navigator.pop(context, _dataSent);
                          }
                        : null
                    : null,
              )
            : SizedBox(height: 0)
        : SizedBox(height: 0);

    final _bottomNavBar = BottomAppBar(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _dataSent = false;
            Navigator.pop(context, _dataSent);
          },
          tooltip: "Zurück",
        ),
        _editable
            ? IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () async {
                  await globals.session
                      .removeShift(_selectedTime, _initialShift);
                  _dataSent = true;
                  Navigator.pop(context, _dataSent);
                },
                tooltip: "Löschen",
              )
            : SizedBox(height: 0),
      ],
    ));

    return Scaffold(
        appBar: CustomAppBar.gone,
        bottomNavigationBar: _bottomNavBar,
        floatingActionButton: _fab,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        backgroundColor: Colors.grey[50],
        body: WillPopScope(
            onWillPop: () {
              _dataSent = false;
              Navigator.pop(context, _dataSent);
            },
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: <Widget>[
                      SizedBox(height: 24),
                      _header,
                      SizedBox(height: 20),
                      _workFromTile,
                      _workToTile,
                      SizedBox(height: 9.5),
                      _divider,
                      SizedBox(height: 9.5),
                      _breakFromTile,
                      _breakToTile,
                      SizedBox(height: 9.5),
                      _divider,
                      SizedBox(height: 9.5),
                      _hoursTile,
                      _placeTile,
                      SizedBox(height: 16),
                      _comment,
                      SizedBox(height: 16)
                    ]))));
  }
}
