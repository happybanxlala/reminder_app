import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';
import 'package:reminder_app/features/reminders/presentation/reminder_view_models.dart';

void main() {
  group('ReminderUiText.trackingModeLabel', () {
    test('maps countdown to fixed time', () {
      expect(
        ReminderUiText.trackingModeLabel(ReminderTrackingMode.countdown),
        '固定時間',
      );
    });

    test('maps accumulation to start date', () {
      expect(
        ReminderUiText.trackingModeLabel(ReminderTrackingMode.accumulation),
        '從某天開始',
      );
    });
  });

  test(
    'history reminder date text does not expose unsupported time precision',
    () {
      final item = HistoryReminderItemViewModel.fromDomain(
        ReminderModel(
          id: 1,
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          status: ReminderStatus.done,
          title: 'Pay bill',
          dueAt: DateTime(2026, 3, 1, 10, 30),
          startAt: DateTime(2026, 2, 20, 9, 0),
          createdAt: DateTime(2026, 2, 1, 8, 0),
          updatedAt: DateTime(2026, 3, 1, 11, 0),
        ),
      );

      expect(item.subtitle, contains('固定日期: 2026/03/01'));
      expect(item.subtitle, isNot(contains('固定日期: 2026/03/01 10:30')));
    },
  );

  test(
    'fixed-time reminder card prioritizes relative day and repeat summary',
    () {
      final item = PendingReminderItemViewModel.fromDomain(
        ReminderModel(
          id: 1,
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          status: ReminderStatus.pending,
          title: 'Pay rent',
          dueAt: DateTime(2026, 3, 2),
          startAt: DateTime(2026, 2, 20),
          repeatRule: 'W1',
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 1),
        ),
        now: DateTime(2026, 3, 1, 9),
      );

      expect(item.primaryText, '明天');
      expect(item.secondaryText, '每週');
    },
  );

  test('start-based reminder card prioritizes day count and start date', () {
    final item = PendingReminderItemViewModel.fromDomain(
      ReminderModel(
        id: 2,
        trackingMode: ReminderTrackingMode.accumulation,
        triggerMode: ReminderTriggerMode.inRange,
        status: ReminderStatus.pending,
        title: 'Pet anniversary',
        startAt: DateTime(2026, 2, 27),
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      ),
      now: DateTime(2026, 3, 1, 9),
    );

    expect(item.primaryText, '第 3 天');
    expect(item.secondaryText, '起始日 2026/02/27');
  });
}
