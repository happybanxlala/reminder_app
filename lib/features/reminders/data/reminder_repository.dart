import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/milestone.dart';
import '../domain/milestone_reminder_rule.dart';
import '../domain/reminder_rule.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/task_scheduler.dart';
import '../domain/task_template.dart';
import '../domain/timeline.dart';
import '../domain/timeline_calculator.dart';
import 'local/app_database.dart';
import 'local/daos.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(appDatabaseProvider).reminderDao);
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(appDatabaseProvider).reminderDao);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    taskRepository: ref.watch(taskRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final todayHomeItemsProvider = StreamProvider<List<HomeItem>>((ref) {
  return ref.watch(homeRepositoryProvider).watchTodayItems();
});

final upcomingHomeItemsProvider = StreamProvider<List<HomeItem>>((ref) {
  return ref.watch(homeRepositoryProvider).watchUpcomingItems();
});

final overdueTasksProvider = StreamProvider<List<TaskBundle>>((ref) {
  return ref.watch(taskRepositoryProvider).watchOverdueTasks();
});

final historyItemsProvider = StreamProvider<List<HistoryItem>>((ref) {
  return ref.watch(homeRepositoryProvider).watchHistoryItems();
});

final taskHistoryProvider = StreamProvider<List<TaskBundle>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTaskHistory();
});

final milestoneHistoryProvider = StreamProvider<List<MilestoneBundle>>((ref) {
  return ref.watch(timelineRepositoryProvider).watchMilestoneHistory();
});

final taskTemplatesProvider = StreamProvider<List<TaskTemplate>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTemplates();
});

final timelinesProvider = StreamProvider<List<Timeline>>((ref) {
  return ref.watch(timelineRepositoryProvider).watchTimelines();
});

final taskDetailProvider = FutureProvider.family<TaskBundle?, int>((ref, id) {
  return ref.watch(taskRepositoryProvider).getTaskById(id);
});

final taskTemplateDetailProvider = FutureProvider.family<TaskTemplate?, int>((
  ref,
  id,
) {
  return ref.watch(taskRepositoryProvider).getTemplateById(id);
});

final timelineDetailProvider = FutureProvider.family<Timeline?, int>((ref, id) {
  return ref.watch(timelineRepositoryProvider).getTimelineById(id);
});

final timelineEditorDetailProvider =
    FutureProvider.family<TimelineDetail?, int>((ref, id) {
      return ref.watch(timelineRepositoryProvider).getTimelineDetailById(id);
    });

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

sealed class HomeItem {
  const HomeItem();
}

class TaskHomeItem extends HomeItem {
  const TaskHomeItem(this.bundle);

  final TaskBundle bundle;
}

class MilestoneHomeItem extends HomeItem {
  const MilestoneHomeItem(this.bundle);

  final MilestoneBundle bundle;
}

sealed class HistoryItem {
  const HistoryItem();
}

class TaskHistoryItem extends HistoryItem {
  const TaskHistoryItem(this.bundle);

  final TaskBundle bundle;
}

class MilestoneHistoryItem extends HistoryItem {
  const MilestoneHistoryItem(this.bundle);

  final MilestoneBundle bundle;
}

class TaskRepository {
  TaskRepository(this._dao, {TaskScheduler? scheduler})
    : _scheduler = scheduler ?? const TaskScheduler();

  final ReminderDao _dao;
  final TaskScheduler _scheduler;

  Stream<List<TaskTemplate>> watchTemplates() => _dao.watchTaskTemplates();

  Stream<List<TaskBundle>> watchAllTasks() => _dao.watchTaskBundles();

