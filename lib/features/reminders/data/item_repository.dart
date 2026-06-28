import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/fixed_schedule_validator.dart';
import '../domain/item.dart';
import '../domain/item_action_record.dart';
import '../domain/item_action_service.dart';
import '../domain/item_pack.dart';
import '../domain/item_snapshot_update_service.dart';
import '../domain/item_status_service.dart';
import '../domain/pack_template.dart';
import '../domain/resource.dart';
import '../domain/resource_refill_service.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import '../domain/stage_tracker.dart';
import 'home_models.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_backed_item_action_service.dart';
import 'remote_shared_pack_repository.dart';
import 'resource_repository.dart';

class ItemInput {
  const ItemInput({
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.attentionPolicySource = AttentionPolicySource.systemDefault,
    this.packId,
    this.assignedToUserId,
  });

  final String title;
  final String? description;
  final ItemType type;
  final ItemConfig config;
  final AttentionPolicySource attentionPolicySource;
  final int? packId;
  final String? assignedToUserId;
}

class ItemResourceBindingInput {
  const ItemResourceBindingInput.existing({
    required int resourceId,
    this.consumeAmount = 1,
  }) : existingResourceId = resourceId,
       newResource = null;

  const ItemResourceBindingInput.newResource({
    required ResourceInput resource,
    this.consumeAmount = 1,
  }) : existingResourceId = null,
       newResource = resource;

  final int? existingResourceId;
  final ResourceInput? newResource;
  final int consumeAmount;
}

class ItemResourceImpactEntry {
  const ItemResourceImpactEntry({
    required this.resourceId,
    required this.resourceTitle,
    required this.amount,
    required this.unitLabel,
    required this.isCompensation,
  });

  final int resourceId;
  final String resourceTitle;
  final int amount;
  final String unitLabel;
  final bool isCompensation;

  String get label {
    final prefix = isCompensation ? '已補回' : '扣除';
    return '$prefix：$resourceTitle $amount $unitLabel';
  }
}

class ItemHistoryEntry {
  const ItemHistoryEntry({
    required this.id,
    required this.actionRecordId,
    required this.actionType,
    required this.actionDate,
    required this.titleLabel,
    this.revertedAt,
    this.revertedActionRecordId,
    this.remark,
    this.resourceImpacts = const <ItemResourceImpactEntry>[],
  });

  final String id;
  final int actionRecordId;
  final ItemActionType actionType;
  final DateTime actionDate;
  final String titleLabel;
  final DateTime? revertedAt;
  final int? revertedActionRecordId;
  final String? remark;
  final List<ItemResourceImpactEntry> resourceImpacts;

  bool get isDone => actionType == ItemActionType.done;
  bool get isReverted => revertedAt != null;
  bool get hasResourceImpact => resourceImpacts.isNotEmpty;
}

enum ArchivePackMode { archiveWithContents, moveContentsToDefault }

class ItemRepository {
  ItemRepository(
    this._dao, {
    ItemStatusService? statusService,
    ItemActionService? actionService,
    ItemSnapshotUpdateService? snapshotUpdateService,
    RemoteBackedItemActionService? remoteBackedItemActionService,
    DateTime Function()? clock,
    Future<String> Function()? currentActorId,
  }) : _statusService = statusService ?? const ItemStatusService(),
       _actionService = actionService ?? const ItemActionService(),
       _snapshotUpdateService =
           snapshotUpdateService ??
           ItemSnapshotUpdateService(statusService: statusService),
       _remoteBackedItemActionService = remoteBackedItemActionService,
       _clock = clock ?? DateTime.now,
       _currentActorId = currentActorId;

  static const managedItemStatuses = {
    ItemLifecycleStatus.active,
    ItemLifecycleStatus.paused,
  };
  static const majorActivityActionTypes = {
    ItemActionType.created,
    ItemActionType.done,
    ItemActionType.skipped,
  };
  static const remoteBackedUnsupportedMessage =
      '共同生活場景暫時未支援修改場景資料。你仍可以新增、編輯、封存、完成或復原事項。';
  static const _pendingRemoteItemIdPrefix = 'pending:';

  final ReminderDao _dao;
  final ItemStatusService _statusService;
  final ItemActionService _actionService;
  final ItemSnapshotUpdateService _snapshotUpdateService;
  final RemoteBackedItemActionService? _remoteBackedItemActionService;
  final FixedScheduleValidator _fixedScheduleValidator =
      const FixedScheduleValidator();
  final DateTime Function() _clock;
  final Future<String> Function()? _currentActorId;

  Stream<List<ItemPack>> watchPacks({bool includeArchived = false}) =>
      _dao.watchItemPacks(includeArchived: includeArchived);

  Stream<List<ItemBundle>> watchItems() =>
      _dao.watchItemBundles(statuses: const {ItemLifecycleStatus.active});

  Stream<List<ItemBundle>> watchPackManagementItems() =>
      _dao.watchItemBundles(statuses: managedItemStatuses);

  Stream<List<ItemBundle>> watchItemsByStatus(
    ItemStatus status, {
    DateTime? now,
  }) {
    final current = now ?? _clock();
    return watchItems().map(
      (items) => items
          .where(
            (item) =>
                _statusService.classify(item.item, now: current) == status,
          )
          .toList(growable: false),
    );
  }

  Stream<Map<int, HomeItemSyncStatus>> watchHomeItemSyncStatuses() {
    return _combineLatest3(
      _dao.watchRemotePackSyncMetadataEntries(),
      _dao.watchRemoteItemSyncMetadataEntries(),
      _dao.watchSyncOutboxEntries(
        statuses: const {
          SyncOutboxStatus.pending,
          SyncOutboxStatus.syncing,
          SyncOutboxStatus.failed,
          SyncOutboxStatus.conflict,
          SyncOutboxStatus.noOp,
        },
      ),
      _buildHomeItemSyncStatuses,
    );
  }

  Stream<List<ItemActionRecord>> watchActionHistory(int itemId) {
    return _dao.watchItemActionRecordsForItem(itemId);
  }

  Stream<List<ItemHistoryEntry>> watchHistoryEntries(int itemId) {
    return _dao
        .watchItemHistoryActionResourceRows(itemId)
        .map(_buildHistoryEntries);
  }

  Future<List<ItemActionRecord>> listActionHistory(int itemId) {
    return _dao.listItemActionRecordsForItem(itemId);
  }

  Stream<List<ItemActionEntry>> watchDoneActionEntriesForDate(DateTime date) {
    final start = _normalizeDate(date);
    return _dao.watchItemActionEntriesForDateRange(
      actionTypes: const {ItemActionType.done},
      actionDateFrom: start,
      actionDateBefore: start.add(const Duration(days: 1)),
    );
  }

  Future<List<ItemActivityEntry>> listActivityFeed({
    int limit = 20,
    int offset = 0,
    String? query,
    int? recentDays,
    DateTime? now,
    DateTime? actionDateBefore,
    bool majorActionsOnly = true,
  }) {
    final current = _normalizeDate(now ?? _clock());
    final actionDateFrom = recentDays == null
        ? null
        : current.subtract(Duration(days: recentDays - 1));
    return _dao.listItemActivityEntries(
      actionTypes: majorActionsOnly ? majorActivityActionTypes : null,
      limit: limit,
      offset: offset,
      query: query,
      actionDateFrom: actionDateFrom,
      actionDateBefore: actionDateBefore == null
          ? null
          : _normalizeDate(actionDateBefore),
    );
  }

  Future<List<SharedItemActivityEntry>> listSharedItemActivityFeed({
    int limit = 20,
    int offset = 0,
    String? query,
    int? recentDays,
    DateTime? now,
    DateTime? actionDateBefore,
  }) {
    final current = _normalizeDate(now ?? _clock());
    final createdAtFrom = recentDays == null
        ? null
        : current.subtract(Duration(days: recentDays - 1));
    return _dao.listSharedItemActivityEntries(
      limit: limit,
      offset: offset,
      query: query,
      createdAtFrom: createdAtFrom,
      createdAtBefore: actionDateBefore == null
          ? null
          : _normalizeDate(actionDateBefore),
    );
  }

  Future<ItemBundle?> getItemById(int id) => _dao.getItemBundleById(id);

  Future<ItemPack?> getPackById(int id) => _dao.getItemPackById(id);

  Future<bool> isRemoteBackedPack(int id) => _dao.isRemoteBackedPack(id);

  Future<bool> isRemoteBackedItem(int itemId) async {
    final bundle = await getItemById(itemId);
    if (bundle == null) {
      return false;
    }
    return _dao.isRemoteBackedPack(bundle.pack.id);
  }

