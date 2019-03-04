import 'package:flutter/material.dart';
import 'package:tribeka/screens/LoginScreen.dart';
import 'package:tribeka/screens/ShiftRow.dart';
import 'package:tribeka/screens/addShiftScreen.dart';
import 'package:tribeka/utils/Globals.dart' as globals;
import 'package:tribeka/utils/Shift.dart';

class MonthScreen extends StatefulWidget {
  @override
  State createState() => new MonthScreenState();
}

class MonthScreenState extends State<MonthScreen> {
  List<String> _yearsAvail;
  List<String> _monthNames = [
    "Jänner",
    "Februar",
    "März",
    "April",
    "Mai",
    "Juni",
    "Juli",
    "August",
    "September",
    "Oktober",
    "November",
    "Dezember"
  ];
  String _selectedMonth;
  List<Shift> _shifts;
  bool _isLoaded;
  bool _monthEditable;

  @override
  void initState() {
    connect().then((result) {
      setState(() {
        _isLoaded = result;
      });
    });
    super.initState();
  }

  connect() async {
    if (globals.session.url == "http://intra.tribeka.at/stunden/") {
      _yearsAvail = globals.session.getYearsAvail();

      DateTime now = new DateTime.now();
      _selectedMonth = _monthNames.elementAt(now.month - 1);
      globals.selMonth = now.month.toString();
      globals.selYear =
          _yearsAvail.singleWhere((year) => year == now.year.toString());
      globals.empId = globals.session.getEmpID();
      debugPrint("Employee: ${globals.empId}");
      debugPrint(
          "Month: $_selectedMonth (Web: ${globals.selMonth}), Year: ${globals.selYear}");
      return await loadMonth();
    } else {
      logout();
    }
  }

  loadMonth() async {
    await globals.session.get(globals.baseURL + globals.hoursURL);
    debugPrint(globals.session.url);
    await globals.session
        .post(globals.baseURL + globals.hoursURL + globals.monthURL, {
      "pEmpId": globals.empId,
      "pMonth": globals.selMonth,
      "pYear": globals.selYear,
      "submit": "jetzt zeigen"
    });
    debugPrint(globals.session.url);
    if (_shifts != null) {
      if (_shifts.isNotEmpty) _shifts.removeRange(0, _shifts.length - 1);
    }
    _shifts = globals.session.getShifts();
    _monthEditable = globals.session.isMonthEditable();
    if (_monthEditable) {
      globals.defBranch = globals.session.getBranch();
    }
    setState(() {
      _isLoaded = true;
    });
    return _isLoaded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded == null) {
      return Scaffold(
          appBar: new AppBar(
            centerTitle: true,
            title: new Text(
              "tribeka",
              style: TextStyle(fontFamily: 'Tribeka', fontSize: 30.0),
            ),
          ),
          body: new Center(
            child: new CircularProgressIndicator(),
          ));
    } // If Data is loaded!
    return Scaffold(
      appBar: new AppBar(
        centerTitle: true,
        title: new Text(
          "tribeka",
          style: TextStyle(fontFamily: 'Tribeka', fontSize: 30.0),
        ),
      ),
      body: new Container(
          child: new Column(
        children: <Widget>[
          new Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 36),
                child: new DropdownButton(
                  value: _selectedMonth,
                  onChanged: (newMonth) {
                    _isLoaded = null;
                    globals.selMonth =
                        (_monthNames.indexOf(newMonth.toString()) + 1)
                            .toString();
                    debugPrint("Selected ${globals.selMonth}");
                    setState(() {
                      _selectedMonth = newMonth;
                    });
                    loadMonth();
                  },
                  items:
                      _monthNames.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 36),
                child: new DropdownButton(
                  value: globals.selYear,
                  onChanged: (newYear) {
                    _isLoaded = null;
                    setState(() {
                      globals.selYear = newYear;
                    });
                    debugPrint("Selected ${globals.selYear}");
                    loadMonth();
                  },
                  items:
                      _yearsAvail.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
          new Expanded(
              child: new ScrollConfiguration(
                  behavior: MyBehavior(), // No Scroll Effect
                  child: _shifts.length == 0
                      ? Text("Bisher wurden keine Dienste hinzugefügt!")
                      : new ListView.builder(
                          itemCount: _shifts.length,
                          itemBuilder: (BuildContext context, int index) {
                            return new ShiftRow(_shifts.elementAt(index));
                          })))
        ],
      )),
      floatingActionButton: _monthEditable
          ? FloatingActionButton.extended(
              elevation: 4.0,
              icon: const Icon(Icons.add),
              label: const Text('Dienst hinzufügen'),
              onPressed: () {
                _newShiftCallback(context);
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: logout,
              tooltip: "Abmelden",
            ),
            _monthEditable
                ? IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      finishMonth();
                    },
                    tooltip: "Monat fertigstellen",
                  )
                : Text(""),
          ],
        ),
      ),
    );
  }

  _newShiftCallback(BuildContext context) async {
    // Navigator.push returns a Future that will complete after we call
    // Navigator.pop on the Selection Screen!
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddShiftScreen()),
    );
    if (result) {
      globals.session.stopPing();
      loadMonth();
      globals.session.startPing();
    }
  }

  logout() {
    showDialog(
      context: context,
      child: new AlertDialog(
        title: const Text("Abmelden"),
        content: const Text("Bist du dir sicher dass du dich abmelden willst?"),
        actions: [
          new FlatButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ABBRECHEN")),
          new FlatButton(
            child: const Text("JA"),
            onPressed: () {
              globals.storage.write(key: "email", value: "");
              globals.storage.write(key: "password", value: "");
              globals.autoLogin = false;
              globals.session.stopPing();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  finishMonth() async {
    showDialog(
      context: context,
      child: new AlertDialog(
        title: const Text("Monat Fertigstellen"),
        content: const Text(
            "Bist du dir sicher dass du den Monat diesen fertigstellen willst?\n\nDas kann nicht rückgängig gemacht werden."),
        actions: [
          new FlatButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ABBRECHEN")),
          new FlatButton(
              child: const Text("JA"),
              onPressed: () {
                /*
                globals.session.stopPing();
                finishMonthPost();
                loadMonth();
                globals.session.startPing();
                */
              }
              //Todo: Activate finishMonthPost() it's disabled for now so I don't unintentionally finish a month... again
              ),
        ],
      ),
    );
  }

  finishMonthPost() async {
    await globals.session
        .post(globals.baseURL + globals.hoursURL + globals.monthURL, {
      "pEmpId": globals.empId,
      "pYear": globals.selYear,
      "pMonth": globals.selMonth,
      "submit": "monat jetzt fertigstellen"
    }).then((onValue) {
      Navigator.pop(context);
    });
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
