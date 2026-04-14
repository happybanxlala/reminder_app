import 'timeline.dart';

class TimelineCalculator {
  const TimelineCalculator();

  int displayValue(Timeline timeline, DateTime now) {
    final start = DateTime(
      timeline.startDate.year,
      timeline.startDate.month,
      timeline.startDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(start).inDays + 1;
    final safeDays = days < 1 ? 1 : days;
    return switch (timeline.displayUnit) {
      TimelineDisplayUnit.day => safeDays,
      TimelineDisplayUnit.week => ((safeDays - 1) ~/ 7) + 1,
      TimelineDisplayUnit.month =>
        ((today.year - start.year) * 12 + today.month - start.month) + 1,
      TimelineDisplayUnit.year => (today.year - start.year) + 1,
    };
  }
}
