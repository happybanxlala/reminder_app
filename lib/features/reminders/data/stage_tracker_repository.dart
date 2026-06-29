import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import '../domain/stage_occurrence.dart';
import '../domain/stage_occurrence_service.dart';
import '../domain/stage_record.dart';
import '../domain/stage_rule.dart';
import '../domain/stage_tracker.dart';
import 'item_repository.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_repository.dart';
import 'stage_tracker_models.dart';

class StageTrackerRepository {
  StageTrackerRepository(
    this._dao, {
    ItemRepository? itemRepository,
    StageOccurrenceService? occurrenceService,
    DateTime Function()? clock,
    Future<String> Function()? currentActorId,
  }) : _itemRepository =
           itemRepository ??
           ItemRepository(_dao, currentActorId: currentActorId),
       _occurrenceService = occurrenceService ?? const StageOccurrenceService(),
       _clock = clock ?? DateTime.now,
       _currentActorId = currentActorId;

  final ReminderDao _dao;
  final ItemRepository _itemRepository;
  final StageOccurrenceService _occurrenceService;
  final DateTime Function() _clock;
  final Future<String> Function()? _currentActorId;

  static const systemDefaultKey = AppDatabase.systemDefaultStageTrackerKey;
  static const remoteBackedUnsupportedMessage = '共同生活場景暫時未支援這個階段操作';
  static const _pendingRemoteStageIdPrefix = 'pending_stage:';

  Stream<List<StageTracker>> watchStageTrackers() {
    return _dao.watchStageTrackers();
  }

  Stream<List<StageRule>> watchStageRules() {
    return _dao.watchStageRules();
  }

  Stream<List<StageRecord>> watchStageRecords() {
    return _dao.watchStageRecords();
  }

  Future<List<StageAcknowledgement>> listStageAcknowledgementsForRecord(
    int stageRecordId,
  ) {
    return _dao.listStageAcknowledgementsForRecord(stageRecordId);
  }

