import 'package:drift/drift.dart';

import '../domain/item_action_record.dart';
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

  static const managedItemStatuses = {
    ItemLifecycleStatus.active,
    ItemLifecycleStatus.paused,
  };

  final ItemTimelineDao _dao;
  final ItemStatusService _statusService;

  Stream<List<ItemPack>> watchPacks({bool includeArchived = false}) =>
      _dao.watchItemPacks(includeArchived: includeArchived);

  Stream<List<ItemBundle>> watchItems() =>
      _dao.watchItemBundles(statuses: const {ItemLifecycleStatus.active});

  Stream<List<ItemBundle>> watchPackManagementItems() =>
      _dao.watchItemBundles(statuses: managedItemStatuses);

  Stream<List<ItemBundle>> watchItemsByStatus(
    ItemStatus status, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return watchItems().map(
      (items) => items
          .where(
            (item) =>
                _statusService.classify(item.item, now: current) == status,
          )
          .toList(growable: false),
    );
  }

  Stream<List<ItemActionRecord>> watchActionHistory(int itemId) {
    return _dao.watchItemActionRecordsForItem(itemId);
  }

  Future<List<ItemActionRecord>> listActionHistory(int itemId) {
    return _dao.listItemActionRecordsForItem(itemId);
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
        status: const Value('active'),
        type: input.type.name,
        fixedScheduleType: Value(_fixedScheduleType(input.config)),
        fixedAnchorDate: Value(_fixedAnchorDate(input.config)),
        fixedDueDate: Value(_fixedDueDate(input.config)),
        fixedTimeOfDay: Value(_fixedTimeOfDay(input.config)),
        fixedOverduePolicy: Value(_fixedOverduePolicy(input.config)),
        fixedExpectedBeforeMinutes: Value(
          _durationMinutes(_fixedInfoBefore(input.config)),
        ),
        fixedWarningBeforeMinutes: Value(
          _durationMinutes(_fixedWarningBefore(input.config)),
        ),
        fixedDangerBeforeMinutes: Value(
          _durationMinutes(_fixedDangerBefore(input.config)),
        ),
        stateExpectedAfterMinutes: Value(
          _durationMinutes(_stateInfoAfter(input.config)),
        ),
        stateAnchorDate: Value(_stateAnchorDate(input.config)),
        stateWarningAfterMinutes: Value(
          _durationMinutes(_stateWarningAfter(input.config)),
        ),
        stateDangerAfterMinutes: Value(
          _durationMinutes(_stateDangerAfter(input.config)),
        ),
        resourceAnchorDate: Value(_resourceAnchorDate(input.config)),
        resourceDurationDays: Value(_resourceDurationDays(input.config)),
        resourceExpectedBeforeDays: Value(_resourceInfoBefore(input.config)),
        resourceWarningBeforeDays: Value(_resourceWarningBefore(input.config)),
        resourceDangerBeforeDays: Value(_resourceDangerBefore(input.config)),
        lastDoneAt: Value(_snapshotLastDoneAtForCreate(input.config)),
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
    final lastDoneAt = _updatedLastDoneAtForSave(existing.item, input.config);
    await _assertPackCanAcceptItems(packId, existingItem: existing.item);
    return _dao.updateItemRecord(
      ItemRow(
        id: existing.item.id,
        packId: packId,
        title: input.title,
        description: input.description,
        status: existing.item.status.name,
        type: input.type.name,
        fixedScheduleType: _fixedScheduleType(input.config),
        fixedAnchorDate: _fixedAnchorDate(input.config),
        fixedDueDate: _fixedDueDate(input.config),
        fixedTimeOfDay: _fixedTimeOfDay(input.config),
        fixedOverduePolicy: _fixedOverduePolicy(input.config),
        fixedExpectedBeforeMinutes: _durationMinutes(
          _fixedInfoBefore(input.config),
        ),
        fixedWarningBeforeMinutes: _durationMinutes(
          _fixedWarningBefore(input.config),
        ),
        fixedDangerBeforeMinutes: _durationMinutes(
          _fixedDangerBefore(input.config),
        ),
        stateExpectedAfterMinutes: _durationMinutes(
          _stateInfoAfter(input.config),
        ),
        stateAnchorDate: _stateAnchorDate(input.config),
        stateWarningAfterMinutes: _durationMinutes(
          _stateWarningAfter(input.config),
        ),
        stateDangerAfterMinutes: _durationMinutes(
          _stateDangerAfter(input.config),
        ),
        resourceAnchorDate: _resourceAnchorDate(input.config),
        resourceDurationDays: _resourceDurationDays(input.config),
        resourceExpectedBeforeDays: _resourceInfoBefore(input.config),
        resourceWarningBeforeDays: _resourceWarningBefore(input.config),
        resourceDangerBeforeDays: _resourceDangerBefore(input.config),
        lastDoneAt: lastDoneAt?.millisecondsSinceEpoch,
        createdAt: existing.item.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> markDone(
    int id, {
    DateTime? doneAt,
    String? remark,
    int? addedDays,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final payload = <String, Object?>{
      'nextCycleStrategy': nextCycleStrategy.name,
    };
    if (existing.item.type == ItemType.resourceBased) {
      if (addedDays == null || addedDays <= 0) {
        return false;
      }
      payload['addedDays'] = addedDays;
    } else if (addedDays != null) {
      payload['addedDays'] = addedDays;
    }
    return _recordAction(
      id,
      actionType: ItemActionType.done,
      actionDate: doneAt,
      remark: remark,
      payload: payload,
    );
  }

  Future<bool> skip(
    int id, {
    DateTime? actionAt,
    String? remark,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    final existing = await getItemById(id);
    if (existing == null || existing.item.type == ItemType.resourceBased) {
      return false;
    }
    return _recordAction(
      id,
      actionType: ItemActionType.skipped,
      actionDate: actionAt,
      remark: remark,
      payload: {'nextCycleStrategy': nextCycleStrategy.name},
    );
  }

  Future<bool> defer(
    int id, {
    required int deferDays,
    DateTime? actionAt,
    String? remark,
  }) {
    return _recordAction(
      id,
      actionType: ItemActionType.deferred,
      actionDate: actionAt,
      remark: remark,
      payload: {'deferDays': deferDays},
    );
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
    return pack != null &&
        !pack.isSystemDefault &&
        pack.status != ItemPackStatus.archived;
  }

  Future<int> countPackManagedItems(int id) {
    return _dao.countItemsForPack(id, statuses: managedItemStatuses);
  }

  Future<bool> archivePack(int id) async {
    final existing = await getPackById(id);
    if (existing == null || !await canArchivePack(id)) {
      return false;
    }
    final now = DateTime.now();
    final updated = await _dao.updateItemPackRecord(
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
    if (!updated) {
      return false;
    }
    await _dao.updateItemsStatusForPack(id, ItemLifecycleStatus.archived);
    return true;
  }

  Future<bool> pauseItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status != ItemLifecycleStatus.active) {
      return false;
    }
    return _dao.updateItemStatus(id, ItemLifecycleStatus.paused);
  }

  Future<bool> resumeItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status != ItemLifecycleStatus.paused) {
      return false;
    }
    return _dao.updateItemStatus(id, ItemLifecycleStatus.active);
  }

  Future<bool> archiveItem(int id) async {
    final existing = await getItemById(id);
    if (existing == null ||
        existing.item.status == ItemLifecycleStatus.archived) {
      return false;
    }
    return _dao.updateItemStatus(id, ItemLifecycleStatus.archived);
  }

  ItemStatus statusFor(Item item, {DateTime? now}) {
    return _statusService.classify(item, now: now);
  }

  Duration? elapsedFor(Item item, {DateTime? now}) {
    return _statusService.elapsedSinceLastDone(item, now: now);
  }

  Future<bool> _recordAction(
    int id, {
    required ItemActionType actionType,
    DateTime? actionDate,
    String? remark,
    Map<String, Object?>? payload,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final normalizedActionDate = _normalizeDate(actionDate ?? DateTime.now());
    final now = DateTime.now();
    return _dao.attachedDatabase.transaction(() async {
      final companion = _updatedItemSnapshot(
        existing.item,
        actionType: actionType,
        actionDate: normalizedActionDate,
        payload: payload,
        updatedAt: now,
      );
      final updated = await _dao.updateItemFields(id, companion);
      if (!updated) {
        return false;
      }
      await _dao.insertItemActionRecord(
        ItemActionRecordsCompanion.insert(
          itemId: id,
          actionType: actionType.name,
          actionDate: normalizedActionDate.millisecondsSinceEpoch,
          remark: Value(remark),
          payload: Value(ItemActionRecord.encodePayload(payload)),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return true;
    });
  }

  ItemsCompanion _updatedItemSnapshot(
    Item item, {
    required ItemActionType actionType,
    required DateTime actionDate,
    required Map<String, Object?>? payload,
    required DateTime updatedAt,
  }) {
    return switch (item.config) {
      FixedItemConfig config => _updateFixedItemSnapshot(
        item,
        config,
        actionType: actionType,
        actionDate: actionDate,
        payload: payload,
        updatedAt: updatedAt,
      ),
      StateBasedItemConfig config => _updateStateBasedSnapshot(
        config,
        actionType: actionType,
        actionDate: actionDate,
        updatedAt: updatedAt,
      ),
      ResourceBasedItemConfig config => _updateResourceSnapshot(
        config,
        actionType: actionType,
        actionDate: actionDate,
        payload: payload,
        updatedAt: updatedAt,
      ),
      _ => ItemsCompanion(updatedAt: Value(updatedAt.millisecondsSinceEpoch)),
    };
  }

  ItemsCompanion _updateFixedItemSnapshot(
    Item item,
    FixedItemConfig config, {
    required ItemActionType actionType,
    required DateTime actionDate,
    required Map<String, Object?>? payload,
    required DateTime updatedAt,
  }) {
    final cycle = _statusService.resolveFixedCycle(config, now: actionDate);
    final nextCycleStrategy = ItemNextCycleStrategy.values.byName(
      (payload?['nextCycleStrategy'] as String?) ??
          ItemNextCycleStrategy.keepSchedule.name,
    );
    var anchorDate = config.anchorDate;
    var dueDate = config.dueDate;
    var lastDoneAt = item.lastDoneAt;

    if (actionType == ItemActionType.deferred) {
      final deferDays = (payload?['deferDays'] as num?)?.toInt() ?? 0;
      if (anchorDate != null) {
        anchorDate = anchorDate.add(Duration(days: deferDays));
      }
      if (dueDate != null) {
        dueDate = dueDate.add(Duration(days: deferDays));
      }
    } else if (cycle != null &&
        config.scheduleType != FixedScheduleType.oneTime) {
      anchorDate = _statusService.nextFixedCycleAnchor(cycle, config);
      dueDate = _statusService.nextFixedCycleDue(cycle, config);
      if (config.overduePolicy == ItemOverduePolicy.waitForAction &&
          actionDate.isAfter(cycle.dueDate) &&
          nextCycleStrategy == ItemNextCycleStrategy.shiftByDelay) {
        final delayDays = actionDate.difference(cycle.dueDate).inDays;
        anchorDate = _statusService.shiftDateByDelay(anchorDate, delayDays);
        dueDate = _statusService.shiftDateByDelay(dueDate, delayDays);
      }
    }

    if (actionType == ItemActionType.done) {
      lastDoneAt = actionDate;
    }

    return ItemsCompanion(
      fixedAnchorDate: Value(anchorDate?.millisecondsSinceEpoch),
      fixedDueDate: Value(dueDate?.millisecondsSinceEpoch),
      lastDoneAt: Value(lastDoneAt?.millisecondsSinceEpoch),
      updatedAt: Value(updatedAt.millisecondsSinceEpoch),
    );
  }

  ItemsCompanion _updateStateBasedSnapshot(
    StateBasedItemConfig config, {
    required ItemActionType actionType,
    required DateTime actionDate,
    required DateTime updatedAt,
  }) {
    return ItemsCompanion(
      stateAnchorDate: actionType == ItemActionType.done
          ? Value(actionDate.millisecondsSinceEpoch)
          : Value(config.anchorDate?.millisecondsSinceEpoch),
      lastDoneAt: const Value(null),
      updatedAt: Value(updatedAt.millisecondsSinceEpoch),
    );
  }

  ItemsCompanion _updateResourceSnapshot(
    ResourceBasedItemConfig config, {
    required ItemActionType actionType,
    required DateTime actionDate,
    required Map<String, Object?>? payload,
    required DateTime updatedAt,
  }) {
    var anchorDate = config.anchorDate;
    var durationDays = config.durationDays;
    int? lastDoneAt;

    if (actionType == ItemActionType.done) {
      final nextAddedDays =
          (payload?['addedDays'] as num?)?.toInt() ?? durationDays;
      if (anchorDate == null || durationDays <= 0) {
        anchorDate = actionDate;
        durationDays = nextAddedDays;
      } else {
        final depletionDate = anchorDate.add(Duration(days: durationDays - 1));
        if (actionDate.isAfter(depletionDate)) {
          anchorDate = actionDate;
          durationDays = nextAddedDays;
        } else {
          final remainingCarryDays =
              depletionDate.difference(actionDate).inDays + 1;
          durationDays =
              (remainingCarryDays < 0 ? 0 : remainingCarryDays) + nextAddedDays;
          anchorDate = actionDate;
        }
      }
      lastDoneAt = actionDate.millisecondsSinceEpoch;
    }

    return ItemsCompanion(
      resourceAnchorDate: Value(anchorDate?.millisecondsSinceEpoch),
      resourceDurationDays: Value(durationDays),
      lastDoneAt: lastDoneAt == null ? const Value.absent() : Value(lastDoneAt),
      updatedAt: Value(updatedAt.millisecondsSinceEpoch),
    );
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
      FixedItemConfig fixed => fixed.scheduleType.name,
      _ => null,
    };
  }

  int? _fixedAnchorDate(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  int? _fixedDueDate(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.dueDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  String? _fixedTimeOfDay(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.timeOfDay,
      _ => null,
    };
  }

  String? _fixedOverduePolicy(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.overduePolicy.name,
      _ => null,
    };
  }

  Duration? _fixedInfoBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.infoBefore,
      _ => null,
    };
  }

  Duration? _fixedWarningBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.warningBefore,
      _ => null,
    };
  }

  Duration? _fixedDangerBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.dangerBefore,
      _ => null,
    };
  }

  Duration? _stateInfoAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.infoAfter,
      _ => null,
    };
  }

  int? _stateAnchorDate(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.anchorDate?.millisecondsSinceEpoch,
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

  int? _resourceAnchorDate(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource =>
        resource.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  int? _resourceDurationDays(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.durationDays,
      _ => null,
    };
  }

  int? _resourceInfoBefore(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.infoBefore,
      _ => null,
    };
  }

  int? _resourceWarningBefore(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.warningBefore,
      _ => null,
    };
  }

  int? _resourceDangerBefore(ItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.dangerBefore,
      _ => null,
    };
  }

  int? _durationMinutes(Duration? value) {
    return value?.inMinutes;
  }

  int? _snapshotLastDoneAtForCreate(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig _ => null,
      _ => null,
    };
  }

  DateTime? _updatedLastDoneAtForSave(Item existing, ItemConfig nextConfig) {
    if (nextConfig is! StateBasedItemConfig) {
      return existing.lastDoneAt;
    }
    return null;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