  Stream<List<TaskBundle>> watchTodayTasks({DateTime? now}) {
    return _dao.watchTaskBundles().map(
      (items) => items
          .where(
            (item) => _scheduler.isInToday(
              item.task,
              item.template.reminderRule,
              now ?? DateTime.now(),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<TaskBundle>> watchUpcomingTasks({DateTime? now}) {
    return _dao.watchTaskBundles().map(
      (items) => items
          .where(
            (item) => _scheduler.isUpcoming(
              item.task,
              item.template.reminderRule,
              now ?? DateTime.now(),
            ),
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

  Future<bool> updateTemplate(int id, TaskTemplateInput input) async {
    final existing = await getTemplateById(id);
    if (existing == null) {
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
    if (existing == null) {
      return false;
    }
    return _dao.updateTaskTemplateRecord(
      TaskTemplateRow(
        id: existing.id,
        title: existing.title,
        categoryId: existing.categoryId,
        note: existing.note,
        kind: existing.kind.name,
        status: TaskTemplateStatus.paused.name,
        firstDueDate: existing.firstDueDate.millisecondsSinceEpoch,
        repeatRule: existing.repeatRule?.encode(),
        reminderRule: existing.reminderRule.encode(),
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<TaskBundle?> getTaskById(int id) => _dao.getTaskBundleById(id);

  Future<TaskTemplate?> getTemplateById(int id) => _dao.getTaskTemplateById(id);

  Future<bool> updateTask(int id, DateTime dueDate) async {
    final bundle = await getTaskById(id);
    if (bundle == null || !bundle.task.isPending) {
      return false;
    }
    return _dao.updateTaskRecord(
      TaskRow(
        id: bundle.task.id,
        templateId: bundle.task.templateId,
        titleSnapshot: bundle.task.titleSnapshot,
        noteSnapshot: bundle.task.noteSnapshot,
        categoryId: bundle.task.categoryId,
        dueDate: _normalizeDate(dueDate).millisecondsSinceEpoch,
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
        templateId: template.id,
        titleSnapshot: template.title,
        noteSnapshot: Value(template.note),
        categoryId: Value(template.categoryId),
        dueDate: _normalizeDate(dueDate).millisecondsSinceEpoch,
        deferredDueDate: const Value.absent(),
        status: TaskStatus.pending.name,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
        resolvedAt: const Value.absent(),
      ),
    );
  }
}

class TimelineRepository {
  TimelineRepository(this._dao, {TimelineCalculator? calculator})
    : _calculator = calculator ?? const TimelineCalculator();

  final ReminderDao _dao;
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
    if (existing == null) {
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

  Future<bool> pauseTimeline(int id) async {
    final existing = await getTimelineById(id);
    if (existing == null) {
      return false;
    }
    return _dao.updateTimelineRecord(
      TimelineRow(
        id: existing.id,
        title: existing.title,
        startDate: existing.startDate.millisecondsSinceEpoch,
        displayUnit: existing.displayUnit.name,
        status: TimelineStatus.paused.name,
        milestoneReminderRule: existing.milestoneReminderRule.encode(),
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
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

class HomeRepository {
  HomeRepository({
    required TaskRepository taskRepository,
    required TimelineRepository timelineRepository,
  }) : _taskRepository = taskRepository,
       _timelineRepository = timelineRepository;

  final TaskRepository _taskRepository;
  final TimelineRepository _timelineRepository;

  Stream<List<HomeItem>> watchTodayItems() {
    return _combineLatest(
      _taskRepository.watchTodayTasks(),
      _timelineRepository.watchTodayMilestones(),
      (tasks, milestones) => [
        ...tasks.map(TaskHomeItem.new),
        ...milestones.map(MilestoneHomeItem.new),
      ],
    );
  }

  Stream<List<HomeItem>> watchUpcomingItems() {
    return _combineLatest(
      _taskRepository.watchUpcomingTasks(),
      _timelineRepository.watchUpcomingMilestones(),
      (tasks, milestones) => [
        ...tasks.map(TaskHomeItem.new),
        ...milestones.map(MilestoneHomeItem.new),
      ],
    );
  }

  Stream<List<HistoryItem>> watchHistoryItems() {
    return _combineLatest(
      _taskRepository.watchTaskHistory(),
      _timelineRepository.watchMilestoneHistory(),
      (tasks, milestones) => [
        ...tasks.map(TaskHistoryItem.new),
        ...milestones.map(MilestoneHistoryItem.new),
      ],
    );
  }

  Stream<T> _combineLatest<A, B, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    T Function(A a, B b) combine,
  ) {
    late StreamController<T> controller;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    A? latestA;
    B? latestB;

    void emitIfReady() {
      final valueA = latestA;
      final valueB = latestB;
      if (valueA != null && valueB != null) {
        controller.add(combine(valueA, valueB));
      }
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        subA = streamA.listen((value) {
          latestA = value;
          emitIfReady();
        });
        subB = streamB.listen((value) {
          latestB = value;
          emitIfReady();
        });
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