  Future<List<StageAcknowledgement>> listStageAcknowledgementsForPack(
    int packId,
  ) {
    return _dao.listStageAcknowledgementsForPack(packId);
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
      final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
        packId,
      );
      if (packMetadata != null &&
          packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
        if (_isRemoteAccessLost(packMetadata)) {
          throw StateError(remoteBackedUnsupportedMessage);
        }
        return _createRemoteBackedStageTrackerLocally(input, packMetadata, now);
      }
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return 0;
      }
      final now = _clock();
      return _dao.attachedDatabase.transaction(() async {
        final id = await _insertRule(stageTrackerId, input, now);
        await _markRemoteBackedStagePendingPush(
          localEntityType: RemoteSharedPackRepository.localEntityStageRule,
          localEntityId: id,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          remoteEntityId: _pendingRemoteStageId('rule', id, now),
          remoteStatus: input.status.name,
          now: now,
        );
        await _enqueueRemoteBackedStageMutation(
          actionType: SyncOutboxActionType.createStageRule,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          localEntityType: RemoteSharedPackRepository.localEntityStageRule,
          localEntityId: id,
          remoteEntityId: null,
          clientMutationId: _remoteBackedClientMutationId(
            'create_stage_rule',
            id,
            now,
          ),
          actor: await _resolveActorUser(),
          actionAt: now,
          fields: _stageRuleFields(input),
          parent: {
            'localStageTrackerId': tracker.id,
            'remoteStageTrackerId': await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageTracker,
              tracker.id,
            ),
          },
        );
        await _markRemoteBackedPackStale(packMetadata.id, now);
        return id;
      });
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return 0;
      }
      final now = _clock();
      return _dao.attachedDatabase.transaction(() async {
        final id = await _dao.insertStageRecord(
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
        await _markRemoteBackedStagePendingPush(
          localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
          localEntityId: id,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          remoteEntityId: _pendingRemoteStageId('record', id, now),
          remoteStatus: StageRecordStatus.normal.name,
          now: now,
        );
        await _enqueueRemoteBackedStageMutation(
          actionType: SyncOutboxActionType.createStageRecord,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
          localEntityId: id,
          remoteEntityId: null,
          clientMutationId: _remoteBackedClientMutationId(
            'create_stage_record',
            id,
            now,
          ),
          actor: await _resolveActorUser(),
          actionAt: now,
          fields: _manualStageFields(input),
          parent: {
            'localStageTrackerId': tracker.id,
            'remoteStageTrackerId': await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageTracker,
              tracker.id,
            ),
          },
        );
        await _markRemoteBackedPackStale(packMetadata.id, now);
        return id;
      });
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

  Future<bool> updateStageTracker(
    int id,
    StageTrackerInput input, {
    bool moveRelatedItemsOnPackChange = true,
    bool moveRelatedResourcesOnPackChange = true,
  }) async {
    final tracker = await getStageTrackerById(id);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    final now = _clock();
    final packId = input.packId == null
        ? tracker.packId
        : await _resolvePackId(input.packId, now);
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata) || packId != tracker.packId) {
        return false;
      }
      return _dao.attachedDatabase.transaction(() async {
        final updated = await _dao.updateStageTrackerRecord(
          StageTrackerRow(
            id: tracker.id,
            packId: tracker.packId,
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
        if (!updated) {
          return false;
        }
        await _markRemoteBackedStagePendingPush(
          localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
          localEntityId: tracker.id,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          remoteEntityId:
              await _remoteStageEntityId(
                RemoteSharedPackRepository.localEntityStageTracker,
                tracker.id,
              ) ??
              _pendingRemoteStageId('tracker', tracker.id, now),
          remoteStatus: tracker.status.name,
          now: now,
        );
        await _enqueueRemoteBackedStageMutation(
          actionType: SyncOutboxActionType.updateStageTracker,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
          localEntityId: tracker.id,
          remoteEntityId: await _remoteStageEntityId(
            RemoteSharedPackRepository.localEntityStageTracker,
            tracker.id,
          ),
          clientMutationId: _remoteBackedClientMutationId(
            'update_stage_tracker',
            tracker.id,
            now,
          ),
          actor: await _resolveActorUser(),
          actionAt: now,
          fields: _stageTrackerFields(input),
        );
        await _markRemoteBackedPackStale(packMetadata.id, now);
        return true;
      });
    }
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateStageTrackerRecord(
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
      if (!updated) {
        return false;
      }
      if (packId != tracker.packId) {
        await _cleanupStageTrackerMoveRelations(
          id,
          targetPackId: packId,
          moveRelatedItems: moveRelatedItemsOnPackChange,
          moveRelatedResources: moveRelatedResourcesOnPackChange,
        );
      }
      return true;
    });
  }

  Future<bool> moveStageTrackerToPack(
    int id, {
    required int targetPackId,
    required bool moveRelatedItems,
    required bool moveRelatedResources,
  }) async {
    final tracker = await getStageTrackerById(id);
    if (tracker == null ||
        tracker.status == StageTrackerStatus.archived ||
        tracker.isSystemDefault) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(tracker.packId) ||
        await _dao.isRemoteBackedPack(targetPackId)) {
      return false;
    }
    final now = _clock();
    final packId = await _resolvePackId(targetPackId, now);
    if (packId == tracker.packId) {
      return true;
    }
    return _dao.attachedDatabase.transaction(() async {
      final movedTracker = await _dao.moveStageTrackerToPackById(id, packId);
      if (!movedTracker) {
        return false;
      }
      await _cleanupStageTrackerMoveRelations(
        id,
        targetPackId: packId,
        moveRelatedItems: moveRelatedItems,
        moveRelatedResources: moveRelatedResources,
      );
      return true;
    });
  }

  Future<({int itemCount, int resourceCount})> moveImpactForStageTracker(
    int id,
  ) async {
    final relatedItemIds = await _dao.listRelatedItemIdsForStageTracker(id);
    final relatedResourceIds = <int>{};
    for (final itemId in relatedItemIds) {
      final rules = await _dao.listConsumptionRulesForItem(
        itemId,
        enabledOnly: true,
      );
      relatedResourceIds.addAll(rules.map((rule) => rule.resourceId));
    }
    return (
      itemCount: relatedItemIds.length,
      resourceCount: relatedResourceIds.length,
    );
  }

  Future<void> _cleanupStageTrackerMoveRelations(
    int id, {
    required int targetPackId,
    required bool moveRelatedItems,
    required bool moveRelatedResources,
  }) async {
    final relatedItemIds = await _dao.listRelatedItemIdsForStageTracker(id);
    final relatedResourceIds = <int>{};
    for (final itemId in relatedItemIds) {
      final rules = await _dao.listConsumptionRulesForItem(
        itemId,
        enabledOnly: true,
      );
      relatedResourceIds.addAll(rules.map((rule) => rule.resourceId));
    }

    if (moveRelatedItems) {
      for (final itemId in relatedItemIds) {
        await _dao.moveItemToPackById(itemId, targetPackId);
      }
    } else {
      await _dao.deleteStageRelatedItemsForStageTracker(id);
    }

    if (moveRelatedResources) {
      for (final resourceId in relatedResourceIds) {
        await _dao.moveResourceToPackById(resourceId, targetPackId);
      }
    }

    if (moveRelatedItems && !moveRelatedResources) {
      for (final itemId in relatedItemIds) {
        await _dao.disableConsumptionRulesForItem(itemId);
      }
    }
    if (!moveRelatedItems && moveRelatedResources) {
      for (final resourceId in relatedResourceIds) {
        await _dao.disableConsumptionRulesForResource(resourceId);
      }
    }
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return false;
      }
      final updated = await _dao.updateStageRuleRecord(
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
      if (!updated) {
        return false;
      }
      await _markRemoteBackedStagePendingPush(
        localEntityType: RemoteSharedPackRepository.localEntityStageRule,
        localEntityId: rule.id,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        remoteEntityId:
            await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageRule,
              rule.id,
            ) ??
            _pendingRemoteStageId('rule', rule.id, now),
        remoteStatus: rule.status.name,
        now: now,
      );
      await _enqueueRemoteBackedStageMutation(
        actionType: SyncOutboxActionType.updateStageRule,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        localEntityType: RemoteSharedPackRepository.localEntityStageRule,
        localEntityId: rule.id,
        remoteEntityId: await _remoteStageEntityId(
          RemoteSharedPackRepository.localEntityStageRule,
          rule.id,
        ),
        clientMutationId: _remoteBackedClientMutationId(
          'update_stage_rule',
          rule.id,
          now,
        ),
        actor: await _resolveActorUser(),
        actionAt: now,
        fields: _stageRuleFields(input),
      );
      await _markRemoteBackedPackStale(packMetadata.id, now);
      return true;
    }
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return false;
      }
      final updated = await _dao.updateStageRuleRecord(
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
      if (!updated) {
        return false;
      }
      await _markRemoteBackedStagePendingPush(
        localEntityType: RemoteSharedPackRepository.localEntityStageRule,
        localEntityId: rule.id,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        remoteEntityId:
            await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageRule,
              rule.id,
            ) ??
            _pendingRemoteStageId('rule', rule.id, now),
        remoteStatus: status.name,
        now: now,
      );
      await _enqueueRemoteBackedStageMutation(
        actionType: SyncOutboxActionType.updateStageRuleStatus,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        localEntityType: RemoteSharedPackRepository.localEntityStageRule,
        localEntityId: rule.id,
        remoteEntityId: await _remoteStageEntityId(
          RemoteSharedPackRepository.localEntityStageRule,
          rule.id,
        ),
        clientMutationId: _remoteBackedClientMutationId(
          'update_stage_rule_status',
          rule.id,
          now,
        ),
        actor: await _resolveActorUser(),
        actionAt: now,
        fields: {'status': status.name},
      );
      await _markRemoteBackedPackStale(packMetadata.id, now);
      return true;
    }
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return false;
      }
      final updated = await _dao.updateStageRecordRecord(
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
      if (!updated) {
        return false;
      }
      await _markRemoteBackedStagePendingPush(
        localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
        localEntityId: record.id,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        remoteEntityId:
            await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageRecord,
              record.id,
            ) ??
            _pendingRemoteStageId('record', record.id, now),
        remoteStatus: record.status.name,
        now: now,
      );
      await _enqueueRemoteBackedStageMutation(
        actionType: SyncOutboxActionType.updateStageRecord,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
        localEntityId: record.id,
        remoteEntityId: await _remoteStageEntityId(
          RemoteSharedPackRepository.localEntityStageRecord,
          record.id,
        ),
        clientMutationId: _remoteBackedClientMutationId(
          'update_stage_record',
          record.id,
          now,
        ),
        actor: await _resolveActorUser(),
        actionAt: now,
        fields: _manualStageFields(input),
      );
      await _markRemoteBackedPackStale(packMetadata.id, now);
      return true;
    }
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

  Future<void> acknowledgeOccurrence(
    StageOccurrence occurrence, {
    String? actorUserId,
  }) async {
    final actor = await _resolveActorId(actorUserId);
    final tracker = await getStageTrackerById(occurrence.stageTrackerId);
    if (tracker == null || !await _canActOnPack(tracker.packId, actor)) {
      return;
    }
    final existingPackMetadata = await _dao
        .getRemotePackSyncMetadataForLocalPack(tracker.packId);
    if (existingPackMetadata != null &&
        existingPackMetadata.syncKind == RemotePackSyncKind.remoteBacked &&
        _isRemoteAccessLost(existingPackMetadata)) {
      return;
    }
    final now = _clock();
    await _dao.attachedDatabase.transaction(() async {
      final record = await _upsertGeneratedOccurrenceRecord(
        occurrence,
        StageRecordStatus.acknowledged,
      );
      if (record == null) {
        return;
      }
      final acknowledgedAt = _normalizeDate(now);
      await _dao.upsertStageAcknowledgement(
        StageAcknowledgementsCompanion.insert(
          stageRecordId: record.id,
          packId: tracker.packId,
          userId: actor,
          acknowledgedAt: acknowledgedAt.millisecondsSinceEpoch,
        ),
      );
      await _dao.insertActivityEvent(
        ActivityEventsCompanion.insert(
          packId: tracker.packId,
          actorUserId: actor,
          entityType: 'stage',
          entityId: record.id,
          action: 'stage_acknowledged',
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
        tracker.packId,
      );
      if (packMetadata != null &&
          packMetadata.syncKind == RemotePackSyncKind.remoteBacked &&
          !_isRemoteAccessLost(packMetadata)) {
        final remoteRecordId = await _remoteStageEntityId(
          RemoteSharedPackRepository.localEntityStageRecord,
          record.id,
        );
        await _markRemoteBackedStagePendingPush(
          localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
          localEntityId: record.id,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          remoteEntityId:
              remoteRecordId ?? _pendingRemoteStageId('record', record.id, now),
          remoteStatus: StageRecordStatus.acknowledged.name,
          now: now,
        );
        await _enqueueRemoteBackedStageMutation(
          actionType: remoteRecordId == null
              ? SyncOutboxActionType.createStageRecord
              : SyncOutboxActionType.stageAcknowledge,
          localPackId: tracker.packId,
          remotePackId: packMetadata.remotePackId,
          localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
          localEntityId: record.id,
          remoteEntityId: remoteRecordId,
          clientMutationId: _remoteBackedClientMutationId(
            remoteRecordId == null
                ? 'create_stage_record_ack'
                : 'stage_acknowledge',
            record.id,
            now,
          ),
          actor: await _resolveActorUser(actor),
          actionAt: now,
          fields: remoteRecordId == null
              ? _stageRecordFields(
                  record,
                  status: StageRecordStatus.acknowledged,
                )
              : const {},
          event: {'acknowledgedAt': acknowledgedAt.toIso8601String()},
          parent: {
            'localStageTrackerId': tracker.id,
            'remoteStageTrackerId': await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageTracker,
              tracker.id,
            ),
            'localStageRuleId': record.stageRuleId,
            if (record.stageRuleId != null)
              'remoteStageRuleId': await _remoteStageEntityId(
                RemoteSharedPackRepository.localEntityStageRule,
                record.stageRuleId!,
              ),
          },
        );
        await _markRemoteBackedPackStale(packMetadata.id, now);
      }
    });
  }

  Future<void> ignoreOccurrence(StageOccurrence occurrence) async {
    final tracker = await getStageTrackerById(occurrence.stageTrackerId);
    if (tracker == null || await _dao.isRemoteBackedPack(tracker.packId)) {
      return;
    }
    await _upsertGeneratedOccurrenceRecord(
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return false;
      }
      final updated = await _dao.updateStageTrackerRecord(
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
      if (!updated) {
        return false;
      }
      await _markRemoteBackedStagePendingPush(
        localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
        localEntityId: tracker.id,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        remoteEntityId:
            await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageTracker,
              tracker.id,
            ) ??
            _pendingRemoteStageId('tracker', tracker.id, now),
        remoteStatus: StageTrackerStatus.archived.name,
        now: now,
      );
      await _enqueueRemoteBackedStageMutation(
        actionType: SyncOutboxActionType.archiveStageTracker,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
        localEntityId: tracker.id,
        remoteEntityId: await _remoteStageEntityId(
          RemoteSharedPackRepository.localEntityStageTracker,
          tracker.id,
        ),
        clientMutationId: _remoteBackedClientMutationId(
          'archive_stage_tracker',
          tracker.id,
          now,
        ),
        actor: await _resolveActorUser(),
        actionAt: now,
      );
      await _markRemoteBackedPackStale(packMetadata.id, now);
      return true;
    }
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
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      tracker.packId,
    );
    if (packMetadata != null &&
        packMetadata.syncKind == RemotePackSyncKind.remoteBacked) {
      if (_isRemoteAccessLost(packMetadata)) {
        return false;
      }
      final updated = await _updateRecordStatus(
        record,
        StageRecordStatus.archived,
      );
      if (!updated) {
        return false;
      }
      final now = _clock();
      await _markRemoteBackedStagePendingPush(
        localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
        localEntityId: record.id,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        remoteEntityId:
            await _remoteStageEntityId(
              RemoteSharedPackRepository.localEntityStageRecord,
              record.id,
            ) ??
            _pendingRemoteStageId('record', record.id, now),
        remoteStatus: StageRecordStatus.archived.name,
        now: now,
      );
      await _enqueueRemoteBackedStageMutation(
        actionType: SyncOutboxActionType.archiveStageRecord,
        localPackId: tracker.packId,
        remotePackId: packMetadata.remotePackId,
        localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
        localEntityId: record.id,
        remoteEntityId: await _remoteStageEntityId(
          RemoteSharedPackRepository.localEntityStageRecord,
          record.id,
        ),
        clientMutationId: _remoteBackedClientMutationId(
          'archive_stage_record',
          record.id,
          now,
        ),
        actor: await _resolveActorUser(),
        actionAt: now,
      );
      await _markRemoteBackedPackStale(packMetadata.id, now);
      return true;
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
    final tracker = await getStageTrackerById(occurrence.stageTrackerId);
    if (tracker != null && await _dao.isRemoteBackedPack(tracker.packId)) {
      throw StateError(remoteBackedUnsupportedMessage);
    }
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

  Future<int> _createRemoteBackedStageTrackerLocally(
    StageTrackerInput input,
    RemotePackSyncMetadataEntry packMetadata,
    DateTime now,
  ) async {
    final trackerId = await _dao.insertStageTracker(
      StageTrackersCompanion.insert(
        packId: packMetadata.localPackId,
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
    final ruleIds = <int>[];
    for (final rule in input.stageRules) {
      final ruleId = await _insertRule(trackerId, rule, now);
      ruleIds.add(ruleId);
      await _markRemoteBackedStagePendingPush(
        localEntityType: RemoteSharedPackRepository.localEntityStageRule,
        localEntityId: ruleId,
        localPackId: packMetadata.localPackId,
        remotePackId: packMetadata.remotePackId,
        remoteEntityId: _pendingRemoteStageId('rule', ruleId, now),
        remoteStatus: rule.status.name,
        now: now,
      );
    }
    await _markRemoteBackedStagePendingPush(
      localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
      localEntityId: trackerId,
      localPackId: packMetadata.localPackId,
      remotePackId: packMetadata.remotePackId,
      remoteEntityId: _pendingRemoteStageId('tracker', trackerId, now),
      remoteStatus: StageTrackerStatus.active.name,
      now: now,
    );
    await _enqueueRemoteBackedStageMutation(
      actionType: SyncOutboxActionType.createStageTracker,
      localPackId: packMetadata.localPackId,
      remotePackId: packMetadata.remotePackId,
      localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
      localEntityId: trackerId,
      remoteEntityId: null,
      clientMutationId: _remoteBackedClientMutationId(
        'create_stage_tracker',
        trackerId,
        now,
      ),
      actor: await _resolveActorUser(),
      actionAt: now,
      fields: _stageTrackerFields(input),
      children: {
        'rules': [
          for (var index = 0; index < input.stageRules.length; index++)
            {
              'localStageRuleId': ruleIds[index],
              ..._stageRuleFields(input.stageRules[index]),
            },
        ],
      },
    );
    await _markRemoteBackedPackStale(packMetadata.id, now);
    return trackerId;
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

  Future<void> _enqueueRemoteBackedStageMutation({
    required SyncOutboxActionType actionType,
    required int localPackId,
    required String remotePackId,
    required String localEntityType,
    required int localEntityId,
    required String? remoteEntityId,
    required String clientMutationId,
    required LocalUser actor,
    required DateTime actionAt,
    Map<String, Object?> fields = const {},
    Map<String, Object?> event = const {},
    Map<String, Object?> parent = const {},
    Map<String, Object?> children = const {},
  }) {
    final now = _clock();
    return _dao
        .insertSyncOutbox(
          SyncOutboxCompanion.insert(
            localPackId: localPackId,
            remotePackId: Value(remotePackId),
            localEntityType: localEntityType,
            localEntityId: Value(localEntityId),
            remoteEntityId: Value(remoteEntityId),
            actionType: actionType.storageValue,
            payloadJson: jsonEncode({
              'remotePackId': remotePackId,
              'remoteEntityId': remoteEntityId,
              'localPackId': localPackId,
              'localEntityType': localEntityType,
              'localEntityId': localEntityId,
              'clientMutationId': clientMutationId,
              'actorLocalUserId': actor.id,
              'actorRemoteUserId': actor.remoteUserId,
              'actionAt': actionAt.toIso8601String(),
              if (fields.isNotEmpty) 'fields': fields,
              if (event.isNotEmpty) 'event': event,
              if (parent.isNotEmpty) 'parent': parent,
              if (children.isNotEmpty) 'children': children,
            }),
            clientMutationId: clientMutationId,
            actorLocalUserId: actor.id,
            actorRemoteUserId: Value(actor.remoteUserId),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            status: SyncOutboxStatus.pending.storageValue,
          ),
        )
        .then((_) {});
  }

  Future<void> _markRemoteBackedStagePendingPush({
    required String localEntityType,
    required int localEntityId,
    required int localPackId,
    required String remotePackId,
    required String remoteEntityId,
    required String remoteStatus,
    required DateTime now,
  }) async {
    final existing = await _dao.getRemoteStageSyncMetadataForLocalEntity(
      localEntityType: localEntityType,
      localEntityId: localEntityId,
    );
    if (existing == null) {
      await _dao.insertRemoteStageSyncMetadata(
        RemoteStageSyncMetadataCompanion.insert(
          localEntityType: localEntityType,
          localEntityId: localEntityId,
          localPackId: localPackId,
          remoteEntityId: remoteEntityId,
          remotePackId: remotePackId,
          syncState: RemoteStageSyncState.pendingPush.storageValue,
          remoteStatus: Value(remoteStatus),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return;
    }
    await _dao.updateRemoteStageSyncMetadata(
      existing.id,
      RemoteStageSyncMetadataCompanion(
        remoteEntityId: Value(
          existing.remoteEntityId.startsWith(_pendingRemoteStageIdPrefix)
              ? remoteEntityId
              : existing.remoteEntityId,
        ),
        syncState: Value(RemoteStageSyncState.pendingPush.storageValue),
        remoteStatus: Value(remoteStatus),
        updatedAt: Value(now.millisecondsSinceEpoch),
        lastSyncError: const Value(null),
      ),
    );
  }

  Future<void> _markRemoteBackedPackStale(int metadataId, DateTime now) async {
    await _dao.updateRemotePackSyncMetadata(
      metadataId,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.stale.storageValue),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<String?> _remoteStageEntityId(
    String localEntityType,
    int localEntityId,
  ) async {
    final metadata = await _dao.getRemoteStageSyncMetadataForLocalEntity(
      localEntityType: localEntityType,
      localEntityId: localEntityId,
    );
    if (metadata != null &&
        !metadata.remoteEntityId.startsWith(_pendingRemoteStageIdPrefix)) {
      return metadata.remoteEntityId;
    }
    final table = switch (localEntityType) {
      RemoteSharedPackRepository.localEntityStageTracker =>
        RemoteSharedPackRepository.remoteTableStageTrackers,
      RemoteSharedPackRepository.localEntityStageRule =>
        RemoteSharedPackRepository.remoteTableStageRules,
      RemoteSharedPackRepository.localEntityStageRecord =>
        RemoteSharedPackRepository.remoteTableStageRecords,
      _ => '',
    };
    if (table.isEmpty) {
      return null;
    }
    final mapping = await _dao.getSyncMapping(
      localEntityType: localEntityType,
      localEntityId: localEntityId,
      remoteTable: table,
    );
    return mapping?.remoteEntityId;
  }

  Future<LocalUser> _resolveActorUser([String? actorUserId]) async {
    final userId = await _resolveActorId(actorUserId);
    final user = await _dao.getLocalUserById(userId);
    if (user != null) {
      return user;
    }
    final fallback = await _dao.getLocalUserById(AppDatabase.defaultHostUserId);
    if (fallback != null) {
      return fallback;
    }
    final fallbackNow = DateTime.fromMillisecondsSinceEpoch(0);
    return LocalUser(
      id: userId,
      displayName: '你',
      remoteUserId: null,
      remoteProvider: null,
      identityKind: LocalUserIdentityKind.local,
      linkedAt: null,
      createdAt: fallbackNow,
      updatedAt: fallbackNow,
    );
  }

  bool _isRemoteAccessLost(RemotePackSyncMetadataEntry metadata) {
    return metadata.syncState == RemotePackSyncState.accessLost ||
        metadata.syncState == RemotePackSyncState.removed ||
        metadata.currentUserRemoteStatus == RemoteUserStatus.removed;
  }

  String _pendingRemoteStageId(String entity, int localId, DateTime now) {
    return '$_pendingRemoteStageIdPrefix${entity}_${localId}_${now.microsecondsSinceEpoch}';
  }

  String _remoteBackedClientMutationId(
    String action,
    int localId,
    DateTime now,
  ) {
    return 'phase6e_${action}_${localId}_${now.microsecondsSinceEpoch}';
  }

  Map<String, Object?> _stageTrackerFields(StageTrackerInput input) {
    return {
      'title': input.title,
      'subjectName': _nullableTrim(input.subjectName),
      'trackingStartDate': _normalizeDate(
        input.trackingStartDate,
      ).toIso8601String(),
      'trackingEndDate': input.trackingEndDate == null
          ? null
          : _normalizeDate(input.trackingEndDate!).toIso8601String(),
    };
  }

  Map<String, Object?> _stageRuleFields(StageRuleInput input) {
    return {
      'type': _encodeRuleType(input.type),
      'intervalValue': input.intervalValue,
      'intervalUnit': input.intervalUnit.name,
      'labelTemplate': _nullableTrim(input.labelTemplate),
      'reminderOffsetDays': input.reminderOffsetDays,
      'status': input.status.name,
    };
  }

  Map<String, Object?> _manualStageFields(ManualStageInput input) {
    return {
      'sourceType': StageRecordSourceType.manual.name,
      'occurrenceDate': _normalizeDate(input.occurrenceDate).toIso8601String(),
      'relativeAmount': input.relativeAmount,
      'relativeUnit': input.relativeUnit?.name,
      'status': StageRecordStatus.normal.name,
      'label': input.label,
      'note': _nullableTrim(input.note),
      'reminderOffsetDays': input.reminderOffsetDays,
    };
  }

  Map<String, Object?> _stageRecordFields(
    StageRecord record, {
    StageRecordStatus? status,
  }) {
    return {
      'sourceType': record.sourceType.name,
      'occurrenceIndex': record.occurrenceIndex,
      'occurrenceDate': _normalizeDate(record.occurrenceDate).toIso8601String(),
      'relativeAmount': record.relativeAmount,
      'relativeUnit': record.relativeUnit?.name,
      'status': (status ?? record.status).name,
      'label': record.label,
      'note': record.note,
      'reminderOffsetDays': record.reminderOffsetDays,
    };
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

  Future<StageRecord?> _upsertGeneratedOccurrenceRecord(
    StageOccurrence occurrence,
    StageRecordStatus status,
  ) async {
    final now = _clock();
    final existing = occurrence.stageRecordId == null
        ? await _generatedRecordForOccurrence(occurrence)
        : await _dao.getStageRecordById(occurrence.stageRecordId!);
    if (existing == null) {
      final id = await _dao.insertStageRecord(
        _recordCompanionForOccurrence(occurrence, status, now),
      );
      return _dao.getStageRecordById(id);
    }
    if (existing.status == StageRecordStatus.ignored ||
        existing.status == StageRecordStatus.archived) {
      return existing;
    }
    await _updateRecordStatus(existing, status);
    return _dao.getStageRecordById(existing.id);
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

  Future<String> _resolveActorId(String? actorUserId) async {
    if (actorUserId != null) {
      return actorUserId;
    }
    final resolver = _currentActorId;
    if (resolver == null) {
      return AppDatabase.defaultHostUserId;
    }
    return resolver();
  }

  Future<bool> _canActOnPack(int packId, String actorUserId) async {
    final pack = await _dao.getItemPackById(packId);
    if (pack == null || pack.packType != ItemPackType.shared) {
      return true;
    }
    return _dao.isActivePackMember(packId: packId, userId: actorUserId);
  }
}
