import 'package:drift/drift.dart';

@DataClassName('LocalUserRow')
class LocalUsers extends Table {
  @override
  String get tableName => 'local_users';

  TextColumn get id => text()();
  TextColumn get displayName => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

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
  TextColumn get packType => text().withDefault(const Constant('personal'))();
  TextColumn get hostUserId => text().nullable().references(LocalUsers, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('PackMemberRow')
class PackMembers extends Table {
  @override
  String get tableName => 'pack_members';

  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get role => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get joinedAt => integer()();

  @override
  Set<Column> get primaryKey => {packId, userId};
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
  TextColumn get assignedToUserId =>
      text().nullable().references(LocalUsers, #id)();
  IntColumn get lastDoneAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('PackTemplateRow')
class PackTemplates extends Table {
  @override
  String get tableName => 'pack_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get templateName => text()();
  TextColumn get iconEmoji => text().withDefault(const Constant('🏷️'))();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('PackTemplateItemRow')
class PackTemplateItems extends Table {
  @override
  String get tableName => 'pack_template_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(PackTemplates, #id)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get attentionPolicySource =>
      text().withDefault(const Constant('systemDefault'))();
  TextColumn get fixedScheduleType => text().nullable()();
  IntColumn get fixedScheduleInterval => integer().nullable()();
  IntColumn get fixedMonthlyDay => integer().nullable()();
  TextColumn get fixedRepeatRuleV2 => text().nullable()();
  TextColumn get fixedTimeOfDay => text().nullable()();
  TextColumn get fixedOverduePolicy => text().nullable()();
  IntColumn get fixedExpectedBeforeMinutes => integer().nullable()();
  IntColumn get fixedWarningBeforeMinutes => integer().nullable()();
  IntColumn get fixedDangerBeforeMinutes => integer().nullable()();
  IntColumn get stateExpectedAfterMinutes => integer().nullable()();
  IntColumn get stateWarningAfterMinutes => integer().nullable()();
  IntColumn get stateDangerAfterMinutes => integer().nullable()();
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

@DataClassName('ItemCompletionRow')
class ItemCompletions extends Table {
  @override
  String get tableName => 'item_completions';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id)();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  IntColumn get itemActionRecordId =>
      integer().references(ItemActionRecords, #id)();
  @ReferenceName('completedItemCompletions')
  TextColumn get completedByUserId => text().references(LocalUsers, #id)();
  IntColumn get completedAt => integer()();
  @ReferenceName('undoneItemCompletions')
  TextColumn get undoneByUserId =>
      text().nullable().references(LocalUsers, #id)();
  IntColumn get undoneAt => integer().nullable()();
  TextColumn get clientMutationId => text().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('ResourceEventRow')
class ResourceEvents extends Table {
  @override
  String get tableName => 'resource_events';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get resourceId => integer().references(Resources, #id)();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get actorUserId => text().references(LocalUsers, #id)();
  TextColumn get changeType => text()();
  IntColumn get previousValue => integer().nullable()();
  IntColumn get newValue => integer().nullable()();
  IntColumn get deltaValue => integer().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get metadataJson => text().nullable()();
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

@DataClassName('StageAcknowledgementRow')
class StageAcknowledgements extends Table {
  @override
  String get tableName => 'stage_acknowledgements';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get stageRecordId => integer().references(StageRecords, #id)();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get userId => text().references(LocalUsers, #id)();
  IntColumn get acknowledgedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {stageRecordId, userId},
  ];
}

@DataClassName('ActivityEventRow')
class ActivityEvents extends Table {
  @override
  String get tableName => 'activity_events';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get packId => integer().references(ItemPacks, #id)();
  TextColumn get actorUserId => text().references(LocalUsers, #id)();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer()();
  TextColumn get action => text()();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  IntColumn get createdAt => integer()();
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
