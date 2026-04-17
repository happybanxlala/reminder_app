enum ItemType { fixedTime, stateBased, resourceBased }

enum ItemStatus { normal, warning, danger, unknown }

enum FixedTimeScheduleType { daily, weekly, custom }

abstract class ItemConfig {
  const ItemConfig();

  ItemType get type;
}

class FixedTimeItemConfig extends ItemConfig {
  const FixedTimeItemConfig({
    required this.scheduleType,
    this.anchorDate,
    this.timeOfDay,
  });

  final FixedTimeScheduleType scheduleType;
  final DateTime? anchorDate;
  final String? timeOfDay;

  @override
  ItemType get type => ItemType.fixedTime;
}

class StateBasedItemConfig extends ItemConfig {
  const StateBasedItemConfig({
    required this.expectedInterval,
    required this.warningAfter,
    required this.dangerAfter,
  });

  final Duration expectedInterval;
  final Duration warningAfter;
  final Duration dangerAfter;

  @override
  ItemType get type => ItemType.stateBased;
}

class ResourceBasedItemConfig extends ItemConfig {
  const ResourceBasedItemConfig({
    required this.estimatedDuration,
    required this.warningBeforeDepletion,
  });

  final Duration estimatedDuration;
  final Duration warningBeforeDepletion;

  @override
  ItemType get type => ItemType.resourceBased;
}

class Item {
  const Item({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.lastDoneAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int packId;
  final String title;
  final String? description;
  final ItemType type;
  final ItemConfig config;
  final DateTime? lastDoneAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
