import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/item.dart';
import '../domain/item_action_record.dart';
import '../domain/item_action_service.dart';
import '../domain/item_pack.dart';
import '../domain/item_pack_template.dart';
import '../domain/item_snapshot_update_service.dart';
import '../domain/item_status_service.dart';
import '../domain/resource.dart';
import '../domain/resource_refill_service.dart';
import 'builtin_item_pack_templates.dart';
import 'local/app_database.dart';
import 'local/item_timeline_dao.dart';
import 'resource_repository.dart';

class ItemInput {
  const ItemInput({
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.attentionPolicySource = AttentionPolicySource.systemDefault,
    this.packId,
  });

  final String title;
  final String? description;
  final ItemType type;
  final ItemConfig config;
  final AttentionPolicySource attentionPolicySource;
  final int? packId;
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

class ItemRepository {
  ItemRepository(
    this._dao, {
    ItemStatusService? statusService,
    ItemActionService? actionService,
    ItemSnapshotUpdateService? snapshotUpdateService,
    DateTime Function()? clock,
  }) : _statusService = statusService ?? const ItemStatusService(),
       _actionService = actionService ?? const ItemActionService(),
       _snapshotUpdateService =
           snapshotUpdateService ??
           ItemSnapshotUpdateService(statusService: statusService),
       _clock = clock ?? DateTime.now;

  static const managedItemStatuses = {
    ItemLifecycleStatus.active,
    ItemLifecycleStatus.paused,
  };
  static const majorActivityActionTypes = {
    ItemActionType.created,
    ItemActionType.done,
    ItemActionType.skipped,
  };

  final ItemTimelineDao _dao;
  final ItemStatusService _statusService;
  final ItemActionService _actionService;
  final ItemSnapshotUpdateService _snapshotUpdateService;
  final DateTime Function() _clock;

  Stream<List<ItemPack>> watchPacks({bool includeArchived = false}) =>
      _dao.watchItemPacks(includeArchived: includeArchived);

  Stream<List<ItemPackTemplate>> watchTemplates() =>
      _dao.watchCustomItemPackTemplates().map(
        (customTemplates) => [...builtinItemPackTemplates, ...customTemplates],
      );

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

  Stream<List<ItemActionRecord>> watchActionHistory(int itemId) {
    return _dao.watchItemActionRecordsForItem(itemId);
  }