  Future<int> createItem(
    ItemInput input, {
    List<ItemResourceBindingInput> resourceBindings = const [],
    String? actorUserId,
  }) async {
    final now = _clock();
    final actor = await _resolveActorId(actorUserId);
    return _dao.attachedDatabase.transaction(() async {
      final packId = await _resolvePackId(input.packId, now);
      if (await _dao.isRemoteBackedPack(packId)) {
        return _createRemoteBackedItemLocally(
          _copyItemInput(input, packId: packId),
          actorUserId: actor,
          resourceBindings: resourceBindings,
          now: now,
        );
      }
      final itemId = await _createItemRecord(
        _copyItemInput(input, packId: packId),
        now: now,
      );
      await _insertCreatedAction(itemId, now: now);
      await _insertActivityEvent(
        packId: packId,
        actorUserId: actor,
        entityType: 'item',
        entityId: itemId,
        action: 'item_created',
        now: now,
      );
      await _applyResourceBindingInputs(
        itemId: itemId,
        packId: packId,
        bindings: resourceBindings,
        now: now,
      );
      return itemId;
    });
  }

  Future<int> createItemWithOptionalNewPack({
    required ItemInput item,
    ItemPackInput? newPack,
    List<ItemResourceBindingInput> resourceBindings = const [],
    String? actorUserId,
  }) async {
    final now = _clock();
    final actor = await _resolveActorId(actorUserId);
    return _dao.attachedDatabase.transaction(() async {
      final createdPackId = newPack == null
          ? null
          : await _dao.insertItemPack(
              _packCompanion(
                newPack,
                now: now,
                orderIndex: await _nextCustomPackOrderIndex(),
              ),
            );
      final packId = createdPackId ?? await _resolvePackId(item.packId, now);
      if (createdPackId == null && await _dao.isRemoteBackedPack(packId)) {
        return _createRemoteBackedItemLocally(
          _copyItemInput(item, packId: packId),
          actorUserId: actor,
          resourceBindings: resourceBindings,
          now: now,
        );
      }
      final itemId = await _createItemRecord(
        _copyItemInput(item, packId: packId),
        now: now,
      );
      await _insertCreatedAction(itemId, now: now);
      await _insertActivityEvent(
        packId: packId,
        actorUserId: actor,
        entityType: 'item',
        entityId: itemId,
        action: 'item_created',
        now: now,
      );
      await _applyResourceBindingInputs(
        itemId: itemId,
        packId: packId,
        bindings: resourceBindings,
        now: now,
      );
      return itemId;
    });
  }

