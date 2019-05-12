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

  static Shift copy(Shift shift) {
    return Shift(
      shift.day,
      shift.workFrom,
      shift.workTo,
      shift.breakFrom,
      shift.breakTo,
      shift.place,
      shift.comment,
      shift.hours,
      shift.weekday,
    );
  }

  String getHours() {
    if (int.parse(hours.split(',')[1]) > 0) {
      return hours;
    } else {
      return hours.substring(0, 1);
    }
  }

  @override
  String toString() {
    return "Weekday: $weekday,\n Day: $day,\n WorkFrom: $workFrom,\n WorkTo: $workTo,\n BreakFrom: $breakFrom,\n BreakTo: $breakTo,\n Place: $place,\n Comment: $comment,\n $hours\n";
  }

  @override
  bool operator ==(other) {
    return this.hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    return day.hashCode +
        workFrom.hashCode +
        workTo.hashCode +
        breakFrom.hashCode +
        breakTo.hashCode +
        place.hashCode +
        comment.hashCode +
        hours.hashCode +
        weekday.hashCode;
  }
}
