import 'package:drift/drift.dart';

import '../../domain/item.dart';
import '../../domain/item_pack.dart';
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
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
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

  Future<bool> updateItemPackRecord(ItemPackRow entry) {
    return update(itemPacks).replace(entry);
  }

  Future<bool> updateItemRecord(ItemRow entry) {
    return update(items).replace(entry);
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

  Future<bool> markItemDone(int id, {DateTime? doneAt}) async {
    final completionTime = doneAt == null
        ? DateTime.now()
        : DateTime(doneAt.year, doneAt.month, doneAt.day);
    final updatedAt = DateTime.now();
    final updatedRows = await (update(items)..where((t) => t.id.equals(id)))
        .write(
          ItemsCompanion(
            lastDoneAt: Value(completionTime.millisecondsSinceEpoch),
            updatedAt: Value(updatedAt.millisecondsSinceEpoch),
          ),
        );
    return updatedRows > 0;
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

  ItemBundle _mapItemBundle(TypedResult row) {
    return ItemBundle(
      item: _toItem(row.readTable(items)),
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

  Item _toItem(ItemRow row) {
    final itemType = ItemType.values.byName(row.type);
    return Item(
      id: row.id,
      packId: row.packId,
      title: row.title,
      description: row.description,
      status: ItemLifecycleStatus.values.byName(row.status),
      type: itemType,
      config: _toItemConfig(row, itemType),
      lastDoneAt: row.lastDoneAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastDoneAt!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ItemConfig _toItemConfig(ItemRow row, ItemType type) {
    return switch (type) {
      ItemType.fixedTime => FixedTimeItemConfig(
        scheduleType: FixedTimeScheduleType.values.byName(
          row.fixedScheduleType ?? FixedTimeScheduleType.custom.name,
        ),
        anchorDate: row.fixedAnchorDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.fixedAnchorDate!),
        timeOfDay: row.fixedTimeOfDay,
      ),
      ItemType.stateBased => StateBasedItemConfig(
        expectedInterval: Duration(
          minutes: row.stateExpectedIntervalMinutes ?? 0,
        ),
        warningAfter: Duration(minutes: row.stateWarningAfterMinutes ?? 0),
        dangerAfter: Duration(minutes: row.stateDangerAfterMinutes ?? 0),
      ),
      ItemType.resourceBased => ResourceBasedItemConfig(
        estimatedDuration: Duration(
          minutes: row.resourceEstimatedDurationMinutes ?? 0,
        ),
        warningBeforeDepletion: Duration(
          minutes: row.resourceWarningBeforeDepletionMinutes ?? 0,
        ),
      ),
    };
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

  TimelineMilestoneRuleType _timelineMilestoneRuleType(String value) {
    return switch (value) {
      'every_n_days' => TimelineMilestoneRuleType.everyNDays,
      'every_n_weeks' => TimelineMilestoneRuleType.everyNWeeks,
      'every_n_months' => TimelineMilestoneRuleType.everyNMonths,
      'every_n_years' => TimelineMilestoneRuleType.everyNYears,
      _ => TimelineMilestoneRuleType.everyNDays,
    };
  }

  List<OrderingTerm Function($ItemPacksTable)> get _itemPackOrdering => [
    (t) => OrderingTerm.desc(t.isSystemDefault),
    (t) => OrderingTerm.desc(t.updatedAt),
    (t) => OrderingTerm.asc(t.id),
  ];
}
