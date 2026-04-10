import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/action_category.dart';
import '../domain/reminder.dart';
import '../domain/recurring_reminder.dart';
import '../domain/topic_category.dart';
import 'local/app_database.dart';
import 'local/daos.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ReminderRepository(database.reminderDao);
});

final remindersListProvider = StreamProvider<List<ReminderModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchAll();
});

final activePendingProvider = StreamProvider<List<ReminderModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchActivePending();
});

final todayPendingProvider = StreamProvider<List<ReminderModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchTodayPending();
});

final completedOrSkippedProvider = StreamProvider<List<ReminderModel>>((ref) {
  return ref
      .watch(reminderRepositoryProvider)
      .watchCompletedOrSkipped(limit: 30);
});

final nextReminderProvider = StreamProvider<ReminderModel?>((ref) {
  return ref.watch(reminderRepositoryProvider).watchNextReminder();
});

final reminderDetailProvider = FutureProvider.family<ReminderModel?, int>((
  ref,
  reminderId,
) {
  return ref.watch(reminderRepositoryProvider).getEditableById(reminderId);
});

final recurringRemindersProvider = StreamProvider<List<RecurringReminderModel>>(
  (ref) {
    return ref.watch(reminderRepositoryProvider).watchAllRecurringReminders();
  },
);

@Deprecated('Use recurringRemindersProvider instead.')
final reminderSeriesListProvider = recurringRemindersProvider;

final recurringReminderDetailProvider =
    FutureProvider.family<RecurringReminderModel?, int>((
      ref,
      recurringReminderId,
    ) {
      return ref
          .watch(reminderRepositoryProvider)
          .getRecurringReminderDetailById(recurringReminderId);
    });

@Deprecated('Use recurringReminderDetailProvider instead.')
final reminderSeriesDetailProvider = recurringReminderDetailProvider;

final topicCategoriesProvider = FutureProvider<List<TopicCategoryModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).listTopicCategories();
});

@Deprecated('Use topicCategoriesProvider instead.')
final issueTypesProvider = topicCategoriesProvider;

final actionCategoriesProvider = FutureProvider<List<ActionCategoryModel>>((
  ref,
) {
  return ref.watch(reminderRepositoryProvider).listActionCategories();
});

@Deprecated('Use actionCategoriesProvider instead.')
final handleTypesProvider = actionCategoriesProvider;

class ReminderInput {
  const ReminderInput({
    required this.title,
    this.note,
    required this.trackingMode,
    required this.triggerMode,
    this.triggerOffsetDays,
    this.dueAt,
    this.startAt,
    this.repeatRule,
    this.topicCategoryId,
    this.actionCategoryId,
  });

  final String title;
  final String? note;
  final int trackingMode;
  final int triggerMode;
  final int? triggerOffsetDays;
  final DateTime? dueAt;
  final DateTime? startAt;
  final String? repeatRule;
  final int? topicCategoryId;
  final int? actionCategoryId;

  bool get isRecurring => repeatRule != null;
}

@Deprecated('Use ReminderInput instead.')
class ReminderUpsert extends ReminderInput {
  const ReminderUpsert({
    required super.title,
    super.note,
    required int timeBasis,
    required int notifyStrategy,
    int? remindDays,
    super.dueAt,
    super.startAt,
    super.repeatRule,
    int? issueTypeId,
    int? handleTypeId,
  }) : super(
         trackingMode: timeBasis,
         triggerMode: notifyStrategy,
         triggerOffsetDays: remindDays,
         topicCategoryId: issueTypeId,
         actionCategoryId: handleTypeId,
       );
}

class ReminderRepository {
  const ReminderRepository(this._dao);

  final ReminderDao _dao;

  Stream<List<ReminderModel>> watchAll() {
    return _dao.watchAll().map((items) => items.map(_toDomain).toList());
  }

  Stream<List<ReminderModel>> watchActivePending() {
    return _dao.watchActivePending().map(
      (items) => items.map(_toDomain).toList(),
    );
  }

  Stream<List<ReminderModel>> watchTodayPending() {
    return _dao.watchTodayPending().map(
      (items) => items.map(_toDomain).toList(),
    );
  }

