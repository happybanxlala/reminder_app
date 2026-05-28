import 'package:drift/drift.dart';

@DataClassName('ItemPackRow')
class ItemPacks extends Table {
  @override
  String get tableName => 'item_packs';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconEmoji => text().withDefault(const Constant('📌'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
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
  TextColumn get attentionPolicySource =>
      text().withDefault(const Constant('systemDefault'))();
  TextColumn get fixedScheduleType => text().nullable()();
  IntColumn get fixedScheduleInterval => integer().nullable()();
  IntColumn get fixedMonthlyDay => integer().nullable()();
  TextColumn get fixedRepeatRuleV2 => text().nullable()();
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
  IntColumn get lastDoneAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ResourceRow')
class Resources extends Table {
  @override
  String get tableName => 'resources';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get type => text()();
  IntColumn get timeAnchorDate => integer().nullable()();
  IntColumn get timeDurationDays => integer().nullable()();
  IntColumn get timeExpectedBeforeDays => integer().nullable()();
  IntColumn get timeWarningBeforeDays => integer().nullable()();
  IntColumn get timeDangerBeforeDays => integer().nullable()();
  IntColumn get quantityCurrent => integer().nullable()();
  TextColumn get quantityUnitLabel => text().nullable()();
  IntColumn get quantityExpectedThreshold => integer().nullable()();
  IntColumn get quantityWarningThreshold => integer().nullable()();
  IntColumn get quantityDangerThreshold => integer().nullable()();
  IntColumn get lastRefilledAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ResourceConsumptionRuleRow')
class ResourceConsumptionRules extends Table {
  @override
  String get tableName => 'resource_consumption_rules';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get resourceId => integer().references(Resources, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  TextColumn get triggerActionType =>
      text().withDefault(const Constant('done'))();
  IntColumn get consumeAmount => integer().withDefault(const Constant(1))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ResourceActionRecordRow')
class ResourceActionRecords extends Table {
  @override
  String get tableName => 'resource_action_records';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get resourceId => integer().references(Resources, #id)();
  TextColumn get actionType => text()();
  IntColumn get actionDate => integer()();
  IntColumn get amount => integer().nullable()();
  IntColumn get resultingQuantity => integer().nullable()();
  IntColumn get addedDays => integer().nullable()();
  IntColumn get resultingDurationDays => integer().nullable()();
  IntColumn get sourceItemActionRecordId =>
      integer().nullable().references(ItemActionRecords, #id)();
  TextColumn get remark => text().nullable()();
  BoolColumn get isReverted => boolean().withDefault(const Constant(false))();
  IntColumn get revertedAt => integer().nullable()();
  IntColumn get revertedByActionRecordId => integer().nullable()();
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
  BoolColumn get isReverted => boolean().withDefault(const Constant(false))();
  IntColumn get revertedAt => integer().nullable()();
  IntColumn get revertedByActionRecordId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('StageTrackerRow')
class StageTrackers extends Table {
  @override
  String get tableName => 'stage_trackers';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get title => text()();
  TextColumn get subjectName => text().nullable()();
  IntColumn get trackingStartDate => integer()();
  IntColumn get trackingEndDate => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isSystemDefault =>
      boolean().withDefault(const Constant(false))();
  TextColumn get systemKey => text().nullable()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {systemKey},
  ];
}

@DataClassName('StageRuleRow')
class StageRules extends Table {
  @override
  String get tableName => 'stage_rules';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get stageTrackerId => integer().references(StageTrackers, #id)();
  TextColumn get type => text()();
  IntColumn get intervalValue => integer()();
  TextColumn get intervalUnit => text()();
  TextColumn get labelTemplate => text().nullable()();
  IntColumn get reminderOffsetDays => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('StageRecordRow')
class StageRecords extends Table {
  @override
  String get tableName => 'stage_records';

  @override
  List<Set<Column>> get uniqueKeys => [
    {stageTrackerId, stageRuleId, occurrenceIndex},
  ];

  IntColumn get id => integer().autoIncrement()();
  IntColumn get stageTrackerId => integer().references(StageTrackers, #id)();
  IntColumn get stageRuleId =>
      integer().nullable().references(StageRules, #id)();
  TextColumn get sourceType => text()();
  IntColumn get occurrenceIndex => integer().nullable()();
  IntColumn get occurrenceDate => integer()();
  IntColumn get relativeAmount => integer().nullable()();
  TextColumn get relativeUnit => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('normal'))();
  TextColumn get label => text()();
  TextColumn get note => text().nullable()();
  IntColumn get reminderOffsetDays => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('StageRelatedItemRow')
class StageRelatedItems extends Table {
  @override
  String get tableName => 'stage_related_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get stageRecordId => integer().references(StageRecords, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('AppSettingsRow')
class AppSettingsEntries extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get reminderTone =>
      text().withDefault(const Constant('standard'))();
  TextColumn get notificationReminderTime =>
      text().withDefault(const Constant('09:00'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
