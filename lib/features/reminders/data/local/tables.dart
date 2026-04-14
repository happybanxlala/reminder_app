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
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('TimelineMilestoneRuleRow')
class TimelineMilestoneRules extends Table {
  @override
  String get tableName => 'timeline_milestone_rules';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get timelineId => integer()();
  TextColumn get type => text()();
  IntColumn get intervalValue => integer()();
  TextColumn get intervalUnit => text()();
  TextColumn get labelTemplate => text().nullable()();
  IntColumn get reminderOffsetDays =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('TimelineMilestoneRecordRow')
class TimelineMilestoneRecords extends Table {
  @override
  String get tableName => 'timeline_milestone_records';

  @override
  List<Set<Column>> get uniqueKeys => [
    {timelineId, ruleId, occurrenceIndex},
  ];

  IntColumn get id => integer().autoIncrement()();
  IntColumn get timelineId => integer()();
  IntColumn get ruleId => integer()();
  IntColumn get occurrenceIndex => integer()();
  IntColumn get targetDate => integer()();
  TextColumn get status => text()();
  IntColumn get notifiedAt => integer().nullable()();
  IntColumn get actedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
