import 'package:flutter/material.dart';

class MonthSummaryRow extends StatelessWidget {
  final double _sum;

  MonthSummaryRow(this._sum);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Stunden gesamt: ${_sum.toString()}',
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
    );
  }
}
/*
leading: CircleAvatar(
child: Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.grey[850],
),
child: Text('1.',
style: TextStyle(
fontFamily: 'Tribeka',
fontSize: 32.0,
color: Colors.white)),
),
minRadius: 24,
maxRadius: 24,
),
*/
