import 'dart:convert';

import 'repeat_rule.dart';

enum RepeatRuleV2Kind {
  simple,
  weeklyWeekdays,
  monthlyDates,
  monthlyNthWeekday,
}

enum RepeatEndType { never, onDate, afterCount }

enum MonthlyWeekOrdinal { first, second, third, fourth, fifth, last }

enum MonthlyRepeatMode { dates, nthWeekday }

class RepeatEndCondition {
  const RepeatEndCondition.never()
    : type = RepeatEndType.never,
      untilDate = null,
      occurrenceCount = null;

  const RepeatEndCondition.onDate(DateTime date)
    : type = RepeatEndType.onDate,
      untilDate = date,
      occurrenceCount = null;

  const RepeatEndCondition.afterCount(int count)
    : type = RepeatEndType.afterCount,
      untilDate = null,
      occurrenceCount = count;

  final RepeatEndType type;
  final DateTime? untilDate;
  final int? occurrenceCount;

  bool get isNever => type == RepeatEndType.never;

  Map<String, Object?> toJson() {
    return switch (type) {
      RepeatEndType.never => {'type': type.name},
      RepeatEndType.onDate => {
        'type': type.name,
        'untilDate': _encodeDate(untilDate!),
      },
      RepeatEndType.afterCount => {
        'type': type.name,
        'occurrenceCount': occurrenceCount,
      },
    };
  }

  static RepeatEndCondition parse(Object? value) {
    if (value is! Map) {
      return const RepeatEndCondition.never();
    }
    final typeName = value['type'];
    final type = RepeatEndType.values.cast<RepeatEndType?>().firstWhere(
      (candidate) => candidate?.name == typeName,
      orElse: () => null,
    );
    return switch (type) {
      RepeatEndType.onDate => () {
        final date = _parseDate(value['untilDate']);
        return date == null
            ? const RepeatEndCondition.never()
            : RepeatEndCondition.onDate(date);
      }(),
      RepeatEndType.afterCount => () {
        final count = (value['occurrenceCount'] as num?)?.toInt();
        return count == null || count < 1
            ? const RepeatEndCondition.never()
            : RepeatEndCondition.afterCount(count);
      }(),
      _ => const RepeatEndCondition.never(),
    };
  }
}

class RepeatRuleV2 {
  const RepeatRuleV2._({
    required this.kind,
    required this.unit,
    required this.interval,
    this.weekdays = const <int>[],
    this.monthDays = const <int>[],
    this.monthlyWeekOrdinal,
    this.monthlyWeekday,
    this.end = const RepeatEndCondition.never(),
    this.completedCount = 0,
  });

  factory RepeatRuleV2.simple({
    required RepeatUnit unit,
    required int interval,
    RepeatEndCondition end = const RepeatEndCondition.never(),
    int completedCount = 0,
  }) {
    return RepeatRuleV2._(
      kind: RepeatRuleV2Kind.simple,
      unit: unit,
      interval: _positiveInterval(interval),
      end: end,
      completedCount: completedCount < 0 ? 0 : completedCount,
    );
  }

  factory RepeatRuleV2.weeklyWeekdays({
    required int interval,
    required Iterable<int> weekdays,
    RepeatEndCondition end = const RepeatEndCondition.never(),
    int completedCount = 0,
  }) {
    final normalized = _sortedUnique(
      weekdays.where((day) => day >= DateTime.monday && day <= DateTime.sunday),
    );
    return RepeatRuleV2._(
      kind: RepeatRuleV2Kind.weeklyWeekdays,
      unit: RepeatUnit.week,
      interval: _positiveInterval(interval),
      weekdays: normalized.isEmpty ? const [DateTime.monday] : normalized,
      end: end,
      completedCount: completedCount < 0 ? 0 : completedCount,
    );
  }

