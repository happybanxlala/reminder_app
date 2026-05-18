import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/attention_summary_repository.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';

void main() {
  test('danger count includes danger resources', () async {
    final repository = AttentionSummaryRepository(
      homeRepository: _FakeHomeAttentionSource(
        dangerEntries: [
          _resourceEntry(
            title: 'Water filter',
            severity: HomeAttentionSeverity.danger,
          ),
        ],
      ),
    );

    final summary = await repository.getSummary(now: DateTime(2026, 5, 1));

    expect(summary.dangerResourceCount, 1);
    expect(summary.dangerCount, 1);
    expect(summary.totalCount, 1);
  });

  test('warning count includes warning resources', () async {
    final repository = AttentionSummaryRepository(
      homeRepository: _FakeHomeAttentionSource(
        warningEntries: [
          _resourceEntry(
            id: 2,
            title: 'Shampoo',
            severity: HomeAttentionSeverity.warning,
          ),
        ],
      ),
    );

    final summary = await repository.getSummary(now: DateTime(2026, 5, 1));

    expect(summary.warningResourceCount, 1);
    expect(summary.warningCount, 1);
    expect(summary.totalCount, 1);
  });

  test('stage upcoming count stays separate from danger and warning', () async {
    final repository = AttentionSummaryRepository(
      homeRepository: _FakeHomeAttentionSource(
        dangerEntries: [
          _itemEntry(title: 'Clean litter box'),
          _resourceEntry(
            id: 2,
            title: 'Water filter',
            severity: HomeAttentionSeverity.danger,
          ),
        ],
        warningEntries: [
          _resourceEntry(
            id: 3,
            title: 'Shampoo',
            severity: HomeAttentionSeverity.warning,
          ),
        ],
        stages: [
          StageOccurrence(
            stageTrackerId: 1,
            sourceType: StageRecordSourceType.generated,
            occurrenceDate: DateTime(2026, 5, 1),
            label: '滿 1 個月',
            reminderOffsetDays: 0,
          ),
        ],
      ),
    );

    final summary = await repository.getSummary(now: DateTime(2026, 5, 1));

    expect(summary.dangerItemCount, 1);
    expect(summary.dangerResourceCount, 1);
    expect(summary.warningResourceCount, 1);
    expect(summary.dangerCount, 2);
    expect(summary.warningCount, 1);
    expect(summary.stageUpcomingCount, 1);
    expect(summary.totalCount, 4);
  });
}

HomeAttentionEntry _itemEntry({int id = 1, required String title}) {
  final pack = _pack();
  return HomeAttentionEntry.item(
    entry: ItemHomeEntry(
      bundle: ItemBundle(
        item: Item(
          id: id,
          packId: pack.id,
          title: title,
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 4, 1),
            warningAfter: const Duration(days: 7),
            dangerAfter: const Duration(days: 14),
          ),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
        pack: pack,
      ),
      status: ItemStatus.danger,
    ),
    severity: HomeAttentionSeverity.danger,
    urgencyDate: DateTime(2026, 4, 14),
  );
}

HomeAttentionEntry _resourceEntry({
  int id = 1,
  required String title,
  required HomeAttentionSeverity severity,
}) {
  final pack = _pack();
  return HomeAttentionEntry.resource(
    bundle: ResourceBundle(
      resource: Resource(
        id: id,
        packId: pack.id,
        title: title,
        type: ResourceType.quantityBased,
        config: const QuantityBasedResourceConfig(
          currentQuantity: 0,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
      pack: pack,
    ),
    severity: severity,
    urgencyDate: null,
  );
}

ItemPack _pack() {
  return ItemPack(
    id: 1,
    title: '一般',
    status: ItemPackStatus.active,
    isSystemDefault: true,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

class _FakeHomeAttentionSource implements HomeAttentionSource {
  const _FakeHomeAttentionSource({
    this.dangerEntries = const [],
    this.warningEntries = const [],
    this.stages = const [],
  });

  final List<HomeAttentionEntry> dangerEntries;
  final List<HomeAttentionEntry> warningEntries;
  final List<StageOccurrence> stages;

  @override
  Stream<List<HomeAttentionEntry>> watchDangerAttentionEntries({
    DateTime? now,
  }) {
    return Stream.value(dangerEntries);
  }

  @override
  Stream<List<HomeAttentionEntry>> watchWarningAttentionEntries({
    DateTime? now,
  }) {
    return Stream.value(warningEntries);
  }

  @override
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now}) {
    return Stream.value(
      dangerEntries
          .where((entry) => entry.type == HomeAttentionEntryType.item)
          .map((entry) => entry.itemEntry!)
          .toList(growable: false),
    );
  }

  @override
  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now}) {
    return Stream.value(
      warningEntries
          .where((entry) => entry.type == HomeAttentionEntryType.item)
          .map((entry) => entry.itemEntry!)
          .toList(growable: false),
    );
  }

  @override
  Stream<List<StageOccurrence>> watchUpcomingStages({DateTime? now}) {
    return Stream.value(stages);
  }

  @override
  Stream<List<TodayCompletedEntry>> watchTodayCompletedEntries({
    DateTime? now,
  }) {
    return Stream.value(const <TodayCompletedEntry>[]);
  }
}
