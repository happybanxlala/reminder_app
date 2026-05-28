import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';
import 'package:reminder_app/features/reminders/presentation/formatters/reminder_formatters.dart';

void main() {
  test('stage tracker day label starts at day one and clamps before start', () {
    final tracker = _tracker(start: DateTime(2026, 5, 20));

    expect(
      ReminderFormatters.stageTrackerDayLabel(
        tracker,
        now: DateTime(2026, 5, 19),
      ),
      '第1天',
    );
    expect(
      ReminderFormatters.stageTrackerDayLabel(
        tracker,
        now: DateTime(2026, 5, 20),
      ),
      '第1天',
    );
    expect(
      ReminderFormatters.stageTrackerDayLabel(
        tracker,
        now: DateTime(2026, 5, 21),
      ),
      '第2天',
    );
  });

  test('stage tracker day label clamps after tracking end date', () {
    final tracker = _tracker(
      start: DateTime(2026, 5, 20),
      end: DateTime(2026, 5, 22),
    );

    expect(
      ReminderFormatters.stageTrackerDayLabel(
        tracker,
        now: DateTime(2026, 5, 30),
      ),
      '第3天',
    );
  });
}

StageTracker _tracker({required DateTime start, DateTime? end}) {
  return StageTracker(
    id: 1,
    packId: 1,
    title: 'Tracker',
    trackingStartDate: start,
    trackingEndDate: end,
    status: StageTrackerStatus.active,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
