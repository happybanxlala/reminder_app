import 'package:flutter/material.dart';

import '../domain/item_action_record.dart';

IconData itemActivityActionIcon(ItemActionType? actionType) {
  return switch (actionType) {
    ItemActionType.created => Icons.add_circle_outline,
    ItemActionType.done => Icons.check_circle_outline,
    ItemActionType.skipped => Icons.skip_next_outlined,
    ItemActionType.deferred => Icons.schedule_outlined,
    ItemActionType.reverted => Icons.undo_outlined,
    null => Icons.history_outlined,
  };
}
