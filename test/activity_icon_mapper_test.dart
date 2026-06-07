import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/presentation/activity_icon_mapper.dart';

void main() {
  test('item activity action icon maps known actions and fallback', () {
    expect(
      itemActivityActionIcon(ItemActionType.created),
      Icons.add_circle_outline,
    );
    expect(
      itemActivityActionIcon(ItemActionType.done),
      Icons.check_circle_outline,
    );
    expect(
      itemActivityActionIcon(ItemActionType.skipped),
      Icons.skip_next_outlined,
    );
    expect(
      itemActivityActionIcon(ItemActionType.deferred),
      Icons.schedule_outlined,
    );
    expect(
      itemActivityActionIcon(ItemActionType.reverted),
      Icons.undo_outlined,
    );
    expect(itemActivityActionIcon(null), Icons.history_outlined);
  });
}
