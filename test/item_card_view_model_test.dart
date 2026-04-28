import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/presentation/view_models/item_timeline_card_view_model.dart';

void main() {
  test('item card view model maps base statuses when not overridden', () {
    final cases = <(ItemStatus, ItemCardDisplayState)>[
      (ItemStatus.normal, ItemCardDisplayState.normal),
      (ItemStatus.warning, ItemCardDisplayState.warning),
      (ItemStatus.danger, ItemCardDisplayState.danger),
      (ItemStatus.unknown, ItemCardDisplayState.unknown),
    ];

    for (final (status, expected) in cases) {
      final viewModel = ItemCardViewModel.fromEntry(
        _entry(
          status: status,
          item: Item(
            id: status.index + 1,
            packId: 1,
            title: 'State ${status.name}',
            type: ItemType.resourceBased,
            config: ResourceBasedItemConfig(
              anchorDate: DateTime(2026, 4, 1),
              durationDays: 10,
              warningBefore: 2,
              dangerBefore: 1,
            ),
            createdAt: DateTime(2026, 4, 1),
            updatedAt: DateTime(2026, 4, 1),
          ),
        ),
        now: DateTime(2026, 4, 11),
      );

      expect(viewModel.displayState, expected);
    }
  });

  test(
    'item card view model resolves not started state and disables complete',
    () {
      final viewModel = ItemCardViewModel.fromEntry(
        _entry(
          status: ItemStatus.warning,
          item: Item(
            id: 10,
            packId: 1,
            title: 'Future task',
            type: ItemType.stateBased,
            config: StateBasedItemConfig(
              anchorDate: DateTime(2026, 4, 30),
              infoAfter: Duration.zero,
              warningAfter: Duration(days: 1),
              dangerAfter: Duration(days: 2),
            ),
            createdAt: DateTime(2026, 4, 1),
            updatedAt: DateTime(2026, 4, 1),
          ),
        ),
        now: DateTime(2026, 4, 21),
      );

      expect(viewModel.displayState, ItemCardDisplayState.notStarted);
      expect(viewModel.canComplete, isFalse);
    },
  );

  test('item card view model resolves overdue fixed waitForAction state', () {
    final viewModel = ItemCardViewModel.fromEntry(
      _entry(
        status: ItemStatus.danger,
        item: Item(
          id: 11,
          packId: 1,
          title: 'Submit form',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.oneTime,
            anchorDate: DateTime(2026, 4, 10),
            dueDate: DateTime(2026, 4, 15),
            overduePolicy: ItemOverduePolicy.waitForAction,
          ),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ),
      now: DateTime(2026, 4, 21),
    );

    expect(viewModel.displayState, ItemCardDisplayState.overdue);
    expect(viewModel.badgeLabel, '一次');
    expect(viewModel.dueDateLabel, '2026/04/15');
  });

  test('item card view model keeps state based danger display state', () {
    final viewModel = ItemCardViewModel.fromEntry(
      _entry(
        status: ItemStatus.danger,
        item: Item(
          id: 12,
          packId: 1,
          title: 'Clean litter box',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 4, 18),
            infoAfter: Duration.zero,
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ),
      now: DateTime(2026, 4, 21),
    );

    expect(viewModel.displayState, ItemCardDisplayState.danger);
  });

  test(
    'item card view model shows state based elapsed days in trailing label',
    () {
      final viewModel = ItemCardViewModel.fromEntry(
        _entry(
          status: ItemStatus.danger,
          item: Item(
            id: 14,
            packId: 1,
            title: 'Clean litter box',
            type: ItemType.stateBased,
            config: StateBasedItemConfig(
              anchorDate: DateTime(2026, 4, 18),
              infoAfter: Duration.zero,
              warningAfter: Duration(days: 1),
              dangerAfter: Duration(days: 2),
            ),
            createdAt: DateTime(2026, 4, 1),
            updatedAt: DateTime(2026, 4, 1),
          ),
        ),
        now: DateTime(2026, 4, 21),
      );

      expect(viewModel.trailingLabel, '已持續4日');
    },
  );

  test('item card view model shows fixed due state in trailing label', () {
    final remainingViewModel = ItemCardViewModel.fromEntry(
      _entry(
        status: ItemStatus.warning,
        item: Item(
          id: 15,
          packId: 1,
          title: 'Pay rent',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.oneTime,
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 12),
          ),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ),
      now: DateTime(2026, 4, 10),
    );
    final todayViewModel = ItemCardViewModel.fromEntry(
      _entry(
        status: ItemStatus.danger,
        item: Item(
          id: 16,
          packId: 1,
          title: 'Pay rent',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.oneTime,
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 12),
          ),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ),
      now: DateTime(2026, 4, 12),
    );
    final overdueViewModel = ItemCardViewModel.fromEntry(
      _entry(
        status: ItemStatus.danger,
        item: Item(
          id: 17,
          packId: 1,
          title: 'Pay rent',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.oneTime,
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 12),
            overduePolicy: ItemOverduePolicy.waitForAction,
          ),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ),
      now: DateTime(2026, 4, 13),
    );

    expect(remainingViewModel.trailingLabel, '剩餘2日');
    expect(todayViewModel.trailingLabel, '今天到期');
    expect(overdueViewModel.trailingLabel, '過期');
  });

  test(
    'item card view model shows resource remaining days in trailing label',
    () {
      final viewModel = ItemCardViewModel.fromEntry(
        _entry(
          status: ItemStatus.warning,
          item: Item(
            id: 13,
            packId: 1,
            title: 'Cat food',
            type: ItemType.resourceBased,
            config: ResourceBasedItemConfig(
              anchorDate: DateTime(2026, 4, 1),
              durationDays: 10,
              warningBefore: 2,
            ),
            createdAt: DateTime(2026, 4, 1),
            updatedAt: DateTime(2026, 4, 1),
          ),
        ),
        now: DateTime(2026, 4, 8),
      );

      expect(viewModel.trailingLabel, '剩餘2日');
    },
  );
}

ItemHomeEntry _entry({required ItemStatus status, required Item item}) {
  return ItemHomeEntry(
    bundle: ItemBundle(item: item, pack: _defaultPack()),
    status: status,
    elapsed: null,
  );
}

ItemPack _defaultPack() {
  return ItemPack(
    id: 1,
    title: 'Default Item Pack',
    status: ItemPackStatus.active,
    isSystemDefault: true,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}
