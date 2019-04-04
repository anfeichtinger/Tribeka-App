class Shift {
  String day;
  String weekday;
  String workFrom;
  String workTo;
  String breakFrom;
  String breakTo;
  String place;
  String comment;
  String hours;

  Shift(this.day, this.workFrom, this.workTo, this.breakFrom, this.breakTo,
      this.place, this.comment,
      [this.hours, this.weekday]);

  @override
  String toString() {
    return "Weekday: $weekday, Day: $day, WorkFrom: $workFrom, WorkTo: $workTo, BreakFrom: $breakFrom, BreakTo: $breakTo, Place: $place, Comment: $comment";
  }
}
