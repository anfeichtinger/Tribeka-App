import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tribeka/services/InitTimeGenerator.dart';
import 'package:tribeka/services/Validator.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/util/TagHandler.dart';
import 'package:tribeka/widgets/CustomAppBar.dart';
import 'package:tribeka/widgets/CustomSelectableTags.dart';

class AddShiftScreen extends StatefulWidget {
  final DateTime _selectedTime;
  final List<int> _presentDates;

  AddShiftScreen(this._selectedTime, this._presentDates);

  @override
  State createState() {
    return AddShiftScreenState(_selectedTime, _presentDates);
  }
}

class AddShiftScreenState extends State<AddShiftScreen> {
  final List<int> _presentDates;
  static DateTime _now;
  static Shift _shift;
  static List<Tag> _templates = [];
  static bool _dataSent = false;
  static bool _valid = false;
  static TextEditingController _commentController;

  AddShiftScreenState(DateTime _selectedTime, this._presentDates) {
    _now =
        DateTime(_selectedTime.year, _selectedTime.month, DateTime.now().day);
    _shift =
        Shift(_now.day.toString(), '-', '-', '-', '-', globals.user.place, '');
    while (_presentDates.contains(int.parse(_shift.day))) {
      _shift.day = (int.parse(_shift.day) + 1).toString();
    }
  }

