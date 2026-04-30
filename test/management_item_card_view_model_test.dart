import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/presentation/view_models/management_item_card_view_model.dart';

void main() {
  group('ManagementItemCardViewModel', () {
    test('fixed item shows normal next due label', () {
      final viewModel = ManagementItemCardViewModel.fromBundle(
        _bundle(
          1,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.weekly,
            anchorDate: DateTime(2026, 4, 10),
            dueDate: DateTime(2026, 4, 20),
            warningBefore: const Duration(days: 3),
            dangerBefore: const Duration(days: 1),
          ),
        ),
        now: DateTime(2026, 4, 11),
      );

      expect(viewModel.typeIcon, Icons.schedule_outlined);
      expect(viewModel.status.label, '下次截止：2026/04/20');
      expect(viewModel.status.isWarningOrDanger, isFalse);
      expect(viewModel.canComplete, isTrue);
    });

    test('fixed item shows not started before anchor date', () {
      final viewModel = ManagementItemCardViewModel.fromBundle(
        _bundle(
          1,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.weekly,
            anchorDate: DateTime(2026, 4, 20),
            dueDate: DateTime(2026, 4, 27),
          ),
        ),
        now: DateTime(2026, 4, 11),
      );

      expect(viewModel.status.label, '尚未開始');
      expect(viewModel.status.isNotStarted, isTrue);
      expect(viewModel.canComplete, isFalse);
      expect(viewModel.canSkip, isFalse);
    });

    test('fixed waitForAction item shows overdue danger label', () {
      final viewModel = ManagementItemCardViewModel.fromBundle(
        _bundle(
          1,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.oneTime,
            anchorDate: DateTime(2026, 4, 10),
            dueDate: DateTime(2026, 4, 10),
            overduePolicy: ItemOverduePolicy.waitForAction,
          ),
        ),
        now: DateTime(2026, 4, 12),
      );

      expect(viewModel.status.label, '需要處理：已逾期2天');
      expect(viewModel.status.isWarningOrDanger, isTrue);
    });

    test(
      'state based item keeps unknown baseline separate from not started',
      () {
        final viewModel = ManagementItemCardViewModel.fromBundle(
          _bundle(
            2,
            type: ItemType.stateBased,
            config: StateBasedItemConfig(
              warningAfter: const Duration(days: 5),
              dangerAfter: const Duration(days: 7),
            ),
          ),
          now: DateTime(2026, 4, 11),
        );

        expect(viewModel.typeIcon, Icons.gesture_outlined);
        expect(viewModel.status.label, '未建立基準');
        expect(viewModel.status.isUnknown, isTrue);
        expect(viewModel.requireCompletionConfirmation, isTrue);
      },
    );

    test(
      'state based item shows warning copy and requires confirm in normal only',
      () {
        final warningViewModel = ManagementItemCardViewModel.fromBundle(
          _bundle(
            2,
            type: ItemType.stateBased,
            config: StateBasedItemConfig(
              anchorDate: DateTime(2026, 4, 7),
              warningAfter: const Duration(days: 5),
              dangerAfter: const Duration(days: 7),
            ),
          ),
          now: DateTime(2026, 4, 11),
        );
        final normalViewModel = ManagementItemCardViewModel.fromBundle(
          _bundle(
            3,
            type: ItemType.stateBased,
            config: StateBasedItemConfig(
              anchorDate: DateTime(2026, 4, 10),
              warningAfter: const Duration(days: 5),
              dangerAfter: const Duration(days: 7),
            ),
          ),
          now: DateTime(2026, 4, 11),
        );

        expect(warningViewModel.status.label, '要留意：距上次處理已經有5天了');
        expect(warningViewModel.requireCompletionConfirmation, isFalse);
        expect(normalViewModel.status.label, '距上次處理：2天前');
        expect(normalViewModel.requireCompletionConfirmation, isTrue);
      },
    );

    test(
      'resource based item shows danger inventory label and disables skip',
      () {
        final viewModel = ManagementItemCardViewModel.fromBundle(
          _bundle(
            4,
            type: ItemType.resourceBased,
            config: ResourceBasedItemConfig(
              anchorDate: DateTime(2026, 4, 10),
              durationDays: 3,
              warningBefore: 2,
              dangerBefore: 1,
            ),
          ),
          now: DateTime(2026, 4, 11),
        );

        expect(viewModel.typeIcon, Icons.inventory_2_outlined);
        expect(viewModel.status.label, '需要處理：只剩1天庫存量');
        expect(viewModel.canComplete, isTrue);
        expect(viewModel.canSkip, isFalse);
      },
    );
  });
}

ItemBundle _bundle(
  int id, {
  ItemType type = ItemType.fixed,
  required ItemConfig config,
}) {
  return ItemBundle(
    item: Item(
      id: id,
      packId: 1,
      title: 'Item $id',
      type: type,
      config: config,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    pack: ItemPack(
      id: 1,
      title: 'Default Item Pack',
      status: ItemPackStatus.active,
      isSystemDefault: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  );
}
