import 'package:drift/drift.dart';

import '../../domain/responsibility_item.dart';
import '../../domain/responsibility_pack.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_record.dart';
import '../../domain/timeline_milestone_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'responsibility_timeline_dao.g.dart';

class ResponsibilityItemBundle {
  const ResponsibilityItemBundle({required this.item, required this.pack});

  final ResponsibilityItem item;
  final ResponsibilityPack pack;
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
    ResponsibilityPacks,
    ResponsibilityItems,
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
  ],
)
class ResponsibilityTimelineDao extends DatabaseAccessor<AppDatabase>
    with _$ResponsibilityTimelineDaoMixin {
  ResponsibilityTimelineDao(super.attachedDatabase);

  Future<int> insertResponsibilityPack(ResponsibilityPacksCompanion entry) {
    return into(responsibilityPacks).insert(entry);
  }

  Future<int> insertResponsibilityItem(ResponsibilityItemsCompanion entry) {
    return into(responsibilityItems).insert(entry);
  }

  Future<bool> updateResponsibilityPackRecord(ResponsibilityPackRow entry) {
    return update(responsibilityPacks).replace(entry);
  }

  Future<bool> updateResponsibilityItemRecord(ResponsibilityItemRow entry) {
    return update(responsibilityItems).replace(entry);
  }

  Stream<List<ResponsibilityPack>> watchResponsibilityPacks() {
    final query = select(responsibilityPacks)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch().map(
      (rows) => rows.map(_toResponsibilityPack).toList(growable: false),
    );
  }

  Future<List<ResponsibilityPack>> listResponsibilityPacks() async {
    final rows = await (select(
      responsibilityPacks,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    return rows.map(_toResponsibilityPack).toList(growable: false);
  }

  Future<ResponsibilityPack?> getResponsibilityPackById(int id) async {
    final row = await (select(
      responsibilityPacks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toResponsibilityPack(row);
  }

  Stream<List<ResponsibilityItemBundle>> watchResponsibilityItemBundles() {
    return _responsibilityItemBundleQuery().watch().map(
      (rows) => rows.map(_mapResponsibilityItemBundle).toList(growable: false),
    );
  }

  Future<List<ResponsibilityItemBundle>> listResponsibilityItemBundles() {
    return _responsibilityItemBundleQuery().get().then(
      (rows) => rows.map(_mapResponsibilityItemBundle).toList(growable: false),
    );
  }

  Future<ResponsibilityItemBundle?> getResponsibilityItemBundleById(
    int id,
  ) async {
    final rows = await _responsibilityItemBundleQuery(
      where: (t) => t.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapResponsibilityItemBundle(rows.single);
  }

  Future<bool> markResponsibilityItemDone(int id, {DateTime? doneAt}) async {
    final now = doneAt ?? DateTime.now();
    final updatedRows =
        await (update(
          responsibilityItems,
        )..where((t) => t.id.equals(id))).write(
          ResponsibilityItemsCompanion(
            lastDoneAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
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

  JoinedSelectStatement<HasResultSet, dynamic> _responsibilityItemBundleQuery({
    Expression<bool> Function($ResponsibilityItemsTable t)? where,
    int? limit,
  }) {
    final query = select(responsibilityItems).join([
      innerJoin(
        responsibilityPacks,
        responsibilityPacks.id.equalsExp(responsibilityItems.packId),
      ),
    ]);
    if (where != null) {
      query.where(where(responsibilityItems));
    }
    query.orderBy([
      OrderingTerm.desc(responsibilityItems.updatedAt),
      OrderingTerm.asc(responsibilityItems.id),
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

  ResponsibilityItemBundle _mapResponsibilityItemBundle(TypedResult row) {
    return ResponsibilityItemBundle(
      item: _toResponsibilityItem(row.readTable(responsibilityItems)),
      pack: _toResponsibilityPack(row.readTable(responsibilityPacks)),
    );
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

  ResponsibilityPack _toResponsibilityPack(ResponsibilityPackRow row) {
    return ResponsibilityPack(
      id: row.id,
      title: row.title,
      description: row.description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ResponsibilityItem _toResponsibilityItem(ResponsibilityItemRow row) {
    final itemType = ResponsibilityItemType.values.byName(row.type);
    return ResponsibilityItem(
      id: row.id,
      packId: row.packId,
      title: row.title,
      description: row.description,
      type: itemType,
      config: _toResponsibilityItemConfig(row, itemType),
      lastDoneAt: row.lastDoneAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastDoneAt!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  ResponsibilityItemConfig _toResponsibilityItemConfig(
    ResponsibilityItemRow row,
    ResponsibilityItemType type,
  ) {
    return switch (type) {
      ResponsibilityItemType.fixedTime => FixedTimeItemConfig(
        scheduleType: FixedTimeScheduleType.values.byName(
          row.fixedScheduleType ?? FixedTimeScheduleType.custom.name,
        ),
        anchorDate: row.fixedAnchorDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.fixedAnchorDate!),
        timeOfDay: row.fixedTimeOfDay,
      ),
      ResponsibilityItemType.stateBased => StateBasedItemConfig(
        expectedInterval: Duration(
          minutes: row.stateExpectedIntervalMinutes ?? 0,
        ),
        warningAfter: Duration(minutes: row.stateWarningAfterMinutes ?? 0),
        dangerAfter: Duration(minutes: row.stateDangerAfterMinutes ?? 0),
      ),
      ResponsibilityItemType.resourceBased => ResourceBasedItemConfig(
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
}
