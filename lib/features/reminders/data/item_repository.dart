import 'package:drift/drift.dart';

import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/item_status_service.dart';
import 'local/app_database.dart';
import 'local/item_timeline_dao.dart';

class ItemInput {
  const ItemInput({
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.packId,
  });

  final String title;
  final String? description;
  final ItemType type;
  final ItemConfig config;
  final int? packId;
}

class ItemRepository {
  ItemRepository(this._dao, {ItemStatusService? statusService})
    : _statusService = statusService ?? const ItemStatusService();

  final ItemTimelineDao _dao;
  final ItemStatusService _statusService;

  Stream<List<ItemPack>> watchPacks({bool includeArchived = false}) =>
      _dao.watchItemPacks(includeArchived: includeArchived);

  Stream<List<ItemBundle>> watchItems() => _dao.watchItemBundles();

  Stream<List<ItemBundle>> watchItemsByStatus(
    ItemStatus status, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return _dao.watchItemBundles().map(
      (items) => items
          .where(
            (item) =>
                _statusService.classify(item.item, now: current) == status,
          )
          .toList(growable: false),
    );
  }

  Future<ItemBundle?> getItemById(int id) => _dao.getItemBundleById(id);

  Future<ItemPack?> getPackById(int id) => _dao.getItemPackById(id);

  Future<int> createItem(ItemInput input) async {
    final now = DateTime.now();
    final packId = input.packId ?? await _ensureDefaultPackId(now);
    await _assertPackCanAcceptItems(packId);
    return _dao.insertItem(
      ItemsCompanion.insert(
        packId: packId,
        title: input.title,
        description: Value(input.description),
        type: input.type.name,
        fixedScheduleType: Value(_fixedScheduleType(input.config)),
        fixedAnchorDate: Value(_fixedAnchorDate(input.config)),
        fixedTimeOfDay: Value(_fixedTimeOfDay(input.config)),
        stateExpectedIntervalMinutes: Value(
          _durationMinutes(_stateExpectedInterval(input.config)),
        ),
        stateWarningAfterMinutes: Value(
          _durationMinutes(_stateWarningAfter(input.config)),
        ),
        stateDangerAfterMinutes: Value(
          _durationMinutes(_stateDangerAfter(input.config)),
        ),
        resourceEstimatedDurationMinutes: Value(
          _durationMinutes(_resourceEstimatedDuration(input.config)),
        ),
        resourceWarningBeforeDepletionMinutes: Value(
          _durationMinutes(_resourceWarningBeforeDepletion(input.config)),
        ),
        lastDoneAt: const Value.absent(),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateItem(int id, ItemInput input) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final now = DateTime.now();
    final packId = input.packId ?? existing.item.packId;
    await _assertPackCanAcceptItems(packId, existingItem: existing.item);
    return _dao.updateItemRecord(
      ItemRow(
        id: existing.item.id,
        packId: packId,
        title: input.title,
        description: input.description,
        type: input.type.name,
        fixedScheduleType: _fixedScheduleType(input.config),
        fixedAnchorDate: _fixedAnchorDate(input.config),
        fixedTimeOfDay: _fixedTimeOfDay(input.config),
        stateExpectedIntervalMinutes: _durationMinutes(
          _stateExpectedInterval(input.config),
        ),
        stateWarningAfterMinutes: _durationMinutes(
          _stateWarningAfter(input.config),
        ),
        stateDangerAfterMinutes: _durationMinutes(
          _stateDangerAfter(input.config),
        ),
        resourceEstimatedDurationMinutes: _durationMinutes(
          _resourceEstimatedDuration(input.config),
        ),
        resourceWarningBeforeDepletionMinutes: _durationMinutes(
          _resourceWarningBeforeDepletion(input.config),
        ),
        lastDoneAt: existing.item.lastDoneAt?.millisecondsSinceEpoch,
        createdAt: existing.item.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> markDone(int id, {DateTime? doneAt}) {
    return _dao.markItemDone(id, doneAt: doneAt);
  }

  Future<int> createPack(ItemPackInput input) async {
    final now = DateTime.now();
    return _dao.insertItemPack(
      ItemPacksCompanion.insert(
        title: input.title,
        description: Value(input.description),
        status: const Value('active'),
        isSystemDefault: const Value(false),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updatePack(int id, ItemPackInput input) async {
    final existing = await getPackById(id);
    if (existing == null ||
        existing.isSystemDefault ||
        existing.status == ItemPackStatus.archived) {
      return false;
    }
    final now = DateTime.now();
    return _dao.updateItemPackRecord(
      ItemPackRow(
        id: existing.id,
        title: input.title,
        description: input.description,
        status: existing.status.name,
        isSystemDefault: existing.isSystemDefault,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> canArchivePack(int id) async {
    final pack = await getPackById(id);
    if (pack == null ||
        pack.isSystemDefault ||
        pack.status == ItemPackStatus.archived) {
      return false;
    }
    final itemCount = await _dao.countItemsForPack(id);
    return itemCount == 0;
  }

  Future<bool> archivePack(int id) async {
    final existing = await getPackById(id);
    if (existing == null || !await canArchivePack(id)) {
      return false;
    }
    final now = DateTime.now();
    return _dao.updateItemPackRecord(
      ItemPackRow(
        id: existing.id,
        title: existing.title,
        description: existing.description,
        status: ItemPackStatus.archived.name,
        isSystemDefault: existing.isSystemDefault,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  ItemStatus statusFor(Item item, {DateTime? now}) {
    return _statusService.classify(item, now: now);
  }

  Duration? elapsedFor(Item item, {DateTime? now}) {
    return _statusService.elapsedSinceLastDone(item, now: now);
  }

  Future<int> _ensureDefaultPackId(DateTime now) async {
    final packs = await _dao.listItemPacks(includeArchived: true);
    for (final pack in packs) {
      if (pack.isSystemDefault) {
        return pack.id;
      }
    }
    return _dao.insertItemPack(
      ItemPacksCompanion.insert(
        title: AppDatabase.systemDefaultPackTitle,
        description: const Value(AppDatabase.systemDefaultPackDescription),
        status: const Value('active'),
        isSystemDefault: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _assertPackCanAcceptItems(
    int packId, {
    Item? existingItem,
  }) async {
    final pack = await getPackById(packId);
    if (pack == null) {
      throw StateError('Item pack not found.');
    }
    if (pack.status == ItemPackStatus.active) {
      return;
    }
    if (existingItem != null && existingItem.packId == pack.id) {
      return;
    }
    throw StateError('Archived item pack cannot accept items.');
  }

  String? _fixedScheduleType(ItemConfig config) {
    return switch (config) {
      FixedTimeItemConfig fixed => fixed.scheduleType.name,
      _ => null,
    };
  }

  int? _fixedAnchorDate(ItemConfig config) {
    return switch (config) {
      FixedTimeItemConfig fixed => fixed.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  String? _fixedTimeOfDay(ItemConfig config) {
    return switch (config) {
      FixedTimeItemConfig fixed => fixed.timeOfDay,
      _ => null,
    };
  }

  Duration? _stateExpectedInterval(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.expectedInterval,
      _ => null,
    };
  }

  Duration? _stateWarningAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.warningAfter,
      _ => null,
    };
  }

  Duration? _stateDangerAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.dangerAfter,
      _ => null,
    };
  }

  Duration? _resourceEstimatedDuration(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.estimatedDuration,
      _ => null,
    };
  }

  Duration? _resourceWarningBeforeDepletion(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.warningBeforeDepletion,
      _ => null,
    };
  }

  int? _durationMinutes(Duration? value) {
    return value?.inMinutes;
  }
}
