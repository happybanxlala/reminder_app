import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/task_repository.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule.dart';
import 'package:reminder_app/features/reminders/domain/task.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';

void main() {
  test('recurring task done creates next task occurrence', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    final templateId = await repository.createTemplateWithFirstTask(
      TaskTemplateInput(
        title: 'Weekly trash',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 1),
        reminderRule: const ReminderRule.onDue(),
      ),
    );

    final task = (await repository.watchAllTasks().first).single;
    await repository.completeTask(task.task.id);

    final tasks = await repository.watchAllTasks().first;
    expect(tasks, hasLength(2));
    expect(tasks.first.task.status, TaskStatus.done);
    expect(tasks.last.task.status, TaskStatus.pending);
    expect(tasks.last.task.dueDate, DateTime(2026, 4, 17));
    expect(tasks.last.template!.id, templateId);
  });

  test('recurring task skipped creates next task occurrence', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    await repository.createTemplateWithFirstTask(
      TaskTemplateInput(
        title: 'Weekly recycling',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 1),
        reminderRule: const ReminderRule.onDue(),
      ),
    );

    final task = (await repository.watchAllTasks().first).single;
    await repository.skipTask(task.task.id);

    final tasks = await repository.watchAllTasks().first;
    expect(tasks, hasLength(2));
    expect(tasks.first.task.status, TaskStatus.skipped);
    expect(tasks.last.task.status, TaskStatus.pending);
    expect(tasks.last.task.dueDate, DateTime(2026, 4, 17));
  });

  test('defer only affects current task effective due date', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    await repository.createStandaloneTask(
      TaskInput(
        title: 'Laundry',
        dueDate: DateTime(2026, 4, 10),
        reminderRule: const ReminderRule.onDue(),
      ),
    );

    final task = (await repository.watchAllTasks().first).single;
    final deferred = await repository.deferTask(task.task.id, 2);
    final updatedTask = (await repository.watchAllTasks().first).single.task;

    expect(deferred, isTrue);
    expect(updatedTask.effectiveDueDate, DateTime(2026, 4, 12));
    expect(updatedTask.templateId, isNull);
  });

  test('cancel task pauses template and does not create next task', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    final templateId = await repository.createTemplateWithFirstTask(
      TaskTemplateInput(
        title: 'Pet nails',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.month, interval: 1),
        reminderRule: const ReminderRule.advance(2),
      ),
    );

    final task = (await repository.watchAllTasks().first).single.task;
    await repository.cancelTask(task.id);

    final tasks = await repository.watchAllTasks().first;
    final template = await repository.getTemplateById(templateId);
    expect(tasks, hasLength(1));
    expect(tasks.single.task.status, TaskStatus.canceled);
    expect(template!.status, TaskTemplateStatus.paused);
  });

  test(
    'pausing template cancels all pending tasks and clears deferred date',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = TaskRepository(db.taskTimelineDao);

      final templateId = await repository.createTemplateWithFirstTask(
        TaskTemplateInput(
          title: 'Vaccum',
          kind: TaskKind.recurring,
          firstDueDate: DateTime(2026, 4, 10),
          repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 1),
          reminderRule: const ReminderRule.advance(1),
        ),
      );

      final firstTask = (await repository.watchAllTasks().first).single.task;
      await repository.deferTask(firstTask.id, 2);
      expect(await repository.pauseTemplate(templateId), isTrue);

      final pausedTask = (await repository.watchAllTasks().first).single.task;
      expect(pausedTask.status, TaskStatus.canceled);
      expect(pausedTask.deferredDueDate, isNull);
    },
  );

  test('editing template does not mutate existing task snapshot', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    final templateId = await repository.createTemplateWithFirstTask(
      TaskTemplateInput(
        title: 'Original title',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 2),
        reminderRule: const ReminderRule.onDue(),
      ),
    );

    await repository.updateTemplate(
      templateId,
      TaskTemplateInput(
        title: 'Updated title',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 2),
        reminderRule: const ReminderRule.onDue(),
      ),
    );

    final task = (await repository.watchAllTasks().first).single.task;
    final template = await repository.getTemplateById(templateId);
    expect(task.titleSnapshot, 'Original title');
    expect(template!.title, 'Updated title');
  });

  test('template can resume from paused and archive from active', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    final templateId = await repository.createTemplate(
      TaskTemplateInput(
        title: 'Status test',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 1),
        reminderRule: const ReminderRule.onDue(),
      ),
    );

    expect(await repository.pauseTemplate(templateId), isTrue);
    expect(
      (await repository.getTemplateById(templateId))!.status,
      TaskTemplateStatus.paused,
    );

    expect(await repository.resumeTemplate(templateId), isTrue);
    expect(
      (await repository.getTemplateById(templateId))!.status,
      TaskTemplateStatus.active,
    );

    expect(await repository.archiveTemplate(templateId), isTrue);
    expect(
      (await repository.getTemplateById(templateId))!.status,
      TaskTemplateStatus.archived,
    );
  });

  test('archived template is read-only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TaskRepository(db.taskTimelineDao);

    final templateId = await repository.createTemplate(
      TaskTemplateInput(
        title: 'Archived rule',
        kind: TaskKind.recurring,
        firstDueDate: DateTime(2026, 4, 10),
        repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 1),
        reminderRule: const ReminderRule.onDue(),
      ),
    );
    expect(await repository.archiveTemplate(templateId), isTrue);

    expect(
      await repository.updateTemplate(
        templateId,
        TaskTemplateInput(
          title: 'Should fail',
          kind: TaskKind.recurring,
          firstDueDate: DateTime(2026, 4, 10),
          repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 2),
          reminderRule: const ReminderRule.immediate(),
        ),
      ),
      isFalse,
    );
    expect(await repository.pauseTemplate(templateId), isFalse);
    expect(await repository.resumeTemplate(templateId), isFalse);
  });
}
