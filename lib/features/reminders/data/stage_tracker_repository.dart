import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/stage_occurrence.dart';
import '../domain/stage_occurrence_service.dart';
import '../domain/stage_record.dart';
import '../domain/stage_rule.dart';
import '../domain/stage_tracker.dart';
import 'item_repository.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'stage_tracker_models.dart';

class StageTrackerRepository {
  StageTrackerRepository(
    this._dao, {
    ItemRepository? itemRepository,
    StageOccurrenceService? occurrenceService,
    DateTime Function()? clock,
  }) : _itemRepository = itemRepository ?? ItemRepository(_dao),
       _occurrenceService = occurrenceService ?? const StageOccurrenceService(),
       _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final ItemRepository _itemRepository;
  final StageOccurrenceService _occurrenceService;
  final DateTime Function() _clock;

  static const systemDefaultKey = AppDatabase.systemDefaultStageTrackerKey;

  Stream<List<StageTracker>> watchStageTrackers() {
    return _dao.watchStageTrackers();
  }

  Stream<List<StageRule>> watchStageRules() {
    return _dao.watchStageRules();
  }

  Stream<List<StageRecord>> watchStageRecords() {
    return _dao.watchStageRecords();
  }

  Stream<List<StageActionEntry>> watchAcknowledgedActionEntriesForDate(
    DateTime date,
  ) {
    final start = _normalizeDate(date);
    return _dao.watchAcknowledgedStageActionEntriesForDateRange(
      updatedAtFrom: start,
      updatedAtBefore: start.add(const Duration(days: 1)),
    );
  }

  Future<StageTracker?> getStageTrackerById(int id) {
    return _dao.getStageTrackerById(id);
  }

  Future<StageTracker> ensureSystemStageTracker({bool? isHidden}) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final existing = await _dao.getSystemStageTrackerByKey(systemDefaultKey);
      final defaultPackId = await _ensureDefaultPackId(now);
      if (existing != null) {
        final shouldHide = isHidden ?? existing.isHidden;
        await _dao.updateStageTrackerRecord(
          StageTrackerRow(
            id: existing.id,
            packId: defaultPackId,
            title: AppDatabase.systemDefaultStageTrackerTitle,
            subjectName: AppDatabase.systemDefaultStageTrackerSubject,
            trackingStartDate:
                existing.trackingStartDate.millisecondsSinceEpoch,
            trackingEndDate: existing.trackingEndDate?.millisecondsSinceEpoch,
            status: StageTrackerStatus.active.name,
            isSystemDefault: true,
            systemKey: systemDefaultKey,
            isHidden: shouldHide,
            createdAt: existing.createdAt.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
        return (await _dao.getSystemStageTrackerByKey(systemDefaultKey))!;
      }

      final id = await _dao.insertStageTracker(
        StageTrackersCompanion.insert(
          packId: defaultPackId,
          title: AppDatabase.systemDefaultStageTrackerTitle,
          subjectName: const Value(
            AppDatabase.systemDefaultStageTrackerSubject,
          ),
          trackingStartDate: _normalizeDate(now).millisecondsSinceEpoch,
          status: Value(StageTrackerStatus.active.name),
          isSystemDefault: const Value(true),
          systemKey: const Value(systemDefaultKey),
          isHidden: Value(isHidden ?? false),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return (await _dao.getStageTrackerById(id))!;
    });
  }

  Future<StageTrackerDetail?> getStageTrackerDetailById(
    int id, {
    DateTime? now,
  }) async {
    final record = await _dao.getStageTrackerDetailRecordById(id);
    if (record == null) {
      return null;
    }
    final current = _normalizeDate(now ?? _clock());
    final scheduleEnd =
        record.stageTracker.trackingEndDate ??
        current.add(const Duration(days: 366));
    final historyStart = current.subtract(const Duration(days: 3650));
    final dashboardStages = _occurrenceService
        .getDashboardUpcomingOccurrences(
          record.stageTracker,
          record.stageRules,
          record.stageRecords,
          now: current,
        )
        .take(3)
        .toList(growable: false);
    return StageTrackerDetail(
      stageTracker: record.stageTracker,
      stageRules: record.stageRules,
      stageRecords: record.stageRecords,
      dashboardUpcomingStages: await _attachRelatedSummaries(dashboardStages),
      scheduleStages: await _attachRelatedSummaries(
        _occurrenceService.getScheduleOccurrences(
          record.stageTracker,
          record.stageRules,
          record.stageRecords,
          StageOccurrenceRange(
            start: current,
            end: scheduleEnd.add(const Duration(days: 1)),
          ),
          now: current,
        ),
      ),
      historyStages: await _attachRelatedSummaries(
        _occurrenceService.getHistoryOccurrences(
          record.stageTracker,
          record.stageRules,
          record.stageRecords,
          StageOccurrenceRange(start: historyStart, end: current),
          now: current,
        ),
      ),
    );
  }

  Future<int> createStageTracker(StageTrackerInput input) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final packId = await _resolvePackId(input.packId, now);
      final trackerId = await _dao.insertStageTracker(
        StageTrackersCompanion.insert(
          packId: packId,
          title: input.title,
          subjectName: Value(_nullableTrim(input.subjectName)),
          trackingStartDate: _normalizeDate(
            input.trackingStartDate,
          ).millisecondsSinceEpoch,
          trackingEndDate: Value(
            input.trackingEndDate == null
                ? null
                : _normalizeDate(input.trackingEndDate!).millisecondsSinceEpoch,
          ),
          status: Value(StageTrackerStatus.active.name),
          isSystemDefault: const Value(false),
          systemKey: const Value(null),
          isHidden: const Value(false),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      for (final rule in input.stageRules) {
        await _insertRule(trackerId, rule, now);
      }
      return trackerId;
    });
  }

