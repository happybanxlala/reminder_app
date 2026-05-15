import 'package:drift/drift.dart';

import '../domain/item_action_record.dart';
import '../domain/item_pack.dart';
import '../domain/resource.dart';
import '../domain/resource_refill_service.dart';
import '../domain/resource_status_service.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';

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
  }) : _statusService = statusService ?? const ResourceStatusService(),
       _refillService = refillService ?? const ResourceRefillService(),
       _clock = clock ?? DateTime.now;

  static const managedResourceStatuses = {
    ResourceLifecycleStatus.active,
    ResourceLifecycleStatus.paused,
  };

  final ReminderDao _dao;
  final ResourceStatusService _statusService;
  final ResourceRefillService _refillService;
  final DateTime Function() _clock;

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

  Stream<List<ResourceActionRecord>> watchActionHistory(int resourceId) {
    return _dao.watchResourceActionRecordsForResource(resourceId);
  }

  Future<List<ResourceActionRecord>> listActionHistory(int resourceId) {
    return _dao.listResourceActionRecordsForResource(resourceId);
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
    await _assertPackCanAcceptResources(packId, existing: existing.resource);
    return _dao.updateResourceRecord(
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
  }

  Future<bool> archiveResource(int resourceId) {
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
  }) async {
    final existing = await getResourceById(resourceId);
    if (existing == null ||
        existing.resource.config is! QuantityBasedResourceConfig) {
      return false;
    }
    final now = _clock();
    final actionDate = _normalizeDate(actionAt ?? now);
    final resultingQuantity = _refillService.adjustQuantity(newQuantity);
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
          resultingQuantity: Value(resultingQuantity),
          remark: Value(remark),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return true;
    });
  }

  Future<int> createConsumptionRule(ResourceConsumptionRuleInput input) async {
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
}
