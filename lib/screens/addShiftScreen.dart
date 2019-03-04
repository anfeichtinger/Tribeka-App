import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tags/selectable_tags.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:tribeka/utils/Shift.dart';
import 'package:tribeka/utils/Globals.dart' as globals;
import 'package:tribeka/utils/TagHandler.dart';

class AddShiftScreen extends StatefulWidget {
  @override
  State createState() => AddShiftScreenState();
}

class AddShiftScreenState extends State<AddShiftScreen> {
  String _dayText = DateTime.now().day.toString();
  String _workFromText = "-";
  String _workToText = "-";
  String _breakFromText = "-";
  String _breakToText = "-";
  String _commentText = "";
  List<Tag> _templates = [];

  @override
  void initState() {
    super.initState();

    TagHandler().getTags().then((newList) {
      setState(() {
        _templates = newList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Neuer Dienst",
          style: TextStyle(fontFamily: 'Tribeka', fontSize: 28.0),
        ),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 12)),
            InkWell(
              onTap: () {
                _showDayPicker();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Tag",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text("$_dayText.", style: TextStyle(fontSize: 18))
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                if (_workFromText == "-")
                  setState(() {
                    _workFromText = "06:30";
                  });
                DateTime now = DateTime.now();
                showCupertinoModalPopup<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildBottomPicker(
                      CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _workFromText == "-"
                            ? DateTime(now.year, now.month, now.day, 15, 0)
                            : DateTime(
                                now.year,
                                now.month,
                                now.day,
                                int.parse(_workFromText.split(":")[0]),
                                _getMinuteForPicker(_workFromText)),
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() => _workFromText =
                              "${newDateTime.hour.toString().padLeft(2, "0")}:${newDateTime.minute.toString().padLeft(2, "0")}");
                        },
                      ),
                    );
                  },
                );
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Arbeit von",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(_workFromText, style: TextStyle(fontSize: 18))
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                if (_workToText == "-")
                  setState(() {
                    _workToText = "15:00";
                  });
                DateTime now = DateTime.now();
                showCupertinoModalPopup<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildBottomPicker(
                      CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _workToText == "-"
                            ? DateTime(now.year, now.month, now.day, 15, 0)
                            : DateTime(
                                now.year,
                                now.month,
                                now.day,
                                int.parse(_workToText.split(":")[0]),
                                _getMinuteForPicker(_workToText)),
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() => _workToText =
                              "${newDateTime.hour.toString().padLeft(2, "0")}:${newDateTime.minute.toString().padLeft(2, "0")}");
                        },
                      ),
                    );
                  },
                );
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Arbeit bis",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(_workToText, style: TextStyle(fontSize: 18))
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                if (_breakFromText == "-")
                  setState(() {
                    _breakFromText = "11:00";
                  });
                DateTime now = DateTime.now();
                showCupertinoModalPopup<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildBottomPicker(
                      CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _breakFromText == "-"
                            ? DateTime(now.year, now.month, now.day, 15, 0)
                            : DateTime(
                                now.year,
                                now.month,
                                now.day,
                                int.parse(_breakFromText.split(":")[0]),
                                _getMinuteForPicker(_breakFromText)),
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() => _breakFromText =
                              "${newDateTime.hour.toString().padLeft(2, "0")}:${newDateTime.minute.toString().padLeft(2, "0")}");
                        },
                      ),
                    );
                  },
                );
              },
              onLongPress: () => setState(() {
                    _breakFromText = "-";
                  }),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Pause von",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(_breakFromText, style: TextStyle(fontSize: 18))
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                if (_breakToText == "-")
                  setState(() {
                    _breakToText = "11:30";
                  });
                DateTime now = DateTime.now();
                showCupertinoModalPopup<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildBottomPicker(
                      CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _breakToText == "-"
                            ? DateTime(now.year, now.month, now.day, 15, 0)
                            : DateTime(
                                now.year,
                                now.month,
                                now.day,
                                int.parse(_breakToText.split(":")[0]),
                                _getMinuteForPicker(_breakToText)),
                        use24hFormat: true,
                        minuteInterval: 15,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() => _breakToText =
                              "${newDateTime.hour.toString().padLeft(2, "0")}:${newDateTime.minute.toString().padLeft(2, "0")}");
                        },
                      ),
                    );
                  },
                );
              },
              onLongPress: () => setState(() {
                    _breakToText = "-";
                  }),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Pause bis",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(_breakToText, style: TextStyle(fontSize: 18))
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: TextField(
                          autofocus: false,
                          textAlign: TextAlign.center,
                          decoration: new InputDecoration(
                            hintText: 'Kommentar',
                            contentPadding:
                                EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                          ),
                          onChanged: (content) =>
                              _commentText = content.trim())),
                ],
              ),
            ),
            Divider(),
            Text(
              "Vorlagen",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tribeka',
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 16),
            getTagsWidget()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4.0,
        icon: Icon(Icons.check),
        label: Text('Senden'),
        onPressed: () {
          //Todo: Check for valid input
          if (_validInput()) {
            postNewShift();
          }
          debugPrint({
            "pEmpId": globals.empId,
            "pYear": globals.selYear,
            "pMonth": globals.selMonth,
            "pWorkDay": _dayText,
            "pWorkFrom": _workFromText,
            "pWorkTo": _workToText,
            "pWorkBreakFrom": _breakFromText,
            "pWorkBreakTo": _breakToText,
            "pWorkBranch": globals.defBranch,
            "pWorkRemark": _commentText,
            "submit": "speichern"
          }.toString());
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
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
                addTag();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget getTagsWidget() {
    if (_templates.length == 0) {
      return Text(
        "Keine Vorlagen vorhandten!\n\nUm eine neue Vorlage anzulegen gib die gewünschten Zeiten oben ein und schreibe in das Kommentarfeld den Namen den die Vorlage bekommen soll. Dann kannst du diese mit dem Knopf rechts unten hinzufügen.",
        textAlign: TextAlign.center,
      );
    } else {
      return SelectableTags(
        tags: _templates,
        backgroundContainer: Color(0xFFFAFAFA),
        activeColor: Color(0xFF444444),
        onPressed: (tag) {
          applyTemplate(tag);
/*
          _templates.remove(tag);
          TagHandler().deletePersistedTag(tag.title);
*/
        },
      );
    }
  }

  applyTemplate(Tag tag) async {
    tag.active = true;
    Shift shift = await TagHandler().getPersistedShift(tag.title);

    if (shift == null) {
      setState(() {
        _workFromText = "-";
        _workToText = "-";
        _breakFromText = "-";
        _breakToText = "-";
      });
    } else {
      setState(() {
        _workFromText = shift.workFrom;
        _workToText = shift.workTo;
        _breakFromText = shift.breakFrom;
        _breakToText = shift.breakTo;
      });
    }
  }

  addTag() {
    setState(() {
      _templates.add(Tag(title: _commentText));
    });
    TagHandler().persistTag(Shift(_dayText, _workFromText, _workToText,
        _breakFromText, _breakToText, globals.defBranch, _commentText));
  }

  Future _showDayPicker() async {
    //Todo: redo as cupertino picker
    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return new NumberPickerDialog.integer(
          minValue: 1,
          maxValue: 31,
          initialIntegerValue: DateTime.now().day,
          title: new Text("Tag auswählen"),
        );
      },
    ).then((newValue) {
      setState(() {
        if (newValue != null) {
          _dayText = newValue.toString();
        }
      });
    });
  }

  Widget _buildBottomPicker(Widget picker) {
    return Container(
      height: 216.0,
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

  bool _validInput() {
    //Todo: Implement
    return true;
  }

  postNewShift() async {
    await globals.session
        .post(globals.baseURL + globals.hoursURL + globals.monthURL, {
      "pEmpId": globals.empId,
      "pYear": globals.selYear,
      "pMonth": globals.selMonth,
      "pWorkDay": _dayText,
      "pWorkFrom": _workFromText,
      "pWorkTo": _workToText,
      "pWorkBreakFrom": _breakFromText == "-" ? "" : _breakFromText,
      "pWorkBreakTo": _breakToText == "-" ? "" : _breakToText,
      "pWorkBranch": globals.defBranch,
      "pWorkRemark": _commentText,
      "submit": "speichern"
    }).then((result) {
      Navigator.pop(context, true);
    });
  }

  int _getMinuteForPicker(String time) {
    switch (int.parse(time.split(":")[1])) {
      case 15:
        return 45;
      case 45:
        return 15;
      case 0:
      case 30:
        return int.parse(time.split(":")[1]);
      default:
        return 0;
    }
  }
}
