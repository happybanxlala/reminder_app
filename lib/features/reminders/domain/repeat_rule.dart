class RepeatRule {
  const RepeatRule._(this.kind, this.interval);

  final String kind;
  final int interval;

  static RepeatRule? parse(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) return null;

    final match = RegExp(r'^([DWMY])(\d+)$').firstMatch(value);
    if (match == null) return null;

    final interval = int.tryParse(match.group(2)!);
    if (interval == null || interval < 1) return null;

    return RepeatRule._(match.group(1)!, interval);
  }

  DateTime advance(DateTime base) {
    switch (kind) {
      case 'D':
        return base.add(Duration(days: interval));
      case 'W':
        return base.add(Duration(days: interval * 7));
      case 'M':
        return DateTime(
          base.year,
          base.month + interval,
          base.day,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
          base.microsecond,
        );
      case 'Y':
        return DateTime(
          base.year + interval,
          base.month,
          base.day,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
          base.microsecond,
        );
      default:
        return base;
    }
  }
}
