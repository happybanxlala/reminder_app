enum ResponsibilityItemType { fixedTime, stateBased, resourceBased }

enum ResponsibilityItemStatus { normal, warning, danger, unknown }

enum FixedTimeScheduleType { daily, weekly, custom }

abstract class ResponsibilityItemConfig {
  const ResponsibilityItemConfig();

  ResponsibilityItemType get type;
}

class FixedTimeItemConfig extends ResponsibilityItemConfig {
  const FixedTimeItemConfig({
    required this.scheduleType,
    this.anchorDate,
    this.timeOfDay,
  });

  final FixedTimeScheduleType scheduleType;
  final DateTime? anchorDate;
  final String? timeOfDay;

  @override
  ResponsibilityItemType get type => ResponsibilityItemType.fixedTime;
}

class StateBasedItemConfig extends ResponsibilityItemConfig {
  const StateBasedItemConfig({
    required this.expectedInterval,
    required this.warningAfter,
    required this.dangerAfter,
  });

  final Duration expectedInterval;
  final Duration warningAfter;
  final Duration dangerAfter;

  @override
  ResponsibilityItemType get type => ResponsibilityItemType.stateBased;
}

class ResourceBasedItemConfig extends ResponsibilityItemConfig {
  const ResourceBasedItemConfig({
    required this.estimatedDuration,
    required this.warningBeforeDepletion,
  });

  final Duration estimatedDuration;
  final Duration warningBeforeDepletion;

  @override
  ResponsibilityItemType get type => ResponsibilityItemType.resourceBased;
}

class ResponsibilityItem {
  const ResponsibilityItem({
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
  final ResponsibilityItemType type;
  final ResponsibilityItemConfig config;
  final DateTime? lastDoneAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
