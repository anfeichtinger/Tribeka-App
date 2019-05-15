import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tribeka/screens/ShiftScreen.dart';
import 'package:tribeka/widgets/CustomSlidable.dart';
import 'package:tribeka/widgets/CustomSlideAction.dart';

import '../util/Shift.dart';

typedef Future<Null> ReloadCallback({bool refresh, bool showLoading});
typedef DeleteCallback(Shift shift);

class ShiftRow extends StatelessWidget {
  final Shift _shift;
  final DateTime _selectedTime;
  final bool _editable;
  final ReloadCallback reloadCallback;
  final DeleteCallback deleteCallback;

  ShiftRow(this._shift, this._selectedTime, this._editable, this.reloadCallback,
      this.deleteCallback);

  // Navigator.push returns a Future that will complete after we call
  // Navigator.pop on the Selection Screen!
  void _navigatorCallback(BuildContext context) async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ShiftScreen(_shift, _editable, _selectedTime)));
    if (result) {
      reloadCallback(refresh: true, showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _isEmpty = _shift.workFrom == '-';
    final _hasComment = _shift.comment.isNotEmpty;
    final _hasBreak = _shift.breakFrom != '-';

    if (_isEmpty)
      return _getEmptyTile(context);
    else if (_hasBreak && !_hasComment)
      return _getBreakTile(context);
    else if (!_hasBreak && _hasComment)
      return _getCommentTile(context);
    else if (_hasBreak && _hasComment)
      return _getBreakAndCommentTile(context);
    else
      return _getBreaklessTile(context);
  }

  Widget _getBasicTile(BuildContext context,
      [Widget subtitle, bool isThreeLine]) {
    return Slidable(
        delegate: SlidableBehindDelegate(),
        actionExtentRatio: 0.22,
        enabled: _editable ? true : false,
        key: Key(_shift.day),
        secondaryActions: <Widget>[
          IconSlideAction(
              color: Colors.red,
              icon: MdiIcons.deleteOutline,
              caption: 'Löschen',
              onTap: () {
                deleteCallback(_shift);
              })
        ],
        child: Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: ListTile(
              onTap: () {
                _navigatorCallback(context);
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              leading: Hero(
                child: CircleAvatar(
                  backgroundColor: Colors.grey[850],
                  child: Text('${_shift.day}.',
                      style: TextStyle(
                          fontFamily: 'Tribeka',
                          fontSize: 28.0,
                          color: Colors.white)),
                  minRadius: 24,
                  maxRadius: 24,
                ),
                tag: _shift.day,
              ),
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                        '${_shift.weekday.substring(0, 2)}, ${_shift
                            .workFrom} - ${_shift.workTo}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('${_shift.getHours()}h',
                        style: TextStyle(fontSize: 14))
                  ]),
              subtitle: subtitle == null ? null : subtitle,
              isThreeLine: isThreeLine == null ? false : isThreeLine,
            )));
  }

  Widget _getBreakAndCommentTile(BuildContext context) {
    final subtitle =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('${_shift.breakFrom} - ${_shift.breakTo}',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15)),
      Text(_shift.comment,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15))
    ]);
    return _getBasicTile(context, subtitle, true);
  }

  Widget _getBreakTile(BuildContext context) {
    final subtitle = Text('${_shift.breakFrom} - ${_shift.breakTo}',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15));
    return _getBasicTile(context, subtitle, false);
  }

  Widget _getBreaklessTile(BuildContext context) {
    final subtitle = Text('Keine Pause',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15));
    return _getBasicTile(context, subtitle, false);
  }

  Widget _getCommentTile(BuildContext context) {
    final subtitle =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('Keine Pause',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15)),
      Text(_shift.comment,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15))
    ]);
    return _getBasicTile(context, subtitle, true);
  }

  Widget _getEmptyTile(BuildContext context) {
    bool _isSick = _shift.place == 'krank';
    return Card(
        color: Colors.grey[400],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Hero(
              tag: _shift.day,
              child: CircleAvatar(
                backgroundColor: Colors.grey[850],
                child: Text('${_shift.day}.',
                    style: TextStyle(
                        fontFamily: 'Tribeka',
                        fontSize: 20.0,
                        color: Colors.white)),
                minRadius: 18,
                maxRadius: 18,
              )),
          title: _isSick
              ? Text(
                  'Krank',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
          onTap: _isSick
              ? () {
                  _navigatorCallback(context);
                }
              : () {},
        ));
  }
}
