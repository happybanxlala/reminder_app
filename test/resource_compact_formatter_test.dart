import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/presentation/formatters/reminder_formatters.dart';

void main() {
  group('resourceCompactRemainingSummary', () {
    test('quantity resource shows remaining quantity', () {
      expect(
        ReminderFormatters.resourceCompactRemainingSummary(
          _quantityResource(currentQuantity: 5, unitLabel: '包'),
        ),
        '剩 5 包',
      );
    });

    test('quantity resource at zero shows depleted summary', () {
      expect(
        ReminderFormatters.resourceCompactRemainingSummary(
          _quantityResource(currentQuantity: 0, unitLabel: '個'),
        ),
        '已用完',
      );
    });

    test('time resource shows future depletion date', () {
      expect(
        ReminderFormatters.resourceCompactRemainingSummary(
          _timeResource(anchorDate: DateTime(2026, 5, 20), durationDays: 4),
          now: DateTime(2026, 5, 20),
        ),
        '剩 3 天・5/23 用完',
      );
    });

    test('time resource shows today depletion', () {
      expect(
        ReminderFormatters.resourceCompactRemainingSummary(
          _timeResource(anchorDate: DateTime(2026, 5, 20), durationDays: 4),
          now: DateTime(2026, 5, 23),
        ),
        '今天用完',
      );
    });

    test('time resource shows past depletion', () {
      expect(
        ReminderFormatters.resourceCompactRemainingSummary(
          _timeResource(anchorDate: DateTime(2026, 5, 20), durationDays: 4),
          now: DateTime(2026, 5, 25),
        ),
        '已用完 2 天',
      );
    });
  });
}

Resource _quantityResource({
  required int currentQuantity,
  required String unitLabel,
}) {
  return Resource(
    id: 1,
    packId: 1,
    title: '貓砂',
    type: ResourceType.quantityBased,
    config: QuantityBasedResourceConfig(
      currentQuantity: currentQuantity,
      unitLabel: unitLabel,
      warningThreshold: 2,
      dangerThreshold: 1,
    ),
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

Resource _timeResource({
  required DateTime anchorDate,
  required int durationDays,
}) {
  return Resource(
    id: 2,
    packId: 1,
    title: '洗髮精',
    type: ResourceType.timeBased,
    config: TimeBasedResourceConfig(
      anchorDate: anchorDate,
      durationDays: durationDays,
      warningBeforeDays: 2,
      dangerBeforeDays: 1,
    ),
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
