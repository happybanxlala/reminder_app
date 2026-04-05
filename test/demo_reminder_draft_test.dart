import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/demo_reminder_draft.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';

void main() {
  test('DemoReminderDraft.random generates valid field values', () {
    final now = DateTime(2026, 2, 13, 9, 0);

    for (var i = 0; i < 30; i++) {
      final draft = DemoReminderDraft.random(random: Random(i + 1), now: now);

      expect(draft.title.trim(), isNotEmpty);
      expect(draft.triggerOffsetDays, inInclusiveRange(0, 5));
      expect(
        const [
          ReminderTrackingMode.countdown,
          ReminderTrackingMode.countUp,
        ].contains(draft.trackingMode),
        isTrue,
      );
      expect(
        const [
          ReminderTriggerMode.inRange,
          ReminderTriggerMode.immediate,
          ReminderTriggerMode.onPoint,
        ].contains(draft.triggerMode),
        isTrue,
      );
      expect(
        draft.startAt.isAfter(now) || draft.startAt.isAtSameMomentAs(now),
        isTrue,
      );
      if (draft.trackingMode == ReminderTrackingMode.countdown) {
        expect(draft.dueAt, isNotNull);
        expect(draft.dueAt!.isAfter(draft.startAt), isTrue);
      } else {
        expect(draft.dueAt, isNull);
      }
      expect(draft.repeatInterval, greaterThanOrEqualTo(1));
      expect(
        const [null, 'D', 'W', 'M', 'Y'].contains(draft.repeatType),
        isTrue,
      );
      if (draft.repeatType == null) {
        expect(draft.repeatInterval, 1);
      }
    }
  });
}