  Future<int> createStageRule(int stageTrackerId, StageRuleInput input) async {
    final tracker = await getStageTrackerById(stageTrackerId);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return 0;
    }
    return _insertRule(stageTrackerId, input, _clock());
  }

  Future<int> createImportantStage(
    int stageTrackerId,
    ManualStageInput input,
  ) async {
    final tracker = await getStageTrackerById(stageTrackerId);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return 0;
    }
    final now = _clock();
    return _dao.insertStageRecord(
      StageRecordsCompanion.insert(
        stageTrackerId: stageTrackerId,
        stageRuleId: const Value(null),
        sourceType: StageRecordSourceType.manual.name,
        occurrenceIndex: const Value(null),
        occurrenceDate: _normalizeDate(
          input.occurrenceDate,
        ).millisecondsSinceEpoch,
        relativeAmount: Value(input.relativeAmount),
        relativeUnit: Value(input.relativeUnit?.name),
        status: Value(StageRecordStatus.normal.name),
        label: input.label,
        note: Value(_nullableTrim(input.note)),
        reminderOffsetDays: Value(input.reminderOffsetDays),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateStageTracker(int id, StageTrackerInput input) async {
    final tracker = await getStageTrackerById(id);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    final now = _clock();
    final packId = await _resolvePackId(input.packId, now);
    return _dao.updateStageTrackerRecord(
      StageTrackerRow(
        id: tracker.id,
        packId: packId,
        title: input.title,
        subjectName: _nullableTrim(input.subjectName),
        trackingStartDate: _normalizeDate(
          input.trackingStartDate,
        ).millisecondsSinceEpoch,
        trackingEndDate: input.trackingEndDate == null
            ? null
            : _normalizeDate(input.trackingEndDate!).millisecondsSinceEpoch,
        status: tracker.status.name,
        isSystemDefault: tracker.isSystemDefault,
        systemKey: tracker.systemKey,
        isHidden: tracker.isHidden,
        createdAt: tracker.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateStageRule(int id, StageRuleInput input) async {
    final rule = await _dao.getStageRuleById(id);
    if (rule == null) {
      return false;
    }
    final tracker = await getStageTrackerById(rule.stageTrackerId);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    if (input.intervalValue <= 0) {
      throw ArgumentError.value(input.intervalValue, 'intervalValue');
    }
    final now = _clock();
    return _dao.updateStageRuleRecord(
      StageRuleRow(
        id: rule.id,
        stageTrackerId: rule.stageTrackerId,
        type: _encodeRuleType(input.type),
        intervalValue: input.intervalValue,
        intervalUnit: input.intervalUnit.name,
        labelTemplate: _nullableTrim(input.labelTemplate),
        reminderOffsetDays: input.reminderOffsetDays,
        status: rule.status.name,
        createdAt: rule.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateStageRuleStatus(int id, StageRuleStatus status) async {
    final rule = await _dao.getStageRuleById(id);
    if (rule == null) {
      return false;
    }
    final tracker = await getStageTrackerById(rule.stageTrackerId);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    final now = _clock();
    return _dao.updateStageRuleRecord(
      StageRuleRow(
        id: rule.id,
        stageTrackerId: rule.stageTrackerId,
        type: _encodeRuleType(rule.type),
        intervalValue: rule.intervalValue,
        intervalUnit: rule.intervalUnit.name,
        labelTemplate: rule.labelTemplate,
        reminderOffsetDays: rule.reminderOffsetDays,
        status: status.name,
        createdAt: rule.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateImportantStage(
    int stageRecordId,
    ManualStageInput input,
  ) async {
    final record = await _dao.getStageRecordById(stageRecordId);
    if (record == null ||
        record.sourceType != StageRecordSourceType.manual ||
        record.status == StageRecordStatus.archived) {
      return false;
    }
    final tracker = await getStageTrackerById(record.stageTrackerId);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    final now = _clock();
    return _dao.updateStageRecordRecord(
      StageRecordRow(
        id: record.id,
        stageTrackerId: record.stageTrackerId,
        stageRuleId: record.stageRuleId,
        sourceType: record.sourceType.name,
        occurrenceIndex: record.occurrenceIndex,
        occurrenceDate: _normalizeDate(
          input.occurrenceDate,
        ).millisecondsSinceEpoch,
        relativeAmount: record.relativeAmount,
        relativeUnit: record.relativeUnit?.name,
        status: record.status.name,
        label: input.label,
        note: _nullableTrim(input.note),
        reminderOffsetDays: input.reminderOffsetDays,
        createdAt: record.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> acknowledgeOccurrence(StageOccurrence occurrence) {
    return _upsertGeneratedOccurrenceRecord(
      occurrence,
      StageRecordStatus.acknowledged,
    );
  }

  Future<void> ignoreOccurrence(StageOccurrence occurrence) {
    return _upsertGeneratedOccurrenceRecord(
      occurrence,
      StageRecordStatus.ignored,
    );
  }

  Future<bool> archiveStageTracker(int id) async {
    final tracker = await getStageTrackerById(id);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    final now = _clock();
    return _dao.updateStageTrackerRecord(
      StageTrackerRow(
        id: tracker.id,
        packId: tracker.packId,
        title: tracker.title,
        subjectName: tracker.subjectName,
        trackingStartDate: tracker.trackingStartDate.millisecondsSinceEpoch,
        trackingEndDate: tracker.trackingEndDate?.millisecondsSinceEpoch,
        status: StageTrackerStatus.archived.name,
        isSystemDefault: tracker.isSystemDefault,
        systemKey: tracker.systemKey,
        isHidden: tracker.isHidden,
        createdAt: tracker.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> hideSystemStageTracker() async {
    await ensureSystemStageTracker();
    return await _dao.updateSystemStageTrackerVisibility(
          systemKey: systemDefaultKey,
          isHidden: true,
        ) >
        0;
  }

  Future<bool> showSystemStageTracker() async {
    await ensureSystemStageTracker(isHidden: false);
    return await _dao.updateSystemStageTrackerVisibility(
          systemKey: systemDefaultKey,
          isHidden: false,
        ) >
        0;
  }

  Future<bool> deleteOrArchiveImportantStage(int stageRecordId) async {
    final record = await _dao.getStageRecordById(stageRecordId);
    if (record == null ||
        record.sourceType != StageRecordSourceType.manual ||
        record.status == StageRecordStatus.archived) {
      return false;
    }
    final tracker = await getStageTrackerById(record.stageTrackerId);
    if (tracker == null || tracker.isSystemDefault) {
      return false;
    }
    final current = _normalizeDate(_clock());
    if (record.occurrenceDate.isAfter(current)) {
      return (await _dao.deleteStageRecordById(stageRecordId)) > 0;
    }
    return _updateRecordStatus(record, StageRecordStatus.archived);
  }

  Future<int> createRelatedItemFromOccurrence(
    StageOccurrence occurrence, {
    required String title,
    String? description,
    DateTime? dueDate,
    int? packId,
  }) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final record = await _ensureRecordForOccurrence(occurrence, now);
      final itemId = await _itemRepository.createItem(
        ItemInput(
          title: title,
          description: description,
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.oneTime,
            anchorDate: _normalizeDate(dueDate ?? occurrence.occurrenceDate),
            dueDate: _normalizeDate(dueDate ?? occurrence.occurrenceDate),
            overduePolicy: ItemOverduePolicy.waitForAction,
          ),
          attentionPolicySource: AttentionPolicySource.systemDefault,
          packId: packId,
        ),
      );
      await _dao.insertStageRelatedItem(
        StageRelatedItemsCompanion.insert(
          stageRecordId: record.id,
          itemId: itemId,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return itemId;
    });
  }

  Future<StageRelatedItemSource?> getRelatedItemSourceForItem(int itemId) {
    return _dao.getStageRelatedItemSourceForItem(itemId);
  }

  Future<List<StageRelatedItemEntry>> getRelatedItemEntriesForStageRecord(
    int stageRecordId,
  ) {
    return _dao.relatedItemEntriesForRecord(stageRecordId);
  }

  List<StageOccurrence> computeHomeAttentionOccurrences({
    required List<StageTracker> trackers,
    required List<StageRule> rules,
    required List<StageRecord> records,
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? _clock());
    return [
      for (final tracker in trackers.where(
        (item) => item.status == StageTrackerStatus.active && !item.isHidden,
      ))
        ..._occurrenceService.getHomeAttentionOccurrences(
          tracker,
          rules
              .where((rule) => rule.stageTrackerId == tracker.id)
              .toList(growable: false),
          records
              .where((record) => record.stageTrackerId == tracker.id)
              .toList(growable: false),
          StageOccurrenceRange(
            start: current,
            end: current.add(const Duration(days: 366)),
          ),
          now: current,
        ),
    ]..sort(_occurrenceService.compareFuture);
  }

  Future<int> _insertRule(
    int stageTrackerId,
    StageRuleInput input,
    DateTime now,
  ) {
    if (input.intervalValue <= 0) {
      throw ArgumentError.value(input.intervalValue, 'intervalValue');
    }
    return _dao.insertStageRule(
      StageRulesCompanion.insert(
        stageTrackerId: stageTrackerId,
        type: _encodeRuleType(input.type),
        intervalValue: input.intervalValue,
        intervalUnit: input.intervalUnit.name,
        labelTemplate: Value(_nullableTrim(input.labelTemplate)),
        reminderOffsetDays: Value(input.reminderOffsetDays),
        status: Value(input.status.name),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<int> _resolvePackId(int? packId, DateTime now) async {
    final resolvedPackId = packId ?? await _ensureDefaultPackId(now);
    final pack = await _dao.getItemPackById(resolvedPackId);
    if (pack == null) {
      throw StateError('Item pack not found.');
    }
    if (pack.status != ItemPackStatus.active) {
      throw StateError('Archived item pack cannot accept stage trackers.');
    }
    return resolvedPackId;
  }

  Future<int> _ensureDefaultPackId(DateTime now) async {
    final defaultPack = await _dao.getSystemDefaultPack();
    if (defaultPack != null) {
      if (defaultPack.title != AppDatabase.systemDefaultPackTitle ||
          defaultPack.iconEmoji != AppDatabase.systemDefaultPackIconEmoji ||
          defaultPack.status != ItemPackStatus.active ||
          defaultPack.orderIndex != AppDatabase.systemDefaultPackOrderIndex) {
        await _dao.updateItemPackFields(
          defaultPack.id,
          ItemPacksCompanion(
            title: const Value(AppDatabase.systemDefaultPackTitle),
            iconEmoji: const Value(AppDatabase.systemDefaultPackIconEmoji),
            orderIndex: const Value(AppDatabase.systemDefaultPackOrderIndex),
            status: const Value('active'),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
      return defaultPack.id;
    }
    return _dao.insertItemPack(
      ItemPacksCompanion.insert(
        title: AppDatabase.systemDefaultPackTitle,
        description: const Value(AppDatabase.systemDefaultPackDescription),
        iconEmoji: const Value(AppDatabase.systemDefaultPackIconEmoji),
        orderIndex: const Value(AppDatabase.systemDefaultPackOrderIndex),
        status: const Value('active'),
        isSystemDefault: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _upsertGeneratedOccurrenceRecord(
    StageOccurrence occurrence,
    StageRecordStatus status,
  ) async {
    final now = _clock();
    final existing = occurrence.stageRecordId == null
        ? await _generatedRecordForOccurrence(occurrence)
        : await _dao.getStageRecordById(occurrence.stageRecordId!);
    if (existing == null) {
      await _dao.insertStageRecord(
        _recordCompanionForOccurrence(occurrence, status, now),
      );
      return;
    }
    if (existing.status == StageRecordStatus.ignored ||
        existing.status == StageRecordStatus.archived) {
      return;
    }
    await _updateRecordStatus(existing, status);
  }

  Future<StageRecord> _ensureRecordForOccurrence(
    StageOccurrence occurrence,
    DateTime now,
  ) async {
    if (occurrence.stageRecordId != null) {
      final existing = await _dao.getStageRecordById(occurrence.stageRecordId!);
      if (existing != null) {
        return existing;
      }
    }
    if (occurrence.isGenerated) {
      final existing = await _generatedRecordForOccurrence(occurrence);
      if (existing != null) {
        return existing;
      }
    }
    final id = await _dao.insertStageRecord(
      _recordCompanionForOccurrence(occurrence, StageRecordStatus.normal, now),
    );
    final record = await _dao.getStageRecordById(id);
    if (record == null) {
      throw StateError('Failed to create stage record.');
    }
    return record;
  }

  Future<StageRecord?> _generatedRecordForOccurrence(
    StageOccurrence occurrence,
  ) {
    final ruleId = occurrence.stageRuleId;
    final index = occurrence.occurrenceIndex;
    if (ruleId == null || index == null) {
      return Future.value(null);
    }
    return _dao.getStageRecordByOccurrence(
      stageRuleId: ruleId,
      occurrenceIndex: index,
    );
  }

  StageRecordsCompanion _recordCompanionForOccurrence(
    StageOccurrence occurrence,
    StageRecordStatus status,
    DateTime now,
  ) {
    return StageRecordsCompanion.insert(
      stageTrackerId: occurrence.stageTrackerId,
      stageRuleId: Value(occurrence.stageRuleId),
      sourceType: occurrence.sourceType.name,
      occurrenceIndex: Value(occurrence.occurrenceIndex),
      occurrenceDate: _normalizeDate(
        occurrence.occurrenceDate,
      ).millisecondsSinceEpoch,
      status: Value(status.name),
      label: occurrence.label,
      note: Value(_nullableTrim(occurrence.note)),
      reminderOffsetDays: Value(occurrence.reminderOffsetDays),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  Future<bool> _updateRecordStatus(
    StageRecord record,
    StageRecordStatus status,
  ) {
    final now = _clock();
    return _dao.updateStageRecordRecord(
      StageRecordRow(
        id: record.id,
        stageTrackerId: record.stageTrackerId,
        stageRuleId: record.stageRuleId,
        sourceType: record.sourceType.name,
        occurrenceIndex: record.occurrenceIndex,
        occurrenceDate: record.occurrenceDate.millisecondsSinceEpoch,
        relativeAmount: record.relativeAmount,
        relativeUnit: record.relativeUnit?.name,
        status: status.name,
        label: record.label,
        note: record.note,
        reminderOffsetDays: record.reminderOffsetDays,
        createdAt: record.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<StageOccurrence>> _attachRelatedSummaries(
    List<StageOccurrence> occurrences,
  ) async {
    final result = <StageOccurrence>[];
    for (final occurrence in occurrences) {
      final recordId = occurrence.stageRecordId;
      result.add(
        StageOccurrence(
          stageTrackerId: occurrence.stageTrackerId,
          stageTrackerTitle: occurrence.stageTrackerTitle,
          subjectName: occurrence.subjectName,
          stageRuleId: occurrence.stageRuleId,
          stageRecordId: occurrence.stageRecordId,
          sourceType: occurrence.sourceType,
          occurrenceIndex: occurrence.occurrenceIndex,
          occurrenceDate: occurrence.occurrenceDate,
          label: occurrence.label,
          note: occurrence.note,
          reminderOffsetDays: occurrence.reminderOffsetDays,
          recordStatus: occurrence.recordStatus,
          relatedItemSummary: recordId == null
              ? null
              : await _dao.relatedItemSummaryForRecord(recordId),
        ),
      );
    }
    return result;
  }

  String _encodeRuleType(StageRuleType type) {
    return switch (type) {
      StageRuleType.everyNDays => 'every_n_days',
      StageRuleType.everyNWeeks => 'every_n_weeks',
      StageRuleType.everyNMonths => 'every_n_months',
      StageRuleType.everyNYears => 'every_n_years',
    };
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
