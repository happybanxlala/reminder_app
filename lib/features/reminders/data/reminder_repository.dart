import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ReminderRepository(database.reminderDao);
});

class ReminderRepository {
  const ReminderRepository(this._dao);

  final ReminderDao _dao;

  Stream<List<Reminder>> watchAll() => _dao.watchAll();

  Stream<List<Reminder>> watchTodayPending() => _dao.watchTodayPending();

  Future<Reminder?> getById(String id) => _dao.getById(id);

  Future<int> insert(RemindersCompanion entry) => _dao.insert(entry);

  Future<bool> update(Reminder reminder) => _dao.update(reminder);

  Future<int> delete(String id) => _dao.delete(id);
}