  Stream<List<ReminderModel>> watchCompletedOrSkipped({int limit = 30}) {
    return _dao
        .watchCompletedOrSkipped(limit: limit)
        .map((items) => items.map(_toDomain).toList());
  }

  Stream<ReminderModel?> watchNextReminder() {
    return _dao.watchNextReminder().map(
      (item) => item == null ? null : _toDomain(item),
    );
  }

  Stream<List<RecurringReminderModel>> watchAllRecurringReminders() {
    return _dao.watchAllRecurringReminders().map(
      (items) => items.map(_toRecurringReminderDomain).toList(),
    );
  }

  @Deprecated('Use watchAllRecurringReminders instead.')
  Stream<List<RecurringReminderModel>> watchAllSeries() {
    return watchAllRecurringReminders();
  }

  Future<ReminderModel?> getEditableById(int id) async {
    final item = await _dao.getEditableById(id);
    if (item == null) {
      return null;
    }
    return _toDomain(item);
  }

  Future<RecurringReminderModel?> getRecurringReminderDetailById(int id) async {
    final item = await _dao.getRecurringReminderRecordById(id);
    if (item == null) {
      return null;
    }
    return _toRecurringReminderDomain(item);
  }

  @Deprecated('Use getRecurringReminderDetailById instead.')
  Future<RecurringReminderModel?> getSeriesDetailById(int id) {
    return getRecurringReminderDetailById(id);
  }

  Future<List<TopicCategoryModel>> listTopicCategories() async {
    final items = await _dao.listTopicCategories();
    return items.map(_toTopicCategory).toList();
  }

  @Deprecated('Use listTopicCategories instead.')
  Future<List<TopicCategoryModel>> listIssueTypes() {
    return listTopicCategories();
  }

  Future<List<ActionCategoryModel>> listActionCategories() async {
    final items = await _dao.listActionCategories();
    return items.map(_toActionCategory).toList();
  }

  @Deprecated('Use listActionCategories instead.')
  Future<List<ActionCategoryModel>> listHandleTypes() {
    return listActionCategories();
  }

  Future<int> create(ReminderInput input) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final normalizedDueAt = _normalizeToDayStart(input.dueAt);
    final normalizedStartAt = _normalizeToDayStart(input.startAt ?? now)!;

