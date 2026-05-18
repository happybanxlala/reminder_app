import 'item_action_record.dart';

enum ResourceType { timeBased, quantityBased }

enum ResourceLifecycleStatus { active, paused, archived }

enum ResourceStatus { normal, warning, danger, unknown }

enum ResourceActionType { created, consumed, refilled, adjusted, reverted }

abstract class ResourceConfig {
  const ResourceConfig();

  ResourceType get type;
}

class TimeBasedResourceConfig extends ResourceConfig {
  const TimeBasedResourceConfig({
    this.anchorDate,
    required this.durationDays,
    this.infoBeforeDays = 0,
    this.warningBeforeDays = 0,
    this.dangerBeforeDays = 0,
  });

  final DateTime? anchorDate;
  final int durationDays;
  final int infoBeforeDays;
  final int warningBeforeDays;
  final int dangerBeforeDays;

  @override
  ResourceType get type => ResourceType.timeBased;
}

class QuantityBasedResourceConfig extends ResourceConfig {
  const QuantityBasedResourceConfig({
    required this.currentQuantity,
    required this.unitLabel,
    this.infoThreshold,
    this.warningThreshold = 0,
    this.dangerThreshold = 0,
  });

  final int currentQuantity;
  final String unitLabel;
  final int? infoThreshold;
  final int warningThreshold;
  final int dangerThreshold;

  @override
  ResourceType get type => ResourceType.quantityBased;
}

class Resource {
  const Resource({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.status = ResourceLifecycleStatus.active,
    this.lastRefilledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int packId;
  final String title;
  final String? description;
  final ResourceType type;
  final ResourceConfig config;
  final ResourceLifecycleStatus status;
  final DateTime? lastRefilledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ResourceConsumptionRule {
  const ResourceConsumptionRule({
    required this.id,
    required this.resourceId,
    required this.itemId,
    this.triggerActionType = ItemActionType.done,
    this.consumeAmount = 1,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int resourceId;
  final int itemId;
  final ItemActionType triggerActionType;
  final int consumeAmount;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ResourceActionRecord {
  const ResourceActionRecord({
    required this.id,
    required this.resourceId,
    required this.actionType,
    required this.actionDate,
    this.amount,
    this.resultingQuantity,
    this.addedDays,
    this.resultingDurationDays,
    this.sourceItemActionRecordId,
    this.remark,
    this.isReverted = false,
    this.revertedAt,
    this.revertedByActionRecordId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int resourceId;
  final ResourceActionType actionType;
  final DateTime actionDate;
  final int? amount;
  final int? resultingQuantity;
  final int? addedDays;
  final int? resultingDurationDays;
  final int? sourceItemActionRecordId;
  final String? remark;
  final bool isReverted;
  final DateTime? revertedAt;
  final int? revertedByActionRecordId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
