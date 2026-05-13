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

@DataClassName('ItemPackTemplateRow')
class ItemPackTemplates extends Table {
  @override
  String get tableName => 'item_pack_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get description => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ItemTemplateItemRow')
class ItemTemplateItems extends Table {
  @override
  String get tableName => 'item_template_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(ItemPackTemplates, #id)();
  TextColumn get logicalId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
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

@DataClassName('ResourceTemplateItemRow')
class ResourceTemplateItems extends Table {
  @override
  String get tableName => 'resource_template_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(ItemPackTemplates, #id)();
  TextColumn get logicalId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()();
  IntColumn get timeDurationDays => integer().nullable()();
  IntColumn get timeExpectedBeforeDays => integer().nullable()();
  IntColumn get timeWarningBeforeDays => integer().nullable()();
  IntColumn get timeDangerBeforeDays => integer().nullable()();
  IntColumn get quantityCurrent => integer().nullable()();
  TextColumn get quantityUnitLabel => text().nullable()();
  IntColumn get quantityExpectedThreshold => integer().nullable()();
  IntColumn get quantityWarningThreshold => integer().nullable()();
  IntColumn get quantityDangerThreshold => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ResourceConsumptionRuleTemplateRow')
class ResourceConsumptionRuleTemplateItems extends Table {
  @override
  String get tableName => 'resource_consumption_rule_template_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(ItemPackTemplates, #id)();
  TextColumn get itemLogicalId => text()();
  TextColumn get resourceLogicalId => text()();
  TextColumn get triggerActionType =>
      text().withDefault(const Constant('done'))();
  IntColumn get consumeAmount => integer().withDefault(const Constant(1))();
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

@DataClassName('AppSettingsRow')
class AppSettingsEntries extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get reminderTone =>
      text().withDefault(const Constant('standard'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
