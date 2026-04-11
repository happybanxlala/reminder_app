import 'package:drift/drift.dart';

import '../../domain/milestone.dart';
import '../../domain/milestone_reminder_rule.dart';
import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task.dart';
import '../../domain/task_scheduler.dart';
import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

class TaskBundle {
  const TaskBundle({required this.task, required this.template});

  final Task task;
  final TaskTemplate template;
}

class MilestoneBundle {
  const MilestoneBundle({required this.milestone, required this.timeline});

  final Milestone milestone;
  final Timeline timeline;
}

class TimelineDetailRecord {
  const TimelineDetailRecord({
    required this.timeline,
    required this.customMilestones,
    required this.ruleBasedMilestones,
  });

  final Timeline timeline;
  final List<MilestoneBundle> customMilestones;
  final List<MilestoneBundle> ruleBasedMilestones;
}

@DriftAccessor(tables: [TaskTemplates, Tasks, Timelines, Milestones])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.attachedDatabase);

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

  Future<int> insertMilestone(MilestonesCompanion entry) {
    return into(milestones).insert(entry);
  }

  Future<bool> updateMilestoneRecord(MilestoneRow entry) {
    return update(milestones).replace(entry);
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

  Stream<List<MilestoneBundle>> watchMilestoneBundles() {
    return _milestoneBundleQuery().watch().map(
      (rows) => rows.map(_mapMilestoneBundle).toList(),
    );
  }

  Future<List<MilestoneBundle>> listMilestoneBundlesForTimeline(
    int timelineId,
  ) {
    return _milestoneBundleQuery(
      where: (m) => m.timelineId.equals(timelineId),
    ).get().then((rows) => rows.map(_mapMilestoneBundle).toList());
  }

  Future<TimelineDetailRecord?> getTimelineDetailRecordById(int id) async {
    final timeline = await getTimelineById(id);
    if (timeline == null) {
      return null;
    }
    final milestones = await listMilestoneBundlesForTimeline(id);
    return TimelineDetailRecord(
      timeline: timeline,
      customMilestones: milestones
          .where((item) => item.milestone.source == MilestoneSource.custom)
          .toList(growable: false),
      ruleBasedMilestones: milestones
          .where((item) => item.milestone.source == MilestoneSource.ruleBased)
          .toList(growable: false),
    );
  }

  Future<MilestoneBundle?> getMilestoneBundleById(int id) async {
    final rows = await _milestoneBundleQuery(
      where: (m) => m.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapMilestoneBundle(rows.single);
  }

  Future<void> deleteUpcomingRuleBasedMilestones(int timelineId) {
    return (delete(milestones)..where(
          (m) =>
              m.timelineId.equals(timelineId) &
              m.source.equals(MilestoneSource.ruleBased.name) &
              m.status.equals(MilestoneStatus.upcoming.name),
        ))
        .go();
  }

  Future<void> deleteUpcomingCustomMilestones(int timelineId) {
    return (delete(milestones)..where(
          (m) =>
              m.timelineId.equals(timelineId) &
              m.source.equals(MilestoneSource.custom.name) &
              m.status.equals(MilestoneStatus.upcoming.name),
        ))
        .go();
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

      if ((nextStatus == TaskStatus.done || nextStatus == TaskStatus.skipped) &&
          bundle.template.kind == TaskKind.recurring &&
          bundle.template.status == TaskTemplateStatus.active) {
        final nextDueDate = scheduler.nextDueDate(bundle.task, bundle.template);
        await insertTask(
          TasksCompanion.insert(
            templateId: bundle.template.id,
            titleSnapshot: bundle.template.title,
            noteSnapshot: Value(bundle.template.note),
            categoryId: Value(bundle.template.categoryId),
            dueDate: nextDueDate.millisecondsSinceEpoch,
            deferredDueDate: const Value.absent(),
            status: TaskStatus.pending.name,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            resolvedAt: const Value.absent(),
          ),
        );
      }

      if (nextStatus == TaskStatus.canceled) {
        await (update(
          taskTemplates,
        )..where((t) => t.id.equals(bundle.template.id))).write(
          TaskTemplatesCompanion(
            status: Value(TaskTemplateStatus.paused.name),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
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

  Future<void> noticeMilestone(int milestoneId) async {
    await _transitionMilestone(milestoneId, MilestoneStatus.noticed);
  }

  Future<void> skipMilestone(int milestoneId) async {
    await _transitionMilestone(milestoneId, MilestoneStatus.skipped);
  }

  Future<void> _transitionMilestone(int milestoneId, MilestoneStatus status) {
    return (update(milestones)..where((m) => m.id.equals(milestoneId))).write(
      MilestonesCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _taskBundleQuery({
    Expression<bool> Function($TasksTable t)? where,
    int? limit,
  }) {
    final query = select(tasks).join([
      innerJoin(taskTemplates, taskTemplates.id.equalsExp(tasks.templateId)),
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

  JoinedSelectStatement<HasResultSet, dynamic> _milestoneBundleQuery({
    Expression<bool> Function($MilestonesTable m)? where,
    int? limit,
  }) {
    final query = select(milestones).join([
      innerJoin(timelines, timelines.id.equalsExp(milestones.timelineId)),
    ]);
    if (where != null) {
      query.where(where(milestones));
    }
    query.orderBy([
      OrderingTerm.asc(milestones.targetDate),
      OrderingTerm.asc(milestones.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  TaskBundle _mapTaskBundle(TypedResult row) {
    return TaskBundle(
      task: _toTask(row.readTable(tasks)),
      template: _toTaskTemplate(row.readTable(taskTemplates)),
    );
  }

  MilestoneBundle _mapMilestoneBundle(TypedResult row) {
    return MilestoneBundle(
      milestone: _toMilestone(row.readTable(milestones)),
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
      titleSnapshot: row.titleSnapshot,
      noteSnapshot: row.noteSnapshot,
      categoryId: row.categoryId,
      dueDate: DateTime.fromMillisecondsSinceEpoch(row.dueDate),
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

  Timeline _toTimeline(TimelineRow row) {
    return Timeline(
      id: row.id,
      title: row.title,
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
      displayUnit: TimelineDisplayUnit.values.byName(row.displayUnit),
      status: TimelineStatus.values.byName(row.status),
      milestoneReminderRule: MilestoneReminderRule.decode(
        row.milestoneReminderRule,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  Milestone _toMilestone(MilestoneRow row) {
    return Milestone(
      id: row.id,
      timelineId: row.timelineId,
      targetDate: DateTime.fromMillisecondsSinceEpoch(row.targetDate),
      description: row.description,
      source: MilestoneSource.values.byName(row.source),
      status: MilestoneStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
