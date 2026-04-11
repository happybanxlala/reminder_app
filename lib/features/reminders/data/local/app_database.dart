import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TaskTemplates, Tasks, Timelines, Milestones],
  daos: [ReminderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        await customStatement('DROP TABLE IF EXISTS reminders');
        await customStatement('DROP TABLE IF EXISTS recurring_reminders');
        await customStatement('DROP TABLE IF EXISTS reminder_series');
        await customStatement('DROP TABLE IF EXISTS issue_types');
        await customStatement('DROP TABLE IF EXISTS topic_categories');
        await customStatement('DROP TABLE IF EXISTS handle_types');
        await customStatement('DROP TABLE IF EXISTS action_categories');
        await customStatement('DROP TABLE IF EXISTS task_templates');
        await customStatement('DROP TABLE IF EXISTS tasks');
        await customStatement('DROP TABLE IF EXISTS timelines');
        await customStatement('DROP TABLE IF EXISTS milestones');
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