    int? recurringReminderId;
    if (input.isRecurring) {
      recurringReminderId = await _dao.insertRecurringReminder(
        RecurringRemindersCompanion.insert(
          title: input.title,
          note: Value(input.note),
          trackingMode: input.trackingMode,
          triggerMode: input.triggerMode,
          triggerOffsetDays: Value(input.triggerOffsetDays),
          repeatRule: Value(input.repeatRule),
          topicCategoryId: Value(input.topicCategoryId),
          actionCategoryId: Value(input.actionCategoryId),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );
    }

    return _dao.insertReminder(
      RemindersCompanion.insert(
        recurringReminderId: Value(recurringReminderId),
        previousOccurrenceId: const Value.absent(),
        trackingMode: input.trackingMode,
        triggerMode: input.triggerMode,
        title: input.title,
        note: Value(input.note),
        triggerOffsetDays: Value(input.triggerOffsetDays),
        statusNote: const Value.absent(),
        dueAt: Value(normalizedDueAt?.millisecondsSinceEpoch),
        startAt: normalizedStartAt.millisecondsSinceEpoch,
        deferredDueAt: const Value.absent(),
        topicCategoryId: Value(input.topicCategoryId),
        actionCategoryId: Value(input.actionCategoryId),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  }

  Future<int> createRecurringReminderWithFirstOccurrence(
    ReminderInput input,
  ) async {
    final repeatRule = input.repeatRule;
    if (repeatRule == null || repeatRule.isEmpty) {
      throw ArgumentError('Recurring reminder requires repeatRule.');
    }

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final normalizedDueAt = _normalizeToDayStart(input.dueAt);
    final normalizedStartAt = _normalizeToDayStart(input.startAt ?? now)!;

    final recurringReminderId = await _dao.insertRecurringReminder(
      RecurringRemindersCompanion.insert(
        title: input.title,
        note: Value(input.note),
        trackingMode: input.trackingMode,
        triggerMode: input.triggerMode,
        triggerOffsetDays: Value(input.triggerOffsetDays),
        repeatRule: Value(repeatRule),
        topicCategoryId: Value(input.topicCategoryId),
        actionCategoryId: Value(input.actionCategoryId),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );

    await _dao.insertReminder(
      RemindersCompanion.insert(
        recurringReminderId: Value(recurringReminderId),
        previousOccurrenceId: const Value.absent(),
        trackingMode: input.trackingMode,
        triggerMode: input.triggerMode,
        title: input.title,
        note: Value(input.note),
        triggerOffsetDays: Value(input.triggerOffsetDays),
        statusNote: const Value.absent(),
        dueAt: Value(normalizedDueAt?.millisecondsSinceEpoch),
        startAt: normalizedStartAt.millisecondsSinceEpoch,
        deferredDueAt: const Value.absent(),
        topicCategoryId: Value(input.topicCategoryId),
        actionCategoryId: Value(input.actionCategoryId),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );

    return recurringReminderId;
  }

  @Deprecated('Use createRecurringReminderWithFirstOccurrence instead.')
  Future<int> createSeriesWithFirstReminder(ReminderInput input) {
    return createRecurringReminderWithFirstOccurrence(input);
  }

  Future<bool> updateById(int id, ReminderInput input) async {
    final existing = await _dao.getById(id);
    if (existing == null ||
        existing.reminder.status != ReminderStatus.pending) {
      return false;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final normalizedDueAt = _normalizeToDayStart(input.dueAt);
    final normalizedStartAt =
        _normalizeToDayStart(input.startAt) ??
        DateTime.fromMillisecondsSinceEpoch(existing.reminder.startAt);
    if (existing.recurringReminder != null) {
      final updatedRecurringReminder = existing.recurringReminder!.copyWith(
        title: input.title,
        note: Value(input.note),
        trackingMode: input.trackingMode,
        triggerMode: input.triggerMode,
        triggerOffsetDays: Value(input.triggerOffsetDays),
        repeatRule: Value(input.repeatRule),
        topicCategoryId: Value(input.topicCategoryId),
        actionCategoryId: Value(input.actionCategoryId),
        updatedAt: nowMs,
      );
      await _dao.updateRecurringReminder(updatedRecurringReminder);
    }

    final updatedReminder = existing.reminder.copyWith(
      trackingMode: input.trackingMode,
      triggerMode: input.triggerMode,
      title: input.title,
      note: Value(input.note),
      triggerOffsetDays: Value(input.triggerOffsetDays),
      dueAt: Value(normalizedDueAt?.millisecondsSinceEpoch),
      startAt: normalizedStartAt.millisecondsSinceEpoch,
      topicCategoryId: Value(input.topicCategoryId),
      actionCategoryId: Value(input.actionCategoryId),
      updatedAt: nowMs,
    );

    return _dao.updateReminder(updatedReminder);
  }

  Future<bool> updateRecurringReminderById(int id, ReminderInput input) async {
    final existing = await _dao.getRecurringReminderById(id);
    if (existing == null ||
        existing.status == RecurringReminderStatus.canceled) {
      return false;
    }

    final updatedRecurringReminder = existing.copyWith(
      title: input.title,
      note: Value(input.note),
      // Recurring template type is immutable after creation; the edit UI
      // locks the fixed-time/from-start choice and this repository preserves it.
      trackingMode: existing.trackingMode,
      triggerMode: input.triggerMode,
      triggerOffsetDays: Value(input.triggerOffsetDays),
      repeatRule: Value(input.repeatRule),
      topicCategoryId: Value(input.topicCategoryId),
      actionCategoryId: Value(input.actionCategoryId),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return _dao.updateRecurringReminder(updatedRecurringReminder);
  }

  @Deprecated('Use updateRecurringReminderById instead.')
  Future<bool> updateSeriesById(int id, ReminderInput input) {
    return updateRecurringReminderById(id, input);
  }

  Future<int> delete(int id) => _dao.deleteReminder(id);

  Future<void> complete(int id) => _dao.complete(id);

  Future<void> commitStagedCompletions(List<int> ids) =>
      _dao.commitCompleted(ids);

  Future<void> skip(int id) => _dao.skip(id);

  Future<void> cancel(int id) => _dao.cancel(id);

  Future<bool> defer(int id, int days) => _dao.deferReminder(id, days);

  Future<void> restore(int id) => _dao.restore(id);

  Future<void> stopRecurringReminderById(int id) =>
      _dao.stopRecurringReminder(id);

  @Deprecated('Use stopRecurringReminderById instead.')
  Future<void> stopSeriesById(int id) => stopRecurringReminderById(id);

  Future<void> cancelRecurringReminderById(int id) =>
      _dao.cancelRecurringReminder(id);

  @Deprecated('Use cancelRecurringReminderById instead.')
  Future<void> cancelSeriesById(int id) => cancelRecurringReminderById(id);

  Future<int?> reactivateRecurringReminderById(
    int id, {
    DateTime? dueAt,
    DateTime? startAt,
  }) {
    return _dao.reactivateRecurringReminder(
      id,
      dueAtEpochMs: _normalizeToDayStart(dueAt)?.millisecondsSinceEpoch,
      startAtEpochMs: _normalizeToDayStart(startAt)?.millisecondsSinceEpoch,
    );
  }

  @Deprecated('Use reactivateRecurringReminderById instead.')
  Future<int?> reactivateSeriesById(
    int id, {
    DateTime? dueAt,
    DateTime? startAt,
  }) {
    return reactivateRecurringReminderById(id, dueAt: dueAt, startAt: startAt);
  }

  ReminderModel _toDomain(ReminderRecord item) {
    return ReminderModel(
      id: item.reminder.id,
      recurringReminderId: item.reminder.recurringReminderId,
      previousOccurrenceId: item.reminder.previousOccurrenceId,
      trackingMode: item.reminder.trackingMode,
      triggerMode: item.reminder.triggerMode,
      status: item.reminder.status,
      title: item.reminder.title,
      note: item.reminder.note,
      triggerOffsetDays: item.reminder.triggerOffsetDays,
      statusNote: item.reminder.statusNote,
      dueAt: _fromEpoch(item.reminder.dueAt),
      startAt: DateTime.fromMillisecondsSinceEpoch(item.reminder.startAt),
      deferredDueAt: _fromEpoch(item.reminder.deferredDueAt),
      topicCategoryId: item.reminder.topicCategoryId,
      actionCategoryId: item.reminder.actionCategoryId,
      topicCategoryName: item.topicCategory?.name,
      actionCategoryName: item.actionCategory?.name,
      repeatRule: item.recurringReminder?.repeatRule,
      createdAt: DateTime.fromMillisecondsSinceEpoch(item.reminder.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(item.reminder.updatedAt),
    );
  }

  RecurringReminderModel _toRecurringReminderDomain(
    RecurringReminderRecord item,
  ) {
    return RecurringReminderModel(
      id: item.recurringReminder.id,
      status: item.recurringReminder.status,
      title: item.recurringReminder.title,
      note: item.recurringReminder.note,
      trackingMode: item.recurringReminder.trackingMode,
      triggerMode: item.recurringReminder.triggerMode,
      triggerOffsetDays: item.recurringReminder.triggerOffsetDays,
      repeatRule: item.recurringReminder.repeatRule,
      topicCategoryId: item.recurringReminder.topicCategoryId,
      actionCategoryId: item.recurringReminder.actionCategoryId,
      topicCategoryName: item.topicCategory?.name,
      actionCategoryName: item.actionCategory?.name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        item.recurringReminder.createdAt,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        item.recurringReminder.updatedAt,
      ),
    );
  }

  TopicCategoryModel _toTopicCategory(TopicCategory item) {
    return TopicCategoryModel(
      id: item.id,
      name: item.name,
      description: item.description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(item.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(item.updatedAt),
    );
  }

  ActionCategoryModel _toActionCategory(ActionCategory item) {
    return ActionCategoryModel(
      id: item.id,
      name: item.name,
      description: item.description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(item.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(item.updatedAt),
    );
  }

  DateTime? _fromEpoch(int? ms) {
    if (ms == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  DateTime? _normalizeToDayStart(DateTime? value) {
    if (value == null) {
      return null;
    }
    return DateTime(value.year, value.month, value.day);
  }
}
