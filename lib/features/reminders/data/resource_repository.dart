import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/item_action_record.dart';
import '../domain/item_pack.dart';
import '../domain/remote_sync.dart';
import '../domain/resource.dart';
import '../domain/resource_refill_service.dart';
import '../domain/resource_status_service.dart';
import '../domain/shared_pack.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_repository.dart';

class ResourceInput {
  const ResourceInput({
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.packId,
  });

  final String title;
  final String? description;
  final ResourceType type;
  final ResourceConfig config;
  final int? packId;
}

class ResourceConsumptionRuleInput {
  const ResourceConsumptionRuleInput({
    required this.resourceId,
    required this.itemId,
    this.triggerActionType = ItemActionType.done,
    this.consumeAmount = 1,
    this.isEnabled = true,
  });

  final int resourceId;
  final int itemId;
  final ItemActionType triggerActionType;
  final int consumeAmount;
  final bool isEnabled;
}

class ResourceRepository {
  ResourceRepository(
    this._dao, {
    ResourceStatusService? statusService,
    ResourceRefillService? refillService,
    DateTime Function()? clock,
    Future<String> Function()? currentActorId,
  }) : _statusService = statusService ?? const ResourceStatusService(),
       _refillService = refillService ?? const ResourceRefillService(),
       _clock = clock ?? DateTime.now,
       _currentActorId = currentActorId;

  static const managedResourceStatuses = {
    ResourceLifecycleStatus.active,
    ResourceLifecycleStatus.paused,
  };
  static const remoteBackedUnsupportedMessage = '共同生活場景暫時未支援這個資源操作';
  static const _pendingRemoteResourceIdPrefix = 'pending_resource:';

  final ReminderDao _dao;
  final ResourceStatusService _statusService;
  final ResourceRefillService _refillService;
  final DateTime Function() _clock;
  final Future<String> Function()? _currentActorId;

  Stream<List<ResourceBundle>> watchResources() => _dao.watchResourceBundles(
    statuses: const {ResourceLifecycleStatus.active},
  );

  Stream<List<ResourceBundle>> watchManagedResources() =>
      _dao.watchResourceBundles(statuses: managedResourceStatuses);

  Stream<List<ResourceBundle>> watchResourcesByStatus(
    ResourceStatus status, {
    DateTime? now,
  }) {
    final current = now ?? _clock();
    return watchResources().map(
      (items) => items
          .where(
            (bundle) =>
                _statusService.classify(bundle.resource, now: current) ==
                status,
          )
          .toList(growable: false),
    );
  }

  Future<ResourceBundle?> getResourceById(int id) {
    return _dao.getResourceBundleById(id);
  }

  Stream<List<ResourceConsumptionRule>> watchRulesForItem(int itemId) {
    return _dao.watchConsumptionRulesForItem(itemId);
  }

  Future<List<ResourceConsumptionRule>> listRulesForItem(int itemId) {
    return _dao.listConsumptionRulesForItem(itemId);
  }

  Stream<List<ResourceActionRecord>> watchActionHistory(
    int resourceId, {
    bool includeReverted = false,
  }) {
    return _dao.watchResourceActionRecordsForResource(
      resourceId,
      includeReverted: includeReverted,
    );
  }

  Stream<List<ResourceActionHistoryEntry>> watchActionHistoryEntries(
    int resourceId, {
    bool includeReverted = false,
  }) {
    return _dao.watchResourceActionHistoryEntriesForResource(
      resourceId,
      includeReverted: includeReverted,
    );
  }

  Stream<List<ResourceActionEntry>> watchCompletedActionEntriesForDate(
    DateTime date,
  ) {
    final start = _normalizeDate(date);
    return _dao.watchResourceActionEntriesForDateRange(
      actionTypes: const {
        ResourceActionType.refilled,
        ResourceActionType.adjusted,
      },
      actionDateFrom: start,
      actionDateBefore: start.add(const Duration(days: 1)),
    );
  }

  Future<List<ResourceActionRecord>> listActionHistory(
    int resourceId, {
    bool includeReverted = false,
  }) {
    return _dao.listResourceActionRecordsForResource(
      resourceId,
      includeReverted: includeReverted,
    );
  }

  Future<List<ResourceEvent>> listResourceEventsForResource(int resourceId) {
    return _dao.listResourceEventsForResource(resourceId);
  }

  Future<List<ResourceEvent>> listResourceEventsForPack(int packId) {
    return _dao.listResourceEventsForPack(packId);
  }

  Stream<List<ResourceBinding>> watchBindings(int resourceId) {
    return _dao.watchResourceBindings(resourceId);
  }

  ResourceStatus statusFor(Resource resource, {DateTime? now}) {
    return _statusService.classify(resource, now: now);
  }

  int? remainingDaysFor(Resource resource, {DateTime? now}) {
    final config = resource.config;
    if (config is! TimeBasedResourceConfig) {
      return null;
    }
    return _statusService.timeBasedRemainingDays(config, now: now);
  }

