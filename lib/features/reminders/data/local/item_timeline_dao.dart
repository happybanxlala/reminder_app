import 'package:drift/drift.dart';

import '../../domain/app_settings.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/item_action_record.dart';
import '../../domain/item_pack.dart';
import '../../domain/item_pack_template.dart';
import '../../domain/repeat_rule_v2.dart';
import '../../domain/resource.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_record.dart';
import '../../domain/timeline_milestone_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'item_timeline_dao.g.dart';

class ItemBundle {
  const ItemBundle({required this.item, required this.pack});

  final Item item;
  final ItemPack pack;
}

class ResourceBundle {
  const ResourceBundle({required this.resource, required this.pack});

  final Resource resource;
  final ItemPack pack;
}

class ItemActivityEntry {
  const ItemActivityEntry({
    required this.record,
    required this.item,
    required this.pack,
  });

  final ItemActionRecord record;
  final Item item;
  final ItemPack pack;

  int get itemId => item.id;
  int get packId => pack.id;
  ItemType get itemType => item.type;
  String get itemTitle => item.title;
  String get packTitle => pack.title;

  ItemBundle get bundle => ItemBundle(item: item, pack: pack);
}

class TimelineMilestoneRecordBundle {
  const TimelineMilestoneRecordBundle({
    required this.record,
    required this.rule,
    required this.timeline,
  });

  final TimelineMilestoneRecord record;
  final TimelineMilestoneRule rule;
  final Timeline timeline;
}

class TimelineDetailRecord {
  const TimelineDetailRecord({
    required this.timeline,
    required this.milestoneRules,
    required this.milestoneHistory,
  });

  final Timeline timeline;
  final List<TimelineMilestoneRule> milestoneRules;
  final List<TimelineMilestoneRecordBundle> milestoneHistory;
}