  factory RepeatRuleV2.monthlyDates({
    required int interval,
    required Iterable<int> monthDays,
    RepeatEndCondition end = const RepeatEndCondition.never(),
    int completedCount = 0,
  }) {
    final normalized = _sortedUnique(
      monthDays.where((day) => day >= 1 && day <= 31),
    );
    return RepeatRuleV2._(
      kind: RepeatRuleV2Kind.monthlyDates,
      unit: RepeatUnit.month,
      interval: _positiveInterval(interval),
      monthDays: normalized.isEmpty ? const [1] : normalized,
      end: end,
      completedCount: completedCount < 0 ? 0 : completedCount,
    );
  }

  factory RepeatRuleV2.monthlyNthWeekday({
    required int interval,
    required MonthlyWeekOrdinal ordinal,
    required int weekday,
    RepeatEndCondition end = const RepeatEndCondition.never(),
    int completedCount = 0,
  }) {
    final normalizedWeekday =
        weekday >= DateTime.monday && weekday <= DateTime.sunday
        ? weekday
        : DateTime.monday;
    return RepeatRuleV2._(
      kind: RepeatRuleV2Kind.monthlyNthWeekday,
      unit: RepeatUnit.month,
      interval: _positiveInterval(interval),
      monthlyWeekOrdinal: ordinal,
      monthlyWeekday: normalizedWeekday,
      end: end,
      completedCount: completedCount < 0 ? 0 : completedCount,
    );
  }

  final RepeatRuleV2Kind kind;
  final RepeatUnit unit;
  final int interval;
  final List<int> weekdays;
  final List<int> monthDays;
  final MonthlyWeekOrdinal? monthlyWeekOrdinal;
  final int? monthlyWeekday;
  final RepeatEndCondition end;
  final int completedCount;

  bool get isEndedByCount =>
      end.type == RepeatEndType.afterCount &&
      completedCount >= (end.occurrenceCount ?? 0);

  RepeatRule? get legacySimpleRule {
    if (kind != RepeatRuleV2Kind.simple || !end.isNever) {
      return null;
    }
    return RepeatRule(unit: unit, interval: interval);
  }

  RepeatRuleV2 copyWithCompletedCount(int value) {
    return RepeatRuleV2._(
      kind: kind,
      unit: unit,
      interval: interval,
      weekdays: weekdays,
      monthDays: monthDays,
      monthlyWeekOrdinal: monthlyWeekOrdinal,
      monthlyWeekday: monthlyWeekday,
      end: end,
      completedCount: value < 0 ? 0 : value,
    );
  }

  String encode() {
    return jsonEncode(<String, Object?>{
      'version': 2,
      'kind': kind.name,
      'unit': unit.name,
      'interval': interval,
      if (weekdays.isNotEmpty) 'weekdays': weekdays,
      if (monthDays.isNotEmpty) 'monthDays': monthDays,
      if (monthlyWeekOrdinal != null)
        'monthlyWeekOrdinal': monthlyWeekOrdinal!.name,
      if (monthlyWeekday != null) 'monthlyWeekday': monthlyWeekday,
      'end': end.toJson(),
      'completedCount': completedCount,
    });
  }

