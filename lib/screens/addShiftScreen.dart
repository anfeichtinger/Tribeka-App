import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:tribeka/services/Validator.dart';
import 'package:tribeka/util/AddShiftListTileArgs.dart';
import 'package:tribeka/util/AddShiftScreenArgs.dart';
import 'package:tribeka/util/Globals.dart' as globals;
import 'package:tribeka/util/Shift.dart';
import 'package:tribeka/util/TagHandler.dart';
import 'package:tribeka/widgets/CustomAppBar.dart';
import 'package:tribeka/widgets/CustomSelectableTags.dart';

class AddShiftScreen extends StatefulWidget {
  static final routeName = '/Month/AddShift';

  @override
  State createState() => AddShiftScreenState();
}

class AddShiftScreenState extends State<AddShiftScreen>
    with TickerProviderStateMixin {
  static bool _dataSent = false;
  static bool _hasError = false;
  static String _dayText = DateTime.now().day.toString();
  List<Tag> _templates = [];
  Shift _shift = Shift(_dayText, '-', '-', '-', '-', globals.user.place, '');
  final _commentController = TextEditingController();

  AnimationController _validationController;
  Animation<Offset> _validationOffset;

  @override
  void initState() {
    _validationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));

    _validationOffset =
        Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero)
            .animate(_validationController);

    _hasError = false;
    _dataSent = false;

    TagHandler().getTags().then((newList) {
      setState(() {
        _templates = newList;
      });
    });

    _commentController.addListener(() {
      _shift.comment = _commentController.text;
    });

    super.initState();
  }

  Widget _buildValidationMsg() {
    if (_hasError) {
      return Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
              position: _validationOffset,
              child: Container(
                  height: 45,
                  width: double.infinity,
                  color: Colors.red,
                  padding: EdgeInsets.all(0.0),
                  child: Center(
                      child: Text('Bitte überprüfe deine Eingaben!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0))))));
    } else
      return SizedBox(
        height: 0,
      );
  }

  @override
  Widget build(BuildContext context) {
    // We pass the month and year we are in
    final AddShiftScreenArgs _args = ModalRoute.of(context).settings.arguments;
    // Hide the FAB when the keyboard is open to avoid clipping
    final bool _showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    final Color _iconColor = Colors.grey[800];

    _showPickerDate(BuildContext context) {
      Picker(
          textStyle: TextStyle(fontSize: 24, color: Colors.black),
          height: 200,
          hideHeader: true,
          columnPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          adapter: DateTimePickerAdapter(
            value: _args.time.day.toString() == _shift.day
                ? _args.time
                : DateTime(
                    _args.time.year, _args.time.month, int.parse(_shift.day)),
            customColumnType: [2],
          ),
          onSelect: (Picker picker, int i, List value) {
            setState(() {
              _shift.day = (value.last + 1).toString();
            });
          }).showModal(context);
    }

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

    ListTile _buildRow(DateTime initial, AddShiftListTileArgs args) {
      return ListTile(
          onTap: () {
            args.callback(initial);
            showCupertinoModalPopup(
                context: context,
                builder: (BuildContext context) {
                  return _buildBottomPicker(CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initial,
                    use24hFormat: true,
                    minuteInterval: 15,
                    onDateTimeChanged: (DateTime newDateTime) {
                      args.callback(newDateTime);
                    },
                  ));
                });
          },
          onLongPress: args.longCallback,
          title: Text(args.label),
          leading: Icon(args.iconData, color: _iconColor),
          trailing: Text(
            args.value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ));
    }

    final _dayRow = ListTile(
        onTap: () {
          _showPickerDate(context);
        },
        onLongPress: () {},
        title: Text('Kalendertag'),
        leading: Icon(Icons.today, color: _iconColor),
        trailing: Text(
          '${_shift.day}.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ));

    DateTime _getInitialWorkFromTime() {
      if (_shift.workFrom == '-') {
        return DateTime(
            _args.time.year, _args.time.month, _args.time.day, 12, 0);
      } else {
        return DateTime(
            _args.time.year,
            _args.time.month,
            _args.time.day,
            int.parse(_shift.workFrom.split(':')[0]),
            int.parse(_shift.workFrom.split(':')[1]));
      }
    }

    final _workFromRow = _buildRow(
        _getInitialWorkFromTime(),
        AddShiftListTileArgs(
            label: 'Arbeit von',
            iconData: Icons.work,
            value: _shift.workFrom,
            callback: (dateTime) {
              setState(() {
                _shift.workFrom =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
              });
            },
            longCallback: () {
              setState(() {
                _shift.workFrom = '-';
              });
            }));

    DateTime _getInitialWorkToTime() {
      if (_shift.workTo == '-') {
        return DateTime(
            _args.time.year, _args.time.month, _args.time.day, 12, 0);
      } else {
        return DateTime(
            _args.time.year,
            _args.time.month,
            _args.time.day,
            int.parse(_shift.workTo.split(':')[0]),
            int.parse(_shift.workTo.split(':')[1]));
      }
    }

    final _workToRow = _buildRow(
        _getInitialWorkToTime(),
        AddShiftListTileArgs(
            label: 'Arbeit bis',
            iconData: null,
            value: _shift.workTo,
            callback: (dateTime) {
              setState(() {
                _shift.workTo =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
              });
            },
            longCallback: () {
              setState(() {
                _shift.workTo = '-';
              });
            }));

    DateTime _getInitialBreakFromTime() {
      if (_shift.breakFrom == '-') {
        return DateTime(
            _args.time.year, _args.time.month, _args.time.day, 12, 0);
      } else {
        return DateTime(
            _args.time.year,
            _args.time.month,
            _args.time.day,
            int.parse(_shift.breakFrom.split(':')[0]),
            int.parse(_shift.breakFrom.split(':')[1]));
      }
    }

    final _breakFromRow = _buildRow(
        _getInitialBreakFromTime(),
        AddShiftListTileArgs(
            label: 'Pause von',
            iconData: Icons.free_breakfast,
            value: _shift.breakFrom,
            callback: (dateTime) {
              setState(() {
                _shift.breakFrom =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                switch (dateTime.minute) {
                  case 0:
                  case 15:
                    setState(() {
                      _shift.breakTo =
                          '${dateTime.hour.toString().padLeft(2, '0')}:${(dateTime.minute + 30).toString().padLeft(2, '0')}';
                    });
                    break;
                  case 30:
                    setState(() {
                      _shift.breakTo =
                          '${(dateTime.hour + 1).toString().padLeft(2, '0')}:00';
                    });
                    break;
                  case 45:
                    setState(() {
                      _shift.breakTo =
                          '${(dateTime.hour + 1).toString().padLeft(2, '0')}:15';
                    });
                    break;
                }
              });
            },
            longCallback: () {
              setState(() {
                _shift.breakFrom = '-';
              });
            }));

    DateTime _getInitialBreakToTime() {
      if (_shift.breakTo == '-') {
        return DateTime(
            _args.time.year, _args.time.month, _args.time.day, 12, 0);
      } else {
        return DateTime(
            _args.time.year,
            _args.time.month,
            _args.time.day,
            int.parse(_shift.breakTo.split(':')[0]),
            int.parse(_shift.breakTo.split(':')[1]));
      }
    }

    final _breakToRow = _buildRow(
        _getInitialBreakToTime(),
        AddShiftListTileArgs(
            label: 'Pause bis',
            iconData: null,
            value: _shift.breakTo,
            callback: (dateTime) {
              setState(() {
                _shift.breakTo =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
              });
            },
            longCallback: () {
              setState(() {
                _shift.breakTo = '-';
              });
            }));

    final _comment = Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
            controller: _commentController,
            keyboardType: TextInputType.text,
            autofocus: false,
            decoration: InputDecoration(
              icon: Icon(Icons.comment, color: _iconColor),
              hintText: 'Kommentar',
              contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            )));

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
      }
    }

    Widget _getTagWidgets() {
      if (_templates.length == 0) {
        return Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: <Widget>[
              Image.asset('assets/no_template_found.png', height: 152),
            ]));
      } else {
        return SelectableTags(
          tags: _templates,
          backgroundContainer: Colors.transparent,
          activeColor: _iconColor,
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

    _addTag() async {
      setState(() {
        _templates.add(Tag(title: _shift.comment));
      });
      await TagHandler().persistTag(_shift);
      setState(() {
        _commentController.clear();
      });
    }

    Widget _templateContainer() {
      return Column(children: <Widget>[
        SizedBox(height: 6),
        Text('Vorlagen',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _getTagWidgets()
      ]);
    }

    final _fab = FloatingActionButton.extended(
        backgroundColor: Colors.grey[850],
        elevation: 4.0,
        icon: Icon(Icons.check),
        label: Text('Senden'),
        onPressed: () {
          if (Validator.validateShift(_shift)) {
            _validationController.reverse().then((v) {
              setState(() {
                _hasError = false;
              });
            });
            globals.session.sendShift(_args.time, _shift).then((result) {
              _dataSent = true;
              Navigator.pop(context, _dataSent);
            });
          } else {
            setState(() {
              _hasError = true;
            });
            _validationController.forward();
          }
        });

    final _bottomNavBar = BottomAppBar(
        child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, false);
            },
            tooltip: "Zurück",
          ),
          IconButton(
              icon: Icon(Icons.save),
              tooltip: "Als neue Vorlage speichern",
              onPressed: () {
                if (Validator.validateShift(_shift) &&
                    _commentController.text.isNotEmpty) {
                  _validationController.reverse().then((v) {
                    setState(() {
                      _hasError = false;
                    });
                  });
                  _addTag();
                } else {
                  setState(() {
                    _hasError = true;
                  });
                  _validationController.forward();
                }
              })
        ]));

    return Scaffold(
        appBar: CustomAppBar.dark,
        bottomNavigationBar: _bottomNavBar,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _showFab ? _fab : null,
        // Catch pop events and set callback value.
        // Main purpose is to override the back button to avoid passing null as callback.
        body: WillPopScope(
            onWillPop: () {
              Navigator.pop(context, _dataSent);
            },
            child: Container(
                child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: <Widget>[
                  _buildValidationMsg(),
                  _dayRow,
                  Container(color: Colors.grey[300], height: 1),
                  _workFromRow,
                  _workToRow,
                  Container(color: Colors.grey[300], height: 1),
                  _breakFromRow,
                  _breakToRow,
                  Container(color: Colors.grey[300], height: 1),
                  _comment,
                  Container(color: Colors.grey[300], height: 1),
                  _templateContainer()
                ]))));
  }
}