  Future<List<ItemActionRecord>> listActionHistory(int itemId) {
    return _dao.listItemActionRecordsForItem(itemId);
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

  Future<ItemBundle?> getItemById(int id) => _dao.getItemBundleById(id);

  Future<ItemPack?> getPackById(int id) => _dao.getItemPackById(id);

  Future<ItemPackTemplate?> getTemplateById(String id) async {
    for (final template in builtinItemPackTemplates) {
      if (template.id == id) {
        return template;
      }
    }
    final customId = int.tryParse(id.replaceFirst('custom-', ''));
    if (customId == null) {
      return null;
    }
    return _dao.getCustomItemPackTemplateById(customId);
  }

  Future<int> createItem(
    ItemInput input, {
    List<ItemResourceBindingInput> resourceBindings = const [],
  }) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final packId = await _resolvePackId(input.packId, now);
      final itemId = await _createItemRecord(
        _copyItemInput(input, packId: packId),
        now: now,
      );
      await _insertCreatedAction(itemId, now: now);
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
  }) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final createdPackId = newPack == null
          ? null
          : await _dao.insertItemPack(_packCompanion(newPack, now: now));
      final packId = createdPackId ?? await _resolvePackId(item.packId, now);
      final itemId = await _createItemRecord(
        _copyItemInput(item, packId: packId),
        now: now,
      );
      await _insertCreatedAction(itemId, now: now);
      await _applyResourceBindingInputs(
        itemId: itemId,
        packId: packId,
        bindings: resourceBindings,
        now: now,
      );
      return itemId;
    });
  }

  Future<bool> moveItemToPack(
    int id, {
    int? packId,
    ItemPackInput? newPack,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final resolvedPackId = newPack != null
          ? await _dao.insertItemPack(_packCompanion(newPack, now: now))
          : packId ?? await _ensureDefaultPackId(now);
      await _assertPackCanAcceptItems(
        resolvedPackId,
        existingItem: existing.item,
      );
      return _dao.updateItemFields(
        id,
        ItemsCompanion(
          packId: Value(resolvedPackId),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    });
  }

  Future<bool> updateItem(int id, ItemInput input) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    if (input.type != existing.item.type) {
      return false;
    }
    final now = _clock();
    final packId = input.packId ?? existing.item.packId;
    await _assertPackCanAcceptItems(packId, existingItem: existing.item);
    return _dao.updateItemRecord(
      ItemRow(
        id: existing.item.id,
        packId: packId,
        title: input.title,
        description: input.description,
        status: existing.item.status.name,
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
        lastDoneAt: existing.item.lastDoneAt?.millisecondsSinceEpoch,
        createdAt: existing.item.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> markDone(
    int id, {
    DateTime? doneAt,
    String? remark,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
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
    return _recordAction(id, action: action);
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
    return _recordAction(id, action: action);
  }

  Future<bool> defer(
    int id, {
    required int deferDays,
    DateTime? actionAt,
    String? remark,
  }) async {
    return false;
  }

  Future<int> createPack(ItemPackInput input) async {
    final now = _clock();
    return _dao.insertItemPack(_packCompanion(input, now: now));
  }

  Future<bool> updatePack(int id, ItemPackInput input) async {
    final existing = await getPackById(id);
    if (existing == null ||
        existing.isSystemDefault ||
        existing.status == ItemPackStatus.archived) {
      return false;
    }
    final now = _clock();
    return _dao.updateItemPackRecord(
      ItemPackRow(
        id: existing.id,
        title: input.title,
        description: input.description,
        status: existing.status.name,
        isSystemDefault: existing.isSystemDefault,
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

  Future<bool> archivePack(int id) async {
    final existing = await getPackById(id);
    if (existing == null || !await canArchivePack(id)) {
      return false;
    }
    final now = _clock();
    final updated = await _dao.updateItemPackRecord(
      ItemPackRow(
        id: existing.id,
        title: existing.title,
        description: existing.description,
        status: ItemPackStatus.archived.name,
        isSystemDefault: existing.isSystemDefault,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    if (!updated) {
      return false;
    }
    await _dao.updateItemsStatusForPack(id, ItemLifecycleStatus.archived);
    return true;
  }

  Future<int> applyTemplate(ItemPackTemplate template) async {
    final now = _clock();
    final today = _normalizeDate(now);
    return _dao.attachedDatabase.transaction(() async {
      final packId = await _dao.insertItemPack(
        _packCompanion(
          ItemPackInput(
            title: '${template.name}(模版)',
            description: template.description,
          ),
          now: now,
        ),
      );
      final itemIdsByLogicalId = <String, int>{};
      for (final templateItem in template.items) {
        final itemId = await _createItemRecord(
          ItemInput(
            title: templateItem.title,
            description: templateItem.description,
            type: templateItem.type,
            config: _configForTemplateApply(templateItem.config, today),
            attentionPolicySource: templateItem.attentionPolicySource,
            packId: packId,
          ),
          now: now,
        );
        if (templateItem.logicalId != null) {
          itemIdsByLogicalId[templateItem.logicalId!] = itemId;
        }
        await _insertCreatedAction(itemId, now: now);
      }
      final resourceIdsByLogicalId = <String, int>{};
      for (final templateResource in template.resources) {
        final resourceId = await _dao.insertResource(
          _resourceCompanionForTemplate(
            templateResource,
            packId: packId,
            today: today,
            now: now,
          ),
        );
        resourceIdsByLogicalId[templateResource.logicalId] = resourceId;
        await _dao.insertResourceActionRecord(
          ResourceActionRecordsCompanion.insert(
            resourceId: resourceId,
            actionType: ResourceActionType.created.name,
            actionDate: today.millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
      }
      for (final rule in template.consumptionRules) {
        final itemId = itemIdsByLogicalId[rule.itemLogicalId];
        final resourceId = resourceIdsByLogicalId[rule.resourceLogicalId];
        if (itemId == null || resourceId == null) {
          continue;
        }
        await _dao.insertResourceConsumptionRule(
          ResourceConsumptionRulesCompanion.insert(
            resourceId: resourceId,
            itemId: itemId,
            triggerActionType: Value(rule.triggerActionType.name),
            consumeAmount: Value(
              rule.consumeAmount < 1 ? 1 : rule.consumeAmount,
            ),
            isEnabled: Value(rule.isEnabled),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
      }
      return packId;
    });
  }

  Future<int?> savePackAsTemplate(
    int packId,
    ItemPackTemplateInput input,
  ) async {
    final pack = await getPackById(packId);
    if (pack == null || pack.isSystemDefault) {
      return null;
    }
    final items = await _dao.listItemBundles(statuses: managedItemStatuses);
    final packItems = items
        .where((bundle) => bundle.item.packId == packId)
        .toList(growable: false);
    final resources = await _dao.listResourceBundles(
      statuses: ResourceLifecycleStatus.values.toSet(),
    );
    final packResources = resources
        .where((bundle) => bundle.resource.packId == packId)
        .toList(growable: false);
    final packResourceIds = packResources
        .map((bundle) => bundle.resource.id)
        .toSet();
    final rules = <ResourceConsumptionRule>[];
    for (final bundle in packItems) {
      final itemRules = await _dao.listConsumptionRulesForItem(bundle.item.id);
      rules.addAll(
        itemRules.where((rule) => packResourceIds.contains(rule.resourceId)),
      );
    }
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final templateId = await _dao.insertItemPackTemplate(
        ItemPackTemplatesCompanion.insert(
          name: input.name,
          category: input.category,
          description: input.description,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      for (final bundle in packItems) {
        await _dao.insertItemTemplateItem(
          _templateItemCompanion(
            bundle.item,
            templateId: templateId,
            logicalId: _itemTemplateLogicalId(bundle.item.id),
            now: now,
          ),
        );
      }
      for (final bundle in packResources) {
        await _dao.insertResourceTemplateItem(
          _resourceTemplateItemCompanion(
            bundle.resource,
            templateId: templateId,
            logicalId: _resourceTemplateLogicalId(bundle.resource.id),
            now: now,
          ),
        );
      }
      for (final rule in rules) {
        await _dao.insertResourceConsumptionRuleTemplateItem(
          ResourceConsumptionRuleTemplateItemsCompanion.insert(
            templateId: templateId,
            itemLogicalId: _itemTemplateLogicalId(rule.itemId),
            resourceLogicalId: _resourceTemplateLogicalId(rule.resourceId),
            triggerActionType: Value(rule.triggerActionType.name),
            consumeAmount: Value(rule.consumeAmount),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
      }
      return templateId;
    });
  }

  Future<bool> deleteCustomTemplate(String id) async {
    final customId = int.tryParse(id.replaceFirst('custom-', ''));
    if (customId == null) {
      return false;
    }
    return await _dao.deleteItemPackTemplate(customId) > 0;
  }

  Future<bool> pauseItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status != ItemLifecycleStatus.active) {
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
    return _dao.updateItemStatus(id, ItemLifecycleStatus.active);
  }

  Future<bool> archiveItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status == ItemLifecycleStatus.archived) {
      return false;
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
      final itemActionRecordId = await _dao.insertItemActionRecord(
        ItemActionRecordsCompanion.insert(
          itemId: id,
          actionType: action.type.name,
          actionDate: action.actionDate.millisecondsSinceEpoch,
          remark: Value(action.remark),
          payload: Value(ItemActionRecord.encodePayload(action.payload)),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      if (action.type == ItemActionType.done) {
        await _applyResourceConsumptionRules(
          id,
          itemActionRecordId: itemActionRecordId,
          actionDate: action.actionDate,
          now: now,
        );
      }
      return true;
    });
  }

  Future<void> _applyResourceConsumptionRules(
    int itemId, {
    required int itemActionRecordId,
    required DateTime actionDate,
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
    }
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
    final packId = input.packId ?? await _ensureDefaultPackId(now);
    await _assertPackCanAcceptItems(packId);
    return _dao.insertItem(_itemCompanion(input, packId: packId, now: now));
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
    );
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
      throw StateError('只能綁定同一個責任包內的資源');
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
      lastDoneAt: Value(_snapshotLastDoneAtForCreate(input.config)),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ResourcesCompanion _resourceCompanionForTemplate(
    ResourceTemplateItem templateResource, {
    required int packId,
    required DateTime today,
    required DateTime now,
  }) {
    final config = _resourceConfigForTemplateApply(
      templateResource.config,
      today,
    );
    return ResourcesCompanion.insert(
      packId: packId,
      title: templateResource.title,
      description: Value(templateResource.description),
      status: const Value('active'),
      type: templateResource.type.name,
      timeAnchorDate: Value(_resourceTimeAnchorDate(config)),
      timeDurationDays: Value(_resourceTimeDurationDays(config)),
      timeExpectedBeforeDays: Value(_resourceTimeInfoBeforeDays(config)),
      timeWarningBeforeDays: Value(_resourceTimeWarningBeforeDays(config)),
      timeDangerBeforeDays: Value(_resourceTimeDangerBeforeDays(config)),
      quantityCurrent: Value(_resourceQuantityCurrent(config)),
      quantityUnitLabel: Value(_resourceQuantityUnitLabel(config)),
      quantityExpectedThreshold: Value(_resourceQuantityInfoThreshold(config)),
      quantityWarningThreshold: Value(
        _resourceQuantityWarningThreshold(config),
      ),
      quantityDangerThreshold: Value(_resourceQuantityDangerThreshold(config)),
      lastRefilledAt: Value(_resourceInitialLastRefilledAt(config)),
      createdAt: now.millisecondsSinceEpoch,
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
  }) {
    return ItemPacksCompanion.insert(
      title: input.title,
      description: Value(input.description),
      status: const Value('active'),
      isSystemDefault: const Value(false),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ItemTemplateItemsCompanion _templateItemCompanion(
    Item item, {
    required int templateId,
    String? logicalId,
    required DateTime now,
  }) {
    return ItemTemplateItemsCompanion.insert(
      templateId: templateId,
      logicalId: Value(logicalId),
      title: item.title,
      description: Value(item.description),
      type: item.type.name,
      attentionPolicySource: Value(item.attentionPolicySource.name),
      fixedScheduleType: Value(_fixedScheduleType(item.config)),
      fixedScheduleInterval: Value(_fixedScheduleInterval(item.config)),
      fixedMonthlyDay: Value(_fixedMonthlyDay(item.config)),
      fixedRepeatRuleV2: Value(_fixedRepeatRuleV2(item.config)),
      fixedTimeOfDay: Value(_fixedTimeOfDay(item.config)),
      fixedOverduePolicy: Value(_fixedOverduePolicy(item.config)),
      fixedExpectedBeforeMinutes: Value(
        _durationMinutes(_fixedInfoBefore(item.config)),
      ),
      fixedWarningBeforeMinutes: Value(
        _durationMinutes(_fixedWarningBefore(item.config)),
      ),
      fixedDangerBeforeMinutes: Value(
        _durationMinutes(_fixedDangerBefore(item.config)),
      ),
      stateExpectedAfterMinutes: Value(
        _durationMinutes(_stateInfoAfter(item.config)),
      ),
      stateWarningAfterMinutes: Value(
        _durationMinutes(_stateWarningAfter(item.config)),
      ),
      stateDangerAfterMinutes: Value(
        _durationMinutes(_stateDangerAfter(item.config)),
      ),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ResourceTemplateItemsCompanion _resourceTemplateItemCompanion(
    Resource resource, {
    required int templateId,
    required String logicalId,
    required DateTime now,
  }) {
    final config = resource.config;
    return ResourceTemplateItemsCompanion.insert(
      templateId: templateId,
      logicalId: logicalId,
      title: resource.title,
      description: Value(resource.description),
      type: resource.type.name,
      timeDurationDays: Value(_resourceTimeDurationDays(config)),
      timeExpectedBeforeDays: Value(_resourceTimeInfoBeforeDays(config)),
      timeWarningBeforeDays: Value(_resourceTimeWarningBeforeDays(config)),
      timeDangerBeforeDays: Value(_resourceTimeDangerBeforeDays(config)),
      quantityCurrent: Value(_resourceQuantityCurrent(config)),
      quantityUnitLabel: Value(_resourceQuantityUnitLabel(config)),
      quantityExpectedThreshold: Value(_resourceQuantityInfoThreshold(config)),
      quantityWarningThreshold: Value(
        _resourceQuantityWarningThreshold(config),
      ),
      quantityDangerThreshold: Value(_resourceQuantityDangerThreshold(config)),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  String _itemTemplateLogicalId(int itemId) => 'item-$itemId';

  String _resourceTemplateLogicalId(int resourceId) => 'resource-$resourceId';

  ItemConfig _configForTemplateApply(ItemConfig config, DateTime today) {
    return switch (config) {
      FixedItemConfig fixed => FixedItemConfig(
        scheduleType: fixed.scheduleType,
        scheduleInterval: fixed.scheduleInterval,
        monthlyDay: fixed.monthlyDay ?? today.day,
        anchorDate: today,
        dueDate: _templateFixedDueDate(fixed, today),
        timeOfDay: fixed.timeOfDay,
        overduePolicy: fixed.overduePolicy,
        infoBefore: fixed.infoBefore,
        warningBefore: fixed.warningBefore,
        dangerBefore: fixed.dangerBefore,
      ),
      StateBasedItemConfig state => StateBasedItemConfig(
        anchorDate: today,
        infoAfter: state.infoAfter,
        warningAfter: state.warningAfter,
        dangerAfter: state.dangerAfter,
      ),
      _ => config,
    };
  }

  ResourceConfig _resourceConfigForTemplateApply(
    ResourceConfig config,
    DateTime today,
  ) {
    return switch (config) {
      TimeBasedResourceConfig time => TimeBasedResourceConfig(
        anchorDate: time.anchorDate ?? today,
        durationDays: time.durationDays,
        infoBeforeDays: time.infoBeforeDays,
        warningBeforeDays: time.warningBeforeDays,
        dangerBeforeDays: time.dangerBeforeDays,
      ),
      QuantityBasedResourceConfig quantity => QuantityBasedResourceConfig(
        currentQuantity: quantity.currentQuantity < 0
            ? 0
            : quantity.currentQuantity,
        unitLabel: quantity.unitLabel,
        infoThreshold: quantity.infoThreshold,
        warningThreshold: quantity.warningThreshold,
        dangerThreshold: quantity.dangerThreshold,
      ),
      _ => config,
    };
  }

  DateTime _templateFixedDueDate(FixedItemConfig config, DateTime today) {
    final interval = config.scheduleInterval < 1 ? 1 : config.scheduleInterval;
    return switch (config.scheduleType) {
      FixedScheduleType.daily || FixedScheduleType.oneTime => today,
      FixedScheduleType.weekly => today.add(const Duration(days: 6)),
      FixedScheduleType.everyXDays => today.add(Duration(days: interval - 1)),
      FixedScheduleType.everyXWeeks => today.add(
        Duration(days: interval * 7 - 1),
      ),
      FixedScheduleType.monthly => _addMonthsClamped(
        today,
        interval,
        preferredDay: config.monthlyDay ?? today.day,
      ).subtract(const Duration(days: 1)),
    };
  }

  DateTime _addMonthsClamped(
    DateTime value,
    int months, {
    required int preferredDay,
  }) {
    final targetMonth = DateTime(value.year, value.month + months);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = preferredDay.clamp(1, lastDay);
    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  Future<int> _ensureDefaultPackId(DateTime now) async {
    final packs = await _dao.listItemPacks(includeArchived: true);
    for (final pack in packs) {
      if (pack.isSystemDefault) {
        return pack.id;
      }
    }
    return _dao.insertItemPack(
      ItemPacksCompanion.insert(
        title: AppDatabase.systemDefaultPackTitle,
        description: const Value(AppDatabase.systemDefaultPackDescription),
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

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
}
