import 'item.dart';
import 'item_action_record.dart';

class PlannedItemAction {
  const PlannedItemAction({
    required this.type,
    required this.actionDate,
    this.remark,
    this.payload,
  });

  final ItemActionType type;
  final DateTime actionDate;
  final String? remark;
  final Map<String, Object?>? payload;
}

class ItemActionService {
  const ItemActionService();

  PlannedItemAction? planDone(
    Item item, {
    DateTime? doneAt,
    DateTime? fallbackNow,
    String? remark,
    int? addedDays,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) {
    final actionDate = _normalizeDate(doneAt ?? fallbackNow ?? DateTime.now());
    final payload = <String, Object?>{
      'nextCycleStrategy': nextCycleStrategy.name,
    };

    if (item.type == ItemType.resourceBased) {
      if (addedDays == null || addedDays <= 0) {
        return null;
      }
      payload['addedDays'] = addedDays;
    } else if (addedDays != null) {
      payload['addedDays'] = addedDays;
    }

    return PlannedItemAction(
      type: ItemActionType.done,
      actionDate: actionDate,
      remark: remark,
      payload: payload,
    );
  }

  PlannedItemAction? planSkip(
    Item item, {
    DateTime? actionAt,
    DateTime? fallbackNow,
    String? remark,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) {
    if (item.type == ItemType.resourceBased) {
      return null;
    }
    return PlannedItemAction(
      type: ItemActionType.skipped,
      actionDate: _normalizeDate(actionAt ?? fallbackNow ?? DateTime.now()),
      remark: remark,
      payload: {'nextCycleStrategy': nextCycleStrategy.name},
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
