import 'stage_occurrence.dart';
import 'stage_record.dart';
import 'stage_rule.dart';
import 'stage_tracker.dart';

class StageOccurrenceRange {
  const StageOccurrenceRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class StageOccurrenceService {
  const StageOccurrenceService();

  static const defaultReminderOffsetDays = 0;

  StageOccurrence? getNextOccurrence(
    StageRule rule,
    StageTracker tracker, {
    DateTime? after,
    List<StageRecord> records = const [],
  }) {
    if (rule.status != StageRuleStatus.active) {
      return null;
    }
    final current = _normalizeDate(after ?? tracker.trackingStartDate);
    final endDate = _normalizeNullableDate(tracker.trackingEndDate);
    var occurrenceIndex = 1;

    while (occurrenceIndex < 10000) {
      final occurrenceDate = targetDateForOccurrence(
        tracker.trackingStartDate,
        rule,
        occurrenceIndex,
      );
      if (endDate != null && occurrenceDate.isAfter(endDate)) {
        return null;
      }
      if (occurrenceDate.isAfter(current)) {
        final record = _recordForGenerated(records, rule.id, occurrenceIndex);
        if (!_isHiddenRecord(record)) {
          return _generatedOccurrence(
            tracker,
            rule,
            occurrenceIndex,
            occurrenceDate,
            record,
          );
        }
      }
      occurrenceIndex++;
    }
    return null;
  }

  List<StageOccurrence> getDashboardUpcomingOccurrences(
    StageTracker tracker,
    List<StageRule> rules,
    List<StageRecord> records, {
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    final manual = _manualOccurrences(
      tracker,
      records,
      StageOccurrenceRange(
        start: current.add(const Duration(days: 1)),
        end: current.add(const Duration(days: 366)),
      ),
      includeFuture: true,
    );
    final generated = [
      for (final rule in rules)
        if (rule.status == StageRuleStatus.active)
          getNextOccurrence(rule, tracker, after: current, records: records),
    ].whereType<StageOccurrence>();

    return [...manual, ...generated]..sort(compareFuture);
  }

  List<StageOccurrence> getScheduleOccurrences(
    StageTracker tracker,
    List<StageRule> rules,
    List<StageRecord> records,
    StageOccurrenceRange range, {
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    return mergeOccurrencesWithRecords(
      tracker,
      rules,
      records,
      StageOccurrenceRange(
        start: _maxDate(
          _normalizeDate(range.start),
          current.add(const Duration(days: 1)),
        ),
        end: range.end,
      ),
    )..sort(compareFuture);
  }

  List<StageOccurrence> getHistoryOccurrences(
    StageTracker tracker,
    List<StageRule> rules,
    List<StageRecord> records,
    StageOccurrenceRange range, {
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    final items = mergeOccurrencesWithRecords(
      tracker,
      rules,
      records,
      StageOccurrenceRange(start: range.start, end: current),
    );
    return items
        .where((item) => item.occurrenceDate.isBefore(current))
        .toList(growable: false)
      ..sort(compareHistory);
  }

  List<StageOccurrence> getHomeAttentionOccurrences(
    StageTracker tracker,
    List<StageRule> rules,
    List<StageRecord> records,
    StageOccurrenceRange range, {
    DateTime? now,
  }) {
    if (tracker.status != StageTrackerStatus.active) {
      return const [];
    }
    final current = _normalizeDate(now ?? DateTime.now());
    return mergeOccurrencesWithRecords(tracker, rules, records, range)
        .where((occurrence) {
          if (occurrence.recordStatus == StageRecordStatus.ignored ||
              occurrence.recordStatus == StageRecordStatus.archived ||
              occurrence.recordStatus == StageRecordStatus.acknowledged) {
            return false;
          }
          final reminderDate = computeReminderDate(
            occurrence.occurrenceDate,
            occurrence.reminderOffsetDays,
          );
          return !current.isBefore(reminderDate);
        })
        .toList(growable: false)
      ..sort(compareFuture);
  }

  List<StageOccurrence> mergeOccurrencesWithRecords(
    StageTracker tracker,
    List<StageRule> rules,
    List<StageRecord> records,
    StageOccurrenceRange range,
  ) {
    final start = _normalizeDate(range.start);
    final end = _normalizeDate(range.end);
    final occurrences = <StageOccurrence>[
      ..._manualOccurrences(tracker, records, range, includeFuture: true),
    ];
    final endDate = _normalizeNullableDate(tracker.trackingEndDate);
    final generatedRecordMap = {
      for (final record in records.where(
        (item) =>
            item.sourceType == StageRecordSourceType.generated &&
            item.stageRuleId != null &&
            item.occurrenceIndex != null,
      ))
        '${record.stageRuleId}:${record.occurrenceIndex}': record,
    };

    for (final rule in rules.where(
      (item) => item.status == StageRuleStatus.active,
    )) {
      var occurrenceIndex = 1;
      while (occurrenceIndex < 10000) {
        final occurrenceDate = targetDateForOccurrence(
          tracker.trackingStartDate,
          rule,
          occurrenceIndex,
        );
        if (endDate != null && occurrenceDate.isAfter(endDate)) {
          break;
        }
        if (!occurrenceDate.isBefore(start) && occurrenceDate.isBefore(end)) {
          final record = generatedRecordMap['${rule.id}:$occurrenceIndex'];
          if (!_isHiddenRecord(record)) {
            occurrences.add(
              _generatedOccurrence(
                tracker,
                rule,
                occurrenceIndex,
                occurrenceDate,
                record,
              ),
            );
          }
        }
        if (!occurrenceDate.isBefore(end)) {
          break;
        }
        occurrenceIndex++;
      }
    }

    occurrences.sort(compareFuture);
    return occurrences;
  }

  DateTime computeReminderDate(DateTime occurrenceDate, int offsetDays) {
    return _normalizeDate(occurrenceDate).subtract(Duration(days: offsetDays));
  }

  DateTime targetDateForOccurrence(
    DateTime trackingStartDate,
    StageRule rule,
    int occurrenceIndex,
  ) {
    final start = _normalizeDate(trackingStartDate);
    return switch (rule.intervalUnit) {
      StageIntervalUnit.days => start.add(
        Duration(days: rule.intervalValue * occurrenceIndex),
      ),
      StageIntervalUnit.weeks => start.add(
        Duration(days: rule.intervalValue * occurrenceIndex * 7),
      ),
      StageIntervalUnit.months => _addMonthsClamped(
        start,
        rule.intervalValue * occurrenceIndex,
      ),
      StageIntervalUnit.years => _addYearsClamped(
        start,
        rule.intervalValue * occurrenceIndex,
      ),
    };
  }

  String formatLabel(StageRule rule, int occurrenceIndex) {
    final template =
        (rule.labelTemplate != null && rule.labelTemplate!.trim().isNotEmpty)
        ? rule.labelTemplate!.trim()
        : '滿 {value}{unit}';
    return template
        .replaceAll('{n}', '$occurrenceIndex')
        .replaceAll('{value}', '${rule.intervalValue * occurrenceIndex}')
        .replaceAll('{unit}', displayUnitLabel(rule.intervalUnit));
  }

  String displayUnitLabel(StageIntervalUnit unit) {
    return switch (unit) {
      StageIntervalUnit.days => '天',
      StageIntervalUnit.weeks => '週',
      StageIntervalUnit.months => '個月',
      StageIntervalUnit.years => '年',
    };
  }

  int compareFuture(StageOccurrence a, StageOccurrence b) {
    final dateCompare = a.occurrenceDate.compareTo(b.occurrenceDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    if (a.isManual != b.isManual) {
      return a.isManual ? -1 : 1;
    }
    return (a.stageRuleId ?? a.stageRecordId ?? 0).compareTo(
      b.stageRuleId ?? b.stageRecordId ?? 0,
    );
  }

  int compareHistory(StageOccurrence a, StageOccurrence b) {
    final dateCompare = b.occurrenceDate.compareTo(a.occurrenceDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    if (a.isManual != b.isManual) {
      return a.isManual ? -1 : 1;
    }
    return (a.stageRuleId ?? a.stageRecordId ?? 0).compareTo(
      b.stageRuleId ?? b.stageRecordId ?? 0,
    );
  }

  List<StageOccurrence> _manualOccurrences(
    StageTracker tracker,
    List<StageRecord> records,
    StageOccurrenceRange range, {
    required bool includeFuture,
  }) {
    final start = _normalizeDate(range.start);
    final end = _normalizeDate(range.end);
    return records
        .where((record) {
          if (record.sourceType != StageRecordSourceType.manual ||
              record.status == StageRecordStatus.ignored ||
              record.status == StageRecordStatus.archived) {
            return false;
          }
          final date = _normalizeDate(record.occurrenceDate);
          return !date.isBefore(start) && date.isBefore(end);
        })
        .map(
          (record) => StageOccurrence(
            stageTrackerId: tracker.id,
            stageTrackerTitle: tracker.title,
            subjectName: tracker.subjectName,
            stageRecordId: record.id,
            sourceType: StageRecordSourceType.manual,
            occurrenceDate: _normalizeDate(record.occurrenceDate),
            label: record.label,
            note: record.note,
            reminderOffsetDays:
                record.reminderOffsetDays ?? defaultReminderOffsetDays,
            recordStatus: record.status,
          ),
        )
        .toList(growable: false);
  }

  StageOccurrence _generatedOccurrence(
    StageTracker tracker,
    StageRule rule,
    int occurrenceIndex,
    DateTime occurrenceDate,
    StageRecord? record,
  ) {
    return StageOccurrence(
      stageTrackerId: tracker.id,
      stageTrackerTitle: tracker.title,
      subjectName: tracker.subjectName,
      stageRuleId: rule.id,
      stageRecordId: record?.id,
      sourceType: StageRecordSourceType.generated,
      occurrenceIndex: occurrenceIndex,
      occurrenceDate: _normalizeDate(record?.occurrenceDate ?? occurrenceDate),
      label: record?.label ?? formatLabel(rule, occurrenceIndex),
      note: record?.note,
      reminderOffsetDays:
          record?.reminderOffsetDays ??
          rule.reminderOffsetDays ??
          defaultReminderOffsetDays,
      recordStatus: record?.status,
    );
  }

  StageRecord? _recordForGenerated(
    List<StageRecord> records,
    int ruleId,
    int occurrenceIndex,
  ) {
    for (final record in records) {
      if (record.sourceType == StageRecordSourceType.generated &&
          record.stageRuleId == ruleId &&
          record.occurrenceIndex == occurrenceIndex) {
        return record;
      }
    }
    return null;
  }

  bool _isHiddenRecord(StageRecord? record) {
    return record?.status == StageRecordStatus.ignored ||
        record?.status == StageRecordStatus.archived;
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

  DateTime _maxDate(DateTime a, DateTime b) {
    return a.isAfter(b) ? a : b;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _normalizeNullableDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _normalizeDate(value);
  }
}
