import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [ReminderSeriesEntries, IssueTypes, HandleTypes, Reminders],
  daos: [ReminderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        await customStatement('DROP TABLE IF EXISTS reminders');
        await customStatement('DROP TABLE IF EXISTS reminder_series');
        await customStatement('DROP TABLE IF EXISTS issue_types');
        await customStatement('DROP TABLE IF EXISTS handle_types');
        await m.createAll();
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'reminder_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
