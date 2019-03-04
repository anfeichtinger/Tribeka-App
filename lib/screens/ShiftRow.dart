import 'package:flutter/material.dart';
import 'package:tribeka/utils/Shift.dart';

class ShiftRow extends StatelessWidget {
  final Shift shift;

  ShiftRow(this.shift);

  @override
  Widget build(BuildContext context) {
    return getBasicCard();
  }

  Card getBasicCard() {
    if (shift.workFrom == "-") {
      return Card(
        color: Colors.white54,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(8),
              alignment: FractionalOffset.centerLeft,
              child: CircleAvatar(
                child: Image.asset('assets/${shift.day}.png'),
                minRadius: 16,
                maxRadius: 16,
              ),
            ),
          ],
        ),
      );
    } else {
      return Card(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Container(
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(children: <Widget>[
                Container(
                  padding: EdgeInsets.all(8),
                  alignment: FractionalOffset.centerLeft,
                  child: CircleAvatar(
                    child: Image.asset('assets/${shift.day}.png'),
                    minRadius: 24,
                    maxRadius: 24,
                  ),
                ),
                Container(
                  width: 8,
                ),
                getContentColumn(),
                Spacer(),
                Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text(
                      shift.hours[0] + 'h',
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ))
              ])));
    }
  }

  Column getContentColumn() {
    if (shift.comment.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            shift.workFrom + " - " + shift.workTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
              shift.breakFrom == "-"
                  ? "Keine Pause"
                  : shift.breakFrom + " - " + shift.breakTo,
              style: TextStyle(fontSize: 14)),
          Text(shift.comment, style: TextStyle(fontSize: 13))
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            shift.workFrom + " - " + shift.workTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
              shift.breakFrom == "-"
                  ? "Keine Pause"
                  : shift.breakFrom + " - " + shift.breakTo,
              style: TextStyle(fontSize: 14)),
        ],
      );
    }
  }
}
