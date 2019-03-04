import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:threading/threading.dart';
import 'package:tribeka/utils/Shift.dart';

class Session {
  static final Session _session = new Session.internal();

  factory Session() {
    return _session;
  }

  Session.internal();

  Map<String, String> headers = {};
  http.Response _response;
  String url;
  bool loop;
  Thread pingThread;

  http.Response get response => _response;

  Future<http.Response> get(String url) async {
    _response = await http.get(url, headers: headers);
    updateCookie();
    this.url = url;
    return _response;
  }

  Future<http.Response> post(String url, dynamic data) async {
    _response = await http.post(url, body: data, headers: headers);
    updateCookie();
    this.url = url;
    return _response;
  }

  startPing() async {
    loop = true;
    pingThread = new Thread(() async {
      while (loop) {
        Thread.sleep(180000);
        await get(url);
      }
    });
    pingThread.start();
  }

  stopPing() {
    loop = false;
    pingThread.join();
  }

  getErrorMessage() {
    Document doc = parse(_response.body);
    Element errorMsg = doc.getElementsByTagName("li").first;
    return errorMsg.outerHtml.substring(4, errorMsg.outerHtml.length - 5);
  }

  getHtml() {
    Document doc = parse(_response.body);
    return doc.outerHtml;
  }

  updateCookie() {
    String rawCookie = _response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  List<String> getMonthsAvail() {
    Document doc = parse(_response.body);
    List<Element> monthOptions =
        doc.getElementsByTagName("select").first.getElementsByTagName("option");
    List<String> options = new List();
    for (Element optionElem in monthOptions) {
      options.add(optionElem.attributes.values.first);
    }
    return options;
  }

  List<String> getMonthNamesAvail() {
    Document doc = parse(_response.body);
    List<Element> monthOptions =
        doc.getElementsByTagName("select").first.getElementsByTagName("option");
    List<String> options = new List();
    for (Element optionElem in monthOptions) {
      options.add(optionElem.text);
    }
    return options;
  }

  List<String> getYearsAvail() {
    Document doc = parse(_response.body);
    List<Element> monthOptions = doc
        .getElementsByTagName("select")
        .elementAt(1)
        .getElementsByTagName("option");
    List<String> options = new List();
    for (Element optionElem in monthOptions) {
      options.add(optionElem.attributes.values.first);
    }
    return options;
  }

  bool isMonthEditable() {
    Document doc = parse(_response.body);
    if (doc.getElementById("month_ready") != null) {
      return true;
    } else {
      return false;
    }
  }

  String getEmpID() {
    Document doc = parse(_response.body);
    return doc
        .getElementsByTagName("input")
        .first
        .attributes
        .values
        .elementAt(2);
  }

  String getBranch() {
    Document doc = parse(_response.body);
    return doc
        .getElementsByTagName("option")
        .first
        .attributes
        .values
        .elementAt(0);
  }

  List<Shift> getShifts() {
    List<Shift> shifts = new List();

    Document doc = parse(_response.body);
    Element tableBody = doc.getElementsByTagName("tbody").first;
    List<Element> tableRows = tableBody.getElementsByTagName("tr");

    for (int i = 0; i < tableRows.length - 1; i++) {
      String _fullDay =
          tableRows.elementAt(i).getElementsByTagName("td").elementAt(0).text;
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
      String _place =
          tableRows.elementAt(i).getElementsByTagName("td").elementAt(5).text;
      String _comment =
          tableRows.elementAt(i).getElementsByTagName("td").elementAt(6).text;
      String _hours =
          tableRows.elementAt(i).getElementsByTagName("td").elementAt(7).text;

      shifts.add(new Shift(_day, _workFrom, _workTo, _breakFrom, _breakTo,
          _place, _comment, _hours));
    }
    return shifts;
  }
}