  Future<int> createResource(ResourceInput input) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final packId = input.packId ?? await _ensureDefaultPackId(now);
      if (await _dao.isRemoteBackedPack(packId)) {
        return _createRemoteBackedResourceLocally(
          input,
          packId: packId,
          now: now,
        );
      }
      await _assertPackCanAcceptResources(packId);
      final resourceId = await _dao.insertResource(
        _resourceCompanion(input, packId: packId, now: now),
      );
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: resourceId,
          actionType: ResourceActionType.created.name,
          actionDate: _normalizeDate(now).millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return resourceId;
    });
  }

  Future<bool> updateResource(int id, ResourceInput input) async {
    final existing = await getResourceById(id);
    if (existing == null || existing.resource.type != input.type) {
      return false;
    }
    final now = _clock();
    final packId = input.packId ?? existing.resource.packId;
    final existingRemoteBacked = await _dao.isRemoteBackedPack(
      existing.resource.packId,
    );
    final targetRemoteBacked = await _dao.isRemoteBackedPack(packId);
    if (existingRemoteBacked || targetRemoteBacked) {
      if (!existingRemoteBacked ||
          !targetRemoteBacked ||
          packId != existing.resource.packId) {
        return false;
      }
      return _updateRemoteBackedResourceLocally(existing, input, now: now);
    }
    await _assertPackCanAcceptResources(packId, existing: existing.resource);
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceRecord(
        ResourceRow(
          id: existing.resource.id,
          packId: packId,
          title: input.title,
          description: input.description,
          status: existing.resource.status.name,
          type: input.type.name,
          timeAnchorDate: _timeAnchorDate(input.config),
          timeDurationDays: _timeDurationDays(input.config),
          timeExpectedBeforeDays: _timeInfoBeforeDays(input.config),
          timeWarningBeforeDays: _timeWarningBeforeDays(input.config),
          timeDangerBeforeDays: _timeDangerBeforeDays(input.config),
          quantityCurrent: _quantityCurrent(input.config),
          quantityUnitLabel: _quantityUnitLabel(input.config),
          quantityExpectedThreshold: _quantityInfoThreshold(input.config),
          quantityWarningThreshold: _quantityWarningThreshold(input.config),
          quantityDangerThreshold: _quantityDangerThreshold(input.config),
          lastRefilledAt:
              existing.resource.lastRefilledAt?.millisecondsSinceEpoch,
          createdAt: existing.resource.createdAt.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      if (!updated) {
        return false;
      }
      if (packId != existing.resource.packId) {
        await _dao.disableConsumptionRulesForResource(id);
      }
      return true;
    });
  }

  Future<bool> moveResourceToPack(
    int resourceId, {
    required int targetPackId,
  }) async {
    final existing = await getResourceById(resourceId);
    if (existing == null ||
        existing.resource.status == ResourceLifecycleStatus.archived) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.resource.packId) ||
        await _dao.isRemoteBackedPack(targetPackId)) {
      return false;
    }
    await _assertPackCanAcceptResources(
      targetPackId,
      existing: existing.resource,
    );
    if (targetPackId == existing.resource.packId) {
      return true;
    }
    return _dao.attachedDatabase.transaction(() async {
      final moved = await _dao.moveResourceToPackById(resourceId, targetPackId);
      if (!moved) {
        return false;
      }
      await _dao.disableConsumptionRulesForResource(resourceId);
      return true;
    });
  }

  Future<bool> archiveResource(int resourceId) async {
    final existing = await getResourceById(resourceId);
    if (existing == null) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.resource.packId)) {
      return _archiveRemoteBackedResourceLocally(existing, now: _clock());
    }
    final now = _clock();
    return _dao.updateResourceFields(
      resourceId,
      ResourcesCompanion(
        status: Value(ResourceLifecycleStatus.archived.name),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<bool> refillResource(
    int resourceId, {
    DateTime? actionAt,
    int? addedDays,
    int? addedQuantity,
    String? remark,
  }) async {
    final existing = await getResourceById(resourceId);
    if (existing == null) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.resource.packId)) {
      return _refillRemoteBackedResourceLocally(
        existing,
        actionAt: actionAt,
        addedDays: addedDays,
        addedQuantity: addedQuantity,
        remark: remark,
      );
    }
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    return _dao.attachedDatabase.transaction(() async {
      final resource = existing.resource;
      switch (resource.config) {
        case TimeBasedResourceConfig config:
          final days = addedDays ?? 0;
          if (days <= 0) {
            return false;
          }
          final refill = _refillService.refillTimeBased(
            config,
            actionDate: actionDate,
            addedDays: days,
          );
          final updated = await _dao.updateResourceFields(
            resourceId,
            ResourcesCompanion(
              timeAnchorDate: Value(refill.anchorDate.millisecondsSinceEpoch),
              timeDurationDays: Value(refill.durationDays),
              lastRefilledAt: Value(actionDate.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
          if (!updated) {
            return false;
          }
          await _dao.insertResourceActionRecord(
            ResourceActionRecordsCompanion.insert(
              resourceId: resourceId,
              actionType: ResourceActionType.refilled.name,
              actionDate: actionDate.millisecondsSinceEpoch,
              addedDays: Value(days),
              resultingDurationDays: Value(refill.durationDays),
              remark: Value(remark),
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
            ),
          );
          return true;
        case QuantityBasedResourceConfig config:
          final quantity = addedQuantity ?? 0;
          if (quantity <= 0) {
            return false;
          }
          final resultingQuantity = _refillService.refillQuantity(
            config,
            quantity,
          );
          final updated = await _dao.updateResourceFields(
            resourceId,
            ResourcesCompanion(
              quantityCurrent: Value(resultingQuantity),
              lastRefilledAt: Value(actionDate.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
          if (!updated) {
            return false;
          }
          await _dao.insertResourceActionRecord(
            ResourceActionRecordsCompanion.insert(
              resourceId: resourceId,
              actionType: ResourceActionType.refilled.name,
              actionDate: actionDate.millisecondsSinceEpoch,
              amount: Value(quantity),
              resultingQuantity: Value(resultingQuantity),
              remark: Value(remark),
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
            ),
          );
          return true;
        default:
          return false;
      }
    });
  }

  Future<bool> adjustResourceQuantity(
    int resourceId, {
    required int newQuantity,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) async {
    final existing = await getResourceById(resourceId);
    if (existing == null ||
        existing.resource.config is! QuantityBasedResourceConfig) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.resource.packId)) {
      return _adjustRemoteBackedQuantityLocally(
        existing,
        newQuantity: newQuantity,
        actionAt: actionAt,
        remark: remark,
        actorUserId: actorUserId,
      );
    }
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    final actor = await _resolveActorId(actorUserId);
    if (!await _canActOnPack(existing.pack, actor)) {
      return false;
    }
    final resultingQuantity = _refillService.adjustQuantity(newQuantity);
    return _dao.attachedDatabase.transaction(() async {
      final config = existing.resource.config as QuantityBasedResourceConfig;
      final updated = await _dao.updateResourceFields(
        resourceId,
        ResourcesCompanion(
          quantityCurrent: Value(resultingQuantity),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: resourceId,
          actionType: ResourceActionType.adjusted.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          resultingQuantity: Value(resultingQuantity),
          remark: Value(remark),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _insertResourceEvent(
        resourceId: resourceId,
        packId: existing.resource.packId,
        actorUserId: actor,
        changeType: ResourceEventChangeType.adjust,
        previousValue: config.currentQuantity,
        newValue: resultingQuantity,
        deltaValue: null,
        unit: config.unitLabel,
        metadata: {'resource_action': ResourceActionType.adjusted.name},
        now: now,
      );
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor,
        entityType: 'resource',
        entityId: resourceId,
        action: 'resource_adjusted',
        beforeJson: _jsonObject({'quantity': config.currentQuantity}),
        afterJson: _jsonObject({'quantity': resultingQuantity}),
        now: now,
      );
      return true;
    });
  }

  Future<bool> incrementResourceQuantity(
    int resourceId, {
    required int amount,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) {
    return _changeResourceQuantityByDelta(
      resourceId,
      amount: amount,
      changeType: ResourceEventChangeType.increment,
      actionAt: actionAt,
      remark: remark,
      actorUserId: actorUserId,
    );
  }

  Future<bool> decrementResourceQuantity(
    int resourceId, {
    required int amount,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) {
    return _changeResourceQuantityByDelta(
      resourceId,
      amount: -amount,
      changeType: ResourceEventChangeType.decrement,
      actionAt: actionAt,
      remark: remark,
      actorUserId: actorUserId,
    );
  }

  Future<bool> _changeResourceQuantityByDelta(
    int resourceId, {
    required int amount,
    required ResourceEventChangeType changeType,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) async {
    if (amount == 0) {
      return false;
    }
    final existing = await getResourceById(resourceId);
    if (existing == null ||
        existing.resource.config is! QuantityBasedResourceConfig) {
      return false;
    }
    if (await _dao.isRemoteBackedPack(existing.resource.packId)) {
      return _changeRemoteBackedQuantityByDeltaLocally(
        existing,
        amount: amount,
        changeType: changeType,
        actionAt: actionAt,
        remark: remark,
        actorUserId: actorUserId,
      );
    }
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    final actor = await _resolveActorId(actorUserId);
    if (!await _canActOnPack(existing.pack, actor)) {
      return false;
    }
    final config = existing.resource.config as QuantityBasedResourceConfig;
    final resultingQuantity = _refillService.adjustQuantity(
      config.currentQuantity + amount,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceFields(
        resourceId,
        ResourcesCompanion(
          quantityCurrent: Value(resultingQuantity),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: resourceId,
          actionType: ResourceActionType.adjusted.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          amount: Value(amount.abs()),
          resultingQuantity: Value(resultingQuantity),
          remark: Value(remark),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _insertResourceEvent(
        resourceId: resourceId,
        packId: existing.resource.packId,
        actorUserId: actor,
        changeType: changeType,
        previousValue: config.currentQuantity,
        newValue: resultingQuantity,
        deltaValue: amount,
        unit: config.unitLabel,
        metadata: {'resource_action': ResourceActionType.adjusted.name},
        now: now,
      );
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor,
        entityType: 'resource',
        entityId: resourceId,
        action: changeType == ResourceEventChangeType.increment
            ? 'resource_incremented'
            : 'resource_decremented',
        beforeJson: _jsonObject({'quantity': config.currentQuantity}),
        afterJson: _jsonObject({'quantity': resultingQuantity}),
        now: now,
      );
      return true;
    });
  }

  Future<int> createConsumptionRule(ResourceConsumptionRuleInput input) async {
    final resource = await _dao.getResourceBundleById(input.resourceId);
    final item = await _dao.getItemBundleById(input.itemId);
    if ((resource != null &&
            await _dao.isRemoteBackedPack(resource.resource.packId)) ||
        (item != null && await _dao.isRemoteBackedPack(item.item.packId))) {
      throw StateError(remoteBackedUnsupportedMessage);
    }
    final now = _clock();
    return _dao.insertResourceConsumptionRule(
      ResourceConsumptionRulesCompanion.insert(
        resourceId: input.resourceId,
        itemId: input.itemId,
        triggerActionType: Value(input.triggerActionType.name),
        consumeAmount: Value(input.consumeAmount < 1 ? 1 : input.consumeAmount),
        isEnabled: Value(input.isEnabled),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<int> _createRemoteBackedResourceLocally(
    ResourceInput input, {
    required int packId,
    required DateTime now,
  }) async {
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      packId,
    );
    if (packMetadata == null ||
        packMetadata.syncKind != RemotePackSyncKind.remoteBacked ||
        _isRemoteAccessLost(packMetadata)) {
      throw StateError(remoteBackedUnsupportedMessage);
    }
    final actor = await _resolveActorUser(await _resolveActorId(null));
    final clientMutationId = _remoteBackedClientMutationId(
      'create_resource',
      packId,
      now,
    );
    final resourceId = await _dao.insertResource(
      _resourceCompanion(input, packId: packId, now: now),
    );
    await _dao.insertResourceActionRecord(
      ResourceActionRecordsCompanion.insert(
        resourceId: resourceId,
        actionType: ResourceActionType.created.name,
        actionDate: _normalizeDate(now).millisecondsSinceEpoch,
        resultingQuantity: Value(_quantityCurrent(input.config)),
        resultingDurationDays: Value(_timeDurationDays(input.config)),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await _insertActivityEvent(
      packId: packId,
      actorUserId: actor.id,
      entityType: 'resource',
      entityId: resourceId,
      action: 'resource_created',
      metadataJson: _jsonObject({
        'remoteBackedPending': true,
        'syncActionType': SyncOutboxActionType.createResource.storageValue,
        'clientMutationId': clientMutationId,
      }),
      now: now,
    );
    await _dao.insertRemoteResourceSyncMetadata(
      RemoteResourceSyncMetadataCompanion.insert(
        localResourceId: resourceId,
        localPackId: packId,
        remoteResourceId: '$_pendingRemoteResourceIdPrefix$clientMutationId',
        remotePackId: packMetadata.remotePackId,
        syncState: RemoteResourceSyncState.pendingPush.storageValue,
        remoteStatus: const Value('active'),
        lastSyncError: const Value(null),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await _enqueueRemoteBackedResourceMutation(
      actionType: SyncOutboxActionType.createResource,
      localPackId: packId,
      remotePackId: packMetadata.remotePackId,
      localResourceId: resourceId,
      remoteResourceId: null,
      clientMutationId: clientMutationId,
      actor: actor,
      actionAt: now,
      fields: _resourceFields(input),
    );
    await _markRemoteBackedPackStale(packMetadata, now);
    return resourceId;
  }

  Future<bool> _updateRemoteBackedResourceLocally(
    ResourceBundle existing,
    ResourceInput input, {
    required DateTime now,
  }) async {
    final remoteResourceId = await _remoteResourceIdForLocalResource(
      existing.resource.id,
    );
    if (remoteResourceId == null) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.resource.packId,
    );
    if (packMetadata == null || _isRemoteAccessLost(packMetadata)) {
      return false;
    }
    final actor = await _resolveActorUser(await _resolveActorId(null));
    final clientMutationId = _remoteBackedClientMutationId(
      'update_resource',
      existing.resource.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceRecord(
        ResourceRow(
          id: existing.resource.id,
          packId: existing.resource.packId,
          title: input.title,
          description: input.description,
          status: existing.resource.status.name,
          type: input.type.name,
          timeAnchorDate: _timeAnchorDate(input.config),
          timeDurationDays: _timeDurationDays(input.config),
          timeExpectedBeforeDays: _timeInfoBeforeDays(input.config),
          timeWarningBeforeDays: _timeWarningBeforeDays(input.config),
          timeDangerBeforeDays: _timeDangerBeforeDays(input.config),
          quantityCurrent: _quantityCurrent(input.config),
          quantityUnitLabel: _quantityUnitLabel(input.config),
          quantityExpectedThreshold: _quantityInfoThreshold(input.config),
          quantityWarningThreshold: _quantityWarningThreshold(input.config),
          quantityDangerThreshold: _quantityDangerThreshold(input.config),
          lastRefilledAt:
              existing.resource.lastRefilledAt?.millisecondsSinceEpoch,
          createdAt: existing.resource.createdAt.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      if (!updated) {
        return false;
      }
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor.id,
        entityType: 'resource',
        entityId: existing.resource.id,
        action: 'resource_updated',
        beforeJson: _jsonObject(_resourceSnapshotFields(existing.resource)),
        afterJson: _jsonObject(_resourceFields(input)),
        metadataJson: _jsonObject({
          'remoteBackedPending': true,
          'syncActionType': SyncOutboxActionType.updateResource.storageValue,
          'clientMutationId': clientMutationId,
        }),
        now: now,
      );
      await _markRemoteBackedResourcePendingPush(existing.resource.id, now);
      await _enqueueRemoteBackedResourceMutation(
        actionType: SyncOutboxActionType.updateResource,
        localPackId: existing.resource.packId,
        remotePackId: packMetadata.remotePackId,
        localResourceId: existing.resource.id,
        remoteResourceId: remoteResourceId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: now,
        fields: _resourceFields(input),
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<bool> _archiveRemoteBackedResourceLocally(
    ResourceBundle existing, {
    required DateTime now,
  }) async {
    final remoteResourceId = await _remoteResourceIdForLocalResource(
      existing.resource.id,
    );
    if (remoteResourceId == null) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.resource.packId,
    );
    if (packMetadata == null || _isRemoteAccessLost(packMetadata)) {
      return false;
    }
    final actor = await _resolveActorUser(await _resolveActorId(null));
    final clientMutationId = _remoteBackedClientMutationId(
      'archive_resource',
      existing.resource.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceFields(
        existing.resource.id,
        ResourcesCompanion(
          status: Value(ResourceLifecycleStatus.archived.name),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor.id,
        entityType: 'resource',
        entityId: existing.resource.id,
        action: 'resource_archived',
        metadataJson: _jsonObject({
          'remoteBackedPending': true,
          'syncActionType': SyncOutboxActionType.archiveResource.storageValue,
          'clientMutationId': clientMutationId,
        }),
        now: now,
      );
      await _markRemoteBackedResourcePendingPush(existing.resource.id, now);
      await _enqueueRemoteBackedResourceMutation(
        actionType: SyncOutboxActionType.archiveResource,
        localPackId: existing.resource.packId,
        remotePackId: packMetadata.remotePackId,
        localResourceId: existing.resource.id,
        remoteResourceId: remoteResourceId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: now,
        fields: const {'status': 'archived'},
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<bool> _refillRemoteBackedResourceLocally(
    ResourceBundle existing, {
    DateTime? actionAt,
    int? addedDays,
    int? addedQuantity,
    String? remark,
  }) async {
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    final actor = await _resolveActorUser(await _resolveActorId(null));
    if (!await _canActOnPack(existing.pack, actor.id)) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.resource.packId,
    );
    final remoteResourceId = await _remoteResourceIdForLocalResource(
      existing.resource.id,
    );
    if (packMetadata == null ||
        _isRemoteAccessLost(packMetadata) ||
        remoteResourceId == null) {
      return false;
    }
    return switch (existing.resource.config) {
      TimeBasedResourceConfig config => _refillRemoteBackedTimeResource(
        existing,
        config: config,
        addedDays: addedDays,
        actionDate: actionDate,
        remark: remark,
        actor: actor,
        packMetadata: packMetadata,
        remoteResourceId: remoteResourceId,
        now: now,
      ),
      QuantityBasedResourceConfig _ =>
        _changeRemoteBackedQuantityByDeltaLocally(
          existing,
          amount: addedQuantity ?? 0,
          changeType: ResourceEventChangeType.increment,
          actionAt: actionDate,
          remark: remark,
          actorUserId: actor.id,
        ),
      _ => Future.value(false),
    };
  }

  Future<bool> _refillRemoteBackedTimeResource(
    ResourceBundle existing, {
    required TimeBasedResourceConfig config,
    required int? addedDays,
    required DateTime actionDate,
    required String? remark,
    required LocalUser actor,
    required RemotePackSyncMetadataEntry packMetadata,
    required String remoteResourceId,
    required DateTime now,
  }) async {
    final days = addedDays ?? 0;
    if (days <= 0) {
      return false;
    }
    final refill = _refillService.refillTimeBased(
      config,
      actionDate: actionDate,
      addedDays: days,
    );
    final clientMutationId = _remoteBackedClientMutationId(
      'resource_increment',
      existing.resource.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceFields(
        existing.resource.id,
        ResourcesCompanion(
          timeAnchorDate: Value(refill.anchorDate.millisecondsSinceEpoch),
          timeDurationDays: Value(refill.durationDays),
          lastRefilledAt: Value(actionDate.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: existing.resource.id,
          actionType: ResourceActionType.refilled.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          addedDays: Value(days),
          resultingDurationDays: Value(refill.durationDays),
          remark: Value(remark),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _insertResourceEvent(
        resourceId: existing.resource.id,
        packId: existing.resource.packId,
        actorUserId: actor.id,
        changeType: ResourceEventChangeType.increment,
        previousValue: config.durationDays,
        newValue: refill.durationDays,
        deltaValue: days,
        unit: '天',
        metadata: {
          'resource_action': ResourceActionType.refilled.name,
          'clientMutationId': clientMutationId,
        },
        now: now,
      );
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor.id,
        entityType: 'resource',
        entityId: existing.resource.id,
        action: 'resource_incremented',
        beforeJson: _jsonObject({'durationDays': config.durationDays}),
        afterJson: _jsonObject({'durationDays': refill.durationDays}),
        metadataJson: _jsonObject({'clientMutationId': clientMutationId}),
        now: now,
      );
      await _markRemoteBackedResourcePendingPush(existing.resource.id, now);
      await _enqueueRemoteBackedResourceMutation(
        actionType: SyncOutboxActionType.resourceIncrement,
        localPackId: existing.resource.packId,
        remotePackId: packMetadata.remotePackId,
        localResourceId: existing.resource.id,
        remoteResourceId: remoteResourceId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: actionDate,
        event: {
          'changeType': ResourceEventChangeType.increment.name,
          'deltaValue': days,
          'newValue': refill.durationDays,
          'unit': '天',
          'metadata': {'resource_action': ResourceActionType.refilled.name},
        },
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<bool> _adjustRemoteBackedQuantityLocally(
    ResourceBundle existing, {
    required int newQuantity,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) async {
    final config = existing.resource.config;
    if (config is! QuantityBasedResourceConfig) {
      return false;
    }
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    final actor = await _resolveActorUser(await _resolveActorId(actorUserId));
    if (!await _canActOnPack(existing.pack, actor.id)) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.resource.packId,
    );
    final remoteResourceId = await _remoteResourceIdForLocalResource(
      existing.resource.id,
    );
    if (packMetadata == null ||
        _isRemoteAccessLost(packMetadata) ||
        remoteResourceId == null) {
      return false;
    }
    final resultingQuantity = _refillService.adjustQuantity(newQuantity);
    final clientMutationId = _remoteBackedClientMutationId(
      'resource_adjust',
      existing.resource.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceFields(
        existing.resource.id,
        ResourcesCompanion(
          quantityCurrent: Value(resultingQuantity),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: existing.resource.id,
          actionType: ResourceActionType.adjusted.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          resultingQuantity: Value(resultingQuantity),
          remark: Value(remark),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _insertResourceEvent(
        resourceId: existing.resource.id,
        packId: existing.resource.packId,
        actorUserId: actor.id,
        changeType: ResourceEventChangeType.adjust,
        previousValue: config.currentQuantity,
        newValue: resultingQuantity,
        deltaValue: null,
        unit: config.unitLabel,
        metadata: {
          'resource_action': ResourceActionType.adjusted.name,
          'clientMutationId': clientMutationId,
        },
        now: now,
      );
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor.id,
        entityType: 'resource',
        entityId: existing.resource.id,
        action: 'resource_adjusted',
        beforeJson: _jsonObject({'quantity': config.currentQuantity}),
        afterJson: _jsonObject({'quantity': resultingQuantity}),
        metadataJson: _jsonObject({'clientMutationId': clientMutationId}),
        now: now,
      );
      await _markRemoteBackedResourcePendingPush(existing.resource.id, now);
      await _enqueueRemoteBackedResourceMutation(
        actionType: SyncOutboxActionType.resourceAdjust,
        localPackId: existing.resource.packId,
        remotePackId: packMetadata.remotePackId,
        localResourceId: existing.resource.id,
        remoteResourceId: remoteResourceId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: actionDate,
        event: {
          'changeType': ResourceEventChangeType.adjust.name,
          'newValue': resultingQuantity,
          'unit': config.unitLabel,
          'metadata': {'resource_action': ResourceActionType.adjusted.name},
        },
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<bool> _changeRemoteBackedQuantityByDeltaLocally(
    ResourceBundle existing, {
    required int amount,
    required ResourceEventChangeType changeType,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) async {
    if (amount == 0) {
      return false;
    }
    final config = existing.resource.config;
    if (config is! QuantityBasedResourceConfig) {
      return false;
    }
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    final actor = await _resolveActorUser(await _resolveActorId(actorUserId));
    if (!await _canActOnPack(existing.pack, actor.id)) {
      return false;
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      existing.resource.packId,
    );
    final remoteResourceId = await _remoteResourceIdForLocalResource(
      existing.resource.id,
    );
    if (packMetadata == null ||
        _isRemoteAccessLost(packMetadata) ||
        remoteResourceId == null) {
      return false;
    }
    final resultingQuantity = _refillService.adjustQuantity(
      config.currentQuantity + amount,
    );
    final actionType = amount > 0
        ? SyncOutboxActionType.resourceIncrement
        : SyncOutboxActionType.resourceDecrement;
    final clientMutationId = _remoteBackedClientMutationId(
      actionType.storageValue,
      existing.resource.id,
      now,
    );
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateResourceFields(
        existing.resource.id,
        ResourcesCompanion(
          quantityCurrent: Value(resultingQuantity),
          lastRefilledAt: amount > 0
              ? Value(actionDate.millisecondsSinceEpoch)
              : const Value.absent(),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _dao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: existing.resource.id,
          actionType: amount > 0
              ? ResourceActionType.refilled.name
              : ResourceActionType.adjusted.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          amount: Value(amount.abs()),
          resultingQuantity: Value(resultingQuantity),
          remark: Value(remark),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _insertResourceEvent(
        resourceId: existing.resource.id,
        packId: existing.resource.packId,
        actorUserId: actor.id,
        changeType: changeType,
        previousValue: config.currentQuantity,
        newValue: resultingQuantity,
        deltaValue: amount,
        unit: config.unitLabel,
        metadata: {
          'resource_action': amount > 0
              ? ResourceActionType.refilled.name
              : ResourceActionType.adjusted.name,
          'clientMutationId': clientMutationId,
        },
        now: now,
      );
      await _insertActivityEvent(
        packId: existing.resource.packId,
        actorUserId: actor.id,
        entityType: 'resource',
        entityId: existing.resource.id,
        action: amount > 0 ? 'resource_incremented' : 'resource_decremented',
        beforeJson: _jsonObject({'quantity': config.currentQuantity}),
        afterJson: _jsonObject({'quantity': resultingQuantity}),
        metadataJson: _jsonObject({'clientMutationId': clientMutationId}),
        now: now,
      );
      await _markRemoteBackedResourcePendingPush(existing.resource.id, now);
      await _enqueueRemoteBackedResourceMutation(
        actionType: actionType,
        localPackId: existing.resource.packId,
        remotePackId: packMetadata.remotePackId,
        localResourceId: existing.resource.id,
        remoteResourceId: remoteResourceId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: actionDate,
        event: {
          'changeType': changeType.name,
          'deltaValue': amount,
          'newValue': resultingQuantity,
          'unit': config.unitLabel,
          'metadata': {
            'resource_action': amount > 0
                ? ResourceActionType.refilled.name
                : ResourceActionType.adjusted.name,
          },
        },
      );
      await _markRemoteBackedPackStale(packMetadata, now);
      return true;
    });
  }

  Future<bool> disableConsumptionRule(int id) {
    final now = _clock();
    return _dao.updateResourceConsumptionRuleFields(
      id,
      ResourceConsumptionRulesCompanion(
        isEnabled: const Value(false),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
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

  Future<void> _enqueueRemoteBackedResourceMutation({
    required SyncOutboxActionType actionType,
    required int localPackId,
    required String remotePackId,
    required int localResourceId,
    required String? remoteResourceId,
    required String clientMutationId,
    required LocalUser actor,
    required DateTime actionAt,
    Map<String, Object?> fields = const {},
    Map<String, Object?> event = const {},
  }) {
    final now = _clock();
    return _dao
        .insertSyncOutbox(
          SyncOutboxCompanion.insert(
            localPackId: localPackId,
            remotePackId: Value(remotePackId),
            localEntityType: RemoteSharedPackRepository.localEntityResource,
            localEntityId: Value(localResourceId),
            remoteEntityId: Value(remoteResourceId),
            actionType: actionType.storageValue,
            payloadJson: jsonEncode({
              'remotePackId': remotePackId,
              'remoteResourceId': remoteResourceId,
              'localPackId': localPackId,
              'localResourceId': localResourceId,
              'clientMutationId': clientMutationId,
              'actorLocalUserId': actor.id,
              'actorRemoteUserId': actor.remoteUserId,
              'actionAt': actionAt.toIso8601String(),
              if (fields.isNotEmpty) 'fields': fields,
              if (event.isNotEmpty) 'event': event,
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

  Future<void> _markRemoteBackedResourcePendingPush(
    int localResourceId,
    DateTime now,
  ) async {
    final metadata = await _dao.getRemoteResourceSyncMetadataForLocalResource(
      localResourceId,
    );
    if (metadata == null) {
      return;
    }
    await _dao.updateRemoteResourceSyncMetadata(
      metadata.id,
      RemoteResourceSyncMetadataCompanion(
        syncState: Value(RemoteResourceSyncState.pendingPush.storageValue),
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

  Future<String?> _remoteResourceIdForLocalResource(int localResourceId) async {
    final metadata = await _dao.getRemoteResourceSyncMetadataForLocalResource(
      localResourceId,
    );
    final remoteResourceId = metadata?.remoteResourceId;
    if (remoteResourceId != null &&
        !remoteResourceId.startsWith(_pendingRemoteResourceIdPrefix)) {
      return remoteResourceId;
    }
    final mapping = await _dao.getSyncMapping(
      localEntityType: RemoteSharedPackRepository.localEntityResource,
      localEntityId: localResourceId,
      remoteTable: RemoteSharedPackRepository.remoteTableResources,
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
    return 'phase6d_${action}_${localId}_${now.microsecondsSinceEpoch}';
  }

  Map<String, Object?> _resourceFields(ResourceInput input) {
    return {
      'title': input.title,
      'description': input.description,
      'type': input.type.name,
      'config': _resourceConfigPayload(input.config),
    };
  }

  Map<String, Object?> _resourceSnapshotFields(Resource resource) {
    return {
      'title': resource.title,
      'description': resource.description,
      'type': resource.type.name,
      'config': _resourceConfigPayload(resource.config),
    };
  }

  Map<String, Object?> _resourceConfigPayload(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => {
        'timeAnchorDate': time.anchorDate?.toUtc().toIso8601String(),
        'timeDurationDays': time.durationDays,
        'timeExpectedBeforeDays': time.infoBeforeDays,
        'timeWarningBeforeDays': time.warningBeforeDays,
        'timeDangerBeforeDays': time.dangerBeforeDays,
      },
      QuantityBasedResourceConfig quantity => {
        'quantityCurrent': _refillService.adjustQuantity(
          quantity.currentQuantity,
        ),
        'quantityUnitLabel': quantity.unitLabel,
        'quantityExpectedThreshold': quantity.infoThreshold,
        'quantityWarningThreshold': quantity.warningThreshold,
        'quantityDangerThreshold': quantity.dangerThreshold,
      },
      _ => const <String, Object?>{},
    };
  }

  Future<void> _insertResourceEvent({
    required int resourceId,
    required int packId,
    required String actorUserId,
    required ResourceEventChangeType changeType,
    required int? previousValue,
    required int? newValue,
    required int? deltaValue,
    required String? unit,
    required Map<String, Object?> metadata,
    required DateTime now,
  }) {
    return _dao.insertResourceEvent(
      ResourceEventsCompanion.insert(
        resourceId: resourceId,
        packId: packId,
        actorUserId: actorUserId,
        changeType: changeType.name,
        previousValue: Value(previousValue),
        newValue: Value(newValue),
        deltaValue: Value(deltaValue),
        unit: Value(unit),
        createdAt: now.millisecondsSinceEpoch,
        metadataJson: Value(_jsonObject(metadata)),
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

  ResourcesCompanion _resourceCompanion(
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
      timeAnchorDate: Value(_timeAnchorDate(input.config)),
      timeDurationDays: Value(_timeDurationDays(input.config)),
      timeExpectedBeforeDays: Value(_timeInfoBeforeDays(input.config)),
      timeWarningBeforeDays: Value(_timeWarningBeforeDays(input.config)),
      timeDangerBeforeDays: Value(_timeDangerBeforeDays(input.config)),
      quantityCurrent: Value(_quantityCurrent(input.config)),
      quantityUnitLabel: Value(_quantityUnitLabel(input.config)),
      quantityExpectedThreshold: Value(_quantityInfoThreshold(input.config)),
      quantityWarningThreshold: Value(_quantityWarningThreshold(input.config)),
      quantityDangerThreshold: Value(_quantityDangerThreshold(input.config)),
      lastRefilledAt: Value(_initialLastRefilledAt(input.config)),
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

  Future<void> _assertPackCanAcceptResources(
    int packId, {
    Resource? existing,
  }) async {
    final pack = await _dao.getItemPackById(packId);
    if (pack == null) {
      throw StateError('Item pack not found.');
    }
    if (await _dao.isRemoteBackedPack(pack.id)) {
      throw StateError(remoteBackedUnsupportedMessage);
    }
    if (pack.status == ItemPackStatus.active) {
      return;
    }
    if (existing != null && existing.packId == pack.id) {
      return;
    }
    throw StateError('Archived item pack cannot accept resources.');
  }

  int? _timeAnchorDate(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  int? _timeDurationDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.durationDays,
      _ => null,
    };
  }

  int? _timeInfoBeforeDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.infoBeforeDays,
      _ => null,
    };
  }

  int? _timeWarningBeforeDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.warningBeforeDays,
      _ => null,
    };
  }

  int? _timeDangerBeforeDays(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.dangerBeforeDays,
      _ => null,
    };
  }

  int? _quantityCurrent(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => _refillService.adjustQuantity(
        quantity.currentQuantity,
      ),
      _ => null,
    };
  }

  String? _quantityUnitLabel(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.unitLabel,
      _ => null,
    };
  }

  int? _quantityInfoThreshold(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.infoThreshold,
      _ => null,
    };
  }

  int? _quantityWarningThreshold(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.warningThreshold,
      _ => null,
    };
  }

  int? _quantityDangerThreshold(ResourceConfig config) {
    return switch (config) {
      QuantityBasedResourceConfig quantity => quantity.dangerThreshold,
      _ => null,
    };
  }

  int? _initialLastRefilledAt(ResourceConfig config) {
    return switch (config) {
      TimeBasedResourceConfig time => time.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
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
}