  void _checkValid() {
    // Todo: Error messages so the user knows what is wrong
    if (Validator.validateShift(_shift) &&
        !_presentDates.contains(int.parse(_shift.day))) {
      setState(() {
        _valid = true;
      });
    } else {
      setState(() {
        _valid = false;
      });
    }
  }

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
        .copyWith(statusBarIconBrightness: Brightness.dark));
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));

    _dataSent = false;
    _valid = false;

    TagHandler().getTags().then((newList) {
      setState(() {
        _templates = newList;
      });
    });
    _commentController = TextEditingController();

    _commentController.text = _shift.comment;
    _commentController.addListener(() {
      _shift.comment = _commentController.text;
    });

    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

    _applyTemplate(Tag tag) async {
      tag.active = true;
      Shift shift = await TagHandler().getPersistedShift(tag.title);

      if (shift == null) {
        setState(() {
          _shift.workFrom = "-";
          _shift.workTo = "-";
          _shift.breakFrom = "-";
          _shift.breakTo = "-";
        });
      } else {
        setState(() {
          _shift.workFrom = shift.workFrom;
          _shift.workTo = shift.workTo;
          _shift.breakFrom = shift.breakFrom;
          _shift.breakTo = shift.breakTo;
        });
        _checkValid();
      }
    }

    _addTag(String title) {
      setState(() {
        _templates.add(Tag(title: title));
      });
      TagHandler().persistTag(_shift, title);
    }

    Widget _getTagWidgets() {
      if (_templates.length == 0) {
        return SizedBox(height: 0);
      } else {
        return SelectableTags(
          tags: _templates,
          backgroundContainer: Colors.transparent,
          activeColor: Colors.grey[800],
          onPressed: (tag) {
            _applyTemplate(tag);
          },
          onLongPressed: (tag) {
            setState(() {
              _templates.remove(tag);
            });
            TagHandler().deletePersistedTag(tag.title);
          },
        );
      }
    }

    _showPickerDate(BuildContext context) {
      Picker(
          textStyle: TextStyle(fontSize: 24, color: Colors.black),
          height: 200,
          hideHeader: true,
          columnPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          adapter: DateTimePickerAdapter(
            value: _now.day.toString() == _shift.day
                ? _now
                : DateTime(_now.year, _now.month, int.parse(_shift.day)),
            customColumnType: [2],
          ),
          onSelect: (Picker picker, int i, List value) {
            setState(() {
              _shift.day = (value.last + 1).toString();
            });
            _checkValid();
          }).showModal(context);
    }

    _showAddTemplatePrompt() async {
      String _title = '';
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            title: Text("Vorlage benennen"),
            content: TextField(autofocus: true, onChanged: (s) => _title = s),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("ABBRECHEN")),
              FlatButton(
                  child: Text("JA"),
                  onPressed: () {
                    Navigator.pop(context, true);
                  })
            ],
          );
        },
      );
      if (result) {
        _addTag(_title);
      }
    }

    _setBreakFromMinute(DateTime time) {
      switch (time.minute) {
        case 0:
        case 15:
          setState(() {
            _shift.breakTo =
                '${time.hour.toString().padLeft(2, '0')}:${(time.minute + 30).toString().padLeft(2, '0')}';
          });
          break;
        case 30:
          setState(() {
            _shift.breakTo = '${(time.hour + 1).toString().padLeft(2, '0')}:00';
          });
          break;
        case 45:
          setState(() {
            _shift.breakTo = '${(time.hour + 1).toString().padLeft(2, '0')}:15';
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

    final _header = Padding(
        child: Text(DateFormat('MMMM, yyyy').format(_now),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        padding: EdgeInsets.symmetric(horizontal: 16));

    final _dayTile = ListTile(
        onTap: () => _showPickerDate(context),
        leading: Icon(MdiIcons.calendarToday, color: Colors.grey[800]),
        title: Text('Kalendertag', style: TextStyle(fontSize: 16)),
        trailing: Text('${_shift.day}.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _workFromTile = ListTile(
        onLongPress: () {
          setState(() {
            _shift.workFrom = '-';
          });
          _checkValid();
        },
        onTap: () {
          final _initial = InitTimeGenerator.workFrom(_now, _shift);
          setState(() {
            _shift.workFrom =
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
                      _shift.workFrom =
                          '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                    });
                    _checkValid();
                  },
                ));
              });
        },
        leading: Icon(MdiIcons.briefcaseOutline, color: Colors.grey[800]),
        title: Text('Arbeit von', style: TextStyle(fontSize: 16)),
        trailing: Text(_shift.workFrom,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _workToTile = ListTile(
        onLongPress: () {
          setState(() {
            _shift.workTo = '-';
          });
          _checkValid();
        },
        onTap: () {
          final _initial = InitTimeGenerator.workTo(_now, _shift);
          setState(() {
            _shift.workTo =
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
                      _shift.workTo =
                          '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                    });
                    _checkValid();
                  },
                ));
              });
        },
        leading: Icon(null),
        title: Text('Arbeit bis', style: TextStyle(fontSize: 16)),
        trailing: Text(_shift.workTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _breakFromTile = ListTile(
        onLongPress: () {
          setState(() {
            _shift.breakFrom = '-';
          });
          _checkValid();
        },
        onTap: () {
          final _initial = InitTimeGenerator.breakFrom(_now, _shift);
          setState(() {
            _shift.breakFrom =
                '${_initial.hour.toString().padLeft(2, '0')}:${_initial.minute.toString().padLeft(2, '0')}';
          });
          _setBreakFromMinute(_initial);
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
                      _shift.breakFrom =
                          '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                    });
                    _setBreakFromMinute(newDateTime);
                    _checkValid();
                  },
                ));
              });
        },
        leading: Icon(MdiIcons.coffeeOutline, color: Colors.grey[800]),
        title: Text('Pause von', style: TextStyle(fontSize: 16)),
        trailing: Text(_shift.breakFrom,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _breakToTile = ListTile(
        onLongPress: () {
          setState(() {
            _shift.breakTo = '-';
          });
          _checkValid();
        },
        onTap: () {
          final _initial = InitTimeGenerator.breakTo(_now, _shift);
          setState(() {
            _shift.breakTo =
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
                      _shift.breakTo =
                          '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                    });
                    _checkValid();
                  },
                ));
              });
        },
        leading: Icon(null),
        title: Text('Pause bis', style: TextStyle(fontSize: 16)),
        trailing: Text(_shift.breakTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    final _comment = Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
            controller: _commentController,
            keyboardType: TextInputType.text,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Kommentar',
              icon: Icon(MdiIcons.commentOutline, color: Colors.grey[800]),
              contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
            )));

    final _divider = SizedBox(
        height: 1.0,
        child: Center(
            child: Container(
                margin: EdgeInsetsDirectional.only(start: 32.0, end: 32.0),
                height: 1.0,
                color: Colors.grey[500])));

    final _fab = _showFab
        ? FloatingActionButton.extended(
            elevation: 4.0,
            backgroundColor: _valid ? Colors.grey[850] : Colors.grey[600],
            icon: Icon(MdiIcons.cloudUploadOutline),
            label: Text('Senden'),
            onPressed: _valid
                ? () async {
                    await globals.session.updateShift(_now, _shift);
                    _dataSent = true;
                    _valid = false;
                    Navigator.pop(context, _dataSent);
                  }
                : null,
          )
        : SizedBox(height: 0);

    final _bottomNavBar = BottomAppBar(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: Icon(MdiIcons.arrowLeft),
          onPressed: () {
            _dataSent = false;
            _valid = false;
            Navigator.pop(context, _dataSent);
          },
          tooltip: "Zurück",
        ),
        IconButton(
            icon: Icon(MdiIcons.contentSaveOutline),
            onPressed: () async {
              if (_valid) {
                _showAddTemplatePrompt();
              }
            },
            tooltip: "Vorlage speichern"),
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
              _valid = false;
              Navigator.pop(context, _dataSent);
            },
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: <Widget>[
                      SizedBox(height: 34),
                      _header,
                      SizedBox(height: 22),
                      _dayTile,
                      SizedBox(height: 9.5),
                      _divider,
                      SizedBox(height: 9.5),
                      _workFromTile,
                      _workToTile,
                      SizedBox(height: 9.5),
                      _divider,
                      SizedBox(height: 9.5),
                      _breakFromTile,
                      _breakToTile,
                      SizedBox(height: 16),
                      _comment,
                      SizedBox(height: 16),
                      _getTagWidgets(),
                      SizedBox(height: 16),
                    ]))));
  }
}