  static RepeatRuleV2? parse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final legacy = RepeatRule.parse(value);
    if (legacy != null) {
      return RepeatRuleV2.simple(unit: legacy.unit, interval: legacy.interval);
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, Object?> || decoded['version'] != 2) {
        return null;
      }
      final kind = RepeatRuleV2Kind.values.cast<RepeatRuleV2Kind?>().firstWhere(
        (candidate) => candidate?.name == decoded['kind'],
        orElse: () => null,
      );
      final unit = RepeatUnit.values.cast<RepeatUnit?>().firstWhere(
        (candidate) => candidate?.name == decoded['unit'],
        orElse: () => null,
      );
      final interval = (decoded['interval'] as num?)?.toInt();
      if (kind == null || unit == null || interval == null || interval < 1) {
        return null;
      }
      final end = RepeatEndCondition.parse(decoded['end']);
      final completedCount = (decoded['completedCount'] as num?)?.toInt() ?? 0;
      return switch (kind) {
        RepeatRuleV2Kind.simple => RepeatRuleV2.simple(
          unit: unit,
          interval: interval,
          end: end,
          completedCount: completedCount,
        ),
        RepeatRuleV2Kind.weeklyWeekdays => RepeatRuleV2.weeklyWeekdays(
          interval: interval,
          weekdays: _intList(decoded['weekdays']),
          end: end,
          completedCount: completedCount,
        ),
        RepeatRuleV2Kind.monthlyDates => RepeatRuleV2.monthlyDates(
          interval: interval,
          monthDays: _intList(decoded['monthDays']),
          end: end,
          completedCount: completedCount,
        ),
        RepeatRuleV2Kind.monthlyNthWeekday => () {
          final ordinal = MonthlyWeekOrdinal.values
              .cast<MonthlyWeekOrdinal?>()
              .firstWhere(
                (candidate) => candidate?.name == decoded['monthlyWeekOrdinal'],
                orElse: () => null,
              );
          final weekday = (decoded['monthlyWeekday'] as num?)?.toInt();
          if (ordinal == null || weekday == null) {
            return null;
          }
          return RepeatRuleV2.monthlyNthWeekday(
            interval: interval,
            ordinal: ordinal,
            weekday: weekday,
            end: end,
            completedCount: completedCount,
          );
        }(),
      };
    } catch (_) {
      return null;
    }
  }
}

class RepeatRuleOccurrenceCalculator {
  const RepeatRuleOccurrenceCalculator();

  DateTime? nextOccurrence({
    required RepeatRuleV2 rule,
    required DateTime fromDate,
    DateTime? anchorDate,
  }) {
    if (rule.isEndedByCount) {
      return null;
    }
    final from = _normalizeDate(fromDate);
    final anchor = _normalizeDate(anchorDate ?? fromDate);
    final candidate = switch (rule.kind) {
      RepeatRuleV2Kind.simple => _nextSimple(rule, from),
      RepeatRuleV2Kind.weeklyWeekdays => _nextWeeklyWeekday(rule, from, anchor),
      RepeatRuleV2Kind.monthlyDates => _nextMonthlyDate(rule, from, anchor),
      RepeatRuleV2Kind.monthlyNthWeekday => _nextMonthlyNthWeekday(
        rule,
        from,
        anchor,
      ),
    };
    if (candidate == null) {
      return null;
    }
    final untilDate = rule.end.untilDate == null
        ? null
        : _normalizeDate(rule.end.untilDate!);
    if (untilDate != null && candidate.isAfter(untilDate)) {
      return null;
    }
    return candidate;
  }

  DateTime _nextSimple(RepeatRuleV2 rule, DateTime from) {
    return switch (rule.unit) {
      RepeatUnit.day => from.add(Duration(days: rule.interval)),
      RepeatUnit.week => from.add(Duration(days: rule.interval * 7)),
      RepeatUnit.month => _addMonthsClamped(from, rule.interval, from.day),
      RepeatUnit.year => _addYearsClamped(from, rule.interval),
    };
  }

  DateTime? _nextWeeklyWeekday(
    RepeatRuleV2 rule,
    DateTime from,
    DateTime anchor,
  ) {
    final anchorWeekStart = _weekStart(anchor);
    for (var offset = 1; offset <= 3660; offset += 1) {
      final candidate = from.add(Duration(days: offset));
      if (!rule.weekdays.contains(candidate.weekday)) {
        continue;
      }
      final weeksSinceAnchor =
          _weekStart(candidate).difference(anchorWeekStart).inDays ~/ 7;
      if (weeksSinceAnchor >= 0 && weeksSinceAnchor % rule.interval == 0) {
        return candidate;
      }
    }
    return null;
  }

