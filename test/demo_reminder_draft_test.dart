import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/demo_reminder_draft.dart';

void main() {
  test('DemoReminderDraft.random generates valid field values', () {
    final now = DateTime(2026, 2, 13, 9, 0);

    for (var i = 0; i < 30; i++) {
      final draft = DemoReminderDraft.random(
        random: Random(i + 1),
        now: now,
      );

      expect(draft.title.trim(), isNotEmpty);
      expect(draft.remindDays, inInclusiveRange(0, 5));
      expect(draft.dueAt.isAfter(now), isTrue);
      expect(draft.repeatInterval, greaterThanOrEqualTo(1));
      expect(
        const [null, 'D', 'W', 'N', 'Y'].contains(draft.repeatType),
        isTrue,
      );
      if (draft.repeatType == null) {
        expect(draft.repeatInterval, 1);
      }
    }
  });
}
