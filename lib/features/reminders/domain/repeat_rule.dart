enum RepeatUnit { day, week, month, year }

class RepeatRule {
  const RepeatRule({required this.unit, required this.interval});

  final RepeatUnit unit;
  final int interval;

  String encode() {
    final prefix = switch (unit) {
      RepeatUnit.day => 'D',
      RepeatUnit.week => 'W',
      RepeatUnit.month => 'M',
      RepeatUnit.year => 'Y',
    };
    return '$prefix$interval';
  }

  DateTime advance(DateTime date) {
    return switch (unit) {
      RepeatUnit.day => date.add(Duration(days: interval)),
      RepeatUnit.week => date.add(Duration(days: interval * 7)),
      RepeatUnit.month => DateTime(date.year, date.month + interval, date.day),
      RepeatUnit.year => DateTime(date.year + interval, date.month, date.day),
    };
  }

  static RepeatRule? parse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final prefix = value.substring(0, 1);
    final interval = int.tryParse(value.substring(1));
    if (interval == null || interval < 1) {
      return null;
    }
    final unit = switch (prefix) {
      'D' => RepeatUnit.day,
      'W' => RepeatUnit.week,
      'M' => RepeatUnit.month,
      'Y' => RepeatUnit.year,
      _ => null,
    };
    if (unit == null) {
      return null;
    }
    return RepeatRule(unit: unit, interval: interval);
  }
}
