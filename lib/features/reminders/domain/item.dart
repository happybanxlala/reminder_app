enum ItemType { fixed, stateBased, resourceBased }

enum ItemStatus { normal, warning, danger, unknown }

enum ItemLifecycleStatus { active, paused, archived }

enum FixedScheduleType { daily, weekly, oneTime }

enum ItemOverduePolicy { autoAdvance, waitForAction }

enum ItemNextCycleStrategy { keepSchedule, shiftByDelay }

typedef FixedTimeScheduleType = FixedScheduleType;
typedef FixedTimeItemConfig = FixedItemConfig;

abstract class ItemConfig {
  const ItemConfig();

  ItemType get type;
}

class FixedItemConfig extends ItemConfig {
  const FixedItemConfig({
    required this.scheduleType,
    this.anchorDate,
    this.dueDate,
    this.timeOfDay,
    this.overduePolicy = ItemOverduePolicy.autoAdvance,
    this.expectedBefore = Duration.zero,
    this.warningBefore = Duration.zero,
    this.dangerBefore = Duration.zero,
  });

  final FixedScheduleType scheduleType;
  final DateTime? anchorDate;
  final DateTime? dueDate;
  final String? timeOfDay;
  final ItemOverduePolicy overduePolicy;
  final Duration expectedBefore;
  final Duration warningBefore;
  final Duration dangerBefore;

  @override
  ItemType get type => ItemType.fixed;
}

class StateBasedItemConfig extends ItemConfig {
  const StateBasedItemConfig({
    this.anchorDate,
    Duration? expectedAfter,
    Duration? expectedInterval,
    required this.warningAfter,
    required this.dangerAfter,
  }) : expectedAfter = expectedAfter ?? expectedInterval ?? Duration.zero;

  final DateTime? anchorDate;
  final Duration expectedAfter;
  final Duration warningAfter;
  final Duration dangerAfter;

  Duration get expectedInterval => expectedAfter;

  @override
  ItemType get type => ItemType.stateBased;
}

class ResourceBasedItemConfig extends ItemConfig {
  const ResourceBasedItemConfig({
    this.anchorDate,
    required this.durationDays,
    this.expectedBefore = 0,
    this.warningBefore = 0,
    this.dangerBefore = 0,
  });

  final DateTime? anchorDate;
  final int durationDays;
  final int expectedBefore;
  final int warningBefore;
  final int dangerBefore;

  Duration get estimatedDuration => Duration(days: durationDays);
  Duration get warningBeforeDepletion => Duration(days: warningBefore);

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
    this.status = ItemLifecycleStatus.active,
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
  final ItemLifecycleStatus status;
  final DateTime? lastDoneAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
