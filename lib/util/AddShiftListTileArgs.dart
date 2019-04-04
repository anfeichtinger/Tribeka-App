import 'package:flutter/widgets.dart';

typedef void TimeChangedCallback(DateTime dateTimeCallback);
typedef void LongPressCallback();

class AddShiftListTileArgs {
  final String label;
  final IconData iconData;
  final String value;
  final TimeChangedCallback callback;
  final LongPressCallback longCallback;

  AddShiftListTileArgs(
      {this.label,
      this.iconData,
      this.value,
      this.callback,
      this.longCallback});
}
