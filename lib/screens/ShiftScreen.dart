import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
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
  bool _showError = false;
  String _errorMsg = '';

  static Color _workFromColor = Colors.black;
  static Color _workToColor = Colors.black;
  static Color _breakFromColor = Colors.black;
  static Color _breakToColor = Colors.black;

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
    ShiftStatus validationState = Validator.validateShift(_newShift);
    switch (validationState) {
      case ShiftStatus.valid:
        setState(() {
          _valid = true;
          _workFromColor = Colors.black;
          _workToColor = Colors.black;
          _breakFromColor = Colors.black;
          _breakToColor = Colors.black;
          _errorMsg = '';
        });
        break;
      case ShiftStatus.workMissing:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.red;
            _workToColor = Colors.red;
            _breakFromColor = Colors.black;
            _breakToColor = Colors.black;
          }
          _errorMsg = 'Arbeitszeiten werden benötigt';
        });
        break;
      case ShiftStatus.breakFromMissing:
      case ShiftStatus.breakToMissing:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.red;
            _breakToColor = Colors.red;
          }
          _errorMsg = 'Beide/Keine Pausen werden benötigt';
        });
        break;
      case ShiftStatus.workToBeforeWorkFrom:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.red;
            _workToColor = Colors.red;
            _breakFromColor = Colors.black;
            _breakToColor = Colors.black;
          }
          _errorMsg = 'Arbeitsbeginn muss vor Arbeitsende liegen';
        });
        break;
      case ShiftStatus.breakToAfterWorkTo:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.black;
            _breakToColor = Colors.red;
          }
          _errorMsg = 'Pausenbeginn darf nicht nach Arbeitsende liegen';
        });
        break;
      case ShiftStatus.breakFromBeforeWorkFrom:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.red;
            _breakToColor = Colors.black;
          }
          _errorMsg = 'Pausenbeginn darf nicht vor Arbeitsbeginn liegen';
        });
        break;
      case ShiftStatus.breakFromAfterWorkTo:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.red;
            _breakToColor = Colors.black;
          }
          _errorMsg = 'Pausenbegionn darf nicht nach Arbeitende liegen';
        });
        break;
      case ShiftStatus.breakToBeforeWorkTo:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.black;
            _breakToColor = Colors.red;
          }
          _errorMsg = 'Pausenende darf nicht nach Arbeitbegin liegen';
        });
        break;
      case ShiftStatus.breakFromAfterBreakTo:
        setState(() {
          _valid = false;
          if (_showError) {
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.red;
            _breakToColor = Colors.red;
          }
          _errorMsg = 'Pausenende darf nicht vor Pausenbeginn liegen';
        });
        break;
      default:
        setState(() {
          _valid = false;
          _workFromColor = Colors.red;
          _workToColor = Colors.red;
          _breakFromColor = Colors.red;
          _breakToColor = Colors.red;
          _errorMsg = 'Generic Error';
        });
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

    _adjustBreakTo(DateTime time) {
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

    _adjustWorkTo(DateTime time) {
      switch (time.minute) {
        case 0:
        case 15:
          setState(() {
            _newShift.workTo =
                '${(time.hour + 7).toString().padLeft(2, '0')}:${(time.minute + 30).toString().padLeft(2, '0')}';
          });
          break;
        case 30:
          setState(() {
            _newShift.workTo =
                '${(time.hour + 8).toString().padLeft(2, '0')}:00';
          });
          break;
        case 45:
          setState(() {
            _newShift.workTo =
                '${(time.hour + 8).toString().padLeft(2, '0')}:15';
          });
          break;
      }
    }

    // We need this to work around a bug in the picker itself
    DateTime _switch15and45Minutes(DateTime old) {
      switch (old.minute) {
        case 15:
          return DateTime(old.year, old.month, old.day, old.hour, 45);
        case 45:
          return DateTime(old.year, old.month, old.day, old.hour, 15);
        default:
          return old;
      }
    }

    // Will fade in the error Text if _hasError is set to true
    final _errorText = AnimatedOpacity(
      opacity: _showError ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: SizedBox(
          width: 180,
          child: Text(
            _errorMsg,
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.red),
          )),
    );

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
              _errorText,
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
                  _newShift.workTo = '-';
                });
                _checkModified();
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
                _adjustWorkTo(_initial);
                _checkValid();
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _switch15and45Minutes(_initial),
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            _newShift.workFrom =
                                '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                          });
                          _adjustWorkTo(newDateTime);
                          _checkModified();
                          _checkValid();
                        },
                      ));
                    });
              }
            : () {},
        leading: Icon(MdiIcons.briefcaseOutline,
            color:
                _workFromColor == Colors.black ? Colors.grey[800] : Colors.red),
        title: Text('Arbeit von',
            style: TextStyle(fontSize: 16, color: _workFromColor)),
        trailing: Text(_newShift.workFrom,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _workFromColor)));

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
                _checkValid();
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _switch15and45Minutes(_initial),
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
        title: Text('Arbeit bis',
            style: TextStyle(fontSize: 16, color: _workToColor)),
        trailing: Text(_newShift.workTo,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _workToColor)));

    final _breakFromTile = ListTile(
        onLongPress: _editable
            ? () {
                setState(() {
                  _newShift.breakFrom = '-';
                  _newShift.breakTo = '-';
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
                _adjustBreakTo(_initial);
                _checkValid();
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _switch15and45Minutes(_initial),
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            _newShift.breakFrom =
                                '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                          });
                          _adjustBreakTo(newDateTime);
                          _checkModified();
                          _checkValid();
                        },
                      ));
                    });
              }
            : () {},
        leading: Icon(MdiIcons.coffeeOutline,
            color: _breakFromColor == Colors.black
                ? Colors.grey[800]
                : Colors.red),
        title: Text('Pause von',
            style: TextStyle(fontSize: 16, color: _breakFromColor)),
        trailing: Text(_newShift.breakFrom,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _breakFromColor)));

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
                _checkValid();
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _switch15and45Minutes(_initial),
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
        title: Text('Pause bis',
            style: TextStyle(fontSize: 16, color: _breakToColor)),
        trailing: Text(_newShift.breakTo,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _breakToColor)));

    final _comment = Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
            enabled: _editable,
            controller: _commentController,
            keyboardType: TextInputType.text,
            autofocus: false,
            decoration: InputDecoration(
              hintText: _editable ? 'Kommentar' : '',
              icon: Icon(MdiIcons.commentOutline, color: Colors.grey[800]),
              contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
            )));

    final _hoursTile = ListTile(
        leading: Icon(MdiIcons.timerSand, color: Colors.grey[800]),
        title: Text('Stunden', style: TextStyle(fontSize: 16)),
        trailing: Text('${_newShift.hours} h',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _placeTile = ListTile(
        leading: Icon(MdiIcons.mapMarkerOutline, color: Colors.grey[800]),
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
                icon: Icon(MdiIcons.calendarEdit),
                label: Text('Änderungen speichern'),
                onPressed: _modified
                    ? _valid
                        ? () async {
                            await globals.session
                                .updateShift(_selectedTime, _newShift);
                            _dataSent = true;
                            _valid = false;
                            _showError = false;
                            Navigator.pop(context, _dataSent);
                          }
                        : () {
                            setState(() {
                              _showError = true;
                            });
                            _checkValid();
                          }
                    : () {
                        setState(() {
                          _errorMsg = 'Dieser Dienst wurde nicht verändert';
                          _showError = true;
                        });
                      },
              )
            : SizedBox(height: 0)
        : SizedBox(height: 0);

    final _bottomNavBar = BottomAppBar(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: Icon(MdiIcons.arrowLeft),
          onPressed: () {
            _dataSent = false;
            _showError = false;
            _workFromColor = Colors.black;
            _workToColor = Colors.black;
            _breakFromColor = Colors.black;
            _breakToColor = Colors.black;
            Navigator.pop(context, _dataSent);
          },
          tooltip: "Zurück",
        ),
        _editable
            ? IconButton(
                icon: Icon(MdiIcons.deleteOutline),
                onPressed: () async {
                  await globals.session
                      .removeShift(_selectedTime, _initialShift);
                  _dataSent = true;
                  _showError = false;
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
