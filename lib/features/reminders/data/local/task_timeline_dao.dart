import 'package:drift/drift.dart';

import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task.dart';
import '../../domain/task_scheduler.dart';
import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_record.dart';
import '../../domain/timeline_milestone_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'task_timeline_dao.g.dart';

class TaskBundle {
  const TaskBundle({required this.task, required this.template});

  final Task task;
  final TaskTemplate? template;
}

class TimelineMilestoneRecordBundle {
  const TimelineMilestoneRecordBundle({
    required this.record,
    required this.rule,
    required this.timeline,
  });

  final TimelineMilestoneRecord record;
  final TimelineMilestoneRule rule;
  final Timeline timeline;
}

class TimelineDetailRecord {
  const TimelineDetailRecord({
    required this.timeline,
    required this.rules,
    required this.historyRecords,
  });

  final Timeline timeline;
  final List<TimelineMilestoneRule> rules;
  final List<TimelineMilestoneRecordBundle> historyRecords;
}

@DriftAccessor(
  tables: [
    TaskTemplates,
    Tasks,
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
  ],
)
class TaskTimelineDao extends DatabaseAccessor<AppDatabase>
    with _$TaskTimelineDaoMixin {
  TaskTimelineDao(super.attachedDatabase);

  Future<int> insertTaskTemplate(TaskTemplatesCompanion entry) {
    return into(taskTemplates).insert(entry);
  }

  Future<int> insertTask(TasksCompanion entry) {
    return into(tasks).insert(entry);
  }

  Future<bool> updateTaskTemplateRecord(TaskTemplateRow entry) {
    return update(taskTemplates).replace(entry);
  }

  Future<bool> updateTaskRecord(TaskRow entry) {
    return update(tasks).replace(entry);
  }

  Future<int> insertTimeline(TimelinesCompanion entry) {
    return into(timelines).insert(entry);
  }

  Future<bool> updateTimelineRecord(TimelineRow entry) {
    return update(timelines).replace(entry);
  }

  Future<int> insertTimelineMilestoneRule(
    TimelineMilestoneRulesCompanion entry,
  ) {
    return into(timelineMilestoneRules).insert(entry);
  }

  Future<bool> updateTimelineMilestoneRuleRecord(
    TimelineMilestoneRuleRow entry,
  ) {
    return update(timelineMilestoneRules).replace(entry);
  }

  Future<int> insertTimelineMilestoneRecord(
    TimelineMilestoneRecordsCompanion entry,
  ) {
    return into(timelineMilestoneRecords).insert(entry);
  }

  Future<bool> updateTimelineMilestoneRecordRecord(
    TimelineMilestoneRecordRow entry,
  ) {
    return update(timelineMilestoneRecords).replace(entry);
  }

  Stream<List<TaskTemplate>> watchTaskTemplates() {
    final query = select(taskTemplates)
      ..orderBy([
        (t) => OrderingTerm.asc(t.status),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    return query.watch().map((rows) => rows.map(_toTaskTemplate).toList());
  }

  Future<TaskTemplate?> getTaskTemplateById(int id) async {
    final row = await (select(
      taskTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTaskTemplate(row);
  }

  Stream<List<TaskBundle>> watchTaskBundles() {
    return _taskBundleQuery().watch().map(
      (rows) => rows.map(_mapTaskBundle).toList(),
    );
  }

  Future<TaskBundle?> getTaskBundleById(int id) async {
    final rows = await _taskBundleQuery(
      where: (t) => t.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapTaskBundle(rows.single);
  }

  Future<List<TaskBundle>> listTaskBundles() {
    return _taskBundleQuery().get().then(
      (rows) => rows.map(_mapTaskBundle).toList(),
    );
  }

  Stream<List<Timeline>> watchTimelines() {
    final query = select(timelines)
      ..orderBy([
        (t) => OrderingTerm.asc(t.status),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    return query.watch().map((rows) => rows.map(_toTimeline).toList());
  }

  Future<Timeline?> getTimelineById(int id) async {
    final row = await (select(
      timelines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTimeline(row);
  }

  Stream<List<TimelineMilestoneRule>> watchTimelineMilestoneRules() {
    final query = select(timelineMilestoneRules)
      ..orderBy([
        (t) => OrderingTerm.asc(t.timelineId),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toTimelineMilestoneRule).toList(),
    );
  }

  Future<List<TimelineMilestoneRule>> listTimelineMilestoneRulesForTimeline(
    int timelineId,
  ) async {
    final rows =
        await (select(timelineMilestoneRules)
              ..where((t) => t.timelineId.equals(timelineId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toTimelineMilestoneRule).toList(growable: false);
  }

  Future<List<TimelineMilestoneRule>>
  listVisibleTimelineMilestoneRulesForTimeline(int timelineId) async {
    final rows =
        await (select(timelineMilestoneRules)
              ..where(
                (t) =>
                    t.timelineId.equals(timelineId) &
                    t.status.isNotValue(
                      TimelineMilestoneRuleStatus.archived.name,
                    ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toTimelineMilestoneRule).toList(growable: false);
  }

  Future<TimelineMilestoneRule?> getTimelineMilestoneRuleById(int id) async {
    final row = await (select(
      timelineMilestoneRules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTimelineMilestoneRule(row);
  }

  Stream<List<TimelineMilestoneRecord>> watchTimelineMilestoneRecords() {
    final query = select(timelineMilestoneRecords)
      ..orderBy([
        (t) => OrderingTerm.asc(t.targetDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toTimelineMilestoneRecord).toList(),
    );
  }

  Future<List<TimelineMilestoneRecord>> listTimelineMilestoneRecordsForTimeline(
    int timelineId,
  ) async {
    final rows =
        await (select(timelineMilestoneRecords)
              ..where((t) => t.timelineId.equals(timelineId))
              ..orderBy([(t) => OrderingTerm.desc(t.targetDate)]))
            .get();
    return rows.map(_toTimelineMilestoneRecord).toList(growable: false);
  }

  Stream<List<TimelineMilestoneRecordBundle>>
  watchTimelineMilestoneRecordBundles() {
    return _timelineMilestoneRecordBundleQuery().watch().map(
      (rows) => rows.map(_mapTimelineMilestoneRecordBundle).toList(),
    );
  }

  Future<List<TimelineMilestoneRecordBundle>>
  listTimelineMilestoneRecordBundlesForTimeline(int timelineId) {
    return _timelineMilestoneRecordBundleQuery(
      where: (r) => r.timelineId.equals(timelineId),
    ).get().then(
      (rows) => rows.map(_mapTimelineMilestoneRecordBundle).toList(),
    );
  }

  Future<TimelineMilestoneRecord?> getTimelineMilestoneRecordByOccurrence({
    required int ruleId,
    required int occurrenceIndex,
  }) async {
    final row =
        await (select(timelineMilestoneRecords)..where(
              (t) =>
                  t.ruleId.equals(ruleId) &
                  t.occurrenceIndex.equals(occurrenceIndex),
            ))
            .getSingleOrNull();
    return row == null ? null : _toTimelineMilestoneRecord(row);
  }

  Future<TimelineDetailRecord?> getTimelineDetailRecordById(int id) async {
    final timeline = await getTimelineById(id);
    if (timeline == null) {
      return null;
    }
    final rules = await listVisibleTimelineMilestoneRulesForTimeline(id);
    final records = await listTimelineMilestoneRecordBundlesForTimeline(id);
    return TimelineDetailRecord(
      timeline: timeline,
      rules: rules,
      historyRecords: records
          .where((item) => item.record.status != MilestoneStatus.upcoming)
          .toList(growable: false),
    );
  }

  Future<void> upsertTimelineMilestoneRecordForOccurrence({
    required TimelineMilestoneOccurrence occurrence,
    required MilestoneStatus status,
    DateTime? notifiedAt,
    DateTime? actedAt,
  }) async {
    final existing = await getTimelineMilestoneRecordByOccurrence(
      ruleId: occurrence.ruleId,
      occurrenceIndex: occurrence.occurrenceIndex,
    );
    final now = DateTime.now();
    if (existing == null) {
      await insertTimelineMilestoneRecord(
        TimelineMilestoneRecordsCompanion.insert(
          timelineId: occurrence.timelineId,
          ruleId: occurrence.ruleId,
          occurrenceIndex: occurrence.occurrenceIndex,
          targetDate: occurrence.targetDate.millisecondsSinceEpoch,
          status: status.name,
          notifiedAt: Value(notifiedAt?.millisecondsSinceEpoch),
          actedAt: Value(actedAt?.millisecondsSinceEpoch),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return;
    }

    await updateTimelineMilestoneRecordRecord(
      TimelineMilestoneRecordRow(
        id: existing.id,
        timelineId: existing.timelineId,
        ruleId: existing.ruleId,
        occurrenceIndex: existing.occurrenceIndex,
        targetDate: occurrence.targetDate.millisecondsSinceEpoch,
        status: status.name,
        notifiedAt: (notifiedAt ?? existing.notifiedAt)?.millisecondsSinceEpoch,
        actedAt: (actedAt ?? existing.actedAt)?.millisecondsSinceEpoch,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> markTimelineMilestoneRecordNoticed(
    TimelineMilestoneOccurrence occurrence,
  ) {
    final now = DateTime.now();
    return upsertTimelineMilestoneRecordForOccurrence(
      occurrence: occurrence,
      status: MilestoneStatus.noticed,
      actedAt: now,
    );
  }

  Future<void> markTimelineMilestoneRecordSkipped(
    TimelineMilestoneOccurrence occurrence,
  ) {
    final now = DateTime.now();
    return upsertTimelineMilestoneRecordForOccurrence(
      occurrence: occurrence,
      status: MilestoneStatus.skipped,
      actedAt: now,
    );
  }

  Future<void> markTimelineMilestoneRecordNotified(
    TimelineMilestoneOccurrence occurrence,
  ) {
    final now = DateTime.now();
    return upsertTimelineMilestoneRecordForOccurrence(
      occurrence: occurrence,
      status: MilestoneStatus.upcoming,
      notifiedAt: now,
    );
  }

  Future<void> transitionTask(
    int taskId,
    TaskStatus nextStatus, {
    required TaskScheduler scheduler,
  }) async {
    await transaction(() async {
      final bundle = await getTaskBundleById(taskId);
      if (bundle == null || !bundle.task.isPending) {
        return;
      }

      final now = DateTime.now();
      await (update(tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(nextStatus.name),
          updatedAt: Value(now.millisecondsSinceEpoch),
          resolvedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

      final template = bundle.template;
      if ((nextStatus == TaskStatus.done || nextStatus == TaskStatus.skipped) &&
          bundle.task.isRecurring &&
          template != null &&
          template.status == TaskTemplateStatus.active) {
        final nextDueDate = scheduler.nextDueDate(
          bundle.task,
          template.repeatRule,
        );
        await insertTask(
          TasksCompanion.insert(
            templateId: Value(template.id),
            kind: template.kind.name,
            titleSnapshot: template.title,
            noteSnapshot: Value(template.note),
            categoryId: Value(template.categoryId),
            dueDate: nextDueDate.millisecondsSinceEpoch,
            repeatRule: Value(template.repeatRule?.encode()),
            reminderRule: template.reminderRule.encode(),
            deferredDueDate: const Value.absent(),
            status: TaskStatus.pending.name,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            resolvedAt: const Value.absent(),
          ),
        );
      }

      if (nextStatus == TaskStatus.canceled &&
          bundle.task.isRecurring &&
          template != null) {
        await _pauseTemplateAndCancelPendingTasks(template.id, now);
      }
    });
  }

  Future<bool> deferTask(int taskId, int days) async {
    if (days < 1) {
      return false;
    }
    final bundle = await getTaskBundleById(taskId);
    if (bundle == null || !bundle.task.isPending) {
      return false;
    }
    final nextDate = bundle.task.effectiveDueDate
        .add(Duration(days: days))
        .millisecondsSinceEpoch;
    final updatedRows = await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(
          TasksCompanion(
            deferredDueDate: Value(nextDate),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    return updatedRows > 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _taskBundleQuery({
    Expression<bool> Function($TasksTable t)? where,
    int? limit,
  }) {
    final query = select(tasks).join([
      leftOuterJoin(
        taskTemplates,
        taskTemplates.id.equalsExp(tasks.templateId),
      ),
    ]);
    if (where != null) {
      query.where(where(tasks));
    }
    query.orderBy([
      OrderingTerm.asc(tasks.dueDate),
      OrderingTerm.asc(tasks.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic>
  _timelineMilestoneRecordBundleQuery({
    Expression<bool> Function($TimelineMilestoneRecordsTable t)? where,
    int? limit,
  }) {
    final query = select(timelineMilestoneRecords).join([
      innerJoin(
        timelines,
        timelines.id.equalsExp(timelineMilestoneRecords.timelineId),
      ),
      innerJoin(
        timelineMilestoneRules,
        timelineMilestoneRules.id.equalsExp(timelineMilestoneRecords.ruleId),
      ),
    ]);
    if (where != null) {
      query.where(where(timelineMilestoneRecords));
    }
    query.orderBy([
      OrderingTerm.desc(timelineMilestoneRecords.targetDate),
      OrderingTerm.desc(timelineMilestoneRecords.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  TaskBundle _mapTaskBundle(TypedResult row) {
    return TaskBundle(
      task: _toTask(row.readTable(tasks)),
      template: row.readTableOrNull(taskTemplates) == null
          ? null
          : _toTaskTemplate(row.readTable(taskTemplates)),
    );
  }

  TimelineMilestoneRecordBundle _mapTimelineMilestoneRecordBundle(
    TypedResult row,
  ) {
    return TimelineMilestoneRecordBundle(
      record: _toTimelineMilestoneRecord(
        row.readTable(timelineMilestoneRecords),
      ),
      rule: _toTimelineMilestoneRule(row.readTable(timelineMilestoneRules)),
      timeline: _toTimeline(row.readTable(timelines)),
    );
  }

  TaskTemplate _toTaskTemplate(TaskTemplateRow row) {
    return TaskTemplate(
      id: row.id,
      title: row.title,
      categoryId: row.categoryId,
      note: row.note,
      kind: TaskKind.values.byName(row.kind),
      status: TaskTemplateStatus.values.byName(row.status),
      firstDueDate: DateTime.fromMillisecondsSinceEpoch(row.firstDueDate),
      repeatRule: RepeatRule.parse(row.repeatRule),
      reminderRule: ReminderRule.decode(row.reminderRule),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  Task _toTask(TaskRow row) {
    return Task(
      id: row.id,
      templateId: row.templateId,
      kind: TaskKind.values.byName(row.kind),
      titleSnapshot: row.titleSnapshot,
      noteSnapshot: row.noteSnapshot,
      categoryId: row.categoryId,
      dueDate: DateTime.fromMillisecondsSinceEpoch(row.dueDate),
      repeatRule: RepeatRule.parse(row.repeatRule),
      reminderRule: ReminderRule.decode(row.reminderRule),
      deferredDueDate: row.deferredDueDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deferredDueDate!),
      status: TaskStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      resolvedAt: row.resolvedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.resolvedAt!),
    );
  }

  Future<void> _pauseTemplateAndCancelPendingTasks(
    int templateId,
    DateTime now,
  ) async {
    await (update(taskTemplates)..where((t) => t.id.equals(templateId))).write(
      TaskTemplatesCompanion(
        status: Value(TaskTemplateStatus.paused.name),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    await (update(tasks)..where(
          (t) =>
              t.templateId.equals(templateId) &
              t.status.equals(TaskStatus.pending.name),
        ))
        .write(
          TasksCompanion(
            status: Value(TaskStatus.canceled.name),
            deferredDueDate: const Value(null),
            updatedAt: Value(now.millisecondsSinceEpoch),
            resolvedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
  }

  Timeline _toTimeline(TimelineRow row) {
    return Timeline(
      id: row.id,
      title: row.title,
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
      displayUnit: TimelineDisplayUnit.values.byName(row.displayUnit),
      status: TimelineStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  TimelineMilestoneRule _toTimelineMilestoneRule(TimelineMilestoneRuleRow row) {
    return TimelineMilestoneRule(
      id: row.id,
      timelineId: row.timelineId,
      type: _timelineMilestoneRuleType(row.type),
      intervalValue: row.intervalValue,
      intervalUnit: TimelineMilestoneIntervalUnit.values.byName(
        row.intervalUnit,
      ),
      labelTemplate: row.labelTemplate,
      reminderOffsetDays: row.reminderOffsetDays,
      status: TimelineMilestoneRuleStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  TimelineMilestoneRecord _toTimelineMilestoneRecord(
    TimelineMilestoneRecordRow row,
  ) {
    return TimelineMilestoneRecord(
      id: row.id,
      timelineId: row.timelineId,
      ruleId: row.ruleId,
      occurrenceIndex: row.occurrenceIndex,
      targetDate: DateTime.fromMillisecondsSinceEpoch(row.targetDate),
      status: MilestoneStatus.values.byName(row.status),
      notifiedAt: row.notifiedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.notifiedAt!),
      actedAt: row.actedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.actedAt!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  TimelineMilestoneRuleType _timelineMilestoneRuleType(String value) {
    return switch (value) {
      'every_n_days' => TimelineMilestoneRuleType.everyNDays,
      'every_n_weeks' => TimelineMilestoneRuleType.everyNWeeks,
      'every_n_months' => TimelineMilestoneRuleType.everyNMonths,
      'every_n_years' => TimelineMilestoneRuleType.everyNYears,
      _ => TimelineMilestoneRuleType.everyNDays,
    };
  }
}
