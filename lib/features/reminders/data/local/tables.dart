import 'package:drift/drift.dart';

@DataClassName('ItemPackRow')
class ItemPacks extends Table {
  @override
  String get tableName => 'item_packs';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isSystemDefault =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ItemRow')
class Items extends Table {
  @override
  String get tableName => 'items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get type => text()();
  TextColumn get fixedScheduleType => text().nullable()();
  IntColumn get fixedAnchorDate => integer().nullable()();
  IntColumn get fixedDueDate => integer().nullable()();
  TextColumn get fixedTimeOfDay => text().nullable()();
  TextColumn get fixedOverduePolicy => text().nullable()();
  IntColumn get fixedExpectedBeforeMinutes => integer().nullable()();
  IntColumn get fixedWarningBeforeMinutes => integer().nullable()();
  IntColumn get fixedDangerBeforeMinutes => integer().nullable()();
  IntColumn get stateAnchorDate => integer().nullable()();
  IntColumn get stateExpectedAfterMinutes => integer().nullable()();
  IntColumn get stateWarningAfterMinutes => integer().nullable()();
  IntColumn get stateDangerAfterMinutes => integer().nullable()();
  IntColumn get resourceAnchorDate => integer().nullable()();
  IntColumn get resourceDurationDays => integer().nullable()();
  IntColumn get resourceExpectedBeforeDays => integer().nullable()();
  IntColumn get resourceWarningBeforeDays => integer().nullable()();
  IntColumn get resourceDangerBeforeDays => integer().nullable()();
  IntColumn get lastDoneAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ItemActionRecordRow')
class ItemActionRecords extends Table {
  @override
  String get tableName => 'item_action_records';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id)();
  TextColumn get actionType => text()();
  IntColumn get actionDate => integer()();
  TextColumn get remark => text().nullable()();
  TextColumn get payload => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
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
  IntColumn get timelineId => integer().references(Timelines, #id)();
  TextColumn get type => text()();
  IntColumn get intervalValue => integer()();
  TextColumn get intervalUnit => text()();
  TextColumn get labelTemplate => text().nullable()();
  IntColumn get reminderOffsetDays =>
      integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
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
  IntColumn get timelineId => integer().references(Timelines, #id)();
  IntColumn get ruleId => integer().references(TimelineMilestoneRules, #id)();
  IntColumn get occurrenceIndex => integer()();
  IntColumn get targetDate => integer()();
  TextColumn get status => text()();
  IntColumn get notifiedAt => integer().nullable()();
  IntColumn get actedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
