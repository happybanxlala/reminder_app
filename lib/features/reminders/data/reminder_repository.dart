import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/handle_type.dart';
import '../domain/issue_type.dart';
import '../domain/reminder.dart';
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
  return ref.watch(reminderRepositoryProvider).watchCompletedOrSkipped(limit: 30);
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

final issueTypesProvider = FutureProvider<List<IssueTypeModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).listIssueTypes();
});

final handleTypesProvider = FutureProvider<List<HandleTypeModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).listHandleTypes();
});

class ReminderUpsert {
  const ReminderUpsert({
    required this.title,
    this.note,
    required this.timeBasis,
    required this.notifyStrategy,
    this.remindDays,
    this.dueAt,
    this.startAt,
    this.repeatRule,
    this.issueTypeId,
    this.handleTypeId,
  });

  final String title;
  final String? note;
  final int timeBasis;
  final int notifyStrategy;
  final int? remindDays;
  final DateTime? dueAt;
  final DateTime? startAt;
  final String? repeatRule;
  final int? issueTypeId;
  final int? handleTypeId;

  bool get isRecurring => repeatRule != null;
}

class ReminderRepository {
  const ReminderRepository(this._dao);

  final ReminderDao _dao;

  Stream<List<ReminderModel>> watchAll() {
    return _dao.watchAll().map((items) => items.map(_toDomain).toList());
  }

  Stream<List<ReminderModel>> watchActivePending() {
    return _dao.watchActivePending().map((items) => items.map(_toDomain).toList());
  }

  Stream<List<ReminderModel>> watchTodayPending() {
    return _dao.watchTodayPending().map(
      (items) => items.map(_toDomain).toList(),
    );
  }

  Stream<List<ReminderModel>> watchCompletedOrSkipped({int limit = 30}) {
    return _dao.watchCompletedOrSkipped(limit: limit).map(
      (items) => items.map(_toDomain).toList(),
    );
  }

  Stream<ReminderModel?> watchNextReminder() {
    return _dao.watchNextReminder().map(
      (item) => item == null ? null : _toDomain(item),
    );
  }

  Future<ReminderModel?> getEditableById(int id) async {
    final item = await _dao.getEditableById(id);
    if (item == null) {
      return null;
    }
    return _toDomain(item);
  }

  Future<List<IssueTypeModel>> listIssueTypes() async {
    final items = await _dao.listIssueTypes();
    return items.map(_toIssueType).toList();
  }

  Future<List<HandleTypeModel>> listHandleTypes() async {
    final items = await _dao.listHandleTypes();
    return items.map(_toHandleType).toList();
  }

  Future<int> create(ReminderUpsert input) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final normalizedDueAt = _normalizeToDayStart(input.dueAt);
    final normalizedStartAt = _normalizeToDayStart(input.startAt ?? now)!;

    int? seriesId;
    if (input.isRecurring) {
      seriesId = await _dao.insertSeries(
        ReminderSeriesEntriesCompanion.insert(
          title: input.title,
          note: Value(input.note),
          timeBasis: input.timeBasis,
          notifyStrategy: input.notifyStrategy,
          remindDays: Value(input.remindDays),
          repeatRule: Value(input.repeatRule),
          issueTypeId: Value(input.issueTypeId),
          handleTypeId: Value(input.handleTypeId),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );
    }

    return _dao.insertReminder(
      RemindersCompanion.insert(
        seriesId: Value(seriesId),
        previousReminderId: const Value.absent(),
        timeBasis: input.timeBasis,
        notifyStrategy: input.notifyStrategy,
        title: input.title,
        note: Value(input.note),
        remindDays: Value(input.remindDays),
        remark: const Value.absent(),
        dueAt: Value(normalizedDueAt?.millisecondsSinceEpoch),
        startAt: normalizedStartAt.millisecondsSinceEpoch,
        extendAt: const Value.absent(),
        issueTypeId: Value(input.issueTypeId),
        handleTypeId: Value(input.handleTypeId),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  }

  Future<bool> updateById(int id, ReminderUpsert input) async {
    final existing = await _dao.getById(id);
    if (existing == null || existing.reminder.status != ReminderStatus.pending) {
      return false;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final normalizedDueAt = _normalizeToDayStart(input.dueAt);
    final normalizedStartAt = _normalizeToDayStart(input.startAt) ??
        DateTime.fromMillisecondsSinceEpoch(existing.reminder.startAt);
    if (existing.series != null) {
      final updatedSeries = existing.series!.copyWith(
        title: input.title,
        note: Value(input.note),
        timeBasis: input.timeBasis,
        notifyStrategy: input.notifyStrategy,
        remindDays: Value(input.remindDays),
        repeatRule: Value(input.repeatRule),
        issueTypeId: Value(input.issueTypeId),
        handleTypeId: Value(input.handleTypeId),
        updatedAt: nowMs,
      );
      await _dao.updateSeries(updatedSeries);
    }

    final updatedReminder = existing.reminder.copyWith(
      timeBasis: input.timeBasis,
      notifyStrategy: input.notifyStrategy,
      title: input.title,
      note: Value(input.note),
      remindDays: Value(input.remindDays),
      dueAt: Value(normalizedDueAt?.millisecondsSinceEpoch),
      startAt: normalizedStartAt.millisecondsSinceEpoch,
      issueTypeId: Value(input.issueTypeId),
      handleTypeId: Value(input.handleTypeId),
      updatedAt: nowMs,
    );

    return _dao.updateReminder(updatedReminder);
  }

  Future<int> delete(int id) => _dao.deleteReminder(id);

  Future<void> complete(int id) => _dao.complete(id);

  Future<void> commitStagedCompletions(List<int> ids) => _dao.commitCompleted(ids);

  Future<void> skip(int id) => _dao.skip(id);

  Future<void> cancel(int id) => _dao.cancel(id);

  Future<void> restore(int id) => _dao.restore(id);

  ReminderModel _toDomain(ReminderRecord item) {
    return ReminderModel(
      id: item.reminder.id,
      seriesId: item.reminder.seriesId,
      previousReminderId: item.reminder.previousReminderId,
      timeBasis: item.reminder.timeBasis,
      notifyStrategy: item.reminder.notifyStrategy,
      status: item.reminder.status,
      title: item.reminder.title,
      note: item.reminder.note,
      remindDays: item.reminder.remindDays,
      remark: item.reminder.remark,
      dueAt: _fromEpoch(item.reminder.dueAt),
      startAt: DateTime.fromMillisecondsSinceEpoch(item.reminder.startAt),
      extendAt: _fromEpoch(item.reminder.extendAt),
      issueTypeId: item.reminder.issueTypeId,
      handleTypeId: item.reminder.handleTypeId,
      issueTypeName: item.issueType?.name,
      handleTypeName: item.handleType?.name,
      repeatRule: item.series?.repeatRule,
      createdAt: DateTime.fromMillisecondsSinceEpoch(item.reminder.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(item.reminder.updatedAt),
    );
  }

  IssueTypeModel _toIssueType(IssueType item) {
    return IssueTypeModel(
      id: item.id,
      name: item.name,
      description: item.description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(item.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(item.updatedAt),
    );
  }

  HandleTypeModel _toHandleType(HandleType item) {
    return HandleTypeModel(
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
