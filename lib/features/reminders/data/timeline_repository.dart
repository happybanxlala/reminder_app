import 'package:drift/drift.dart';

import '../domain/milestone.dart';
import '../domain/milestone_reminder_rule.dart';
import '../domain/timeline.dart';
import '../domain/timeline_calculator.dart';
import 'local/app_database.dart';
import 'local/task_timeline_dao.dart';

class TimelineInput {
  const TimelineInput({
    required this.title,
    required this.startDate,
    required this.displayUnit,
    required this.milestoneReminderRule,
  });

  final String title;
  final DateTime startDate;
  final TimelineDisplayUnit displayUnit;
  final MilestoneReminderRule milestoneReminderRule;
}

class MilestoneInput {
  const MilestoneInput({
    required this.targetDate,
    this.description,
    this.source = MilestoneSource.custom,
  });

  final DateTime targetDate;
  final String? description;
  final MilestoneSource source;
}

class TimelineDetail {
  const TimelineDetail({
    required this.timeline,
    required this.customMilestones,
    required this.ruleBasedMilestones,
  });

  final Timeline timeline;
  final List<MilestoneBundle> customMilestones;
  final List<MilestoneBundle> ruleBasedMilestones;
}

class TimelineRepository {
  TimelineRepository(this._dao, {TimelineCalculator? calculator})
    : _calculator = calculator ?? const TimelineCalculator();

  final TaskTimelineDao _dao;
  final TimelineCalculator _calculator;

  Stream<List<Timeline>> watchTimelines() => _dao.watchTimelines();

  Stream<List<MilestoneBundle>> watchTodayMilestones({DateTime? now}) {
    return _dao.watchMilestoneBundles().map(
      (items) => items
          .where(
            (item) => _calculator.isToday(
              item.milestone,
              item.timeline.milestoneReminderRule,
              now ?? DateTime.now(),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<MilestoneBundle>> watchUpcomingMilestones({DateTime? now}) {
    return _dao.watchMilestoneBundles().map(
      (items) => items
          .where(
            (item) => _calculator.isUpcoming(
              item.milestone,
              item.timeline.milestoneReminderRule,
              now ?? DateTime.now(),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<MilestoneBundle>> watchMilestoneHistory() {
    return _dao.watchMilestoneBundles().map(
      (items) =>
          items
              .where(
                (item) => item.milestone.status != MilestoneStatus.upcoming,
              )
              .toList(growable: false)
            ..sort(
              (a, b) => b.milestone.updatedAt.compareTo(a.milestone.updatedAt),
            ),
    );
  }

  Future<Timeline?> getTimelineById(int id) => _dao.getTimelineById(id);

  Future<TimelineDetail?> getTimelineDetailById(int id) async {
    final record = await _dao.getTimelineDetailRecordById(id);
    if (record == null) {
      return null;
    }
    return TimelineDetail(
      timeline: record.timeline,
      customMilestones: record.customMilestones,
      ruleBasedMilestones: record.ruleBasedMilestones,
    );
  }

  Future<int> createTimeline(
    TimelineInput input, {
    List<MilestoneInput> customMilestones = const [],
  }) async {
    final now = DateTime.now();
    final timelineId = await _dao.insertTimeline(
      TimelinesCompanion.insert(
        title: input.title,
        startDate: _normalizeDate(input.startDate).millisecondsSinceEpoch,
        displayUnit: input.displayUnit.name,
        status: TimelineStatus.active.name,
        milestoneReminderRule: input.milestoneReminderRule.encode(),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await _regenerateRuleBasedMilestones(
      timelineId,
      startDate: input.startDate,
      displayUnit: input.displayUnit,
    );
    for (final item in customMilestones) {
      await addMilestone(timelineId, item);
    }
    return timelineId;
  }

  Future<bool> updateTimeline(
    int id,
    TimelineInput input, {
    List<MilestoneInput> customMilestones = const [],
  }) async {
    final existing = await getTimelineById(id);
    if (existing == null || existing.status == TimelineStatus.archived) {
      return false;
    }
    final success = await _dao.updateTimelineRecord(
      TimelineRow(
        id: existing.id,
        title: input.title,
        startDate: _normalizeDate(input.startDate).millisecondsSinceEpoch,
        displayUnit: input.displayUnit.name,
        status: existing.status.name,
        milestoneReminderRule: input.milestoneReminderRule.encode(),
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!success) {
      return false;
    }
    await _regenerateRuleBasedMilestones(
      id,
      startDate: input.startDate,
      displayUnit: input.displayUnit,
    );
    await _replaceUpcomingCustomMilestones(id, customMilestones);
    return true;
  }

  Future<int> addMilestone(int timelineId, MilestoneInput input) {
    final now = DateTime.now();
    return _dao.insertMilestone(
      MilestonesCompanion.insert(
        timelineId: timelineId,
        targetDate: _normalizeDate(input.targetDate).millisecondsSinceEpoch,
        description: Value(input.description),
        source: input.source.name,
        status: MilestoneStatus.upcoming.name,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> noticeMilestone(int id) => _dao.noticeMilestone(id);

  Future<void> skipMilestone(int id) => _dao.skipMilestone(id);

  Future<void> _regenerateRuleBasedMilestones(
    int timelineId, {
    required DateTime startDate,
    required TimelineDisplayUnit displayUnit,
  }) async {
    await _dao.deleteUpcomingRuleBasedMilestones(timelineId);
    final start = _normalizeDate(startDate);
    for (
      var index = 1;
      index <= _ruleBasedMilestoneCount(displayUnit);
      index++
    ) {
      final targetDate = switch (displayUnit) {
        TimelineDisplayUnit.day => start.add(Duration(days: index - 1)),
        TimelineDisplayUnit.week => start.add(Duration(days: (index - 1) * 7)),
        TimelineDisplayUnit.month => DateTime(
          start.year,
          start.month + index - 1,
          start.day,
        ),
        TimelineDisplayUnit.year => DateTime(
          start.year + index - 1,
          start.month,
          start.day,
        ),
      };
      await addMilestone(
        timelineId,
        MilestoneInput(
          targetDate: targetDate,
          description: _ruleBasedMilestoneDescription(displayUnit, index),
          source: MilestoneSource.ruleBased,
        ),
      );
    }
  }

  Future<void> _replaceUpcomingCustomMilestones(
    int timelineId,
    List<MilestoneInput> milestones,
  ) async {
    await _dao.deleteUpcomingCustomMilestones(timelineId);
    for (final item in milestones) {
      await addMilestone(timelineId, item);
    }
  }

  int _ruleBasedMilestoneCount(TimelineDisplayUnit displayUnit) {
    return switch (displayUnit) {
      TimelineDisplayUnit.day => 365,
      TimelineDisplayUnit.week => 53,
      TimelineDisplayUnit.month => 12,
      TimelineDisplayUnit.year => 1,
    };
  }

  String _ruleBasedMilestoneDescription(
    TimelineDisplayUnit displayUnit,
    int index,
  ) {
    return switch (displayUnit) {
      TimelineDisplayUnit.day => '第 $index 天',
      TimelineDisplayUnit.week => '第 $index 週',
      TimelineDisplayUnit.month => '第 $index 個月',
      TimelineDisplayUnit.year => '第 $index 年',
    };
  }
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
