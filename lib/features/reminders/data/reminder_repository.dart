import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final todayPendingProvider = StreamProvider<List<ReminderModel>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchTodayPending();
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

class ReminderUpsert {
  const ReminderUpsert({
    required this.title,
    this.note,
    required this.remindDays,
    this.dueAt,
    this.repeatRule,
    this.extendAt,
  });

  final String title;
  final String? note;
  final int remindDays;
  final DateTime? dueAt;
  final String? repeatRule;
  final DateTime? extendAt;
}

class ReminderRepository {
  const ReminderRepository(this._dao);

  final ReminderDao _dao;

  Stream<List<ReminderModel>> watchAll() {
    return _dao.watchAll().map((items) => items.map(_toDomain).toList());
  }

  Stream<List<ReminderModel>> watchTodayPending() {
    return _dao.watchTodayPending().map(
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

  Future<int> create(ReminderUpsert input) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _dao.insertReminder(
      RemindersCompanion.insert(
        title: input.title,
        note: Value(input.note),
        remindDays: Value(input.remindDays),
        dueAt: Value(input.dueAt?.millisecondsSinceEpoch),
        repeatRule: Value(input.repeatRule),
        extendAt: Value(input.extendAt?.millisecondsSinceEpoch),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _dao.backfillStartId(id);
    return id;
  }

  Future<bool> updateById(int id, ReminderUpsert input) async {
    final existing = await _dao.getById(id);
    if (existing == null || existing.isDone != 0 || existing.isCanceled) {
      return false;
    }

    final updated = existing.copyWith(
      title: input.title,
      note: Value(input.note),
      remindDays: input.remindDays,
      dueAt: Value(input.dueAt?.millisecondsSinceEpoch),
      repeatRule: Value(input.repeatRule),
      extendAt: Value(input.extendAt?.millisecondsSinceEpoch),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return _dao.updateReminder(updated);
  }

  Future<int> delete(int id) => _dao.deleteReminder(id);

  Future<void> complete(int id) => _dao.completeOrSkip(id, 1);

  Future<void> skip(int id) => _dao.completeOrSkip(id, 2);

  ReminderModel _toDomain(Reminder item) {
    return ReminderModel(
      id: item.id,
      startId: item.startId,
      title: item.title,
      note: item.note,
      remindDays: item.remindDays,
      dueAt: _fromEpoch(item.dueAt),
      repeatRule: item.repeatRule,
      isDone: item.isDone,
      extendAt: _fromEpoch(item.extendAt),
      isCanceled: item.isCanceled,
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
}