  Future<bool> updateItem(
    int id,
    ItemInput input, {
    List<ItemResourceBindingInput> resourceBindings = const [],
    bool moveLinkedResourcesOnPackChange = true,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    if (input.type != existing.item.type) {
      return false;
    }
    _validateItemInput(input);
    final now = _clock();
    final packId = input.packId ?? existing.item.packId;
    await _assertPackCanAcceptItems(packId, existingItem: existing.item);
    final existingRemoteBacked = await _dao.isRemoteBackedPack(
      existing.item.packId,
    );
    final targetRemoteBacked = await _dao.isRemoteBackedPack(packId);
    if (existingRemoteBacked || targetRemoteBacked) {
      if (!existingRemoteBacked ||
          !targetRemoteBacked ||
          packId != existing.item.packId ||
          resourceBindings.isNotEmpty ||
          input.attentionPolicySource != existing.item.attentionPolicySource ||
          !_sameItemConfig(existing.item.config, input.config)) {
        return false;
      }
      return _updateRemoteBackedItemLocally(existing, input, now: now);
    }
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateItemRecord(
        _itemRowForUpdate(existing.item, input, packId: packId, now: now),
      );
      if (!updated) {
        return false;
      }
      if (packId != existing.item.packId) {
        await _cleanupItemMoveRelations(
          itemId: id,
          targetPackId: packId,
          moveLinkedResources: moveLinkedResourcesOnPackChange,
        );
      }
      await _applyResourceBindingInputs(
        itemId: id,
        packId: packId,
        bindings: resourceBindings,
        now: now,
      );
      return true;
    });
  }

  Future<bool> assignItemToUser(
    int itemId, {
    required String? assignedToUserId,
    String? actorUserId,
  }) async {
    final existing = await getItemById(itemId);
    if (existing == null ||
        existing.item.status == ItemLifecycleStatus.archived) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.pack.id)) {
      return false;
    }
    final now = _clock();
    final actor = await _resolveActorId(actorUserId);
    if (!await _canActOnPack(existing.pack, actor)) {
      return false;
    }
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateItemFields(
        itemId,
        ItemsCompanion(
          assignedToUserId: Value(assignedToUserId),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _insertActivityEvent(
        packId: existing.item.packId,
        actorUserId: actor,
        entityType: 'item',
        entityId: itemId,
        action: 'item_assigned',
        beforeJson: _jsonObject({
          'assigned_to_user_id': existing.item.assignedToUserId,
        }),
        afterJson: _jsonObject({'assigned_to_user_id': assignedToUserId}),
        now: now,
      );
      return true;
    });
  }

  Future<bool> moveItemToPack(
    int itemId, {
    required int targetPackId,
    required bool moveLinkedResources,
  }) async {
    final existing = await getItemById(itemId);
    if (existing == null ||
        existing.item.status == ItemLifecycleStatus.archived) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.item.packId) ||
        await _dao.isRemoteBackedPack(targetPackId)) {
      return false;
    }
    await _assertPackCanAcceptItems(targetPackId, existingItem: existing.item);
    if (targetPackId == existing.item.packId) {
      return true;
    }
    return _dao.attachedDatabase.transaction(() async {
      final moved = await _dao.moveItemToPackById(itemId, targetPackId);
      if (!moved) {
        return false;
      }
      await _cleanupItemMoveRelations(
        itemId: itemId,
        targetPackId: targetPackId,
        moveLinkedResources: moveLinkedResources,
      );
      return true;
    });
  }

  Future<bool> markDone(
    int id, {
    DateTime? doneAt,
    String? remark,
    String? actorUserId,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.pack.id)) {
      final service = _remoteBackedItemActionService;
      if (service == null) {
        return false;
      }
      final actor = actorUserId ?? await _resolveActorId(null);
      final result = await service.completeRemoteBackedItemLocally(
        id,
        actorLocalUserId: actor,
        doneAt: doneAt,
      );
      return result.queued;
    }
    final actor = await _resolveActorId(actorUserId);
    if (!await _canActOnPack(existing.pack, actor)) {
      return false;
    }
    final action = _actionService.planDone(
      existing.item,
      doneAt: doneAt,
      fallbackNow: _clock(),
      remark: remark,
      nextCycleStrategy: nextCycleStrategy,
    );
    if (action == null) {
      return false;
    }
    if (existing.pack.packType == ItemPackType.shared) {
      final existingCompletion = await _dao.getActiveItemCompletionForItem(id);
      if (existingCompletion != null) {
        return false;
      }
    }
    return _recordAction(id, action: action, actorUserId: actor);
  }

  Future<bool> skip(
    int id, {
    DateTime? actionAt,
    String? remark,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.pack.id)) {
      return false;
    }
    final action = _actionService.planSkip(
      existing.item,
      actionAt: actionAt,
      fallbackNow: _clock(),
      remark: remark,
      nextCycleStrategy: nextCycleStrategy,
    );
    if (action == null) {
      return false;
    }
    return _recordAction(
      id,
      action: action,
      actorUserId: await _resolveActorId(null),
    );
  }

  Future<bool> defer(
    int id, {
    required int deferDays,
    DateTime? actionAt,
    String? remark,
  }) async {
    return false;
  }

  Future<bool> undoDone(
    int doneActionRecordId, {
    DateTime? revertedAt,
    String? actorUserId,
  }) async {
    final doneRecord = await _dao.getItemActionRecordById(doneActionRecordId);
    if (doneRecord == null ||
        doneRecord.actionType != ItemActionType.done ||
        doneRecord.isReverted) {
      return false;
    }
    final existing = await getItemById(doneRecord.itemId);
    if (existing == null) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.pack.id)) {
      final service = _remoteBackedItemActionService;
      if (service == null) {
        return false;
      }
      final actor = actorUserId ?? await _resolveActorId(null);
      final result = await service.undoRemoteBackedItemLocally(
        doneRecord.itemId,
        actorLocalUserId: actor,
        undoneAt: revertedAt,
      );
      return result.queued;
    }

    final snapshot = _undoSnapshotFromPayload(doneRecord.payload);
    if (snapshot == null) {
      return false;
    }

    final now = _clock();
    final actionDate = _normalizeDate(revertedAt ?? now);
    final actor = await _resolveActorId(actorUserId);
    if (!await _canActOnPack(existing.pack, actor)) {
      return false;
    }
    try {
      return await _dao.attachedDatabase.transaction(() async {
        final revertedRecordId = await _dao.insertItemActionRecord(
          ItemActionRecordsCompanion.insert(
            itemId: doneRecord.itemId,
            actionType: ItemActionType.reverted.name,
            actionDate: actionDate.millisecondsSinceEpoch,
            payload: Value(
              ItemActionRecord.encodePayload({
                'reason': 'undo_done',
                'revertedActionRecordId': doneActionRecordId,
              }),
            ),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
        final markedDone = await _dao.updateItemActionRecordFields(
          doneActionRecordId,
          ItemActionRecordsCompanion(
            isReverted: const Value(true),
            revertedAt: Value(actionDate.millisecondsSinceEpoch),
            revertedByActionRecordId: Value(revertedRecordId),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
        if (!markedDone) {
          throw const _UndoDoneFailure();
        }
        await _dao.markItemCompletionUndone(
          itemActionRecordId: doneActionRecordId,
          undoneByUserId: actor,
          undoneAt: actionDate,
        );
        final restored = await _dao.updateItemFields(
          doneRecord.itemId,
          snapshot.toCompanion(now),
        );
        if (!restored) {
          throw const _UndoDoneFailure();
        }
        final consumedRecords = await _dao
            .listResourceConsumedRecordsForItemAction(doneActionRecordId);
        for (final consumedRecord in consumedRecords) {
          final restoredResource = await _undoResourceConsumption(
            consumedRecord,
            itemRevertedActionRecordId: revertedRecordId,
            actionDate: actionDate,
            actorUserId: actor,
            now: now,
          );
          if (!restoredResource) {
            throw const _UndoDoneFailure();
          }
        }
        await _insertActivityEvent(
          packId: existing.item.packId,
          actorUserId: actor,
          entityType: 'item',
          entityId: doneRecord.itemId,
          action: 'item_undone',
          metadataJson: _jsonObject({
            'item_action_record_id': doneActionRecordId,
            'reverted_action_record_id': revertedRecordId,
          }),
          now: now,
        );
        return true;
      });
    } on _UndoDoneFailure {
      return false;
    }
  }

  Future<int> createPack(ItemPackInput input) async {
    final now = _clock();
    return _dao.insertItemPack(
      _packCompanion(
        input,
        now: now,
        orderIndex: await _nextCustomPackOrderIndex(),
      ),
    );
  }

  Future<TemplateCreationResult> createPackFromTemplate(
    PackTemplate template,
  ) async {
    final now = _clock();
    final today = _normalizeDate(now);
    final packName = template.packName;
    return _dao.attachedDatabase.transaction(() async {
      final packId = await _dao.insertItemPack(
        _packCompanion(
          ItemPackInput(
            title: packName,
            description: template.description,
            iconEmoji: template.iconEmoji,
          ),
          now: now,
          orderIndex: await _nextCustomPackOrderIndex(),
        ),
      );
      final itemIds = <int>[];
      for (final templateItem in template.items) {
        itemIds.add(
          await _createItemRecord(
            ItemInput(
              title: templateItem.title,
              type: templateItem.type,
              config: _materializeTemplateConfig(templateItem.config, today),
              attentionPolicySource: templateItem.attentionPolicySource,
              packId: packId,
            ),
            now: now,
          ),
        );
      }
      return TemplateCreationResult(
        packId: packId,
        packName: packName,
        itemIds: itemIds,
      );
    });
  }

  Future<bool> activePackTitleExists(String title) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final packs = await _dao.listItemPacks();
    return packs.any((pack) => pack.title == normalized);
  }

  Future<bool> updatePack(int id, ItemPackInput input) async {
    final existing = await getPackById(id);
    if (existing == null ||
        existing.isSystemDefault ||
        existing.status == ItemPackStatus.archived) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(id)) {
      return false;
    }
    final now = _clock();
    return _dao.updateItemPackRecord(
      ItemPackRow(
        id: existing.id,
        title: input.title,
        description: input.description,
        iconEmoji: _normalizePackIcon(input.iconEmoji),
        orderIndex: existing.orderIndex,
        status: existing.status.name,
        isSystemDefault: existing.isSystemDefault,
        packType: existing.packType.name,
        hostUserId: existing.hostUserId,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> canArchivePack(int id) async {
    final pack = await getPackById(id);
    return pack != null &&
        !pack.isSystemDefault &&
        pack.status != ItemPackStatus.archived;
  }

  Future<int> countPackManagedItems(int id) {
    return _dao.countItemsForPack(id, statuses: managedItemStatuses);
  }

  Future<int> countPackManagedContents(int id) async {
    final itemCount = await _dao.countItemsForPack(
      id,
      statuses: managedItemStatuses,
    );
    final resourceCount = await _dao.countResourcesForPack(
      id,
      statuses: ResourceRepository.managedResourceStatuses,
    );
    final stageTrackerCount = await _dao.countStageTrackersForPack(
      id,
      statuses: const {StageTrackerStatus.active},
    );
    return itemCount + resourceCount + stageTrackerCount;
  }

  Future<bool> archivePack(int id) async {
    return archivePackWithContents(id);
  }

  Future<bool> archivePackWithContents(int id) async {
    final existing = await getPackById(id);
    if (existing == null || !await canArchivePack(id)) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(id)) {
      return false;
    }
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _archivePackRecord(existing, now);
      if (!updated) {
        return false;
      }
      await _dao.updateItemsStatusForPack(id, ItemLifecycleStatus.archived);
      await _dao.updateResourcesStatusForPack(
        id,
        ResourceLifecycleStatus.archived,
      );
      await _dao.updateStageTrackersStatusForPack(
        id,
        StageTrackerStatus.archived,
      );
      return true;
    });
  }

  Future<bool> archivePackAndMoveContentsToDefault(int id) async {
    final existing = await getPackById(id);
    if (existing == null || !await canArchivePack(id)) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(id)) {
      return false;
    }
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final defaultPackId = await _ensureDefaultPackId(now);
      final updated = await _archivePackRecord(existing, now);
      if (!updated) {
        return false;
      }
      await _dao.moveItemsToPack(id, defaultPackId);
      await _dao.moveResourcesToPack(id, defaultPackId);
      await _dao.moveStageTrackersToPack(id, defaultPackId);
      return true;
    });
  }

  Future<bool> movePackUp(int id) async {
    return _moveCustomPack(id, -1);
  }

  Future<bool> movePackDown(int id) async {
    return _moveCustomPack(id, 1);
  }

  Future<bool> pauseItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status != ItemLifecycleStatus.active) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.item.packId)) {
      return false;
    }
    return _dao.updateItemStatus(id, ItemLifecycleStatus.paused);
  }

  Future<bool> resumeItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status != ItemLifecycleStatus.paused) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.item.packId)) {
      return false;
    }
    return _dao.updateItemStatus(id, ItemLifecycleStatus.active);
  }

  Future<bool> archiveItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status == ItemLifecycleStatus.archived) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.item.packId)) {
      return _archiveRemoteBackedItemLocally(existing, now: _clock());
    }
    return _dao.updateItemStatus(id, ItemLifecycleStatus.archived);
  }

  ItemStatus statusFor(Item item, {DateTime? now}) {
    return _statusService.classify(item, now: now);
  }

  Duration? elapsedFor(Item item, {DateTime? now}) {
    return _statusService.elapsedSinceLastDone(item, now: now);
  }

  Future<bool> _recordAction(
    int id, {
    required PlannedItemAction action,
    required String actorUserId,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final snapshot = _snapshotUpdateService.build(
        existing.item,
        action: action,
        updatedAt: now,
      );
      final updated = await _dao.updateItemFields(
        id,
        _companionForSnapshotUpdate(snapshot),
      );
      if (!updated) {
        return false;
      }
      final payload = _payloadWithUndoSnapshot(
        action.payload,
        item: existing.item,
        actionType: action.type,
      );
      final itemActionRecordId = await _dao.insertItemActionRecord(
        ItemActionRecordsCompanion.insert(
          itemId: id,
          actionType: action.type.name,
          actionDate: action.actionDate.millisecondsSinceEpoch,
          remark: Value(action.remark),
          payload: Value(ItemActionRecord.encodePayload(payload)),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      if (action.type == ItemActionType.done) {
        await _dao.insertItemCompletion(
          ItemCompletionsCompanion.insert(
            itemId: id,
            packId: existing.item.packId,
            itemActionRecordId: itemActionRecordId,
            completedByUserId: actorUserId,
            completedAt: _normalizeDate(
              action.actionDate,
            ).millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
          ),
        );
        await _insertActivityEvent(
          packId: existing.item.packId,
          actorUserId: actorUserId,
          entityType: 'item',
          entityId: id,
          action: 'item_completed',
          metadataJson: _jsonObject({
            'item_action_record_id': itemActionRecordId,
          }),
          now: now,
        );
        await _applyResourceConsumptionRules(
          id,
          itemActionRecordId: itemActionRecordId,
          actionDate: action.actionDate,
          actorUserId: actorUserId,
          now: now,
        );
      }
      return true;
    });
  }

  Future<bool> _undoResourceConsumption(
    ResourceActionRecord consumedRecord, {
    required int itemRevertedActionRecordId,
    required DateTime actionDate,
    required String actorUserId,
    required DateTime now,
  }) async {
    if (consumedRecord.isReverted) {
      return true;
    }
    final bundle = await _dao.getResourceBundleById(consumedRecord.resourceId);
    final resource = bundle?.resource;
    final amount = consumedRecord.amount;
    if (resource == null ||
        amount == null ||
        amount <= 0 ||
        resource.config is! QuantityBasedResourceConfig) {
      return false;
    }
    final config = resource.config as QuantityBasedResourceConfig;
    final previousQuantity = config.currentQuantity;
    final resultingQuantity = const ResourceRefillService().refillQuantity(
      config,
      amount,
    );
    final updatedResource = await _dao.updateResourceFields(
      resource.id,
      ResourcesCompanion(
        quantityCurrent: Value(resultingQuantity),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (!updatedResource) {
      return false;
    }
    final compensationRecordId = await _dao.insertResourceActionRecord(
      ResourceActionRecordsCompanion.insert(
        resourceId: resource.id,
        actionType: ResourceActionType.reverted.name,
        actionDate: actionDate.millisecondsSinceEpoch,
        amount: Value(amount),
        resultingQuantity: Value(resultingQuantity),
        sourceItemActionRecordId: Value(itemRevertedActionRecordId),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await _dao.insertResourceEvent(
      ResourceEventsCompanion.insert(
        resourceId: resource.id,
        packId: resource.packId,
        actorUserId: actorUserId,
        changeType: ResourceEventChangeType.increment.name,
        previousValue: Value(previousQuantity),
        newValue: Value(resultingQuantity),
        deltaValue: Value(amount),
        unit: Value(config.unitLabel),
        createdAt: now.millisecondsSinceEpoch,
        metadataJson: Value(
          _jsonObject({
            'source_item_reverted_action_record_id': itemRevertedActionRecordId,
          }),
        ),
      ),
    );
    return _dao.updateResourceActionRecordFields(
      consumedRecord.id,
      ResourceActionRecordsCompanion(
        isReverted: const Value(true),
        revertedAt: Value(actionDate.millisecondsSinceEpoch),
        revertedByActionRecordId: Value(compensationRecordId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> _insertActivityEvent({
    required int packId,
    required String actorUserId,
    required String entityType,
    required int entityId,
    required String action,
    String? beforeJson,
    String? afterJson,
    String? metadataJson,
    required DateTime now,
  }) {
    return _dao.insertActivityEvent(
      ActivityEventsCompanion.insert(
        packId: packId,
        actorUserId: actorUserId,
        entityType: entityType,
        entityId: entityId,
        action: action,
        beforeJson: Value(beforeJson),
        afterJson: Value(afterJson),
        metadataJson: Value(metadataJson),
        createdAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  String _jsonObject(Map<String, Object?> value) {
    return jsonEncode(value);
  }

  Future<void> _applyResourceConsumptionRules(
    int itemId, {
    required int itemActionRecordId,
    required DateTime actionDate,
    required String actorUserId,
    required DateTime now,
  }) async {
    final rules = await _dao.listConsumptionRulesForItem(
      itemId,
      enabledOnly: true,
    );
    const refillService = ResourceRefillService();
    for (final rule in rules) {
      if (rule.triggerActionType != ItemActionType.done ||
          rule.consumeAmount <= 0) {
        continue;
      }
      final bundle = await _dao.getResourceBundleById(rule.resourceId);
      final resource = bundle?.resource;
      if (resource == null ||
          resource.status != ResourceLifecycleStatus.active ||
          resource.config is! QuantityBasedResourceConfig) {
        continue;
      }
      final config = resource.config as QuantityBasedResourceConfig;
      final previousQuantity = config.currentQuantity;
      final resultingQuantity = refillService.consumeQuantity(
        config,
        rule.consumeAmount,
      );
      await _dao.updateResourceFields(
        resource.id,
        ResourcesCompanion(
          quantityCurrent: Value(resultingQuantity),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: resource.id,
          actionType: ResourceActionType.consumed.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          amount: Value(rule.consumeAmount),
          resultingQuantity: Value(resultingQuantity),
          sourceItemActionRecordId: Value(itemActionRecordId),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _dao.insertResourceEvent(
        ResourceEventsCompanion.insert(
          resourceId: resource.id,
          packId: resource.packId,
          actorUserId: actorUserId,
          changeType: ResourceEventChangeType.decrement.name,
          previousValue: Value(previousQuantity),
          newValue: Value(resultingQuantity),
          deltaValue: Value(-rule.consumeAmount),
          unit: Value(config.unitLabel),
          createdAt: now.millisecondsSinceEpoch,
          metadataJson: Value(
            _jsonObject({'source_item_action_record_id': itemActionRecordId}),
          ),
        ),
      );
    }
  }

  Map<String, Object?>? _payloadWithUndoSnapshot(
    Map<String, Object?>? payload, {
    required Item item,
    required ItemActionType actionType,
  }) {
    if (actionType != ItemActionType.done) {
      return payload;
    }
    return <String, Object?>{
      ...?payload,
      'undoSnapshot': _undoSnapshotForItem(item).toPayload(),
    };
  }

  _ItemUndoSnapshot _undoSnapshotForItem(Item item) {
    final config = item.config;
    return _ItemUndoSnapshot(
      fixedAnchorDate: config is FixedItemConfig
          ? config.anchorDate?.millisecondsSinceEpoch
          : null,
      fixedDueDate: config is FixedItemConfig
          ? config.dueDate?.millisecondsSinceEpoch
          : null,
      fixedRepeatRuleV2: config is FixedItemConfig
          ? config.repeatRuleV2?.encode()
          : null,
      stateAnchorDate: config is StateBasedItemConfig
          ? config.anchorDate?.millisecondsSinceEpoch
          : null,
      lastDoneAt: item.lastDoneAt?.millisecondsSinceEpoch,
    );
  }

  _ItemUndoSnapshot? _undoSnapshotFromPayload(Map<String, Object?>? payload) {
    final snapshot = payload?['undoSnapshot'];
    if (snapshot is! Map) {
      return null;
    }
    return _ItemUndoSnapshot(
      fixedAnchorDate: _nullableInt(snapshot['fixedAnchorDate']),
      fixedDueDate: _nullableInt(snapshot['fixedDueDate']),
      fixedRepeatRuleV2: snapshot['fixedRepeatRuleV2'] as String?,
      stateAnchorDate: _nullableInt(snapshot['stateAnchorDate']),
      lastDoneAt: _nullableInt(snapshot['lastDoneAt']),
    );
  }

  int? _nullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  Future<void> _insertCreatedAction(int itemId, {required DateTime now}) {
    final actionDate = _normalizeDate(now);
    return _dao.insertItemActionRecord(
      ItemActionRecordsCompanion.insert(
        itemId: itemId,
        actionType: ItemActionType.created.name,
        actionDate: actionDate.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  ItemsCompanion _companionForSnapshotUpdate(ItemSnapshotUpdate snapshot) {
    return ItemsCompanion(
      fixedAnchorDate: _dateValue(snapshot.fixedAnchorDate),
      fixedDueDate: _dateValue(snapshot.fixedDueDate),
      fixedRepeatRuleV2: _stringValue(snapshot.fixedRepeatRuleV2),
      stateAnchorDate: _dateValue(snapshot.stateAnchorDate),
      lastDoneAt: _dateValue(snapshot.lastDoneAt),
      updatedAt: Value(snapshot.updatedAt.millisecondsSinceEpoch),
    );
  }

  Future<int> _createItemRecord(
    ItemInput input, {
    required DateTime now,
  }) async {
    _validateItemInput(input);
    final packId = input.packId ?? await _ensureDefaultPackId(now);
    await _assertPackCanAcceptItems(packId);
    return _dao.insertItem(_itemCompanion(input, packId: packId, now: now));
  }

  Future<int> _createRemoteBackedItemLocally(
    ItemInput input, {
    required String actorUserId,
    required List<ItemResourceBindingInput> resourceBindings,
    required DateTime now,
  }) async {
    if (resourceBindings.isNotEmpty) {
      throw StateError(remoteBackedUnsupportedMessage);
    }
    _validateItemInput(input);
    final packId = input.packId!;
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      packId,
    );
    if (packMetadata == null ||
        packMetadata.syncKind != RemotePackSyncKind.remoteBacked ||
        _isRemoteAccessLost(packMetadata)) {
      throw StateError(remoteBackedUnsupportedMessage);
    }
    final actor = await _resolveActorUser(actorUserId);
    final clientMutationId = _remoteBackedClientMutationId(
      'create_item',
      packId,
      now,
    );
    final itemId = await _dao.insertItem(
      _itemCompanion(input, packId: packId, now: now),
    );
    await _insertCreatedAction(itemId, now: now);
    await _insertActivityEvent(
      packId: packId,
      actorUserId: actor.id,
      entityType: 'item',
      entityId: itemId,
      action: 'item_created',
      metadataJson: _jsonObject({
        'remoteBackedPending': true,
        'syncActionType': SyncOutboxActionType.createItem.storageValue,
        'clientMutationId': clientMutationId,
      }),
      now: now,
    );
    final pendingRemoteItemId = '$_pendingRemoteItemIdPrefix$clientMutationId';
    await _dao.insertRemoteItemSyncMetadata(
      RemoteItemSyncMetadataCompanion.insert(
        localItemId: itemId,
        localPackId: packId,
        remoteItemId: pendingRemoteItemId,
        remotePackId: packMetadata.remotePackId,
        syncState: RemoteItemSyncState.pendingPush.storageValue,
        remoteStatus: const Value('active'),
        lastSyncError: const Value(null),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await _enqueueRemoteBackedItemMutation(
      actionType: SyncOutboxActionType.createItem,
      localPackId: packId,
      remotePackId: packMetadata.remotePackId,
      localItemId: itemId,
      remoteItemId: null,
      clientMutationId: clientMutationId,
      actor: actor,
      actionAt: now,
      fields: {
        'title': input.title,
        'note': input.description,
        'assignedToUserId': await _remoteUserIdForLocalUser(
          input.assignedToUserId,
        ),
      },
    );
    await _markRemoteBackedPackStale(packMetadata, now);
    return itemId;
  }

  Future<bool> _updateRemoteBackedItemLocally(
    ItemBundle existing,
    ItemInput input, {
    required DateTime now,
  }) async {
    final remoteItemId = await _remoteItemIdForLocalItem(existing.item.id);
    if (remoteItemId == null) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.item.packId,
    );
    if (packMetadata == null || _isRemoteAccessLost(packMetadata)) {
      return false;
    }
    final actor = await _resolveActorUser(await _resolveActorId(null));
    final clientMutationId = _remoteBackedClientMutationId(
      'update_item',
      existing.item.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateItemFields(
        existing.item.id,
        ItemsCompanion(
          title: Value(input.title),
          description: Value(input.description),
          assignedToUserId: Value(input.assignedToUserId),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _insertActivityEvent(
        packId: existing.item.packId,
        actorUserId: actor.id,
        entityType: 'item',
        entityId: existing.item.id,
        action: 'item_updated',
        beforeJson: _jsonObject({
          'title': existing.item.title,
          'note': existing.item.description,
          'assigned_to_user_id': existing.item.assignedToUserId,
        }),
        afterJson: _jsonObject({
          'title': input.title,
          'note': input.description,
          'assigned_to_user_id': input.assignedToUserId,
        }),
        metadataJson: _jsonObject({
          'remoteBackedPending': true,
          'syncActionType': SyncOutboxActionType.updateItem.storageValue,
          'clientMutationId': clientMutationId,
        }),
        now: now,
      );
      await _markRemoteBackedItemPendingPush(existing.item.id, now);
      await _enqueueRemoteBackedItemMutation(
        actionType: SyncOutboxActionType.updateItem,
        localPackId: existing.item.packId,
        remotePackId: packMetadata.remotePackId,
        localItemId: existing.item.id,
        remoteItemId: remoteItemId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: now,
        fields: {
          'title': input.title,
          'note': input.description,
          'assignedToUserId': await _remoteUserIdForLocalUser(
            input.assignedToUserId,
          ),
        },
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<bool> _archiveRemoteBackedItemLocally(
    ItemBundle existing, {
    required DateTime now,
  }) async {
    final remoteItemId = await _remoteItemIdForLocalItem(existing.item.id);
    if (remoteItemId == null) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.item.packId,
    );
    if (packMetadata == null || _isRemoteAccessLost(packMetadata)) {
      return false;
    }
    final actor = await _resolveActorUser(await _resolveActorId(null));
    final clientMutationId = _remoteBackedClientMutationId(
      'archive_item',
      existing.item.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateItemStatus(
        existing.item.id,
        ItemLifecycleStatus.archived,
      );
      if (!updated) {
        return false;
      }
      await _insertActivityEvent(
        packId: existing.item.packId,
        actorUserId: actor.id,
        entityType: 'item',
        entityId: existing.item.id,
        action: 'item_archived',
        metadataJson: _jsonObject({
          'remoteBackedPending': true,
          'syncActionType': SyncOutboxActionType.archiveItem.storageValue,
          'clientMutationId': clientMutationId,
        }),
        now: now,
      );
      await _markRemoteBackedItemPendingPush(existing.item.id, now);
      await _enqueueRemoteBackedItemMutation(
        actionType: SyncOutboxActionType.archiveItem,
        localPackId: existing.item.packId,
        remotePackId: packMetadata.remotePackId,
        localItemId: existing.item.id,
        remoteItemId: remoteItemId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: now,
        fields: const {'status': 'archived'},
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<LocalUser> _resolveActorUser(String actorUserId) async {
    final user = await _dao.getLocalUserById(actorUserId);
    if (user != null) {
      return user;
    }
    final fallback = await _dao.getLocalUserById(AppDatabase.defaultHostUserId);
    if (fallback != null) {
      return fallback;
    }
    final fallbackNow = DateTime.fromMillisecondsSinceEpoch(0);
    return LocalUser(
      id: actorUserId,
      displayName: '你',
      remoteUserId: null,
      remoteProvider: null,
      identityKind: LocalUserIdentityKind.local,
      linkedAt: null,
      createdAt: fallbackNow,
      updatedAt: fallbackNow,
    );
  }

  Future<String?> _remoteUserIdForLocalUser(String? localUserId) async {
    if (localUserId == null) {
      return null;
    }
    final user = await _dao.getLocalUserById(localUserId);
    return user?.remoteUserId;
  }

  Future<void> _enqueueRemoteBackedItemMutation({
    required SyncOutboxActionType actionType,
    required int localPackId,
    required String remotePackId,
    required int localItemId,
    required String? remoteItemId,
    required String clientMutationId,
    required LocalUser actor,
    required DateTime actionAt,
    required Map<String, Object?> fields,
  }) {
    final now = _clock();
    return _dao
        .insertSyncOutbox(
          SyncOutboxCompanion.insert(
            localPackId: localPackId,
            remotePackId: Value(remotePackId),
            localEntityType: RemoteSharedPackRepository.localEntityItem,
            localEntityId: Value(localItemId),
            remoteEntityId: Value(remoteItemId),
            actionType: actionType.storageValue,
            payloadJson: jsonEncode({
              'remotePackId': remotePackId,
              'remoteItemId': remoteItemId,
              'localPackId': localPackId,
              'localItemId': localItemId,
              'clientMutationId': clientMutationId,
              'actorLocalUserId': actor.id,
              'actorRemoteUserId': actor.remoteUserId,
              'actionAt': actionAt.toIso8601String(),
              'fields': fields,
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

  Future<void> _markRemoteBackedItemPendingPush(
    int localItemId,
    DateTime now,
  ) async {
    final metadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
      localItemId,
    );
    if (metadata == null) {
      return;
    }
    await _dao.updateRemoteItemSyncMetadata(
      metadata.id,
      RemoteItemSyncMetadataCompanion(
        syncState: Value(RemoteItemSyncState.pendingPush.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> _markRemoteBackedPackStale(
    RemotePackSyncMetadataEntry metadata,
    DateTime now,
  ) {
    return _dao
        .updateRemotePackSyncMetadata(
          metadata.id,
          RemotePackSyncMetadataCompanion(
            syncState: Value(RemotePackSyncState.stale.storageValue),
            lastSyncError: const Value(null),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        )
        .then((_) {});
  }

  Future<String?> _remoteItemIdForLocalItem(int localItemId) async {
    final metadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
      localItemId,
    );
    final remoteItemId = metadata?.remoteItemId;
    if (remoteItemId != null &&
        !remoteItemId.startsWith(_pendingRemoteItemIdPrefix)) {
      return remoteItemId;
    }
    final mapping = await _dao.getSyncMapping(
      localEntityType: RemoteSharedPackRepository.localEntityItem,
      localEntityId: localItemId,
      remoteTable: RemoteSharedPackRepository.remoteTableItems,
    );
    return mapping?.remoteEntityId;
  }

  bool _isRemoteAccessLost(RemotePackSyncMetadataEntry metadata) {
    return metadata.syncState == RemotePackSyncState.accessLost ||
        metadata.syncState == RemotePackSyncState.removed ||
        metadata.currentUserRemoteStatus == RemoteUserStatus.removed;
  }

  String _remoteBackedClientMutationId(
    String action,
    int localId,
    DateTime now,
  ) {
    return 'phase1_${action}_${localId}_${now.microsecondsSinceEpoch}';
  }

  bool _sameItemConfig(ItemConfig left, ItemConfig right) {
    if (left.runtimeType != right.runtimeType || left.type != right.type) {
      return false;
    }
    if (left is FixedItemConfig && right is FixedItemConfig) {
      return left.scheduleType == right.scheduleType &&
          left.scheduleInterval == right.scheduleInterval &&
          left.monthlyDay == right.monthlyDay &&
          left.repeatRuleV2?.encode() == right.repeatRuleV2?.encode() &&
          _sameDate(left.anchorDate, right.anchorDate) &&
          _sameDate(left.dueDate, right.dueDate) &&
          left.timeOfDay == right.timeOfDay &&
          left.overduePolicy == right.overduePolicy &&
          left.infoBefore == right.infoBefore &&
          left.warningBefore == right.warningBefore &&
          left.dangerBefore == right.dangerBefore;
    }
    if (left is StateBasedItemConfig && right is StateBasedItemConfig) {
      return _sameDate(left.anchorDate, right.anchorDate) &&
          left.infoAfter == right.infoAfter &&
          left.warningAfter == right.warningAfter &&
          left.dangerAfter == right.dangerAfter;
    }
    return false;
  }

  bool _sameDate(DateTime? left, DateTime? right) {
    return left?.millisecondsSinceEpoch == right?.millisecondsSinceEpoch;
  }

  Future<int> _resolvePackId(int? packId, DateTime now) async {
    final resolvedPackId = packId ?? await _ensureDefaultPackId(now);
    await _assertPackCanAcceptItems(resolvedPackId);
    return resolvedPackId;
  }

  ItemInput _copyItemInput(ItemInput input, {required int packId}) {
    return ItemInput(
      title: input.title,
      description: input.description,
      type: input.type,
      config: input.config,
      attentionPolicySource: input.attentionPolicySource,
      packId: packId,
      assignedToUserId: input.assignedToUserId,
    );
  }

  void _validateItemInput(ItemInput input) {
    if (input.type != input.config.type) {
      throw StateError('Item type and config type do not match.');
    }
    final config = input.config;
    if (config is FixedItemConfig) {
      _fixedScheduleValidator.validateForSave(config);
    }
  }

  Future<void> _applyResourceBindingInputs({
    required int itemId,
    required int packId,
    required List<ItemResourceBindingInput> bindings,
    required DateTime now,
  }) async {
    for (final binding in bindings) {
      final consumeAmount = binding.consumeAmount < 1
          ? 1
          : binding.consumeAmount;
      final resourceId = binding.existingResourceId == null
          ? await _createResourceForItemBinding(
              binding.newResource,
              packId: packId,
              now: now,
            )
          : await _validateExistingResourceBinding(
              binding.existingResourceId!,
              packId: packId,
            );
      await _dao.insertResourceConsumptionRule(
        ResourceConsumptionRulesCompanion.insert(
          resourceId: resourceId,
          itemId: itemId,
          triggerActionType: Value(ItemActionType.done.name),
          consumeAmount: Value(consumeAmount),
          isEnabled: const Value(true),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
    }
  }

  Future<void> _cleanupItemMoveRelations({
    required int itemId,
    required int targetPackId,
    required bool moveLinkedResources,
  }) async {
    await _dao.deleteStageRelatedItemsForItem(itemId);
    final rules = await _dao.listConsumptionRulesForItem(
      itemId,
      enabledOnly: true,
    );
    if (moveLinkedResources) {
      final resourceIds = rules.map((rule) => rule.resourceId).toSet();
      for (final resourceId in resourceIds) {
        await _dao.moveResourceToPackById(resourceId, targetPackId);
      }
    } else {
      await _dao.disableConsumptionRulesForItem(itemId);
    }
  }

  Future<int> _createResourceForItemBinding(
    ResourceInput? input, {
    required int packId,
    required DateTime now,
  }) async {
    if (input == null ||
        input.type != ResourceType.quantityBased ||
        input.config is! QuantityBasedResourceConfig) {
      throw StateError('新增 item 時只能建立數量庫存資源');
    }
    final resourceId = await _dao.insertResource(
      _resourceCompanionForInput(input, packId: packId, now: now),
    );
    await _dao.insertResourceActionRecord(
      ResourceActionRecordsCompanion.insert(
        resourceId: resourceId,
        actionType: ResourceActionType.created.name,
        actionDate: _normalizeDate(now).millisecondsSinceEpoch,
        resultingQuantity: Value(_resourceQuantityCurrent(input.config)),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    return resourceId;
  }

  Future<int> _validateExistingResourceBinding(
    int resourceId, {
    required int packId,
  }) async {
    final bundle = await _dao.getResourceBundleById(resourceId);
    if (bundle == null) {
      throw StateError('找不到要綁定的資源');
    }
    final resource = bundle.resource;
    if (resource.packId != packId) {
      throw StateError('只能綁定同一個生活場景內的資源');
    }
    if (resource.status != ResourceLifecycleStatus.active ||
        resource.config is! QuantityBasedResourceConfig) {
      throw StateError('只能綁定啟用中的數量庫存資源');
    }
    return resource.id;
  }

  ItemsCompanion _itemCompanion(
    ItemInput input, {
    required int packId,
    required DateTime now,
  }) {
    return ItemsCompanion.insert(
      packId: packId,
      title: input.title,
      description: Value(input.description),
      status: const Value('active'),
      type: input.type.name,
      attentionPolicySource: Value(input.attentionPolicySource.name),
      fixedScheduleType: Value(_fixedScheduleType(input.config)),
      fixedScheduleInterval: Value(_fixedScheduleInterval(input.config)),
      fixedMonthlyDay: Value(_fixedMonthlyDay(input.config)),
      fixedRepeatRuleV2: Value(_fixedRepeatRuleV2(input.config)),
      fixedAnchorDate: Value(_fixedAnchorDate(input.config)),
      fixedDueDate: Value(_fixedDueDate(input.config)),
      fixedTimeOfDay: Value(_fixedTimeOfDay(input.config)),
      fixedOverduePolicy: Value(_fixedOverduePolicy(input.config)),
      fixedExpectedBeforeMinutes: Value(
        _durationMinutes(_fixedInfoBefore(input.config)),
      ),
      fixedWarningBeforeMinutes: Value(
        _durationMinutes(_fixedWarningBefore(input.config)),
      ),
      fixedDangerBeforeMinutes: Value(
        _durationMinutes(_fixedDangerBefore(input.config)),
      ),
      stateExpectedAfterMinutes: Value(
        _durationMinutes(_stateInfoAfter(input.config)),
      ),
      stateAnchorDate: Value(_stateAnchorDate(input.config)),
      stateWarningAfterMinutes: Value(
        _durationMinutes(_stateWarningAfter(input.config)),
      ),
      stateDangerAfterMinutes: Value(
        _durationMinutes(_stateDangerAfter(input.config)),
      ),
      assignedToUserId: Value(input.assignedToUserId),
      lastDoneAt: Value(_snapshotLastDoneAtForCreate(input.config)),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ItemRow _itemRowForUpdate(
    Item existing,
    ItemInput input, {
    required int packId,
    required DateTime now,
  }) {
    return ItemRow(
      id: existing.id,
      packId: packId,
      title: input.title,
      description: input.description,
      status: existing.status.name,
      type: input.type.name,
      attentionPolicySource: input.attentionPolicySource.name,
      fixedScheduleType: _fixedScheduleType(input.config),
      fixedScheduleInterval: _fixedScheduleInterval(input.config),
      fixedMonthlyDay: _fixedMonthlyDay(input.config),
      fixedRepeatRuleV2: _fixedRepeatRuleV2(input.config),
      fixedAnchorDate: _fixedAnchorDate(input.config),
      fixedDueDate: _fixedDueDate(input.config),
      fixedTimeOfDay: _fixedTimeOfDay(input.config),
      fixedOverduePolicy: _fixedOverduePolicy(input.config),
      fixedExpectedBeforeMinutes: _durationMinutes(
        _fixedInfoBefore(input.config),
      ),
      fixedWarningBeforeMinutes: _durationMinutes(
        _fixedWarningBefore(input.config),
      ),
      fixedDangerBeforeMinutes: _durationMinutes(
        _fixedDangerBefore(input.config),
      ),
      stateExpectedAfterMinutes: _durationMinutes(
        _stateInfoAfter(input.config),
      ),
      stateAnchorDate: _stateAnchorDate(input.config),
      stateWarningAfterMinutes: _durationMinutes(
        _stateWarningAfter(input.config),
      ),
      stateDangerAfterMinutes: _durationMinutes(
        _stateDangerAfter(input.config),
      ),
      assignedToUserId: input.assignedToUserId,
      lastDoneAt: existing.lastDoneAt?.millisecondsSinceEpoch,
      createdAt: existing.createdAt.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ResourcesCompanion _resourceCompanionForInput(
    ResourceInput input, {
    required int packId,
    required DateTime now,
  }) {
    return ResourcesCompanion.insert(
      packId: packId,
      title: input.title,
      description: Value(input.description),
      status: const Value('active'),
      type: input.type.name,
      timeAnchorDate: Value(_resourceTimeAnchorDate(input.config)),
      timeDurationDays: Value(_resourceTimeDurationDays(input.config)),
      timeExpectedBeforeDays: Value(_resourceTimeInfoBeforeDays(input.config)),
      timeWarningBeforeDays: Value(
        _resourceTimeWarningBeforeDays(input.config),
      ),
      timeDangerBeforeDays: Value(_resourceTimeDangerBeforeDays(input.config)),
      quantityCurrent: Value(_resourceQuantityCurrent(input.config)),
      quantityUnitLabel: Value(_resourceQuantityUnitLabel(input.config)),
      quantityExpectedThreshold: Value(
        _resourceQuantityInfoThreshold(input.config),
      ),
      quantityWarningThreshold: Value(
        _resourceQuantityWarningThreshold(input.config),
      ),
      quantityDangerThreshold: Value(
        _resourceQuantityDangerThreshold(input.config),
      ),
      lastRefilledAt: Value(_resourceInitialLastRefilledAt(input.config)),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ItemPacksCompanion _packCompanion(
    ItemPackInput input, {
    required DateTime now,
    int? orderIndex,
  }) {
    return ItemPacksCompanion.insert(
      title: input.title,
      description: Value(input.description),
      iconEmoji: Value(_normalizePackIcon(input.iconEmoji)),
      orderIndex: Value(orderIndex ?? 0),
      status: const Value('active'),
      isSystemDefault: const Value(false),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
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

  Future<void> _assertPackCanAcceptItems(
    int packId, {
    Item? existingItem,
  }) async {
    final pack = await getPackById(packId);
    if (pack == null) {
      throw StateError('Item pack not found.');
    }
    if (pack.status == ItemPackStatus.active) {
      return;
    }
    if (existingItem != null && existingItem.packId == pack.id) {
      return;
    }
    throw StateError('Archived item pack cannot accept items.');
  }

  Future<int> _nextCustomPackOrderIndex() async {
    final packs = await _dao.listItemPacks(includeArchived: true);
    final customOrderIndexes = packs
        .where((pack) => !pack.isSystemDefault)
        .map((pack) => pack.orderIndex);
    if (customOrderIndexes.isEmpty) {
      return 1;
    }
    return customOrderIndexes.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<bool> _archivePackRecord(ItemPack existing, DateTime now) {
    return _dao.updateItemPackRecord(
      ItemPackRow(
        id: existing.id,
        title: existing.title,
        description: existing.description,
        iconEmoji: existing.iconEmoji,
        orderIndex: existing.orderIndex,
        status: ItemPackStatus.archived.name,
        isSystemDefault: existing.isSystemDefault,
        packType: existing.packType.name,
        hostUserId: existing.hostUserId,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> _moveCustomPack(int id, int delta) async {
    final packs = (await _dao.listItemPacks())
        .where((pack) => !pack.isSystemDefault)
        .toList(growable: false);
    final index = packs.indexWhere((pack) => pack.id == id);
    final targetIndex = index + delta;
    if (index < 0 || targetIndex < 0 || targetIndex >= packs.length) {
      return false;
    }
    final reordered = [...packs];
    final moving = reordered.removeAt(index);
    reordered.insert(targetIndex, moving);
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      for (var i = 0; i < reordered.length; i++) {
        final pack = reordered[i];
        await _dao.updateItemPackFields(
          pack.id,
          ItemPacksCompanion(
            orderIndex: Value(i + 1),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
      return true;
    });
  }

  String _normalizePackIcon(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '🏷️';
    }
    return trimmed;
  }

  String? _fixedScheduleType(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.scheduleType.name,
      _ => null,
    };
  }

  int? _fixedScheduleInterval(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.scheduleInterval,
      _ => null,
    };
  }

  int? _fixedMonthlyDay(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.monthlyDay,
      _ => null,
    };
  }

  String? _fixedRepeatRuleV2(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.repeatRuleV2?.encode(),
      _ => null,
    };
  }

  ItemConfig _materializeTemplateConfig(ItemConfig config, DateTime today) {
    return switch (config) {
      FixedItemConfig fixed => () {
        final dueDate = _templateDueDate(fixed, today);
        return FixedItemConfig(
          scheduleType: fixed.scheduleType,
          scheduleInterval: fixed.scheduleInterval < 1
              ? 1
              : fixed.scheduleInterval,
          monthlyDay: fixed.scheduleType == FixedScheduleType.monthly
              ? dueDate.day
              : fixed.monthlyDay,
          repeatRuleV2: fixed.repeatRuleV2,
          anchorDate: dueDate,
          dueDate: dueDate,
          timeOfDay: fixed.timeOfDay,
          overduePolicy: fixed.overduePolicy,
          infoBefore: fixed.infoBefore,
          warningBefore: fixed.warningBefore,
          dangerBefore: fixed.dangerBefore,
        );
      }(),
      StateBasedItemConfig state => StateBasedItemConfig(
        anchorDate: today,
        infoAfter: state.infoAfter,
        warningAfter: state.warningAfter,
        dangerAfter: state.dangerAfter,
      ),
      _ => config,
    };
  }

  DateTime _templateDueDate(FixedItemConfig config, DateTime today) {
    final interval = config.scheduleInterval < 1 ? 1 : config.scheduleInterval;
    return switch (config.scheduleType) {
      FixedScheduleType.daily => today.add(const Duration(days: 1)),
      FixedScheduleType.weekly => today.add(const Duration(days: 7)),
      FixedScheduleType.oneTime => today,
      FixedScheduleType.everyXDays => today.add(Duration(days: interval)),
      FixedScheduleType.everyXWeeks => today.add(Duration(days: interval * 7)),
      FixedScheduleType.monthly => _addMonthsClamped(
        today,
        interval,
        preferredDay: today.day,
      ),
    };
  }

  DateTime _addMonthsClamped(
    DateTime value,
    int months, {
    required int preferredDay,
  }) {
    final monthIndex = value.month - 1 + months;
    final targetYear = value.year + monthIndex ~/ 12;
    final targetMonth = monthIndex % 12 + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = preferredDay.clamp(1, lastDay);
    return DateTime(targetYear, targetMonth, day);
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

  Future<bool> _canActOnPack(ItemPack pack, String actorUserId) {
    if (pack.packType != ItemPackType.shared) {
      return Future.value(true);
    }
    return _dao.isActivePackMember(packId: pack.id, userId: actorUserId);
  }

  int? _fixedAnchorDate(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  int? _fixedDueDate(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.dueDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  String? _fixedTimeOfDay(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.timeOfDay,
      _ => null,
    };
  }

  String? _fixedOverduePolicy(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.overduePolicy.name,
      _ => null,
    };
  }

  Duration? _fixedInfoBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.infoBefore,
      _ => null,
    };
  }

  Duration? _fixedWarningBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.warningBefore,
      _ => null,
    };
  }

  Duration? _fixedDangerBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.dangerBefore,
      _ => null,
    };
  }

  Duration? _stateInfoAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.infoAfter,
      _ => null,
    };
  }

  int? _stateAnchorDate(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  Duration? _stateWarningAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.warningAfter,
      _ => null,
    };
  }

  Duration? _stateDangerAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.dangerAfter,
      _ => null,
    };
  }

  int? _resourceTimeAnchorDate(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  int? _resourceTimeDurationDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.durationDays,
      _ => null,
    };
  }

  int? _resourceTimeInfoBeforeDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.infoBeforeDays,
      _ => null,
    };
  }

  int? _resourceTimeWarningBeforeDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.warningBeforeDays,
      _ => null,
    };
  }

  int? _resourceTimeDangerBeforeDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.dangerBeforeDays,
      _ => null,
    };
  }

  int? _resourceQuantityCurrent(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity =>
        quantity.currentQuantity < 0 ? 0 : quantity.currentQuantity,
      _ => null,
    };
  }

  String? _resourceQuantityUnitLabel(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.unitLabel,
      _ => null,
    };
  }

  int? _resourceQuantityInfoThreshold(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.infoThreshold,
      _ => null,
    };
  }

  int? _resourceQuantityWarningThreshold(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.warningThreshold,
      _ => null,
    };
  }

  int? _resourceQuantityDangerThreshold(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.dangerThreshold,
      _ => null,
    };
  }

  int? _resourceInitialLastRefilledAt(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  int? _durationMinutes(Duration? value) {
    return value?.inMinutes;
  }

  int? _snapshotLastDoneAtForCreate(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig _ => null,
      _ => null,
    };
  }

  Value<int?> _dateValue(SnapshotValue<DateTime> value) {
    if (!value.present) {
      return const Value.absent();
    }
    return Value(value.value?.millisecondsSinceEpoch);
  }

  Value<String?> _stringValue(SnapshotValue<String> value) {
    if (!value.present) {
      return const Value.absent();
    }
    return Value(value.value);
  }

  List<ItemHistoryEntry> _buildHistoryEntries(
    List<ItemHistoryActionResourceRow> rows,
  ) {
    final actionsById = <int, ItemActionRecord>{};
    final resourceActionsByItemActionId = <int, List<_ResourceImpactSource>>{};
    for (final row in rows) {
      final action = row.actionRecord;
      actionsById[action.id] = action;
      final resourceAction = row.resourceActionRecord;
      if (resourceAction != null) {
        resourceActionsByItemActionId
            .putIfAbsent(action.id, () => <_ResourceImpactSource>[])
            .add(
              _ResourceImpactSource(
                action: resourceAction,
                resource: row.resource,
              ),
            );
      }
    }

    final entries = <ItemHistoryEntry>[];
    for (final action in actionsById.values) {
      if (action.actionType == ItemActionType.reverted) {
        continue;
      }
      final revertedAction = _revertedActionFor(action, actionsById);
      final resourceImpacts = <ItemResourceImpactEntry>[
        ..._resourceImpactsFor(
          resourceActionsByItemActionId[action.id] ?? const [],
          isCompensation: false,
        ),
        if (revertedAction != null)
          ..._resourceImpactsFor(
            resourceActionsByItemActionId[revertedAction.id] ?? const [],
            isCompensation: true,
          ),
      ];
      entries.add(
        ItemHistoryEntry(
          id: '${action.actionType.name}-${action.id}',
          actionRecordId: action.id,
          actionType: action.actionType,
          actionDate: action.actionDate,
          titleLabel: _itemHistoryTitleFor(action, revertedAction),
          revertedAt: action.revertedAt ?? revertedAction?.actionDate,
          revertedActionRecordId:
              action.revertedByActionRecordId ?? revertedAction?.id,
          remark: action.remark,
          resourceImpacts: resourceImpacts,
        ),
      );
    }
    entries.sort((a, b) {
      final dateCompare = b.actionDate.compareTo(a.actionDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return b.actionRecordId.compareTo(a.actionRecordId);
    });
    return entries;
  }

  ItemActionRecord? _revertedActionFor(
    ItemActionRecord action,
    Map<int, ItemActionRecord> actionsById,
  ) {
    final directId = action.revertedByActionRecordId;
    if (directId != null) {
      return actionsById[directId];
    }
    for (final candidate in actionsById.values) {
      if (candidate.actionType != ItemActionType.reverted) {
        continue;
      }
      if (candidate.payload?['revertedActionRecordId'] == action.id) {
        return candidate;
      }
    }
    return null;
  }

  String _itemHistoryTitleFor(
    ItemActionRecord action,
    ItemActionRecord? revertedAction,
  ) {
    if (action.actionType == ItemActionType.done && revertedAction != null) {
      return '完成，後來已回復';
    }
    if (action.actionType == ItemActionType.done) {
      return '完成';
    }
    return switch (action.actionType) {
      ItemActionType.created => '新增',
      ItemActionType.skipped => '跳過',
      ItemActionType.deferred => '延期',
      ItemActionType.reverted => '已回復',
      ItemActionType.done => '完成',
    };
  }

  List<ItemResourceImpactEntry> _resourceImpactsFor(
    List<_ResourceImpactSource> sources, {
    required bool isCompensation,
  }) {
    final expectedType = isCompensation
        ? ResourceActionType.reverted
        : ResourceActionType.consumed;
    return sources
        .where((source) => source.action.actionType == expectedType)
        .map(
          (source) => ItemResourceImpactEntry(
            resourceId: source.action.resourceId,
            resourceTitle: source.resource?.title ?? '已封存資源',
            amount: source.action.amount ?? 0,
            unitLabel: _resourceUnitLabel(source.resource),
            isCompensation: isCompensation,
          ),
        )
        .toList(growable: false);
  }

  String _resourceUnitLabel(Resource? resource) {
    final config = resource?.config;
    if (config is QuantityBasedResourceConfig &&
        config.unitLabel.trim().isNotEmpty) {
      return config.unitLabel.trim();
    }
    return '個';
  }

  Map<int, HomeItemSyncStatus> _buildHomeItemSyncStatuses(
    List<RemotePackSyncMetadataEntry> packMetadataEntries,
    List<RemoteItemSyncMetadataEntry> itemMetadataEntries,
    List<SyncOutboxEntry> outboxEntries,
  ) {
    final remoteBackedPacks = {
      for (final entry in packMetadataEntries)
        if (entry.syncKind == RemotePackSyncKind.remoteBacked)
          entry.localPackId: entry,
    };
    if (remoteBackedPacks.isEmpty) {
      return const <int, HomeItemSyncStatus>{};
    }

    final outboxByItemId = <int, SyncOutboxEntry>{};
    for (final entry in outboxEntries) {
      final localItemId = _localItemIdFromOutbox(entry);
      if (localItemId == null) {
        continue;
      }
      final current = outboxByItemId[localItemId];
      if (current == null ||
          _outboxPriority(entry) > _outboxPriority(current)) {
        outboxByItemId[localItemId] = entry;
      }
    }

    final result = <int, HomeItemSyncStatus>{};
    for (final itemMetadata in itemMetadataEntries) {
      final packMetadata = remoteBackedPacks[itemMetadata.localPackId];
      if (packMetadata == null) {
        continue;
      }
      final outbox = outboxByItemId[itemMetadata.localItemId];
      result[itemMetadata.localItemId] = HomeItemSyncStatus(
        isRemoteBacked: true,
        remotePackSyncState: packMetadata.syncState,
        remoteItemSyncState: itemMetadata.syncState,
        pendingMutationAction: outbox?.actionType,
        pendingMutationStatus: outbox?.status,
        lastSyncError: _firstNonEmpty([
          outbox?.lastError,
          itemMetadata.lastSyncError,
          packMetadata.lastSyncError,
        ]),
      );
    }
    return result;
  }

  int? _localItemIdFromOutbox(SyncOutboxEntry entry) {
    try {
      final payload = jsonDecode(entry.payloadJson);
      if (payload is Map<String, Object?>) {
        final value = payload['localItemId'];
        if (value is int) {
          return value;
        }
        if (value is String) {
          return int.tryParse(value);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  int _outboxPriority(SyncOutboxEntry entry) {
    final statusPriority = switch (entry.status) {
      SyncOutboxStatus.syncing => 60,
      SyncOutboxStatus.pending => 50,
      SyncOutboxStatus.failed => 40,
      SyncOutboxStatus.conflict => 40,
      SyncOutboxStatus.noOp => 30,
      SyncOutboxStatus.cancelled => 0,
      SyncOutboxStatus.synced => 0,
    };
    return statusPriority * 1000000 +
        entry.updatedAt.millisecondsSinceEpoch.remainder(1000000);
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

Stream<T> _combineLatest3<A, B, C, T>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  T Function(A a, B b, C c) combine,
) {
  late StreamController<T> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  StreamSubscription<C>? subC;
  A? latestA;
  B? latestB;
  C? latestC;
  var streamAReady = false;
  var streamBReady = false;
  var streamCReady = false;

  void emitIfReady() {
    if (streamAReady && streamBReady && streamCReady) {
      controller.add(combine(latestA as A, latestB as B, latestC as C));
    }
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      subA = streamA.listen((value) {
        latestA = value;
        streamAReady = true;
        emitIfReady();
      }, onError: controller.addError);
      subB = streamB.listen((value) {
        latestB = value;
        streamBReady = true;
        emitIfReady();
      }, onError: controller.addError);
      subC = streamC.listen((value) {
        latestC = value;
        streamCReady = true;
        emitIfReady();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
      await subC?.cancel();
    },
  );
  return controller.stream;
}

class _ResourceImpactSource {
  const _ResourceImpactSource({required this.action, this.resource});

  final ResourceActionRecord action;
  final Resource? resource;
}

class _ItemUndoSnapshot {
  const _ItemUndoSnapshot({
    required this.fixedAnchorDate,
    required this.fixedDueDate,
    required this.fixedRepeatRuleV2,
    required this.stateAnchorDate,
    required this.lastDoneAt,
  });

  final int? fixedAnchorDate;
  final int? fixedDueDate;
  final String? fixedRepeatRuleV2;
  final int? stateAnchorDate;
  final int? lastDoneAt;

  Map<String, Object?> toPayload() {
    return {
      'fixedAnchorDate': fixedAnchorDate,
      'fixedDueDate': fixedDueDate,
      'fixedRepeatRuleV2': fixedRepeatRuleV2,
      'stateAnchorDate': stateAnchorDate,
      'lastDoneAt': lastDoneAt,
    };
  }

  ItemsCompanion toCompanion(DateTime updatedAt) {
    return ItemsCompanion(
      fixedAnchorDate: Value(fixedAnchorDate),
      fixedDueDate: Value(fixedDueDate),
      fixedRepeatRuleV2: Value(fixedRepeatRuleV2),
      stateAnchorDate: Value(stateAnchorDate),
      lastDoneAt: Value(lastDoneAt),
      updatedAt: Value(updatedAt.millisecondsSinceEpoch),
    );
  }
}

class _UndoDoneFailure implements Exception {
  const _UndoDoneFailure();
}
