class Shift {
  final String day;
  final String workFrom;
  final String workTo;
  final String breakFrom;
  final String breakTo;
  final String place;
  final String comment;
  final String hours;

  Shift(this.day, this.workFrom, this.workTo, this.breakFrom, this.breakTo,
      this.place, this.comment,[this.hours]);


  @override
  String toString() {
    return "Day: $day, WorkFrom: $workFrom, WorkTo: $workTo, BreakFrom: $breakFrom, BreakTo: $breakTo, Place: $place, Comment: $comment";
  }
}
