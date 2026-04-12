import 'package:drift/drift.dart';

@DataClassName('TaskTemplateRow')
class TaskTemplates extends Table {
  @override
  String get tableName => 'task_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get kind => text()();
  TextColumn get status => text()();
  IntColumn get firstDueDate => integer()();
  TextColumn get repeatRule => text().nullable()();
  TextColumn get reminderRule => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('TaskRow')
class Tasks extends Table {
  @override
  String get tableName => 'tasks';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().nullable()();
  TextColumn get kind => text()();
  TextColumn get titleSnapshot => text()();
  TextColumn get noteSnapshot => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get dueDate => integer()();
  TextColumn get repeatRule => text().nullable()();
  TextColumn get reminderRule => text()();
  IntColumn get deferredDueDate => integer().nullable()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get resolvedAt => integer().nullable()();
}

@DataClassName('TimelineRow')
class Timelines extends Table {
  @override
  String get tableName => 'timelines';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get startDate => integer()();
  TextColumn get displayUnit => text()();
  TextColumn get status => text()();
  TextColumn get milestoneReminderRule => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('MilestoneRow')
class Milestones extends Table {
  @override
  String get tableName => 'milestones';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get timelineId => integer()();
  IntColumn get targetDate => integer()();
  TextColumn get description => text().nullable()();
  TextColumn get source => text()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