  DateTime? _nextMonthlyDate(
    RepeatRuleV2 rule,
    DateTime from,
    DateTime anchor,
  ) {
    for (var monthOffset = 0; monthOffset <= 1200; monthOffset += 1) {
      final month = DateTime(from.year, from.month + monthOffset);
      if (!_isValidMonthInterval(month, anchor, rule.interval)) {
        continue;
      }
      final candidates =
          rule.monthDays
              .map((day) => _monthlyDateWithLastDayFallback(month, day))
              .toSet()
              .toList()
            ..sort();
      for (final candidate in candidates) {
        if (candidate.isAfter(from)) {
          return candidate;
        }
      }
    }
    return null;
  }

  DateTime? _nextMonthlyNthWeekday(
    RepeatRuleV2 rule,
    DateTime from,
    DateTime anchor,
  ) {
    final ordinal = rule.monthlyWeekOrdinal;
    final weekday = rule.monthlyWeekday;
    if (ordinal == null || weekday == null) {
      return null;
    }
    for (var monthOffset = 0; monthOffset <= 1200; monthOffset += 1) {
      final month = DateTime(from.year, from.month + monthOffset);
      if (!_isValidMonthInterval(month, anchor, rule.interval)) {
        continue;
      }
      final candidate = _nthWeekdayOfMonth(month, ordinal, weekday);
      if (candidate != null && candidate.isAfter(from)) {
        return candidate;
      }
    }
    return null;
  }

  bool _isValidMonthInterval(DateTime month, DateTime anchor, int interval) {
    final monthsSinceAnchor =
        (month.year - anchor.year) * 12 + month.month - anchor.month;
    return monthsSinceAnchor >= 0 && monthsSinceAnchor % interval == 0;
  }

  DateTime? _nthWeekdayOfMonth(
    DateTime month,
    MonthlyWeekOrdinal ordinal,
    int weekday,
  ) {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    if (ordinal == MonthlyWeekOrdinal.last) {
      for (var day = lastDay.day; day >= 1; day -= 1) {
        final candidate = DateTime(month.year, month.month, day);
        if (candidate.weekday == weekday) {
          return candidate;
        }
      }
      return null;
    }
    final targetIndex = switch (ordinal) {
      MonthlyWeekOrdinal.first => 1,
      MonthlyWeekOrdinal.second => 2,
      MonthlyWeekOrdinal.third => 3,
      MonthlyWeekOrdinal.fourth => 4,
      MonthlyWeekOrdinal.fifth => 5,
      MonthlyWeekOrdinal.last => 0,
    };
    var count = 0;
    for (var day = firstDay.day; day <= lastDay.day; day += 1) {
      final candidate = DateTime(month.year, month.month, day);
      if (candidate.weekday != weekday) {
        continue;
      }
      count += 1;
      if (count == targetIndex) {
        return candidate;
      }
    }
    // 第五個星期 X 在部分月份不存在；此規則會略過該月。
    return null;
  }

  DateTime _monthlyDateWithLastDayFallback(DateTime month, int preferredDay) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    // 若指定的 29/30/31 在該月不存在，使用該月最後一天。
    return DateTime(month.year, month.month, preferredDay.clamp(1, lastDay));
  }

  DateTime _addMonthsClamped(DateTime value, int months, int preferredDay) {
    final targetMonth = DateTime(value.year, value.month + months);
    return _monthlyDateWithLastDayFallback(targetMonth, preferredDay);
  }

  DateTime _addYearsClamped(DateTime value, int years) {
    final target = DateTime(value.year + years, value.month);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, value.day.clamp(1, lastDay));
  }
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _weekStart(DateTime value) {
  final normalized = _normalizeDate(value);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

int _positiveInterval(int value) => value < 1 ? 1 : value;

List<int> _sortedUnique(Iterable<int> values) {
  return (values.toSet().toList()..sort()).toList(growable: false);
}

List<int> _intList(Object? value) {
  if (value is! List) {
    return const <int>[];
  }
  return value
      .map((item) => (item as num?)?.toInt())
      .whereType<int>()
      .toList(growable: false);
}

String _encodeDate(DateTime value) {
  final normalized = _normalizeDate(value);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}

DateTime? _parseDate(Object? value) {
  if (value is! String) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : _normalizeDate(parsed);
}
