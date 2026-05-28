import 'package:drift/drift.dart';

import '../../domain/app_settings.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/item_action_record.dart';
import '../../domain/item_pack.dart';
import '../../domain/repeat_rule_v2.dart';
import '../../domain/resource.dart';
import '../../domain/stage_record.dart';
import '../../domain/stage_related_item.dart';
import '../../domain/stage_rule.dart';
import '../../domain/stage_tracker.dart';
import 'app_database.dart';
import 'tables.dart';

part 'reminder_dao.g.dart';

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

class ResourceBinding {
  const ResourceBinding({required this.rule, required this.item});

  final ResourceConsumptionRule rule;
  final Item item;
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

class ItemActionEntry {
  const ItemActionEntry({
    required this.record,
    required this.item,
    required this.pack,
  });

  final ItemActionRecord record;
  final Item item;
  final ItemPack pack;

  int get packId => pack.id;
}

class ItemHistoryActionResourceRow {
  const ItemHistoryActionResourceRow({
    required this.actionRecord,
    this.resourceActionRecord,
    this.resource,
  });

  final ItemActionRecord actionRecord;
  final ResourceActionRecord? resourceActionRecord;
  final Resource? resource;
}

class ResourceActionEntry {
  const ResourceActionEntry({
    required this.record,
    required this.resource,
    required this.pack,
  });

  final ResourceActionRecord record;
  final Resource resource;
  final ItemPack pack;

  int get packId => pack.id;
}

class ResourceActionHistoryEntry {
  const ResourceActionHistoryEntry({required this.record, this.sourceItem});

  final ResourceActionRecord record;
  final Item? sourceItem;
}

class StageRecordBundle {
  const StageRecordBundle({
    required this.record,
    this.rule,
    required this.stageTracker,
  });

  final StageRecord record;
  final StageRule? rule;
  final StageTracker stageTracker;
}

class StageActionEntry {
  const StageActionEntry({required this.record, required this.stageTracker});

  final StageRecord record;
  final StageTracker stageTracker;

  int get packId => stageTracker.packId;
}

class StageTrackerDetailRecord {
  const StageTrackerDetailRecord({
    required this.stageTracker,
    required this.stageRules,
    required this.stageRecords,
  });

  final StageTracker stageTracker;
  final List<StageRule> stageRules;
  final List<StageRecord> stageRecords;
}

class StageRelatedItemSource {
  const StageRelatedItemSource({
    required this.stageTrackerTitle,
    required this.stageLabel,
  });

  final String stageTrackerTitle;
  final String stageLabel;
}

class StageRelatedItemEntry {
  const StageRelatedItemEntry({
    required this.relatedItemId,
    required this.bundle,
    required this.hasDoneAction,
    required this.hasSkippedAction,
  });

