import 'package:drift/drift.dart';

import '../domain/item.dart';
import '../domain/item_action_record.dart';
import '../domain/item_action_service.dart';
import '../domain/item_pack.dart';
import '../domain/item_pack_template.dart';
import '../domain/item_snapshot_update_service.dart';
import '../domain/item_status_service.dart';
import 'builtin_item_pack_templates.dart';
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
  ItemRepository(
    this._dao, {
    ItemStatusService? statusService,
    ItemActionService? actionService,
    ItemSnapshotUpdateService? snapshotUpdateService,
    DateTime Function()? clock,
  }) : _statusService = statusService ?? const ItemStatusService(),
       _actionService = actionService ?? const ItemActionService(),
       _snapshotUpdateService =
           snapshotUpdateService ??
           ItemSnapshotUpdateService(statusService: statusService),
       _clock = clock ?? DateTime.now;

  static const managedItemStatuses = {
    ItemLifecycleStatus.active,
    ItemLifecycleStatus.paused,
  };
  static const majorActivityActionTypes = {
    ItemActionType.created,
    ItemActionType.done,
    ItemActionType.skipped,
  };

  final ItemTimelineDao _dao;
  final ItemStatusService _statusService;
  final ItemActionService _actionService;
  final ItemSnapshotUpdateService _snapshotUpdateService;
  final DateTime Function() _clock;

  Stream<List<ItemPack>> watchPacks({bool includeArchived = false}) =>
      _dao.watchItemPacks(includeArchived: includeArchived);

  Stream<List<ItemPackTemplate>> watchTemplates() =>
      _dao.watchCustomItemPackTemplates().map(
        (customTemplates) => [...builtinItemPackTemplates, ...customTemplates],
      );

  Stream<List<ItemBundle>> watchItems() =>
      _dao.watchItemBundles(statuses: const {ItemLifecycleStatus.active});

  Stream<List<ItemBundle>> watchPackManagementItems() =>
      _dao.watchItemBundles(statuses: managedItemStatuses);

  Stream<List<ItemBundle>> watchItemsByStatus(
    ItemStatus status, {
    DateTime? now,
  }) {
    final current = now ?? _clock();
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

  Future<List<ItemActivityEntry>> listActivityFeed({
    int limit = 20,
    int offset = 0,
    String? query,
    int? recentDays,
    DateTime? now,
    DateTime? actionDateBefore,
    bool majorActionsOnly = true,
  }) {
    final current = _normalizeDate(now ?? _clock());
    final actionDateFrom = recentDays == null
        ? null
        : current.subtract(Duration(days: recentDays - 1));
    return _dao.listItemActivityEntries(
      actionTypes: majorActionsOnly ? majorActivityActionTypes : null,
      limit: limit,
      offset: offset,
      query: query,
      actionDateFrom: actionDateFrom,
      actionDateBefore: actionDateBefore == null
          ? null
          : _normalizeDate(actionDateBefore),
    );
  }

  Future<ItemBundle?> getItemById(int id) => _dao.getItemBundleById(id);

  Future<ItemPack?> getPackById(int id) => _dao.getItemPackById(id);

  Future<ItemPackTemplate?> getTemplateById(String id) async {
    for (final template in builtinItemPackTemplates) {
      if (template.id == id) {
        return template;
      }
    }
    final customId = int.tryParse(id.replaceFirst('custom-', ''));
    if (customId == null) {
      return null;
    }
    return _dao.getCustomItemPackTemplateById(customId);
  }

  Future<int> createItem(ItemInput input) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final itemId = await _createItemRecord(input, now: now);
      await _insertCreatedAction(itemId, now: now);
      return itemId;
    });
  }

  Future<int> createItemWithOptionalNewPack({
    required ItemInput item,
    ItemPackInput? newPack,
  }) async {
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final createdPackId = newPack == null
          ? null
          : await _dao.insertItemPack(_packCompanion(newPack, now: now));
      final resolvedInput = ItemInput(
        title: item.title,
        description: item.description,
        type: item.type,
        config: item.config,
        packId: createdPackId ?? item.packId,
      );
      final itemId = await _createItemRecord(resolvedInput, now: now);
      await _insertCreatedAction(itemId, now: now);
      return itemId;
    });
  }

  Future<bool> updateItem(int id, ItemInput input) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    if (input.type != existing.item.type) {
      return false;
    }
    final now = _clock();
    final packId = input.packId ?? existing.item.packId;
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
        fixedScheduleInterval: _fixedScheduleInterval(input.config),
        fixedMonthlyDay: _fixedMonthlyDay(input.config),
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
        lastDoneAt: existing.item.lastDoneAt?.millisecondsSinceEpoch,
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
    final action = _actionService.planDone(
      existing.item,
      doneAt: doneAt,
      fallbackNow: _clock(),
      remark: remark,
      addedDays: addedDays,
      nextCycleStrategy: nextCycleStrategy,
    );
    if (action == null) {
      return false;
    }
    return _recordAction(id, action: action);
  }

  Future<bool> skip(
    int id, {
    DateTime? actionAt,
    String? remark,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final action = _actionService.planSkip(
      existing.item,
      actionAt: actionAt,
      fallbackNow: _clock(),
      remark: remark,
      nextCycleStrategy: nextCycleStrategy,
    );
    if (action == null) {
      return false;
    }
    return _recordAction(id, action: action);
  }

  Future<bool> defer(
    int id, {
    required int deferDays,
    DateTime? actionAt,
    String? remark,
  }) async {
    return false;
  }

  Future<int> createPack(ItemPackInput input) async {
    final now = _clock();
    return _dao.insertItemPack(_packCompanion(input, now: now));
  }

  Future<bool> updatePack(int id, ItemPackInput input) async {
    final existing = await getPackById(id);
    if (existing == null ||
        existing.isSystemDefault ||
        existing.status == ItemPackStatus.archived) {
      return false;
    }
    final now = _clock();
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
    final now = _clock();
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

  Future<int> applyTemplate(ItemPackTemplate template) async {
    final now = _clock();
    final today = _normalizeDate(now);
    return _dao.attachedDatabase.transaction(() async {
      final packId = await _dao.insertItemPack(
        _packCompanion(
          ItemPackInput(
            title: '${template.name}(模版)',
            description: template.description,
          ),
          now: now,
        ),
      );
      for (final templateItem in template.items) {
        final itemId = await _createItemRecord(
          ItemInput(
            title: templateItem.title,
            description: templateItem.description,
            type: templateItem.type,
            config: _configForTemplateApply(templateItem.config, today),
            packId: packId,
          ),
          now: now,
        );
        await _insertCreatedAction(itemId, now: now);
      }
      return packId;
    });
  }

  Future<int?> savePackAsTemplate(
    int packId,
    ItemPackTemplateInput input,
  ) async {
    final pack = await getPackById(packId);
    if (pack == null || pack.isSystemDefault) {
      return null;
    }
    final items = await _dao.listItemBundles(statuses: managedItemStatuses);
    final packItems = items
        .where((bundle) => bundle.item.packId == packId)
        .toList(growable: false);
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final templateId = await _dao.insertItemPackTemplate(
        ItemPackTemplatesCompanion.insert(
          name: input.name,
          category: input.category,
          description: input.description,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      for (final bundle in packItems) {
        await _dao.insertItemTemplateItem(
          _templateItemCompanion(bundle.item, templateId: templateId, now: now),
        );
      }
      return templateId;
    });
  }

  Future<bool> deleteCustomTemplate(String id) async {
    final customId = int.tryParse(id.replaceFirst('custom-', ''));
    if (customId == null) {
      return false;
    }
    return await _dao.deleteItemPackTemplate(customId) > 0;
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
    required PlannedItemAction action,
  }) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final snapshot = _snapshotUpdateService.build(
        existing.item,
        action: action,
        updatedAt: now,
      );
      final updated = await _dao.updateItemFields(
        id,
        _companionForSnapshotUpdate(snapshot),
      );
      if (!updated) {
        return false;
      }
      await _dao.insertItemActionRecord(
        ItemActionRecordsCompanion.insert(
          itemId: id,
          actionType: action.type.name,
          actionDate: action.actionDate.millisecondsSinceEpoch,
          remark: Value(action.remark),
          payload: Value(ItemActionRecord.encodePayload(action.payload)),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return true;
    });
  }

  Future<void> _insertCreatedAction(int itemId, {required DateTime now}) {
    final actionDate = _normalizeDate(now);
    return _dao.insertItemActionRecord(
      ItemActionRecordsCompanion.insert(
        itemId: itemId,
        actionType: ItemActionType.created.name,
        actionDate: actionDate.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  ItemsCompanion _companionForSnapshotUpdate(ItemSnapshotUpdate snapshot) {
    return ItemsCompanion(
      fixedAnchorDate: _dateValue(snapshot.fixedAnchorDate),
      fixedDueDate: _dateValue(snapshot.fixedDueDate),
      stateAnchorDate: _dateValue(snapshot.stateAnchorDate),
      resourceAnchorDate: _dateValue(snapshot.resourceAnchorDate),
      resourceDurationDays: _intValue(snapshot.resourceDurationDays),
      lastDoneAt: _dateValue(snapshot.lastDoneAt),
      updatedAt: Value(snapshot.updatedAt.millisecondsSinceEpoch),
    );
  }

  Future<int> _createItemRecord(
    ItemInput input, {
    required DateTime now,
  }) async {
    final packId = input.packId ?? await _ensureDefaultPackId(now);
    await _assertPackCanAcceptItems(packId);
    return _dao.insertItem(_itemCompanion(input, packId: packId, now: now));
  }

  ItemsCompanion _itemCompanion(
    ItemInput input, {
    required int packId,
    required DateTime now,
  }) {
    return ItemsCompanion.insert(
      packId: packId,
      title: input.title,
      description: Value(input.description),
      status: const Value('active'),
      type: input.type.name,
      fixedScheduleType: Value(_fixedScheduleType(input.config)),
      fixedScheduleInterval: Value(_fixedScheduleInterval(input.config)),
      fixedMonthlyDay: Value(_fixedMonthlyDay(input.config)),
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
    );
  }

  ItemPacksCompanion _packCompanion(
    ItemPackInput input, {
    required DateTime now,
  }) {
    return ItemPacksCompanion.insert(
      title: input.title,
      description: Value(input.description),
      status: const Value('active'),
      isSystemDefault: const Value(false),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ItemTemplateItemsCompanion _templateItemCompanion(
    Item item, {
    required int templateId,
    required DateTime now,
  }) {
    return ItemTemplateItemsCompanion.insert(
      templateId: templateId,
      title: item.title,
      description: Value(item.description),
      type: item.type.name,
      fixedScheduleType: Value(_fixedScheduleType(item.config)),
      fixedScheduleInterval: Value(_fixedScheduleInterval(item.config)),
      fixedMonthlyDay: Value(_fixedMonthlyDay(item.config)),
      fixedTimeOfDay: Value(_fixedTimeOfDay(item.config)),
      fixedOverduePolicy: Value(_fixedOverduePolicy(item.config)),
      fixedExpectedBeforeMinutes: Value(
        _durationMinutes(_fixedInfoBefore(item.config)),
      ),
      fixedWarningBeforeMinutes: Value(
        _durationMinutes(_fixedWarningBefore(item.config)),
      ),
      fixedDangerBeforeMinutes: Value(
        _durationMinutes(_fixedDangerBefore(item.config)),
      ),
      stateExpectedAfterMinutes: Value(
        _durationMinutes(_stateInfoAfter(item.config)),
      ),
      stateWarningAfterMinutes: Value(
        _durationMinutes(_stateWarningAfter(item.config)),
      ),
      stateDangerAfterMinutes: Value(
        _durationMinutes(_stateDangerAfter(item.config)),
      ),
      resourceDurationDays: Value(_resourceDurationDays(item.config)),
      resourceExpectedBeforeDays: Value(_resourceInfoBefore(item.config)),
      resourceWarningBeforeDays: Value(_resourceWarningBefore(item.config)),
      resourceDangerBeforeDays: Value(_resourceDangerBefore(item.config)),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  ItemConfig _configForTemplateApply(ItemConfig config, DateTime today) {
    return switch (config) {
      FixedItemConfig fixed => FixedItemConfig(
        scheduleType: fixed.scheduleType,
        scheduleInterval: fixed.scheduleInterval,
        monthlyDay: fixed.monthlyDay ?? today.day,
        anchorDate: today,
        dueDate: _templateFixedDueDate(fixed, today),
        timeOfDay: fixed.timeOfDay,
        overduePolicy: fixed.overduePolicy,
        infoBefore: fixed.infoBefore,
        warningBefore: fixed.warningBefore,
        dangerBefore: fixed.dangerBefore,
      ),
      StateBasedItemConfig state => StateBasedItemConfig(
        anchorDate: today,
        infoAfter: state.infoAfter,
        warningAfter: state.warningAfter,
        dangerAfter: state.dangerAfter,
      ),
      ResourceBasedItemConfig resource => ResourceBasedItemConfig(
        durationDays: resource.durationDays,
        infoBefore: resource.infoBefore,
        warningBefore: resource.warningBefore,
        dangerBefore: resource.dangerBefore,
      ),
      _ => config,
    };
  }

  DateTime _templateFixedDueDate(FixedItemConfig config, DateTime today) {
    final interval = config.scheduleInterval < 1 ? 1 : config.scheduleInterval;
    return switch (config.scheduleType) {
      FixedScheduleType.daily || FixedScheduleType.oneTime => today,
      FixedScheduleType.weekly => today.add(const Duration(days: 6)),
      FixedScheduleType.everyXDays => today.add(Duration(days: interval - 1)),
      FixedScheduleType.everyXWeeks => today.add(
        Duration(days: interval * 7 - 1),
      ),
      FixedScheduleType.monthly => _addMonthsClamped(
        today,
        interval,
        preferredDay: config.monthlyDay ?? today.day,
      ).subtract(const Duration(days: 1)),
    };
  }

  DateTime _addMonthsClamped(
    DateTime value,
    int months, {
    required int preferredDay,
  }) {
    final targetMonth = DateTime(value.year, value.month + months);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = preferredDay.clamp(1, lastDay);
    return DateTime(targetMonth.year, targetMonth.month, day);
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

  int? _fixedScheduleInterval(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.scheduleInterval,
      _ => null,
    };
  }

  int? _fixedMonthlyDay(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.monthlyDay,
      _ => null,
    };
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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

  Value<int?> _dateValue(SnapshotValue<DateTime> value) {
    if (!value.present) {
      return const Value.absent();
    }
    return Value(value.value?.millisecondsSinceEpoch);
  }

  Value<int?> _intValue(SnapshotValue<int> value) {
    if (!value.present) {
      return const Value.absent();
    }
    return Value(value.value);
  }
}
