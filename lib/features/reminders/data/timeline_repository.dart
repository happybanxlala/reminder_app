import 'package:drift/drift.dart';

import '../domain/timeline.dart';
import '../domain/timeline_milestone_occurrence.dart';
import '../domain/timeline_milestone_record.dart';
import '../domain/timeline_milestone_rule.dart';
import '../domain/timeline_milestone_service.dart';
import 'local/app_database.dart';
import 'local/item_timeline_dao.dart';
import 'timeline_models.dart';

class TimelineRepository {
  TimelineRepository(this._dao, {TimelineMilestoneService? milestoneService})
    : _milestoneService = milestoneService ?? const TimelineMilestoneService();

  final ItemTimelineDao _dao;
  final TimelineMilestoneService _milestoneService;

  Stream<List<Timeline>> watchTimelines() => _dao.watchTimelines();

  Stream<List<TimelineMilestoneRule>> watchMilestoneRules() {
    return _dao.watchTimelineMilestoneRules();
  }

  Stream<List<TimelineMilestoneRecord>> watchMilestoneRecords() {
    return _dao.watchTimelineMilestoneRecords();
  }

  Stream<List<TimelineMilestoneRecordBundle>> watchMilestoneHistory() {
    return _dao.watchTimelineMilestoneRecordBundles().map(
      (items) =>
          items
              .where(
                (item) =>
                    item.record.status !=
                    TimelineMilestoneRecordStatus.upcoming,
              )
              .toList(growable: false)
            ..sort((a, b) => b.record.updatedAt.compareTo(a.record.updatedAt)),
    );
  }

  Future<Timeline?> getTimelineById(int id) => _dao.getTimelineById(id);

  Future<TimelineDetail?> getTimelineDetailById(int id, {DateTime? now}) async {
    final record = await _dao.getTimelineDetailRecordById(id);
    if (record == null) {
      return null;
    }
    final current = _normalizeDate(now ?? DateTime.now());
    final milestoneHistory = record.milestoneHistory;
    final milestoneRules = record.milestoneRules;
    final upcomingMilestones = _milestoneService.getUpcomingOccurrences(
      record.timeline,
      milestoneRules,
      milestoneHistory.map((item) => item.record).toList(growable: false),
      TimelineMilestoneRange(
        start: current,
        end: current.add(const Duration(days: 366)),
      ),
      now: current,
    );
    final milestoneRuleDetails = milestoneRules
        .map((rule) {
          final nextMilestone = _milestoneService.getNextOccurrence(
            rule,
            record.timeline,
            after: current.subtract(const Duration(days: 1)),
          );
          return TimelineMilestoneRuleDetail(
            rule: rule,
            nextMilestone: nextMilestone,
            historyRecords: milestoneHistory
                .where((item) => item.rule.id == rule.id)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    return TimelineDetail(
      timeline: record.timeline,
      milestoneRuleDetails: milestoneRuleDetails,
      upcomingMilestones: upcomingMilestones,
      milestoneHistory: milestoneHistory,
    );
  }

  Future<int> createTimeline(TimelineInput input) async {
    final now = DateTime.now();
    final timelineId = await _dao.insertTimeline(
      TimelinesCompanion.insert(
        title: input.title,
        startDate: _normalizeDate(input.startDate).millisecondsSinceEpoch,
        displayUnit: input.displayUnit.name,
        status: TimelineStatus.active.name,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    for (final rule in input.milestoneRules) {
      await _insertRule(timelineId, rule, now);
    }
    return timelineId;
  }

  Future<bool> updateTimeline(int id, TimelineInput input) async {
    final existing = await getTimelineById(id);
    if (existing == null || existing.status == TimelineStatus.archived) {
      return false;
    }

    final updated = await _dao.updateTimelineRecord(
      TimelineRow(
        id: existing.id,
        title: input.title,
        startDate: _normalizeDate(input.startDate).millisecondsSinceEpoch,
        displayUnit: input.displayUnit.name,
        status: existing.status.name,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!updated) {
      return false;
    }

    await _syncRules(id, input.milestoneRules);
    return true;
  }

  Future<void> noticeOccurrence(TimelineMilestoneOccurrence occurrence) {
    return _dao.markTimelineMilestoneRecordNoticed(occurrence);
  }

  Future<void> skipOccurrence(TimelineMilestoneOccurrence occurrence) {
    return _dao.markTimelineMilestoneRecordSkipped(occurrence);
  }

  Future<void> markOccurrenceNotified(TimelineMilestoneOccurrence occurrence) {
    return _dao.markTimelineMilestoneRecordNotified(occurrence);
  }

  Future<void> _syncRules(
    int timelineId,
    List<TimelineMilestoneRuleInput> inputs,
  ) async {
    final now = DateTime.now();
    final existingRules = await _dao.listTimelineMilestoneRulesForTimeline(
      timelineId,
    );
    final retainedIds = inputs.map((rule) => rule.id).whereType<int>().toSet();

    for (final rule in inputs) {
      if (rule.id == null) {
        await _insertRule(timelineId, rule, now);
        continue;
      }

      TimelineMilestoneRule? existing;
      for (final item in existingRules) {
        if (item.id == rule.id) {
          existing = item;
          break;
        }
      }
      if (existing == null) {
        continue;
      }

      await _dao.updateTimelineMilestoneRuleRecord(
        TimelineMilestoneRuleRow(
          id: existing.id,
          timelineId: timelineId,
          type: _encodeRuleType(rule.type),
          intervalValue: rule.intervalValue,
          intervalUnit: rule.intervalUnit.name,
          labelTemplate: rule.labelTemplate,
          reminderOffsetDays: rule.reminderOffsetDays,
          status: rule.status.name,
          createdAt: existing.createdAt.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
    }

    for (final existing in existingRules.where(
      (item) => !retainedIds.contains(item.id),
    )) {
      if (existing.status == TimelineMilestoneRuleStatus.archived) {
        continue;
      }
      await _dao.updateTimelineMilestoneRuleRecord(
        TimelineMilestoneRuleRow(
          id: existing.id,
          timelineId: existing.timelineId,
          type: _encodeRuleType(existing.type),
          intervalValue: existing.intervalValue,
          intervalUnit: existing.intervalUnit.name,
          labelTemplate: existing.labelTemplate,
          reminderOffsetDays: existing.reminderOffsetDays,
          status: TimelineMilestoneRuleStatus.archived.name,
          createdAt: existing.createdAt.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
    }
  }

  Future<void> _insertRule(
    int timelineId,
    TimelineMilestoneRuleInput rule,
    DateTime now,
  ) {
    return _dao.insertTimelineMilestoneRule(
      TimelineMilestoneRulesCompanion.insert(
        timelineId: timelineId,
        type: _encodeRuleType(rule.type),
        intervalValue: rule.intervalValue,
        intervalUnit: rule.intervalUnit.name,
        labelTemplate: Value(rule.labelTemplate),
        reminderOffsetDays: Value(rule.reminderOffsetDays),
        status: Value(rule.status.name),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  String _encodeRuleType(TimelineMilestoneRuleType type) {
    return switch (type) {
      TimelineMilestoneRuleType.everyNDays => 'every_n_days',
      TimelineMilestoneRuleType.everyNWeeks => 'every_n_weeks',
      TimelineMilestoneRuleType.everyNMonths => 'every_n_months',
      TimelineMilestoneRuleType.everyNYears => 'every_n_years',
    };
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