  final int relatedItemId;
  final ItemBundle bundle;
  final bool hasDoneAction;
  final bool hasSkippedAction;
}

@DriftAccessor(
  tables: [
    ItemPacks,
    Items,
    Resources,
    ResourceConsumptionRules,
    ResourceActionRecords,
    ItemActionRecords,
    StageTrackers,
    StageRules,
    StageRecords,
    StageRelatedItems,
    AppSettingsEntries,
  ],
)
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.attachedDatabase);

  Future<int> insertItemPack(ItemPacksCompanion entry) {
    return into(itemPacks).insert(entry);
  }

  Future<int> insertItem(ItemsCompanion entry) {
    return into(items).insert(entry);
  }

  Future<int> insertItemActionRecord(ItemActionRecordsCompanion entry) {
    return into(itemActionRecords).insert(entry);
  }

  Future<ItemActionRecord?> getItemActionRecordById(int id) async {
    final row = await (select(
      itemActionRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toItemActionRecord(row);
  }

  Future<bool> updateItemActionRecordFields(
    int id,
    ItemActionRecordsCompanion entry,
  ) async {
    final updatedRows = await (update(
      itemActionRecords,
    )..where((t) => t.id.equals(id))).write(entry);
    return updatedRows > 0;
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

  Future<bool> updateResourceActionRecordFields(
    int id,
    ResourceActionRecordsCompanion entry,
  ) async {
    final updatedRows = await (update(
      resourceActionRecords,
    )..where((t) => t.id.equals(id))).write(entry);
    return updatedRows > 0;
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

  Future<bool> updateItemPackFields(int id, ItemPacksCompanion entry) async {
    final updatedRows = await (update(
      itemPacks,
    )..where((t) => t.id.equals(id))).write(entry);
    return updatedRows > 0;
  }

  Future<bool> updateItemRecord(ItemRow entry) {
    return update(items).replace(entry);
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

  Future<ItemPack?> getSystemDefaultPack() async {
    final row =
        await (select(itemPacks)
              ..where((t) => t.isSystemDefault.equals(true))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toItemPack(row);
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

  Future<int> countResourcesForPack(
    int packId, {
    Set<ResourceLifecycleStatus>? statuses,
  }) async {
    final countExpression = resources.id.count();
    final query = selectOnly(resources)
      ..addColumns([countExpression])
      ..where(resources.packId.equals(packId));
    if (statuses != null) {
      query.where(resources.status.isIn(statuses.map((item) => item.name)));
    }
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<int> countStageTrackersForPack(
    int packId, {
    Set<StageTrackerStatus>? statuses,
  }) async {
    final countExpression = stageTrackers.id.count();
    final query = selectOnly(stageTrackers)
      ..addColumns([countExpression])
      ..where(stageTrackers.packId.equals(packId));
    if (statuses != null) {
      query.where(stageTrackers.status.isIn(statuses.map((item) => item.name)));
    }
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

  Stream<List<ResourceBinding>> watchResourceBindings(int resourceId) {
    final query =
        select(resourceConsumptionRules).join([
            innerJoin(
              items,
              items.id.equalsExp(resourceConsumptionRules.itemId),
            ),
          ])
          ..where(resourceConsumptionRules.resourceId.equals(resourceId))
          ..orderBy([OrderingTerm.asc(resourceConsumptionRules.id)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ResourceBinding(
              rule: _toResourceConsumptionRule(
                row.readTable(resourceConsumptionRules),
              ),
              item: _toItem(row.readTable(items)),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<ResourceActionRecord>> watchResourceActionRecordsForResource(
    int resourceId, {
    bool includeReverted = false,
  }) {
    final query = select(resourceActionRecords)
      ..where((t) => t.resourceId.equals(resourceId));
    if (!includeReverted) {
      query.where(
        (t) =>
            t.isReverted.equals(false) &
            t.actionType.isNotValue(ResourceActionType.reverted.name),
      );
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.actionDate),
      (t) => OrderingTerm.desc(t.id),
    ]);
    return query.watch().map(
      (rows) => rows.map(_toResourceActionRecord).toList(growable: false),
    );
  }

  Stream<List<ResourceActionHistoryEntry>>
  watchResourceActionHistoryEntriesForResource(
    int resourceId, {
    bool includeReverted = false,
  }) {
    final query = select(resourceActionRecords).join([
      leftOuterJoin(
        itemActionRecords,
        itemActionRecords.id.equalsExp(
          resourceActionRecords.sourceItemActionRecordId,
        ),
      ),
      leftOuterJoin(items, items.id.equalsExp(itemActionRecords.itemId)),
    ])..where(resourceActionRecords.resourceId.equals(resourceId));
    if (!includeReverted) {
      query.where(
        resourceActionRecords.isReverted.equals(false) &
            resourceActionRecords.actionType.isNotValue(
              ResourceActionType.reverted.name,
            ),
      );
    }
    query.orderBy([
      OrderingTerm.desc(resourceActionRecords.actionDate),
      OrderingTerm.desc(resourceActionRecords.id),
    ]);
    return query.watch().map(
      (rows) =>
          rows.map(_mapResourceActionHistoryEntry).toList(growable: false),
    );
  }

  Future<List<ResourceActionRecord>> listResourceActionRecordsForResource(
    int resourceId, {
    bool includeReverted = false,
  }) async {
    final query = select(resourceActionRecords)
      ..where((t) => t.resourceId.equals(resourceId));
    if (!includeReverted) {
      query.where(
        (t) =>
            t.isReverted.equals(false) &
            t.actionType.isNotValue(ResourceActionType.reverted.name),
      );
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.actionDate),
      (t) => OrderingTerm.desc(t.id),
    ]);
    final rows = await query.get();
    return rows.map(_toResourceActionRecord).toList(growable: false);
  }

  Future<List<ResourceActionRecord>> listResourceConsumedRecordsForItemAction(
    int itemActionRecordId,
  ) async {
    final rows =
        await (select(resourceActionRecords)..where(
              (t) =>
                  t.sourceItemActionRecordId.equals(itemActionRecordId) &
                  t.actionType.equals(ResourceActionType.consumed.name),
            ))
            .get();
    return rows.map(_toResourceActionRecord).toList(growable: false);
  }

  Stream<List<ItemHistoryActionResourceRow>> watchItemHistoryActionResourceRows(
    int itemId,
  ) {
    final query = select(itemActionRecords).join([
      leftOuterJoin(
        resourceActionRecords,
        resourceActionRecords.sourceItemActionRecordId.equalsExp(
          itemActionRecords.id,
        ),
      ),
      leftOuterJoin(
        resources,
        resources.id.equalsExp(resourceActionRecords.resourceId),
      ),
    ])..where(itemActionRecords.itemId.equals(itemId));
    query.orderBy([
      OrderingTerm.desc(itemActionRecords.actionDate),
      OrderingTerm.desc(itemActionRecords.id),
      OrderingTerm.asc(resourceActionRecords.id),
    ]);
    return query.watch().map(
      (rows) =>
          rows.map(_mapItemHistoryActionResourceRow).toList(growable: false),
    );
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

  Stream<List<ItemActionEntry>> watchItemActionEntriesForDateRange({
    required Set<ItemActionType> actionTypes,
    required DateTime actionDateFrom,
    required DateTime actionDateBefore,
    bool includeReverted = false,
  }) {
    return _itemActionEntryQuery(
      actionTypes: actionTypes,
      actionDateFrom: actionDateFrom,
      actionDateBefore: actionDateBefore,
      includeReverted: includeReverted,
    ).watch().map(
      (rows) => rows.map(_mapItemActionEntry).toList(growable: false),
    );
  }

  Stream<List<ResourceActionEntry>> watchResourceActionEntriesForDateRange({
    required Set<ResourceActionType> actionTypes,
    required DateTime actionDateFrom,
    required DateTime actionDateBefore,
    bool includeReverted = false,
  }) {
    return _resourceActionEntryQuery(
      actionTypes: actionTypes,
      actionDateFrom: actionDateFrom,
      actionDateBefore: actionDateBefore,
      includeReverted: includeReverted,
    ).watch().map(
      (rows) => rows.map(_mapResourceActionEntry).toList(growable: false),
    );
  }

  Stream<List<StageActionEntry>>
  watchAcknowledgedStageActionEntriesForDateRange({
    required DateTime updatedAtFrom,
    required DateTime updatedAtBefore,
  }) {
    final query =
        select(stageRecords).join([
            innerJoin(
              stageTrackers,
              stageTrackers.id.equalsExp(stageRecords.stageTrackerId),
            ),
          ])
          ..where(
            stageRecords.status.equals(StageRecordStatus.acknowledged.name) &
                stageRecords.updatedAt.isBiggerOrEqualValue(
                  updatedAtFrom.millisecondsSinceEpoch,
                ) &
                stageRecords.updatedAt.isSmallerThanValue(
                  updatedAtBefore.millisecondsSinceEpoch,
                ),
          )
          ..orderBy([
            OrderingTerm.desc(stageRecords.updatedAt),
            OrderingTerm.desc(stageRecords.id),
          ]);
    return query.watch().map(
      (rows) => rows.map(_mapStageActionEntry).toList(growable: false),
    );
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
    return (update(items)..where(
          (t) =>
              t.packId.equals(packId) &
              t.status.isIn(const ['active', 'paused']),
        ))
        .write(
          ItemsCompanion(
            status: Value(status.name),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
  }

  Future<int> updateResourcesStatusForPack(
    int packId,
    ResourceLifecycleStatus status,
  ) async {
    final now = DateTime.now();
    return (update(resources)..where(
          (t) =>
              t.packId.equals(packId) &
              t.status.isIn(const ['active', 'paused']),
        ))
        .write(
          ResourcesCompanion(
            status: Value(status.name),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
  }

  Future<int> updateStageTrackersStatusForPack(
    int packId,
    StageTrackerStatus status,
  ) async {
    final now = DateTime.now();
    return (update(stageTrackers)..where(
          (t) =>
              t.packId.equals(packId) &
              t.status.equals(StageTrackerStatus.active.name),
        ))
        .write(
          StageTrackersCompanion(
            status: Value(status.name),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
  }

  Future<int> moveItemsToPack(int sourcePackId, int destinationPackId) async {
    final now = DateTime.now();
    return (update(items)..where((t) => t.packId.equals(sourcePackId))).write(
      ItemsCompanion(
        packId: Value(destinationPackId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> moveResourcesToPack(
    int sourcePackId,
    int destinationPackId,
  ) async {
    final now = DateTime.now();
    return (update(
      resources,
    )..where((t) => t.packId.equals(sourcePackId))).write(
      ResourcesCompanion(
        packId: Value(destinationPackId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> moveStageTrackersToPack(
    int sourcePackId,
    int destinationPackId,
  ) async {
    final now = DateTime.now();
    return (update(
      stageTrackers,
    )..where((t) => t.packId.equals(sourcePackId))).write(
      StageTrackersCompanion(
        packId: Value(destinationPackId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> insertStageTracker(StageTrackersCompanion entry) {
    return into(stageTrackers).insert(entry);
  }

  Future<bool> updateStageTrackerRecord(StageTrackerRow entry) {
    return update(stageTrackers).replace(entry);
  }

  Future<int> insertStageRule(StageRulesCompanion entry) {
    return into(stageRules).insert(entry);
  }

  Future<StageRule?> getStageRuleById(int id) async {
    final row = await (select(
      stageRules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toStageRule(row);
  }

  Future<bool> updateStageRuleRecord(StageRuleRow entry) {
    return update(stageRules).replace(entry);
  }

  Future<int> insertStageRecord(StageRecordsCompanion entry) {
    return into(stageRecords).insert(entry);
  }

  Future<bool> updateStageRecordRecord(StageRecordRow entry) {
    return update(stageRecords).replace(entry);
  }

  Future<int> deleteStageRecordById(int id) {
    return (delete(stageRecords)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertStageRelatedItem(StageRelatedItemsCompanion entry) {
    return into(stageRelatedItems).insert(entry);
  }

  Stream<List<StageTracker>> watchStageTrackers({
    bool includeArchived = false,
  }) {
    final query = select(stageTrackers)
      ..orderBy([
        (t) => OrderingTerm.asc(t.status),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    if (!includeArchived) {
      query.where((t) => t.status.equals(StageTrackerStatus.active.name));
    }
    return query.watch().map(
      (rows) => rows.map(_toStageTracker).toList(growable: false),
    );
  }

  Future<StageTracker?> getStageTrackerById(int id) async {
    final row = await (select(
      stageTrackers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toStageTracker(row);
  }

  Stream<List<StageRule>> watchStageRules() {
    final query = select(stageRules)
      ..orderBy([
        (t) => OrderingTerm.asc(t.stageTrackerId),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toStageRule).toList(growable: false),
    );
  }

  Stream<List<StageRecord>> watchStageRecords() {
    final query = select(stageRecords)
      ..orderBy([
        (t) => OrderingTerm.asc(t.occurrenceDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toStageRecord).toList(growable: false),
    );
  }

  Future<List<StageRule>> listStageRulesForTracker(int stageTrackerId) async {
    final rows =
        await (select(stageRules)
              ..where((t) => t.stageTrackerId.equals(stageTrackerId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toStageRule).toList(growable: false);
  }

  Future<List<StageRule>> listVisibleStageRulesForTracker(
    int stageTrackerId,
  ) async {
    final rows =
        await (select(stageRules)
              ..where(
                (t) =>
                    t.stageTrackerId.equals(stageTrackerId) &
                    t.status.isNotValue(StageRuleStatus.archived.name),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toStageRule).toList(growable: false);
  }

  Future<List<StageRecord>> listStageRecordsForTracker(
    int stageTrackerId,
  ) async {
    final rows =
        await (select(stageRecords)
              ..where((t) => t.stageTrackerId.equals(stageTrackerId))
              ..orderBy([
                (t) => OrderingTerm.asc(t.occurrenceDate),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    return rows.map(_toStageRecord).toList(growable: false);
  }

  Future<StageRecord?> getStageRecordById(int id) async {
    final row = await (select(
      stageRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toStageRecord(row);
  }

  Future<StageRecord?> getStageRecordByOccurrence({
    required int stageRuleId,
    required int occurrenceIndex,
  }) async {
    final row =
        await (select(stageRecords)..where(
              (t) =>
                  t.stageRuleId.equals(stageRuleId) &
                  t.occurrenceIndex.equals(occurrenceIndex),
            ))
            .getSingleOrNull();
    return row == null ? null : _toStageRecord(row);
  }

  Future<StageTrackerDetailRecord?> getStageTrackerDetailRecordById(
    int id,
  ) async {
    final tracker = await getStageTrackerById(id);
    if (tracker == null) {
      return null;
    }
    return StageTrackerDetailRecord(
      stageTracker: tracker,
      stageRules: await listVisibleStageRulesForTracker(id),
      stageRecords: await listStageRecordsForTracker(id),
    );
  }

  Stream<List<StageRecordBundle>> watchStageRecordBundles() {
    return _stageRecordBundleQuery().watch().map(
      (rows) => rows.map(_mapStageRecordBundle).toList(growable: false),
    );
  }

  Future<List<StageRecordBundle>> listStageRecordBundlesForTracker(
    int stageTrackerId,
  ) {
    return _stageRecordBundleQuery(
      where: (r) => r.stageTrackerId.equals(stageTrackerId),
    ).get().then(
      (rows) => rows.map(_mapStageRecordBundle).toList(growable: false),
    );
  }

  Future<List<StageRelatedItem>> listStageRelatedItemsForRecord(
    int stageRecordId,
  ) async {
    final rows =
        await (select(stageRelatedItems)
              ..where((t) => t.stageRecordId.equals(stageRecordId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toStageRelatedItem).toList(growable: false);
  }

  Future<StageRelatedItemSummary> relatedItemSummaryForRecord(
    int stageRecordId,
  ) async {
    final query = select(stageRelatedItems).join([
      innerJoin(items, items.id.equalsExp(stageRelatedItems.itemId)),
    ])..where(stageRelatedItems.stageRecordId.equals(stageRecordId));
    final rows = await query.get();
    var done = 0;
    var active = 0;
    var paused = 0;
    var skipped = 0;
    for (final row in rows) {
      final item = _toItem(row.readTable(items));
      if (item.status == ItemLifecycleStatus.archived) {
        continue;
      }
      if (item.status == ItemLifecycleStatus.paused) {
        paused++;
        continue;
      }
      final actions = await listItemActionRecordsForItem(item.id);
      if (actions.any(
        (record) =>
            record.actionType == ItemActionType.done && !record.isReverted,
      )) {
        done++;
      } else if (actions.any(
        (record) =>
            record.actionType == ItemActionType.skipped && !record.isReverted,
      )) {
        skipped++;
      } else {
        active++;
      }
    }
    return StageRelatedItemSummary(
      doneCount: done,
      activeCount: active,
      pausedCount: paused,
      skippedCount: skipped,
    );
  }

  Future<List<StageRelatedItemEntry>> relatedItemEntriesForRecord(
    int stageRecordId,
  ) async {
    final query =
        select(stageRelatedItems).join([
            innerJoin(items, items.id.equalsExp(stageRelatedItems.itemId)),
            innerJoin(itemPacks, itemPacks.id.equalsExp(items.packId)),
          ])
          ..where(stageRelatedItems.stageRecordId.equals(stageRecordId))
          ..where(
            items.status.equals(ItemLifecycleStatus.active.name) |
                items.status.equals(ItemLifecycleStatus.paused.name),
          )
          ..orderBy([OrderingTerm.asc(stageRelatedItems.id)]);
    final rows = await query.get();
    final entries = <StageRelatedItemEntry>[];
    for (final row in rows) {
      final relatedItem = _toStageRelatedItem(row.readTable(stageRelatedItems));
      final item = _toItem(row.readTable(items));
      final actions = await listItemActionRecordsForItem(item.id);
      final hasDoneAction = actions.any(
        (record) =>
            record.actionType == ItemActionType.done && !record.isReverted,
      );
      final hasSkippedAction = actions.any(
        (record) =>
            record.actionType == ItemActionType.skipped && !record.isReverted,
      );
      entries.add(
        StageRelatedItemEntry(
          relatedItemId: relatedItem.id,
          bundle: ItemBundle(
            item: item,
            pack: _toItemPack(row.readTable(itemPacks)),
          ),
          hasDoneAction: hasDoneAction,
          hasSkippedAction: hasSkippedAction,
        ),
      );
    }
    return entries;
  }

  Future<StageRelatedItemSource?> getStageRelatedItemSourceForItem(
    int itemId,
  ) async {
    final query =
        select(stageRelatedItems).join([
            innerJoin(
              stageRecords,
              stageRecords.id.equalsExp(stageRelatedItems.stageRecordId),
            ),
            innerJoin(
              stageTrackers,
              stageTrackers.id.equalsExp(stageRecords.stageTrackerId),
            ),
          ])
          ..where(stageRelatedItems.itemId.equals(itemId))
          ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) {
      return null;
    }
    final record = _toStageRecord(rows.single.readTable(stageRecords));
    final tracker = _toStageTracker(rows.single.readTable(stageTrackers));
    return StageRelatedItemSource(
      stageTrackerTitle: tracker.title,
      stageLabel: record.label,
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

  JoinedSelectStatement<HasResultSet, dynamic> _stageRecordBundleQuery({
    Expression<bool> Function($StageRecordsTable t)? where,
    int? limit,
  }) {
    final query = select(stageRecords).join([
      innerJoin(
        stageTrackers,
        stageTrackers.id.equalsExp(stageRecords.stageTrackerId),
      ),
      leftOuterJoin(
        stageRules,
        stageRules.id.equalsExp(stageRecords.stageRuleId),
      ),
    ]);
    if (where != null) {
      query.where(where(stageRecords));
    }
    query.orderBy([
      OrderingTerm.desc(stageRecords.occurrenceDate),
      OrderingTerm.desc(stageRecords.id),
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

  JoinedSelectStatement<HasResultSet, dynamic> _itemActionEntryQuery({
    required Set<ItemActionType> actionTypes,
    required DateTime actionDateFrom,
    required DateTime actionDateBefore,
    required bool includeReverted,
  }) {
    final query =
        select(itemActionRecords).join([
          innerJoin(items, items.id.equalsExp(itemActionRecords.itemId)),
          innerJoin(itemPacks, itemPacks.id.equalsExp(items.packId)),
        ])..where(
          itemActionRecords.actionType.isIn(
                actionTypes.map((item) => item.name),
              ) &
              itemActionRecords.actionDate.isBiggerOrEqualValue(
                actionDateFrom.millisecondsSinceEpoch,
              ) &
              itemActionRecords.actionDate.isSmallerThanValue(
                actionDateBefore.millisecondsSinceEpoch,
              ),
        );
    if (!includeReverted) {
      query.where(itemActionRecords.isReverted.equals(false));
    }
    query.orderBy([
      OrderingTerm.desc(itemActionRecords.actionDate),
      OrderingTerm.desc(itemActionRecords.id),
    ]);
    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _resourceActionEntryQuery({
    required Set<ResourceActionType> actionTypes,
    required DateTime actionDateFrom,
    required DateTime actionDateBefore,
    required bool includeReverted,
  }) {
    final query =
        select(resourceActionRecords).join([
          innerJoin(
            resources,
            resources.id.equalsExp(resourceActionRecords.resourceId),
          ),
          innerJoin(itemPacks, itemPacks.id.equalsExp(resources.packId)),
        ])..where(
          resourceActionRecords.actionType.isIn(
                actionTypes.map((item) => item.name),
              ) &
              resourceActionRecords.actionDate.isBiggerOrEqualValue(
                actionDateFrom.millisecondsSinceEpoch,
              ) &
              resourceActionRecords.actionDate.isSmallerThanValue(
                actionDateBefore.millisecondsSinceEpoch,
              ),
        );
    if (!includeReverted) {
      query.where(resourceActionRecords.isReverted.equals(false));
    }
    query.orderBy([
      OrderingTerm.desc(resourceActionRecords.actionDate),
      OrderingTerm.desc(resourceActionRecords.id),
    ]);
    return query;
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

  ItemActionEntry _mapItemActionEntry(TypedResult row) {
    return ItemActionEntry(
      record: _toItemActionRecord(row.readTable(itemActionRecords)),
      item: _toItem(row.readTable(items)),
      pack: _toItemPack(row.readTable(itemPacks)),
    );
  }

  ItemHistoryActionResourceRow _mapItemHistoryActionResourceRow(
    TypedResult row,
  ) {
    final resourceActionRow = row.readTableOrNull(resourceActionRecords);
    final resourceRow = row.readTableOrNull(resources);
    return ItemHistoryActionResourceRow(
      actionRecord: _toItemActionRecord(row.readTable(itemActionRecords)),
      resourceActionRecord: resourceActionRow == null
          ? null
          : _toResourceActionRecord(resourceActionRow),
      resource: resourceRow == null ? null : _toResource(resourceRow),
    );
  }

  ResourceActionEntry _mapResourceActionEntry(TypedResult row) {
    return ResourceActionEntry(
      record: _toResourceActionRecord(row.readTable(resourceActionRecords)),
      resource: _toResource(row.readTable(resources)),
      pack: _toItemPack(row.readTable(itemPacks)),
    );
  }

  ResourceActionHistoryEntry _mapResourceActionHistoryEntry(TypedResult row) {
    final sourceItemRow = row.readTableOrNull(items);
    return ResourceActionHistoryEntry(
      record: _toResourceActionRecord(row.readTable(resourceActionRecords)),
      sourceItem: sourceItemRow == null ? null : _toItem(sourceItemRow),
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

  StageRecordBundle _mapStageRecordBundle(TypedResult row) {
    return StageRecordBundle(
      record: _toStageRecord(row.readTable(stageRecords)),
      rule: row.readTableOrNull(stageRules) == null
          ? null
          : _toStageRule(row.readTable(stageRules)),
      stageTracker: _toStageTracker(row.readTable(stageTrackers)),
    );
  }

  StageActionEntry _mapStageActionEntry(TypedResult row) {
    return StageActionEntry(
      record: _toStageRecord(row.readTable(stageRecords)),
      stageTracker: _toStageTracker(row.readTable(stageTrackers)),
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
    maybeAdd(ItemActionType.reverted, ['reverted', 'undo', '撤銷', '恢復']);
    return matches;
  }

  ItemPack _toItemPack(ItemPackRow row) {
    return ItemPack(
      id: row.id,
      title: row.title,
      description: row.description,
      iconEmoji: row.iconEmoji,
      orderIndex: row.orderIndex,
      status: ItemPackStatus.values.byName(row.status),
      isSystemDefault: row.isSystemDefault,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
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

  ItemActionRecord _toItemActionRecord(ItemActionRecordRow row) {
    return ItemActionRecord(
      id: row.id,
      itemId: row.itemId,
      actionType: ItemActionType.values.byName(row.actionType),
      actionDate: DateTime.fromMillisecondsSinceEpoch(row.actionDate),
      remark: row.remark,
      payload: ItemActionRecord.decodePayload(row.payload),
      isReverted: row.isReverted,
      revertedAt: row.revertedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.revertedAt!),
      revertedByActionRecordId: row.revertedByActionRecordId,
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
      isReverted: row.isReverted,
      revertedAt: row.revertedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.revertedAt!),
      revertedByActionRecordId: row.revertedByActionRecordId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  StageTracker _toStageTracker(StageTrackerRow row) {
    return StageTracker(
      id: row.id,
      packId: row.packId,
      title: row.title,
      subjectName: row.subjectName,
      trackingStartDate: DateTime.fromMillisecondsSinceEpoch(
        row.trackingStartDate,
      ),
      trackingEndDate: row.trackingEndDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.trackingEndDate!),
      status: StageTrackerStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  StageRule _toStageRule(StageRuleRow row) {
    return StageRule(
      id: row.id,
      stageTrackerId: row.stageTrackerId,
      type: _stageRuleType(row.type),
      intervalValue: row.intervalValue,
      intervalUnit: StageIntervalUnit.values.byName(row.intervalUnit),
      labelTemplate: row.labelTemplate,
      reminderOffsetDays: row.reminderOffsetDays,
      status: StageRuleStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  StageRecord _toStageRecord(StageRecordRow row) {
    return StageRecord(
      id: row.id,
      stageTrackerId: row.stageTrackerId,
      stageRuleId: row.stageRuleId,
      sourceType: StageRecordSourceType.values.byName(row.sourceType),
      occurrenceIndex: row.occurrenceIndex,
      occurrenceDate: DateTime.fromMillisecondsSinceEpoch(row.occurrenceDate),
      relativeAmount: row.relativeAmount,
      relativeUnit: row.relativeUnit == null
          ? null
          : StageIntervalUnit.values.byName(row.relativeUnit!),
      status: StageRecordStatus.values.byName(row.status),
      label: row.label,
      note: row.note,
      reminderOffsetDays: row.reminderOffsetDays,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  StageRelatedItem _toStageRelatedItem(StageRelatedItemRow row) {
    return StageRelatedItem(
      id: row.id,
      stageRecordId: row.stageRecordId,
      itemId: row.itemId,
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

  StageRuleType _stageRuleType(String value) {
    return switch (value) {
      'every_n_days' => StageRuleType.everyNDays,
      'every_n_weeks' => StageRuleType.everyNWeeks,
      'every_n_months' => StageRuleType.everyNMonths,
      'every_n_years' => StageRuleType.everyNYears,
      _ => StageRuleType.everyNDays,
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
    (t) => OrderingTerm.asc(t.orderIndex),
    (t) => OrderingTerm.asc(t.createdAt),
    (t) => OrderingTerm.asc(t.id),
  ];
}