@DriftAccessor(
  tables: [
    ItemPacks,
    Items,
    ItemPackTemplates,
    ItemTemplateItems,
    ResourceTemplateItems,
    ResourceConsumptionRuleTemplateItems,
    Resources,
    ResourceConsumptionRules,
    ResourceActionRecords,
    ItemActionRecords,
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
    AppSettingsEntries,
  ],
)
class ItemTimelineDao extends DatabaseAccessor<AppDatabase>
    with _$ItemTimelineDaoMixin {
  ItemTimelineDao(super.attachedDatabase);

  Future<int> insertItemPack(ItemPacksCompanion entry) {
    return into(itemPacks).insert(entry);
  }

  Future<int> insertItem(ItemsCompanion entry) {
    return into(items).insert(entry);
  }

  Future<int> insertItemActionRecord(ItemActionRecordsCompanion entry) {
    return into(itemActionRecords).insert(entry);
  }

  Future<int> insertResource(ResourcesCompanion entry) {
    return into(resources).insert(entry);
  }

  Future<int> insertResourceConsumptionRule(
    ResourceConsumptionRulesCompanion entry,
  ) {
    return into(resourceConsumptionRules).insert(entry);
  }

  Future<int> insertResourceActionRecord(ResourceActionRecordsCompanion entry) {
    return into(resourceActionRecords).insert(entry);
  }

  Future<int> insertItemPackTemplate(ItemPackTemplatesCompanion entry) {
    return into(itemPackTemplates).insert(entry);
  }

  Future<int> insertItemTemplateItem(ItemTemplateItemsCompanion entry) {
    return into(itemTemplateItems).insert(entry);
  }

  Future<int> insertResourceTemplateItem(ResourceTemplateItemsCompanion entry) {
    return into(resourceTemplateItems).insert(entry);
  }

  Future<int> insertResourceConsumptionRuleTemplateItem(
    ResourceConsumptionRuleTemplateItemsCompanion entry,
  ) {
    return into(resourceConsumptionRuleTemplateItems).insert(entry);
  }

  Stream<AppSettings> watchAppSettings() {
    return (select(
      appSettingsEntries,
    )..where((t) => t.id.equals(1))).watchSingleOrNull().map(
      (row) => row == null ? _defaultAppSettings() : _toAppSettings(row),
    );
  }

  Future<AppSettings> getAppSettings() async {
    final row = await (select(
      appSettingsEntries,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    return row == null ? _defaultAppSettings() : _toAppSettings(row);
  }

  Future<void> updateReminderTone(ReminderTone tone) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(appSettingsEntries).insertOnConflictUpdate(
      AppSettingsEntriesCompanion.insert(
        id: const Value(1),
        reminderTone: Value(tone.name),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> updateItemPackRecord(ItemPackRow entry) {
    return update(itemPacks).replace(entry);
  }

  Future<bool> updateItemRecord(ItemRow entry) {
    return update(items).replace(entry);
  }

  Future<int> deleteItemPackTemplate(int id) {
    return transaction(() async {
      await (delete(
        resourceConsumptionRuleTemplateItems,
      )..where((t) => t.templateId.equals(id))).go();
      await (delete(
        resourceTemplateItems,
      )..where((t) => t.templateId.equals(id))).go();
      await (delete(
        itemTemplateItems,
      )..where((t) => t.templateId.equals(id))).go();
      return (delete(itemPackTemplates)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<bool> updateItemFields(int id, ItemsCompanion entry) async {
    final updatedRows = await (update(
      items,
    )..where((t) => t.id.equals(id))).write(entry);
    return updatedRows > 0;
  }

  Future<bool> updateResourceFields(int id, ResourcesCompanion entry) async {
    final updatedRows = await (update(
      resources,
    )..where((t) => t.id.equals(id))).write(entry);
    return updatedRows > 0;
  }

  Future<bool> updateResourceRecord(ResourceRow entry) {
    return update(resources).replace(entry);
  }

  Future<bool> updateResourceConsumptionRuleFields(
    int id,
    ResourceConsumptionRulesCompanion entry,
  ) async {
    final updatedRows = await (update(
      resourceConsumptionRules,
    )..where((t) => t.id.equals(id))).write(entry);
    return updatedRows > 0;
  }

  Stream<List<ItemPack>> watchItemPacks({bool includeArchived = false}) {
    final query = select(itemPacks);
    if (!includeArchived) {
      query.where((t) => t.status.equals(ItemPackStatus.active.name));
    }
    query.orderBy(_itemPackOrdering);
    return query.watch().map(
      (rows) => rows.map(_toItemPack).toList(growable: false),
    );
  }

  Future<List<ItemPack>> listItemPacks({bool includeArchived = false}) async {
    final query = select(itemPacks);
    if (!includeArchived) {
      query.where((t) => t.status.equals(ItemPackStatus.active.name));
    }
    query.orderBy(_itemPackOrdering);
    final rows = await query.get();
    return rows.map(_toItemPack).toList(growable: false);
  }

  Future<ItemPack?> getItemPackById(int id) async {
    final row = await (select(
      itemPacks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toItemPack(row);
  }

  Stream<List<ItemPackTemplate>> watchCustomItemPackTemplates() {
    final query = select(itemPackTemplates)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch().asyncMap((rows) async {
      final result = <ItemPackTemplate>[];
      for (final row in rows) {
        result.add(await _toItemPackTemplate(row));
      }
      return result;
    });
  }

  Future<ItemPackTemplate?> getCustomItemPackTemplateById(int id) async {
    final row = await (select(
      itemPackTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toItemPackTemplate(row);
  }

  Future<int> countItemsForPack(
    int packId, {
    Set<ItemLifecycleStatus>? statuses,
  }) async {
    final countExpression = items.id.count();
    final query = selectOnly(items)
      ..addColumns([countExpression])
      ..where(_itemStatusPredicate(items.packId.equals(packId), statuses));
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Stream<List<ItemBundle>> watchItemBundles({
    Set<ItemLifecycleStatus>? statuses,
  }) {
    return _itemBundleQuery(
      statuses: statuses,
    ).watch().map((rows) => rows.map(_mapItemBundle).toList(growable: false));
  }

  Future<List<ItemBundle>> listItemBundles({
    Set<ItemLifecycleStatus>? statuses,
  }) {
    return _itemBundleQuery(
      statuses: statuses,
    ).get().then((rows) => rows.map(_mapItemBundle).toList(growable: false));
  }

  Future<ItemBundle?> getItemBundleById(int id) async {
    final rows = await _itemBundleQuery(
      where: (t) => t.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapItemBundle(rows.single);
  }

  Stream<List<ResourceBundle>> watchResourceBundles({
    Set<ResourceLifecycleStatus>? statuses,
  }) {
    return _resourceBundleQuery(statuses: statuses).watch().map(
      (rows) => rows.map(_mapResourceBundle).toList(growable: false),
    );
  }

  Future<List<ResourceBundle>> listResourceBundles({
    Set<ResourceLifecycleStatus>? statuses,
  }) {
    return _resourceBundleQuery(statuses: statuses).get().then(
      (rows) => rows.map(_mapResourceBundle).toList(growable: false),
    );
  }

  Future<ResourceBundle?> getResourceBundleById(int id) async {
    final rows = await _resourceBundleQuery(
      where: (t) => t.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapResourceBundle(rows.single);
  }

  Future<List<ResourceConsumptionRule>> listConsumptionRulesForItem(
    int itemId, {
    bool enabledOnly = false,
  }) async {
    final query = select(resourceConsumptionRules)
      ..where((t) => t.itemId.equals(itemId));
    if (enabledOnly) {
      query.where((t) => t.isEnabled.equals(true));
    }
    final rows = await query.get();
    return rows.map(_toResourceConsumptionRule).toList(growable: false);
  }

  Stream<List<ResourceConsumptionRule>> watchConsumptionRulesForItem(
    int itemId,
  ) {
    final query = select(resourceConsumptionRules)
      ..where((t) => t.itemId.equals(itemId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch().map(
      (rows) => rows.map(_toResourceConsumptionRule).toList(growable: false),
    );
  }

  Stream<List<ResourceActionRecord>> watchResourceActionRecordsForResource(
    int resourceId,
  ) {
    final query = select(resourceActionRecords)
      ..where((t) => t.resourceId.equals(resourceId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.actionDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toResourceActionRecord).toList(growable: false),
    );
  }

  Future<List<ResourceActionRecord>> listResourceActionRecordsForResource(
    int resourceId,
  ) async {
    final rows =
        await (select(resourceActionRecords)
              ..where((t) => t.resourceId.equals(resourceId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.actionDate),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .get();
    return rows.map(_toResourceActionRecord).toList(growable: false);
  }

  Stream<List<ItemActionRecord>> watchItemActionRecordsForItem(int itemId) {
    final query = select(itemActionRecords)
      ..where((t) => t.itemId.equals(itemId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.actionDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toItemActionRecord).toList(growable: false),
    );
  }

  Future<List<ItemActionRecord>> listItemActionRecordsForItem(
    int itemId,
  ) async {
    final rows =
        await (select(itemActionRecords)
              ..where((t) => t.itemId.equals(itemId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.actionDate),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .get();
    return rows.map(_toItemActionRecord).toList(growable: false);
  }

  Future<List<ItemActivityEntry>> listItemActivityEntries({
    Set<ItemActionType>? actionTypes,
    int limit = 20,
    int offset = 0,
    String? query,
    DateTime? actionDateFrom,
    DateTime? actionDateBefore,
  }) async {
    final rows = await _itemActivityEntryQuery(
      actionTypes: actionTypes,
      query: query,
      actionDateFrom: actionDateFrom,
      actionDateBefore: actionDateBefore,
      limit: limit,
      offset: offset,
    ).get();
    return rows.map(_mapItemActivityEntry).toList(growable: false);
  }

  Future<bool> updateItemStatus(int id, ItemLifecycleStatus status) async {
    final now = DateTime.now();
    final updatedRows = await (update(items)..where((t) => t.id.equals(id)))
        .write(
          ItemsCompanion(
            status: Value(status.name),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
    return updatedRows > 0;
  }

  Future<int> updateItemsStatusForPack(
    int packId,
    ItemLifecycleStatus status,
  ) async {
    final now = DateTime.now();
    return (update(items)..where((t) => t.packId.equals(packId))).write(
      ItemsCompanion(
        status: Value(status.name),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> insertTimeline(TimelinesCompanion entry) {
    return into(timelines).insert(entry);
  }

  Future<bool> updateTimelineRecord(TimelineRow entry) {
    return update(timelines).replace(entry);
  }

  Future<int> insertTimelineMilestoneRule(
    TimelineMilestoneRulesCompanion entry,
  ) {
    return into(timelineMilestoneRules).insert(entry);
  }

  Future<bool> updateTimelineMilestoneRuleRecord(
    TimelineMilestoneRuleRow entry,
  ) {
    return update(timelineMilestoneRules).replace(entry);
  }

  Future<int> insertTimelineMilestoneRecord(
    TimelineMilestoneRecordsCompanion entry,
  ) {
    return into(timelineMilestoneRecords).insert(entry);
  }

  Future<bool> updateTimelineMilestoneRecordRecord(
    TimelineMilestoneRecordRow entry,
  ) {
    return update(timelineMilestoneRecords).replace(entry);
  }

  Stream<List<Timeline>> watchTimelines() {
    final query = select(timelines)
      ..orderBy([
        (t) => OrderingTerm.asc(t.status),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toTimeline).toList(growable: false),
    );
  }

  Future<Timeline?> getTimelineById(int id) async {
    final row = await (select(
      timelines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTimeline(row);
  }

  Stream<List<TimelineMilestoneRule>> watchTimelineMilestoneRules() {
    final query = select(timelineMilestoneRules)
      ..orderBy([
        (t) => OrderingTerm.asc(t.timelineId),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toTimelineMilestoneRule).toList(growable: false),
    );
  }

  Stream<List<TimelineMilestoneRecord>> watchTimelineMilestoneRecords() {
    final query = select(timelineMilestoneRecords)
      ..orderBy([
        (t) => OrderingTerm.asc(t.targetDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toTimelineMilestoneRecord).toList(growable: false),
    );
  }

  Future<List<TimelineMilestoneRule>> listTimelineMilestoneRulesForTimeline(
    int timelineId,
  ) async {
    final rows =
        await (select(timelineMilestoneRules)
              ..where((t) => t.timelineId.equals(timelineId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toTimelineMilestoneRule).toList(growable: false);
  }

  Future<List<TimelineMilestoneRule>>
  listVisibleTimelineMilestoneRulesForTimeline(int timelineId) async {
    final rows =
        await (select(timelineMilestoneRules)
              ..where(
                (t) =>
                    t.timelineId.equals(timelineId) &
                    t.status.isNotValue(
                      TimelineMilestoneRuleStatus.archived.name,
                    ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toTimelineMilestoneRule).toList(growable: false);
  }

  Future<TimelineMilestoneRule?> getTimelineMilestoneRuleById(int id) async {
    final row = await (select(
      timelineMilestoneRules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTimelineMilestoneRule(row);
  }

  Stream<List<TimelineMilestoneRecordBundle>>
  watchTimelineMilestoneRecordBundles() {
    return _timelineMilestoneRecordBundleQuery().watch().map(
      (rows) =>
          rows.map(_mapTimelineMilestoneRecordBundle).toList(growable: false),
    );
  }

  Future<List<TimelineMilestoneRecordBundle>>
  listTimelineMilestoneRecordBundlesForTimeline(int timelineId) {
    return _timelineMilestoneRecordBundleQuery(
      where: (r) => r.timelineId.equals(timelineId),
    ).get().then(
      (rows) =>
          rows.map(_mapTimelineMilestoneRecordBundle).toList(growable: false),
    );
  }

  Future<TimelineMilestoneRecord?> getTimelineMilestoneRecordByOccurrence({
    required int ruleId,
    required int occurrenceIndex,
  }) async {
    final row =
        await (select(timelineMilestoneRecords)..where(
              (t) =>
                  t.ruleId.equals(ruleId) &
                  t.occurrenceIndex.equals(occurrenceIndex),
            ))
            .getSingleOrNull();
    return row == null ? null : _toTimelineMilestoneRecord(row);
  }

  Future<TimelineDetailRecord?> getTimelineDetailRecordById(int id) async {
    final timeline = await getTimelineById(id);
    if (timeline == null) {
      return null;
    }
    final rules = await listVisibleTimelineMilestoneRulesForTimeline(id);
    final records = await listTimelineMilestoneRecordBundlesForTimeline(id);
    return TimelineDetailRecord(
      timeline: timeline,
      milestoneRules: rules,
      milestoneHistory: records
          .where(
            (item) =>
                item.record.status != TimelineMilestoneRecordStatus.upcoming,
          )
          .toList(growable: false),
    );
  }

  Future<void> upsertTimelineMilestoneRecordForOccurrence({
    required TimelineMilestoneOccurrence occurrence,
    required TimelineMilestoneRecordStatus status,
    DateTime? notifiedAt,
    DateTime? actedAt,
  }) async {
    final existing = await getTimelineMilestoneRecordByOccurrence(
      ruleId: occurrence.ruleId,
      occurrenceIndex: occurrence.occurrenceIndex,
    );
    final now = DateTime.now();
    if (existing == null) {
      await insertTimelineMilestoneRecord(
        TimelineMilestoneRecordsCompanion.insert(
          timelineId: occurrence.timelineId,
          ruleId: occurrence.ruleId,
          occurrenceIndex: occurrence.occurrenceIndex,
          targetDate: occurrence.targetDate.millisecondsSinceEpoch,
          status: status.name,
          notifiedAt: Value(notifiedAt?.millisecondsSinceEpoch),
          actedAt: Value(actedAt?.millisecondsSinceEpoch),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return;
    }

    await updateTimelineMilestoneRecordRecord(
      TimelineMilestoneRecordRow(
        id: existing.id,
        timelineId: existing.timelineId,
        ruleId: existing.ruleId,
        occurrenceIndex: existing.occurrenceIndex,
        targetDate: occurrence.targetDate.millisecondsSinceEpoch,
        status: status.name,
        notifiedAt: (notifiedAt ?? existing.notifiedAt)?.millisecondsSinceEpoch,
        actedAt: (actedAt ?? existing.actedAt)?.millisecondsSinceEpoch,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> markTimelineMilestoneRecordNoticed(
    TimelineMilestoneOccurrence occurrence,
  ) {
    final now = DateTime.now();
    return upsertTimelineMilestoneRecordForOccurrence(
      occurrence: occurrence,
      status: TimelineMilestoneRecordStatus.noticed,
      actedAt: now,
    );
  }

  Future<void> markTimelineMilestoneRecordSkipped(
    TimelineMilestoneOccurrence occurrence,
  ) {
    final now = DateTime.now();
    return upsertTimelineMilestoneRecordForOccurrence(
      occurrence: occurrence,
      status: TimelineMilestoneRecordStatus.skipped,
      actedAt: now,
    );
  }

  Future<void> markTimelineMilestoneRecordNotified(
    TimelineMilestoneOccurrence occurrence,
  ) {
    final now = DateTime.now();
    return upsertTimelineMilestoneRecordForOccurrence(
      occurrence: occurrence,
      status: TimelineMilestoneRecordStatus.upcoming,
      notifiedAt: now,
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _itemBundleQuery({
    Expression<bool> Function($ItemsTable t)? where,
    Set<ItemLifecycleStatus>? statuses,
    int? limit,
  }) {
    final query = select(
      items,
    ).join([innerJoin(itemPacks, itemPacks.id.equalsExp(items.packId))]);
    if (statuses != null) {
      query.where(_itemStatusPredicate(const Constant(true), statuses));
    }
    if (where != null) {
      query.where(where(items));
    }
    query.orderBy([
      OrderingTerm.desc(items.updatedAt),
      OrderingTerm.asc(items.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _resourceBundleQuery({
    Expression<bool> Function($ResourcesTable t)? where,
    Set<ResourceLifecycleStatus>? statuses,
    int? limit,
  }) {
    final query = select(
      resources,
    ).join([innerJoin(itemPacks, itemPacks.id.equalsExp(resources.packId))]);
    if (statuses != null) {
      query.where(resources.status.isIn(statuses.map((item) => item.name)));
    }
    if (where != null) {
      query.where(where(resources));
    }
    query.orderBy([
      OrderingTerm.desc(resources.updatedAt),
      OrderingTerm.asc(resources.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic>
  _timelineMilestoneRecordBundleQuery({
    Expression<bool> Function($TimelineMilestoneRecordsTable t)? where,
    int? limit,
  }) {
    final query = select(timelineMilestoneRecords).join([
      innerJoin(
        timelines,
        timelines.id.equalsExp(timelineMilestoneRecords.timelineId),
      ),
      innerJoin(
        timelineMilestoneRules,
        timelineMilestoneRules.id.equalsExp(timelineMilestoneRecords.ruleId),
      ),
    ]);
    if (where != null) {
      query.where(where(timelineMilestoneRecords));
    }
    query.orderBy([
      OrderingTerm.desc(timelineMilestoneRecords.targetDate),
      OrderingTerm.desc(timelineMilestoneRecords.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _itemActivityEntryQuery({
    Set<ItemActionType>? actionTypes,
    String? query,
    DateTime? actionDateFrom,
    DateTime? actionDateBefore,
    int? limit,
    int offset = 0,
  }) {
    final activityQuery = select(itemActionRecords).join([
      innerJoin(items, items.id.equalsExp(itemActionRecords.itemId)),
      innerJoin(itemPacks, itemPacks.id.equalsExp(items.packId)),
    ]);

    if (actionTypes != null && actionTypes.isNotEmpty) {
      activityQuery.where(
        itemActionRecords.actionType.isIn(actionTypes.map((item) => item.name)),
      );
    }
    if (actionDateFrom != null) {
      activityQuery.where(
        itemActionRecords.actionDate.isBiggerOrEqualValue(
          actionDateFrom.millisecondsSinceEpoch,
        ),
      );
    }
    if (actionDateBefore != null) {
      activityQuery.where(
        itemActionRecords.actionDate.isSmallerThanValue(
          actionDateBefore.millisecondsSinceEpoch,
        ),
      );
    }

    final trimmedQuery = query?.trim();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      final pattern = '%$trimmedQuery%';
      final actionNames = _matchingActionTypeNames(trimmedQuery);
      activityQuery.where(
        items.title.like(pattern) |
            itemPacks.title.like(pattern) |
            (actionNames.isEmpty
                ? const Constant(false)
                : itemActionRecords.actionType.isIn(actionNames)),
      );
    }

    activityQuery.orderBy([
      OrderingTerm.desc(itemActionRecords.actionDate),
      OrderingTerm.desc(itemActionRecords.id),
    ]);
    if (limit != null) {
      activityQuery.limit(limit, offset: offset);
    }
    return activityQuery;
  }

  ItemBundle _mapItemBundle(TypedResult row) {
    return ItemBundle(
      item: _toItem(row.readTable(items)),
      pack: _toItemPack(row.readTable(itemPacks)),
    );
  }

  ItemActivityEntry _mapItemActivityEntry(TypedResult row) {
    return ItemActivityEntry(
      record: _toItemActionRecord(row.readTable(itemActionRecords)),
      item: _toItem(row.readTable(items)),
      pack: _toItemPack(row.readTable(itemPacks)),
    );
  }

  ResourceBundle _mapResourceBundle(TypedResult row) {
    return ResourceBundle(
      resource: _toResource(row.readTable(resources)),
      pack: _toItemPack(row.readTable(itemPacks)),
    );
  }

  Expression<bool> _itemStatusPredicate(
    Expression<bool> base,
    Set<ItemLifecycleStatus>? statuses,
  ) {
    if (statuses == null) {
      return base;
    }
    return base & items.status.isIn(statuses.map((item) => item.name));
  }

  TimelineMilestoneRecordBundle _mapTimelineMilestoneRecordBundle(
    TypedResult row,
  ) {
    return TimelineMilestoneRecordBundle(
      record: _toTimelineMilestoneRecord(
        row.readTable(timelineMilestoneRecords),
      ),
      rule: _toTimelineMilestoneRule(row.readTable(timelineMilestoneRules)),
      timeline: _toTimeline(row.readTable(timelines)),
    );
  }

  List<String> _matchingActionTypeNames(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final matches = <String>[];
    void maybeAdd(ItemActionType type, List<String> keywords) {
      if (keywords.any(
        (keyword) =>
            keyword.contains(normalized) || normalized.contains(keyword),
      )) {
        matches.add(type.name);
      }
    }

    maybeAdd(ItemActionType.created, ['created', 'create', '新增']);
    maybeAdd(ItemActionType.done, ['done', 'complete', '完成']);
    maybeAdd(ItemActionType.skipped, ['skipped', 'skip', '跳過']);
    maybeAdd(ItemActionType.deferred, ['deferred', 'defer', '延期']);
    return matches;
  }

  ItemPack _toItemPack(ItemPackRow row) {
    return ItemPack(
      id: row.id,
      title: row.title,
      description: row.description,
      status: ItemPackStatus.values.byName(row.status),
      isSystemDefault: row.isSystemDefault,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  Future<ItemPackTemplate> _toItemPackTemplate(ItemPackTemplateRow row) async {
    final itemRows =
        await (select(itemTemplateItems)
              ..where((t) => t.templateId.equals(row.id))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    final resourceRows =
        await (select(resourceTemplateItems)
              ..where((t) => t.templateId.equals(row.id))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    final ruleRows =
        await (select(resourceConsumptionRuleTemplateItems)
              ..where((t) => t.templateId.equals(row.id))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return ItemPackTemplate(
      id: 'custom-${row.id}',
      source: ItemPackTemplateSource.custom,
      name: row.name,
      category: row.category,
      description: row.description,
      items: itemRows.map(_toItemPackTemplateItem).toList(growable: false),
      resources: resourceRows
          .map(_toResourceTemplateItem)
          .toList(growable: false),
      consumptionRules: ruleRows
          .map(_toResourceConsumptionRuleTemplate)
          .toList(growable: false),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ItemPackTemplateItem _toItemPackTemplateItem(ItemTemplateItemRow row) {
    final itemType = _itemTypeFromRow(row.type);
    return ItemPackTemplateItem(
      logicalId: row.logicalId,
      title: row.title,
      description: row.description,
      type: itemType,
      config: _toTemplateItemConfig(row, itemType),
      attentionPolicySource: _attentionPolicySource(row.attentionPolicySource),
    );
  }

  ResourceTemplateItem _toResourceTemplateItem(ResourceTemplateItemRow row) {
    final type = ResourceType.values.byName(row.type);
    return ResourceTemplateItem(
      logicalId: row.logicalId,
      title: row.title,
      description: row.description,
      type: type,
      config: _toResourceTemplateConfig(row, type),
    );
  }

  ResourceConfig _toResourceTemplateConfig(
    ResourceTemplateItemRow row,
    ResourceType type,
  ) {
    return switch (type) {
      ResourceType.timeBased => TimeBasedResourceConfig(
        durationDays: row.timeDurationDays ?? 1,
        infoBeforeDays: row.timeExpectedBeforeDays ?? 0,
        warningBeforeDays: row.timeWarningBeforeDays ?? 0,
        dangerBeforeDays: row.timeDangerBeforeDays ?? 0,
      ),
      ResourceType.quantityBased => QuantityBasedResourceConfig(
        currentQuantity: row.quantityCurrent ?? 0,
        unitLabel: row.quantityUnitLabel ?? '個',
        infoThreshold: row.quantityExpectedThreshold,
        warningThreshold: row.quantityWarningThreshold ?? 0,
        dangerThreshold: row.quantityDangerThreshold ?? 0,
      ),
    };
  }

  ResourceConsumptionRuleTemplate _toResourceConsumptionRuleTemplate(
    ResourceConsumptionRuleTemplateRow row,
  ) {
    return ResourceConsumptionRuleTemplate(
      itemLogicalId: row.itemLogicalId,
      resourceLogicalId: row.resourceLogicalId,
      triggerActionType: ItemActionType.values.byName(row.triggerActionType),
      consumeAmount: row.consumeAmount,
    );
  }

  Item _toItem(ItemRow row) {
    final itemType = _itemTypeFromRow(row.type);
    return Item(
      id: row.id,
      packId: row.packId,
      title: row.title,
      description: row.description,
      status: ItemLifecycleStatus.values.byName(row.status),
      type: itemType,
      config: _toItemConfig(row, itemType),
      attentionPolicySource: _attentionPolicySource(row.attentionPolicySource),
      lastDoneAt: row.lastDoneAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastDoneAt!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ItemConfig _toItemConfig(ItemRow row, ItemType type) {
    return switch (type) {
      ItemType.fixed => FixedItemConfig(
        scheduleType: FixedScheduleType.values.byName(
          _fixedScheduleTypeFromRow(
            row.fixedScheduleType ?? FixedScheduleType.oneTime.name,
          ),
        ),
        scheduleInterval: row.fixedScheduleInterval ?? 1,
        monthlyDay: row.fixedMonthlyDay,
        repeatRuleV2: RepeatRuleV2.parse(row.fixedRepeatRuleV2),
        anchorDate: row.fixedAnchorDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.fixedAnchorDate!),
        dueDate: row.fixedDueDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.fixedDueDate!),
        timeOfDay: row.fixedTimeOfDay,
        overduePolicy: ItemOverduePolicy.values.byName(
          row.fixedOverduePolicy ?? ItemOverduePolicy.autoAdvance.name,
        ),
        infoBefore: Duration(minutes: row.fixedExpectedBeforeMinutes ?? 0),
        warningBefore: Duration(minutes: row.fixedWarningBeforeMinutes ?? 0),
        dangerBefore: Duration(minutes: row.fixedDangerBeforeMinutes ?? 0),
      ),
      ItemType.stateBased => StateBasedItemConfig(
        anchorDate: row.stateAnchorDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.stateAnchorDate!),
        infoAfter: Duration(minutes: row.stateExpectedAfterMinutes ?? 0),
        warningAfter: Duration(minutes: row.stateWarningAfterMinutes ?? 0),
        dangerAfter: Duration(minutes: row.stateDangerAfterMinutes ?? 0),
      ),
    };
  }

  ItemConfig _toTemplateItemConfig(ItemTemplateItemRow row, ItemType type) {
    return switch (type) {
      ItemType.fixed => FixedItemConfig(
        scheduleType: FixedScheduleType.values.byName(
          _fixedScheduleTypeFromRow(
            row.fixedScheduleType ?? FixedScheduleType.oneTime.name,
          ),
        ),
        scheduleInterval: row.fixedScheduleInterval ?? 1,
        monthlyDay: row.fixedMonthlyDay,
        repeatRuleV2: RepeatRuleV2.parse(row.fixedRepeatRuleV2),
        timeOfDay: row.fixedTimeOfDay,
        overduePolicy: ItemOverduePolicy.values.byName(
          row.fixedOverduePolicy ?? ItemOverduePolicy.autoAdvance.name,
        ),
        infoBefore: Duration(minutes: row.fixedExpectedBeforeMinutes ?? 0),
        warningBefore: Duration(minutes: row.fixedWarningBeforeMinutes ?? 0),
        dangerBefore: Duration(minutes: row.fixedDangerBeforeMinutes ?? 0),
      ),
      ItemType.stateBased => StateBasedItemConfig(
        infoAfter: Duration(minutes: row.stateExpectedAfterMinutes ?? 0),
        warningAfter: Duration(minutes: row.stateWarningAfterMinutes ?? 0),
        dangerAfter: Duration(minutes: row.stateDangerAfterMinutes ?? 0),
      ),
    };
  }

  ItemActionRecord _toItemActionRecord(ItemActionRecordRow row) {
    return ItemActionRecord(
      id: row.id,
      itemId: row.itemId,
      actionType: ItemActionType.values.byName(row.actionType),
      actionDate: DateTime.fromMillisecondsSinceEpoch(row.actionDate),
      remark: row.remark,
      payload: ItemActionRecord.decodePayload(row.payload),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  Resource _toResource(ResourceRow row) {
    final type = ResourceType.values.byName(row.type);
    return Resource(
      id: row.id,
      packId: row.packId,
      title: row.title,
      description: row.description,
      status: ResourceLifecycleStatus.values.byName(row.status),
      type: type,
      config: _toResourceConfig(row, type),
      lastRefilledAt: row.lastRefilledAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastRefilledAt!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ResourceConfig _toResourceConfig(ResourceRow row, ResourceType type) {
    return switch (type) {
      ResourceType.timeBased => TimeBasedResourceConfig(
        anchorDate: row.timeAnchorDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.timeAnchorDate!),
        durationDays: row.timeDurationDays ?? 0,
        infoBeforeDays: row.timeExpectedBeforeDays ?? 0,
        warningBeforeDays: row.timeWarningBeforeDays ?? 0,
        dangerBeforeDays: row.timeDangerBeforeDays ?? 0,
      ),
      ResourceType.quantityBased => QuantityBasedResourceConfig(
        currentQuantity: row.quantityCurrent ?? 0,
        unitLabel: row.quantityUnitLabel ?? '',
        infoThreshold: row.quantityExpectedThreshold,
        warningThreshold: row.quantityWarningThreshold ?? 0,
        dangerThreshold: row.quantityDangerThreshold ?? 0,
      ),
    };
  }

  ResourceConsumptionRule _toResourceConsumptionRule(
    ResourceConsumptionRuleRow row,
  ) {
    return ResourceConsumptionRule(
      id: row.id,
      resourceId: row.resourceId,
      itemId: row.itemId,
      triggerActionType: ItemActionType.values.byName(row.triggerActionType),
      consumeAmount: row.consumeAmount,
      isEnabled: row.isEnabled,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ResourceActionRecord _toResourceActionRecord(ResourceActionRecordRow row) {
    return ResourceActionRecord(
      id: row.id,
      resourceId: row.resourceId,
      actionType: ResourceActionType.values.byName(row.actionType),
      actionDate: DateTime.fromMillisecondsSinceEpoch(row.actionDate),
      amount: row.amount,
      resultingQuantity: row.resultingQuantity,
      addedDays: row.addedDays,
      resultingDurationDays: row.resultingDurationDays,
      sourceItemActionRecordId: row.sourceItemActionRecordId,
      remark: row.remark,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  Timeline _toTimeline(TimelineRow row) {
    return Timeline(
      id: row.id,
      title: row.title,
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
      displayUnit: TimelineDisplayUnit.values.byName(row.displayUnit),
      status: TimelineStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  TimelineMilestoneRule _toTimelineMilestoneRule(TimelineMilestoneRuleRow row) {
    return TimelineMilestoneRule(
      id: row.id,
      timelineId: row.timelineId,
      type: _timelineMilestoneRuleType(row.type),
      intervalValue: row.intervalValue,
      intervalUnit: TimelineMilestoneIntervalUnit.values.byName(
        row.intervalUnit,
      ),
      labelTemplate: row.labelTemplate,
      reminderOffsetDays: row.reminderOffsetDays,
      status: TimelineMilestoneRuleStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  TimelineMilestoneRecord _toTimelineMilestoneRecord(
    TimelineMilestoneRecordRow row,
  ) {
    return TimelineMilestoneRecord(
      id: row.id,
      timelineId: row.timelineId,
      ruleId: row.ruleId,
      occurrenceIndex: row.occurrenceIndex,
      targetDate: DateTime.fromMillisecondsSinceEpoch(row.targetDate),
      status: TimelineMilestoneRecordStatus.values.byName(row.status),
      notifiedAt: row.notifiedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.notifiedAt!),
      actedAt: row.actedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.actedAt!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  AppSettings _toAppSettings(AppSettingsRow row) {
    return AppSettings(
      reminderTone: _reminderTone(row.reminderTone),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  AppSettings _defaultAppSettings() {
    return AppSettings(updatedAt: DateTime.now());
  }

  AttentionPolicySource _attentionPolicySource(String value) {
    return AttentionPolicySource.values.asNameMap()[value] ??
        AttentionPolicySource.systemDefault;
  }

  ReminderTone _reminderTone(String value) {
    return ReminderTone.values.asNameMap()[value] ?? ReminderTone.standard;
  }

  TimelineMilestoneRuleType _timelineMilestoneRuleType(String value) {
    return switch (value) {
      'every_n_days' => TimelineMilestoneRuleType.everyNDays,
      'every_n_weeks' => TimelineMilestoneRuleType.everyNWeeks,
      'every_n_months' => TimelineMilestoneRuleType.everyNMonths,
      'every_n_years' => TimelineMilestoneRuleType.everyNYears,
      _ => TimelineMilestoneRuleType.everyNDays,
    };
  }

  ItemType _itemTypeFromRow(String value) {
    return switch (value) {
      'fixedTime' => ItemType.fixed,
      _ => ItemType.values.byName(value),
    };
  }

  String _fixedScheduleTypeFromRow(String value) {
    return switch (value) {
      'custom' => FixedScheduleType.oneTime.name,
      _ => value,
    };
  }

  List<OrderingTerm Function($ItemPacksTable)> get _itemPackOrdering => [
    (t) => OrderingTerm.desc(t.isSystemDefault),
    (t) => OrderingTerm.desc(t.updatedAt),
    (t) => OrderingTerm.asc(t.id),
  ];
}
