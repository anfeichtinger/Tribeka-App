import 'package:flutter/material.dart';

import '../util/Shift.dart';

typedef void DeleteCallback(DateTime dateTime, Shift shift);

class ShiftRow extends StatelessWidget {
  final Shift _shift;
  final DateTime _selectedTime;
  final DeleteCallback callback;

  ShiftRow(this._shift, this._selectedTime, this.callback);

  @override
  Widget build(BuildContext context) {
    final _isEmpty = _shift.workFrom == '-';
    final _hasComment = _shift.comment.isNotEmpty;
    final _hasBreak = _shift.breakFrom != '-';

    if (_isEmpty)
      return _getEmptyTile();
    else if (_hasBreak && !_hasComment)
      return _getBreakTile();
    else if (!_hasBreak && _hasComment)
      return _getCommentTile();
    else if (_hasBreak && _hasComment)
      return _getBreakAndCommentTile();
    else
      return _getBreaklessTile();
  }

  Card _getBasicTile([Widget subtitle, bool isThreeLine]) {
    return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: ListTile(
          onLongPress: () {
            callback(_selectedTime, _shift);
          },
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[850],
            child: Text('${_shift.day}.',
                style: TextStyle(
                    fontFamily: 'Tribeka',
                    fontSize: 28.0,
                    color: Colors.white)),
            minRadius: 24,
            maxRadius: 24,
          ),
          title: Text(
              '${_shift.weekday.substring(0, 2)}, ${_shift.workFrom} - ${_shift.workTo}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          subtitle: subtitle == null ? null : subtitle,
          isThreeLine: isThreeLine == null ? false : isThreeLine,
        ));
  }

  Card _getBreakAndCommentTile() {
    final subtitle =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('${_shift.breakFrom} - ${_shift.breakTo}',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15)),
      Text(_shift.comment,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15))
    ]);
    return _getBasicTile(subtitle, true);
  }

  Card _getBreakTile() {
    final subtitle = Text('${_shift.breakFrom} - ${_shift.breakTo}',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15));
    return _getBasicTile(subtitle, false);
  }

  Card _getBreaklessTile() {
    final subtitle = Text('Keine Pause',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15));
    return _getBasicTile(subtitle, false);
  }

  Card _getCommentTile() {
    final subtitle =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('Keine Pause',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15)),
      Text(_shift.comment,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15))
    ]);
    return _getBasicTile(subtitle, true);
  }

  Card _getEmptyTile() {
    bool _isSick = _shift.place == 'krank';
    return Card(
        color: Colors.grey[400],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[850],
            child: Text('${_shift.day}.',
                style: TextStyle(
                    fontFamily: 'Tribeka',
                    fontSize: 20.0,
                    color: Colors.white)),
            minRadius: 18,
            maxRadius: 18,
          ),
          title: _isSick
              ? Text(
                  'Krank',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
          onLongPress: _isSick
              ? () {
                  callback(_selectedTime, _shift);
                }
              : () {},
        ));
  }
}

/*leading: CircleAvatar(
            child: Image.asset('assets/${_shift.day}.png'),
            minRadius: 24,
            maxRadius: 24,
          ),
*/
