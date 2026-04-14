import 'timeline.dart';
import 'timeline_milestone_occurrence.dart';
import 'timeline_milestone_record.dart';
import 'timeline_milestone_rule.dart';

class TimelineMilestoneRange {
  const TimelineMilestoneRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class TimelineMilestoneService {
  const TimelineMilestoneService();

  TimelineMilestoneOccurrence? getNextOccurrence(
    TimelineMilestoneRule rule,
    Timeline timeline, {
    DateTime? after,
  }) {
    if (rule.status != TimelineMilestoneRuleStatus.active) {
      return null;
    }

    final normalizedAfter = _normalizeDate(after ?? timeline.startDate);
    final start = _normalizeDate(timeline.startDate);
    var occurrenceIndex = 1;

    while (occurrenceIndex < 10000) {
      final targetDate = _targetDateForOccurrence(start, rule, occurrenceIndex);
      if (targetDate.isAfter(normalizedAfter)) {
        return TimelineMilestoneOccurrence(
          timelineId: timeline.id,
          timelineTitle: timeline.title,
          ruleId: rule.id,
          occurrenceIndex: occurrenceIndex,
          targetDate: targetDate,
          label: formatLabel(rule, occurrenceIndex),
          status: MilestoneStatus.upcoming,
          reminderOffsetDays: rule.reminderOffsetDays,
        );
      }
      occurrenceIndex++;
    }

    return null;
  }

  List<TimelineMilestoneOccurrence> getUpcomingOccurrences(
    Timeline timeline,
    List<TimelineMilestoneRule> rules,
    List<TimelineMilestoneRecord> records,
    TimelineMilestoneRange range, {
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    return mergeOccurrencesWithRecords(
          timeline,
          rules,
          records,
          range,
          now: current,
        )
        .where((occurrence) {
          if (occurrence.status != MilestoneStatus.upcoming) {
            return false;
          }
          if (!occurrence.targetDate.isAfter(current)) {
            return false;
          }
          final reminderDate = computeReminderDate(
            occurrence.targetDate,
            occurrence.reminderOffsetDays,
          );
          return !current.isBefore(reminderDate);
        })
        .toList(growable: false)
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  List<TimelineMilestoneOccurrence> getTodayOccurrences(
    Timeline timeline,
    List<TimelineMilestoneRule> rules,
    List<TimelineMilestoneRecord> records, {
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    final tomorrow = current.add(const Duration(days: 1));
    return mergeOccurrencesWithRecords(
          timeline,
          rules,
          records,
          TimelineMilestoneRange(start: current, end: tomorrow),
          now: current,
        )
        .where((occurrence) {
          return occurrence.status == MilestoneStatus.upcoming &&
              !occurrence.targetDate.isBefore(current) &&
              occurrence.targetDate.isBefore(tomorrow);
        })
        .toList(growable: false)
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  DateTime computeReminderDate(DateTime targetDate, int offsetDays) {
    return _normalizeDate(targetDate).subtract(Duration(days: offsetDays));
  }

  List<TimelineMilestoneOccurrence> mergeOccurrencesWithRecords(
    Timeline timeline,
    List<TimelineMilestoneRule> rules,
    List<TimelineMilestoneRecord> records,
    TimelineMilestoneRange range, {
    DateTime? now,
  }) {
    final start = _normalizeDate(range.start);
    final end = _normalizeDate(range.end);
    final recordMap = {
      for (final record in records)
        '${record.ruleId}:${record.occurrenceIndex}': record,
    };
    final occurrences = <TimelineMilestoneOccurrence>[];

    for (final rule in rules.where(
      (item) => item.status == TimelineMilestoneRuleStatus.active,
    )) {
      var occurrenceIndex = 1;
      while (occurrenceIndex < 10000) {
        final targetDate = _targetDateForOccurrence(
          _normalizeDate(timeline.startDate),
          rule,
          occurrenceIndex,
        );
        if (!targetDate.isBefore(start) && targetDate.isBefore(end)) {
          final record = recordMap['${rule.id}:$occurrenceIndex'];
          occurrences.add(
            TimelineMilestoneOccurrence(
              recordId: record?.id,
              timelineId: timeline.id,
              timelineTitle: timeline.title,
              ruleId: rule.id,
              occurrenceIndex: occurrenceIndex,
              targetDate: targetDate,
              label: formatLabel(rule, occurrenceIndex),
              status: record?.status ?? MilestoneStatus.upcoming,
              reminderOffsetDays: rule.reminderOffsetDays,
              notifiedAt: record?.notifiedAt,
              actedAt: record?.actedAt,
            ),
          );
        }

        if (!targetDate.isBefore(end)) {
          break;
        }
        occurrenceIndex++;
      }
    }

    occurrences.sort((a, b) {
      final dateCompare = a.targetDate.compareTo(b.targetDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.ruleId.compareTo(b.ruleId);
    });
    return occurrences;
  }

  String formatLabel(TimelineMilestoneRule rule, int occurrenceIndex) {
    final template =
        (rule.labelTemplate != null && rule.labelTemplate!.isNotEmpty)
        ? rule.labelTemplate!
        : '第 {value}{unit}';
    return template
        .replaceAll('{n}', '${occurrenceCount(rule, occurrenceIndex)}')
        .replaceAll('{value}', '${accumulatedValue(rule, occurrenceIndex)}')
        .replaceAll('{unit}', displayUnitLabel(rule));
  }

  int occurrenceCount(TimelineMilestoneRule rule, int occurrenceIndex) {
    return occurrenceIndex;
  }

  int accumulatedValue(TimelineMilestoneRule rule, int occurrenceIndex) {
    return occurrenceIndex * rule.intervalValue;
  }

  String displayUnitLabel(TimelineMilestoneRule rule) {
    return switch (rule.intervalUnit) {
      TimelineMilestoneIntervalUnit.days => '天',
      TimelineMilestoneIntervalUnit.weeks => '週',
      TimelineMilestoneIntervalUnit.months => '個月',
      TimelineMilestoneIntervalUnit.years => '年',
    };
  }

  DateTime _targetDateForOccurrence(
    DateTime startDate,
    TimelineMilestoneRule rule,
    int occurrenceIndex,
  ) {
    return switch (rule.intervalUnit) {
      TimelineMilestoneIntervalUnit.days => startDate.add(
        Duration(days: rule.intervalValue * occurrenceIndex - 1),
      ),
      TimelineMilestoneIntervalUnit.weeks => startDate.add(
        Duration(days: rule.intervalValue * occurrenceIndex * 7 - 1),
      ),
      TimelineMilestoneIntervalUnit.months => _addMonthsClamped(
        startDate,
        rule.intervalValue * occurrenceIndex,
      ),
      TimelineMilestoneIntervalUnit.years => _addYearsClamped(
        startDate,
        rule.intervalValue * occurrenceIndex,
      ),
    };
  }

  DateTime _addYearsClamped(DateTime base, int years) {
    return _addMonthsClamped(base, years * 12);
  }

  DateTime _addMonthsClamped(DateTime base, int monthsToAdd) {
    final totalMonths = (base.year * 12 + base.month - 1) + monthsToAdd;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = base.day.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
