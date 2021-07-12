import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tribeka/util/globals.dart' as globals;
import 'package:tribeka/util/shift.dart';

class Scrapper {
  static double hoursInMonth = 0;

  void generateUserId(final _response) {
    Document doc = parse(_response.data);
    globals.user.id =
        doc.getElementsByTagName("input").first.attributes.values.elementAt(2);
  }

  bool generateUserPlace(final _response) {
    Document doc = parse(_response.data);
    try {
      globals.user.place = doc
          .getElementsByTagName("option")
          .first
          .attributes
          .values
          .elementAt(0);
      if (globals.user.place == 'Krank') {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  bool isMonthEditable(final _response) {
    Document doc = parse(_response.data);
    if (doc.getElementById("month_ready") != null) {
      return true;
    } else {
      return false;
    }
  }

  double _hoursAsDouble(String hour) {
    List<String> splitted = hour.split(',');
    int main = int.parse(splitted[0]);
    int comma = int.parse(splitted[1]);

    return double.parse('$main.$comma');
  }

  String _getFullWeekday(String shortWeekday) {
    switch (shortWeekday) {
      case 'mo':
        return 'Montag';
      case 'di':
        return 'Dienstag';
      case 'mi':
        return 'Mittwoch';
      case 'do':
        return 'Donnerstag';
      case 'fr':
        return 'Freitag';
      case 'sa':
        return 'Samstag';
      default:
        return 'Sonntag';
    }
  }

  List<Shift> scrapShiftsFromMonth(final _response) {
    hoursInMonth = 0;
    List<Shift> shifts = [];

    Document doc = parse(_response.data, encoding: 'utf8');
    Element tableBody = doc.getElementsByTagName("tbody").first;
    List<Element> tableRows = tableBody.getElementsByTagName("tr");

    for (int i = 0; i < tableRows.length; i++) {
      if (tableRows.elementAt(i).children.first.id == 'add_row') break;

      String _fullDay =
          tableRows.elementAt(i).getElementsByTagName("td").elementAt(0).text;
      String _weekday = _getFullWeekday(_fullDay.substring(0, 2).trim());
      String _day =
          _fullDay.substring(_fullDay.length - 3, _fullDay.length - 1).trim();
      String _workFrom = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(1)
          .text
          .trim();
      String _workTo = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(2)
          .text
          .trim();
      String _breakFrom = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(3)
          .text
          .trim();
      String _breakTo = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(4)
          .text
          .trim();
      String _place = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(5)
          .text
          .trim();
      String _comment = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(6)
          .text
          .trim();
      String _hours = tableRows
          .elementAt(i)
          .getElementsByTagName("td")
          .elementAt(7)
          .text
          .trim();

      hoursInMonth += _hoursAsDouble(_hours);

      shifts.add(Shift(_day, _workFrom, _workTo, _breakFrom, _breakTo, _place,
          _comment, _hours, _weekday));
    }
    return shifts;
  }

  String getDeleteValue(Shift shift, final _response) {
    Document doc = parse(_response.data);
    Element tableBody = doc.getElementsByTagName("tbody").first;
    List<Element> tableRows = tableBody.getElementsByTagName("tr");

    for (int i = 0; i < tableRows.length; i++) {
      Element currentRow = tableRows.elementAt(i);
      if (currentRow.children.first.text.contains(shift.day)) {
        return currentRow
            .children.last.children.first.children.first.attributes.values
            .elementAt(2);
      }
    }
    return 'error';
  }
}
