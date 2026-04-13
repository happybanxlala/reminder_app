import 'package:drift/drift.dart';

import '../domain/reminder_rule.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/task_scheduler.dart';
import '../domain/task_template.dart';
import 'local/app_database.dart';
import 'local/task_timeline_dao.dart';

class TaskTemplateInput {
  const TaskTemplateInput({
    required this.title,
    this.note,
    this.categoryId,
    required this.kind,
    required this.firstDueDate,
    this.repeatRule,
    required this.reminderRule,
  });

  final String title;
  final String? note;
  final int? categoryId;
  final TaskKind kind;
  final DateTime firstDueDate;
  final RepeatRule? repeatRule;
  final ReminderRule reminderRule;
}

class TaskInput {
  const TaskInput({
    required this.title,
    this.note,
    this.categoryId,
    required this.dueDate,
    required this.reminderRule,
  });

  final String title;
  final String? note;
  final int? categoryId;
  final DateTime dueDate;
  final ReminderRule reminderRule;
}

class TaskRepository {
  TaskRepository(this._dao, {TaskScheduler? scheduler})
    : _scheduler = scheduler ?? const TaskScheduler();

  final TaskTimelineDao _dao;
  final TaskScheduler _scheduler;

  Stream<List<TaskTemplate>> watchTemplates() => _dao.watchTaskTemplates();

  Stream<List<TaskBundle>> watchAllTasks() => _dao.watchTaskBundles();

  Stream<List<TaskBundle>> watchTodayTasks({DateTime? now}) {
    return _dao.watchTaskBundles().map(
      (items) => items
          .where(
            (item) => _scheduler.isInToday(item.task, now ?? DateTime.now()),
          )
          .toList(growable: false),
    );
  }

  Stream<List<TaskBundle>> watchUpcomingTasks({DateTime? now}) {
    return _dao.watchTaskBundles().map(
      (items) => items
          .where(
            (item) => _scheduler.isUpcoming(item.task, now ?? DateTime.now()),
          )
          .toList(growable: false),
    );
  }

  Stream<List<TaskBundle>> watchOverdueTasks({DateTime? now}) {
    return _dao.watchTaskBundles().map(
      (items) => items
          .where(
            (item) => _scheduler.isOverdue(item.task, now ?? DateTime.now()),
          )
          .toList(growable: false),
    );
  }

  Stream<List<TaskBundle>> watchTaskHistory() {
    return _dao.watchTaskBundles().map(
      (items) =>
          items
              .where((item) => item.task.status != TaskStatus.pending)
              .toList(growable: false)
            ..sort(
              (a, b) => (b.task.resolvedAt ?? b.task.updatedAt).compareTo(
                a.task.resolvedAt ?? a.task.updatedAt,
              ),
            ),
    );
  }

