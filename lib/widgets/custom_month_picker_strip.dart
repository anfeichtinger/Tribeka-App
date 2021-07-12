/* 
* Credits go to: mahmed8003
* Git Repository: https://github.com/mahmed8003/month_picker_strip
*/

library month_picker_strip;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

const TextStyle _selectedTextStyle = TextStyle(
  // I had to change some colors in order to match the Apps Theme
  color: Color(0xFF000000),
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
);

const TextStyle _normalTextStyle = TextStyle(
  color: Color(0x7F000000),
  fontSize: 14.0,
  fontWeight: FontWeight.w400,
);

class MonthStrip extends StatefulWidget {
  final String format;
  @required
  final DateTime from;
  @required
  final DateTime to;
  @required
  final DateTime initialMonth;
  @required
  final ValueChanged<DateTime> onMonthChanged;
  final double height;
  final double viewportFraction;
  final TextStyle selectedTextStyle;
  final TextStyle normalTextStyle;

  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  const MonthStrip({
    Key key,
    this.format = 'MMMM yyyy',
    this.from,
    this.to,
    this.initialMonth,
    this.onMonthChanged,
    this.physics,
    this.height = 48.0,
    this.viewportFraction = 0.3,
    this.normalTextStyle = _normalTextStyle,
    this.selectedTextStyle = _selectedTextStyle,
  }) : super(key: key);

  @override
  _MonthStripState createState() {
    List<_MonthItem> months = [];
    int initialPage = 0;
    for (int i = from.year; i <= to.year; i++) {
      for (int j = 1; j <= 12; j++) {
        if (i == from.year && j < from.month) {
          continue;
        }

        if (i == to.year && j > to.month) {
          continue;
        }

        final item = _MonthItem(DateTime(i, j), selected: false);
        if (initialMonth != null) {
          if (item.time.year == initialMonth.year &&
              item.time.month == initialMonth.month) {
            initialPage = months.length;
            item.selected = true;
          }
        }
        months.add(item);
      }
    }

    return _MonthStripState(
        viewportFraction: viewportFraction,
        initialPage: initialPage,
        dateFormat: DateFormat(format),
        months: months);
  }
}

class _MonthStripState extends State<MonthStrip> {
  final DateFormat dateFormat;
  final List<_MonthItem> months;
  final PageController controller;
  int _lastReportedPage;

  _MonthStripState(
      {double viewportFraction, int initialPage, this.dateFormat, this.months})
      : controller = PageController(
            viewportFraction: viewportFraction, initialPage: initialPage),
        _lastReportedPage = initialPage;

  @override
  Widget build(BuildContext context) {
    const AxisDirection axisDirection = AxisDirection.right;
    final ScrollPhysics physics = _kPagePhysics.applyTo(widget.physics);
    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (ScrollEndNotification notification) {
          if (notification.depth == 0 &&
              widget.onMonthChanged != null &&
              notification is ScrollEndNotification) {
            final PageMetrics metrics = notification.metrics as PageMetrics;
            final int currentPage = metrics.page.round();
            if (currentPage != _lastReportedPage) {
              _lastReportedPage = currentPage;

              setState(() {
                for (final item in months) {
                  item.selected = false;
                }
                final m = months[currentPage];
                final d = m.time;
                m.selected = true;
                widget.onMonthChanged(DateTime(d.year, d.month));
              });
            }
          }
          return false;
        },
        child: Scrollable(
          axisDirection: axisDirection,
          controller: controller,
          physics: physics,
          viewportBuilder: (BuildContext context, ViewportOffset position) {
            return Viewport(
              axisDirection: axisDirection,
              offset: position,
              slivers: <Widget>[
                SliverFillViewport(
                  viewportFraction: controller.viewportFraction,
                  delegate: SliverChildBuilderDelegate(_buildContent,
                      childCount: months.length),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int index) {
    final item = months[index];
    return InkWell(
        onTap: () {
          if (_lastReportedPage != index) {
            controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          }
        },
        child: Center(
            child: Text(
              dateFormat.format(item.time),
              textAlign: TextAlign.center,
              style:
              item.selected ? widget.selectedTextStyle : widget.normalTextStyle,
            )));
  }
}

class _MonthItem {
  final DateTime time;
  bool selected;

  _MonthItem(this.time, {this.selected = false});
}
