import 'item.dart';
import 'item_action_record.dart';
import 'item_action_service.dart';
import 'item_status_service.dart';
import 'repeat_rule_v2.dart';

class SnapshotValue<T> {
  const SnapshotValue.absent() : present = false, value = null;

  const SnapshotValue.value(this.value) : present = true;

  final bool present;
  final T? value;
}

class ItemSnapshotUpdate {
  const ItemSnapshotUpdate({
    this.fixedAnchorDate = const SnapshotValue.absent(),
    this.fixedDueDate = const SnapshotValue.absent(),
    this.fixedRepeatRuleV2 = const SnapshotValue.absent(),
    this.stateAnchorDate = const SnapshotValue.absent(),
    this.lastDoneAt = const SnapshotValue.absent(),
    required this.updatedAt,
  });

  final SnapshotValue<DateTime> fixedAnchorDate;
  final SnapshotValue<DateTime> fixedDueDate;
  final SnapshotValue<String> fixedRepeatRuleV2;
  final SnapshotValue<DateTime> stateAnchorDate;
  final SnapshotValue<DateTime> lastDoneAt;
  final DateTime updatedAt;
}

class ItemSnapshotUpdateService {
  ItemSnapshotUpdateService({ItemStatusService? statusService})
    : _statusService = statusService ?? const ItemStatusService();

  final ItemStatusService _statusService;
  final RepeatRuleOccurrenceCalculator _repeatCalculator =
      const RepeatRuleOccurrenceCalculator();

  ItemSnapshotUpdate build(
    Item item, {
    required PlannedItemAction action,
    required DateTime updatedAt,
  }) {
    return switch (item.config) {
      FixedItemConfig config => _buildFixedUpdate(
        item,
        config,
        action: action,
        updatedAt: updatedAt,
      ),
      StateBasedItemConfig config => _buildStateBasedUpdate(
        config,
        action: action,
        updatedAt: updatedAt,
      ),
      _ => ItemSnapshotUpdate(updatedAt: updatedAt),
    };
  }

  ItemSnapshotUpdate _buildFixedUpdate(
    Item item,
    FixedItemConfig config, {
    required PlannedItemAction action,
    required DateTime updatedAt,
  }) {
    final cycle = _statusService.resolveFixedCycle(
      config,
      now: action.actionDate,
    );
    final nextCycleStrategy = ItemNextCycleStrategy.values.byName(
      (action.payload?['nextCycleStrategy'] as String?) ??
          ItemNextCycleStrategy.keepSchedule.name,
    );
    var anchorDate = config.anchorDate;
    var dueDate = config.dueDate;
    var lastDoneAt = item.lastDoneAt;
    var repeatRuleV2 = config.repeatRuleV2;

    if (action.type == ItemActionType.deferred) {
      final deferDays = (action.payload?['deferDays'] as num?)?.toInt() ?? 0;
      if (anchorDate != null) {
        anchorDate = anchorDate.add(Duration(days: deferDays));
      }
      if (dueDate != null) {
        dueDate = dueDate.add(Duration(days: deferDays));
      }
    } else if (cycle != null &&
        (config.scheduleType != FixedScheduleType.oneTime ||
            repeatRuleV2 != null)) {
      if (repeatRuleV2 != null) {
        final shouldCountOccurrence =
            action.type == ItemActionType.done ||
            action.type == ItemActionType.skipped;
        final updatedRule = shouldCountOccurrence
            ? repeatRuleV2.copyWithCompletedCount(
                repeatRuleV2.completedCount + 1,
              )
            : repeatRuleV2;
        final next = _repeatCalculator.nextOccurrence(
          rule: updatedRule,
          fromDate: action.actionDate,
          anchorDate: config.anchorDate ?? cycle.anchorDate,
        );
        repeatRuleV2 = updatedRule;
        if (next != null) {
          anchorDate = next;
          dueDate = next;
        } else {
          anchorDate = cycle.anchorDate;
          dueDate = cycle.dueDate;
        }
      } else {
        anchorDate = _statusService.nextFixedCycleAnchor(cycle, config);
        dueDate = _statusService.nextFixedCycleDue(cycle, config);
      }
      if (config.overduePolicy == ItemOverduePolicy.waitForAction &&
          action.actionDate.isAfter(cycle.dueDate) &&
          repeatRuleV2 == null &&
          nextCycleStrategy == ItemNextCycleStrategy.shiftByDelay) {
        final delayDays = action.actionDate.difference(cycle.dueDate).inDays;
        anchorDate = _statusService.shiftDateByDelay(anchorDate, delayDays);
        dueDate = _statusService.shiftDateByDelay(dueDate, delayDays);
      }
    }

    if (action.type == ItemActionType.done) {
      lastDoneAt = action.actionDate;
    }

    return ItemSnapshotUpdate(
      fixedAnchorDate: SnapshotValue.value(anchorDate),
      fixedDueDate: SnapshotValue.value(dueDate),
      fixedRepeatRuleV2: SnapshotValue.value(repeatRuleV2?.encode()),
      lastDoneAt: SnapshotValue.value(lastDoneAt),
      updatedAt: updatedAt,
    );
  }

  ItemSnapshotUpdate _buildStateBasedUpdate(
    StateBasedItemConfig config, {
    required PlannedItemAction action,
    required DateTime updatedAt,
  }) {
    return ItemSnapshotUpdate(
      stateAnchorDate: action.type == ItemActionType.done
          ? SnapshotValue.value(action.actionDate)
          : SnapshotValue.value(config.anchorDate),
      lastDoneAt: const SnapshotValue.value(null),
      updatedAt: updatedAt,
    );
  }
}