  Future<int> createTemplate(TaskTemplateInput input) async {
    final now = DateTime.now();
    return _dao.insertTaskTemplate(
      TaskTemplatesCompanion.insert(
        title: input.title,
        categoryId: Value(input.categoryId),
        note: Value(input.note),
        kind: input.kind.name,
        status: TaskTemplateStatus.active.name,
        firstDueDate: _normalizeDate(input.firstDueDate).millisecondsSinceEpoch,
        repeatRule: Value(input.repeatRule?.encode()),
        reminderRule: input.reminderRule.encode(),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<int> createTemplateWithFirstTask(TaskTemplateInput input) async {
    final templateId = await createTemplate(input);
    final template = await getTemplateById(templateId);
    if (template == null) {
      throw StateError('Failed to create task template.');
    }
    await _createTaskFromTemplate(template, dueDate: template.firstDueDate);
    return templateId;
  }

  Future<int> createStandaloneTask(TaskInput input) {
    final now = DateTime.now();
    return _dao.insertTask(
      TasksCompanion.insert(
        templateId: const Value(null),
        kind: TaskKind.oneTime.name,
        titleSnapshot: input.title,
        noteSnapshot: Value(input.note),
        categoryId: Value(input.categoryId),
        dueDate: _normalizeDate(input.dueDate).millisecondsSinceEpoch,
        repeatRule: const Value(null),
        reminderRule: input.reminderRule.encode(),
        deferredDueDate: const Value.absent(),
        status: TaskStatus.pending.name,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
        resolvedAt: const Value.absent(),
      ),
    );
  }

  Future<bool> updateTemplate(int id, TaskTemplateInput input) async {
    final existing = await getTemplateById(id);
    if (existing == null || existing.status == TaskTemplateStatus.archived) {
      return false;
    }
    final now = DateTime.now();
    return _dao.updateTaskTemplateRecord(
      TaskTemplateRow(
        id: id,
        title: input.title,
        categoryId: input.categoryId,
        note: input.note,
        kind: input.kind.name,
        status: existing.status.name,
        firstDueDate: _normalizeDate(input.firstDueDate).millisecondsSinceEpoch,
        repeatRule: input.repeatRule?.encode(),
        reminderRule: input.reminderRule.encode(),
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> pauseTemplate(int id) async {
    final existing = await getTemplateById(id);
    if (existing == null || existing.status == TaskTemplateStatus.archived) {
      return false;
    }
    return _updateTemplateStatus(
      existing,
      TaskTemplateStatus.paused,
      cancelPendingTasks: true,
    );
  }

  Future<bool> resumeTemplate(int id) async {
    final existing = await getTemplateById(id);
    if (existing == null || existing.status != TaskTemplateStatus.paused) {
      return false;
    }
    return _updateTemplateStatus(existing, TaskTemplateStatus.active);
  }

  Future<bool> archiveTemplate(int id) async {
    final existing = await getTemplateById(id);
    if (existing == null || existing.status == TaskTemplateStatus.archived) {
      return false;
    }
    return _updateTemplateStatus(existing, TaskTemplateStatus.archived);
  }

  Future<TaskBundle?> getTaskById(int id) => _dao.getTaskBundleById(id);

  Future<TaskTemplate?> getTemplateById(int id) => _dao.getTaskTemplateById(id);

  Future<bool> updateTask(int id, DateTime dueDate) async {
    final bundle = await getTaskById(id);
    if (bundle == null ||
        !bundle.task.isPending ||
        bundle.template?.status == TaskTemplateStatus.archived) {
      return false;
    }
    return _dao.updateTaskRecord(
      TaskRow(
        id: bundle.task.id,
        templateId: bundle.task.templateId,
        kind: bundle.task.kind.name,
        titleSnapshot: bundle.task.titleSnapshot,
        noteSnapshot: bundle.task.noteSnapshot,
        categoryId: bundle.task.categoryId,
        dueDate: _normalizeDate(dueDate).millisecondsSinceEpoch,
        repeatRule: bundle.task.repeatRule?.encode(),
        reminderRule: bundle.task.reminderRule.encode(),
        deferredDueDate: bundle.task.deferredDueDate?.millisecondsSinceEpoch,
        status: bundle.task.status.name,
        createdAt: bundle.task.createdAt.millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        resolvedAt: bundle.task.resolvedAt?.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> completeTask(int id) =>
      _dao.transitionTask(id, TaskStatus.done, scheduler: _scheduler);

  Future<void> skipTask(int id) =>
      _dao.transitionTask(id, TaskStatus.skipped, scheduler: _scheduler);

  Future<void> cancelTask(int id) =>
      _dao.transitionTask(id, TaskStatus.canceled, scheduler: _scheduler);

  Future<bool> deferTask(int id, int days) => _dao.deferTask(id, days);

  Future<void> _createTaskFromTemplate(
    TaskTemplate template, {
    required DateTime dueDate,
  }) {
    final now = DateTime.now();
    return _dao.insertTask(
      TasksCompanion.insert(
        templateId: Value(template.id),
        kind: template.kind.name,
        titleSnapshot: template.title,
        noteSnapshot: Value(template.note),
        categoryId: Value(template.categoryId),
        dueDate: _normalizeDate(dueDate).millisecondsSinceEpoch,
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

  Future<bool> _updateTemplateStatus(
    TaskTemplate existing,
    TaskTemplateStatus status, {
    bool cancelPendingTasks = false,
  }) async {
    final now = DateTime.now();
    final updated = await _dao.updateTaskTemplateRecord(
      TaskTemplateRow(
        id: existing.id,
        title: existing.title,
        categoryId: existing.categoryId,
        note: existing.note,
        kind: existing.kind.name,
        status: status.name,
        firstDueDate: existing.firstDueDate.millisecondsSinceEpoch,
        repeatRule: existing.repeatRule?.encode(),
        reminderRule: existing.reminderRule.encode(),
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    if (!updated || !cancelPendingTasks) {
      return updated;
    }

    final bundles = await _dao.listTaskBundles();
    for (final bundle in bundles.where(
      (item) =>
          item.task.templateId == existing.id &&
          item.task.status == TaskStatus.pending,
    )) {
      await _dao.updateTaskRecord(
        TaskRow(
          id: bundle.task.id,
          templateId: bundle.task.templateId,
          kind: bundle.task.kind.name,
          titleSnapshot: bundle.task.titleSnapshot,
          noteSnapshot: bundle.task.noteSnapshot,
          categoryId: bundle.task.categoryId,
          dueDate: bundle.task.dueDate.millisecondsSinceEpoch,
          repeatRule: bundle.task.repeatRule?.encode(),
          reminderRule: bundle.task.reminderRule.encode(),
          deferredDueDate: null,
          status: TaskStatus.canceled.name,
          createdAt: bundle.task.createdAt.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
          resolvedAt: now.millisecondsSinceEpoch,
        ),
      );
    }
    return true;
  }
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
