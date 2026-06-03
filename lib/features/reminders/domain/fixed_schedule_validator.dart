import 'item.dart';
import 'item_status_service.dart';

class FixedScheduleValidator {
  const FixedScheduleValidator({
    ItemStatusService statusService = const ItemStatusService(),
  }) : _statusService = statusService;

  static const overlapErrorMessage = '可處理時間太長，會和下一次提醒重疊。請縮短可處理期，或調整重複規則。';

  static const invalidWindowErrorMessage = '可處理期設定不正確，請調整到期日或完成方式。';

  final ItemStatusService _statusService;

  FixedScheduleValidationResult validateForSave(FixedItemConfig config) {
    final anchorDate = config.anchorDate == null
        ? null
        : _normalizeDate(config.anchorDate!);
    final dueDate = config.dueDate == null
        ? null
        : _normalizeDate(config.dueDate!);
    if (anchorDate == null || dueDate == null) {
      return const FixedScheduleValidationResult();
    }
    if (anchorDate.isAfter(dueDate)) {
      throw StateError(invalidWindowErrorMessage);
    }

    final cycle = FixedCycleWindow(
      anchorDate: anchorDate,
      dueDate: dueDate,
      isVirtualAdvance: false,
    );
    final nextDueDate = _statusService.nextFixedCycleDueDate(cycle, config);
    if (nextDueDate == null) {
      return const FixedScheduleValidationResult();
    }
    final nextAnchorDate = _statusService.nextFixedCycleAnchorDate(
      cycle,
      config,
    );
    if (nextAnchorDate == null) {
      return const FixedScheduleValidationResult();
    }
    if (!dueDate.isBefore(nextAnchorDate)) {
      throw StateError(overlapErrorMessage);
    }
    return FixedScheduleValidationResult(
      nextDueDate: nextDueDate,
      nextAnchorDate: nextAnchorDate,
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class FixedScheduleValidationResult {
  const FixedScheduleValidationResult({this.nextDueDate, this.nextAnchorDate});

  final DateTime? nextDueDate;
  final DateTime? nextAnchorDate;
}
