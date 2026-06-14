import 'attention_policy.dart';
import 'repeat_rule_v2.dart';

enum ItemType { fixed, stateBased }

enum ItemStatus { normal, warning, danger, unknown }

enum ItemLifecycleStatus { active, paused, archived }

enum FixedScheduleType {
  daily,
  weekly,
  oneTime,
  everyXDays,
  everyXWeeks,
  monthly,
}

enum ItemOverduePolicy { autoAdvance, waitForAction }

enum ItemNextCycleStrategy { keepSchedule, shiftByDelay }

abstract class ItemConfig {
  const ItemConfig();

  ItemType get type;
}

class FixedItemConfig extends ItemConfig {
  const FixedItemConfig({
    required this.scheduleType,
    this.scheduleInterval = 1,
    this.monthlyDay,
    this.repeatRuleV2,
    this.anchorDate,
    this.dueDate,
    this.timeOfDay,
    this.overduePolicy = ItemOverduePolicy.autoAdvance,
    this.infoBefore = Duration.zero,
    this.warningBefore = Duration.zero,
    this.dangerBefore = Duration.zero,
  });

  final FixedScheduleType scheduleType;
  final int scheduleInterval;
  final int? monthlyDay;
  final RepeatRuleV2? repeatRuleV2;
  final DateTime? anchorDate;
  final DateTime? dueDate;
  final String? timeOfDay;
  final ItemOverduePolicy overduePolicy;
  final Duration infoBefore;
  final Duration warningBefore;
  final Duration dangerBefore;

  @override
  ItemType get type => ItemType.fixed;
}

class StateBasedItemConfig extends ItemConfig {
  const StateBasedItemConfig({
    this.anchorDate,
    Duration? infoAfter,
    required this.warningAfter,
    required this.dangerAfter,
  }) : infoAfter = infoAfter ?? Duration.zero;

  final DateTime? anchorDate;
  final Duration infoAfter;
  final Duration warningAfter;
  final Duration dangerAfter;

  @override
  ItemType get type => ItemType.stateBased;
}

class Item {
  const Item({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.attentionPolicySource = AttentionPolicySource.systemDefault,
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
  final AttentionPolicySource attentionPolicySource;
  final ItemLifecycleStatus status;
  final DateTime? lastDoneAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
