import 'package:drift/drift.dart';

import '../domain/responsibility_item.dart';
import '../domain/responsibility_pack.dart';
import '../domain/responsibility_status_service.dart';
import 'local/app_database.dart';
import 'local/responsibility_timeline_dao.dart';

class ResponsibilityItemInput {
  const ResponsibilityItemInput({
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.packId,
  });

  final String title;
  final String? description;
  final ResponsibilityItemType type;
  final ResponsibilityItemConfig config;
  final int? packId;
}

class ResponsibilityRepository {
  ResponsibilityRepository(
    this._dao, {
    ResponsibilityStatusService? statusService,
  }) : _statusService = statusService ?? const ResponsibilityStatusService();

  final ResponsibilityTimelineDao _dao;
  final ResponsibilityStatusService _statusService;

  Stream<List<ResponsibilityPack>> watchPacks({bool includeArchived = false}) =>
      _dao.watchResponsibilityPacks(includeArchived: includeArchived);

  Stream<List<ResponsibilityItemBundle>> watchItems() =>
      _dao.watchResponsibilityItemBundles();

  Stream<List<ResponsibilityItemBundle>> watchItemsByStatus(
    ResponsibilityItemStatus status, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return _dao.watchResponsibilityItemBundles().map(
      (items) => items
          .where(
            (item) =>
                _statusService.classify(item.item, now: current) == status,
          )
          .toList(growable: false),
    );
  }

  Future<ResponsibilityItemBundle?> getItemById(int id) =>
      _dao.getResponsibilityItemBundleById(id);

  Future<ResponsibilityPack?> getPackById(int id) =>
      _dao.getResponsibilityPackById(id);

  Future<int> createItem(ResponsibilityItemInput input) async {
    final now = DateTime.now();
    final packId = input.packId ?? await _ensureDefaultPackId(now);
    await _assertPackCanAcceptItems(packId);
    return _dao.insertResponsibilityItem(
      ResponsibilityItemsCompanion.insert(
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

  Future<bool> updateItem(int id, ResponsibilityItemInput input) async {
    final existing = await getItemById(id);
    if (existing == null) {
      return false;
    }
    final now = DateTime.now();
    final packId = input.packId ?? existing.item.packId;
    await _assertPackCanAcceptItems(packId, existingItem: existing.item);
    return _dao.updateResponsibilityItemRecord(
      ResponsibilityItemRow(
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
    return _dao.markResponsibilityItemDone(id, doneAt: doneAt);
  }

  Future<int> createPack(ResponsibilityPackInput input) async {
    final now = DateTime.now();
    return _dao.insertResponsibilityPack(
      ResponsibilityPacksCompanion.insert(
        title: input.title,
        description: Value(input.description),
        status: const Value('active'),
        isSystemDefault: const Value(false),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updatePack(int id, ResponsibilityPackInput input) async {
    final existing = await getPackById(id);
    if (existing == null ||
        existing.isSystemDefault ||
        existing.status == ResponsibilityPackStatus.archived) {
      return false;
    }
    final now = DateTime.now();
    return _dao.updateResponsibilityPackRecord(
      ResponsibilityPackRow(
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
        pack.status == ResponsibilityPackStatus.archived) {
      return false;
    }
    final itemCount = await _dao.countResponsibilityItemsForPack(id);
    return itemCount == 0;
  }

  Future<bool> archivePack(int id) async {
    final existing = await getPackById(id);
    if (existing == null || !await canArchivePack(id)) {
      return false;
    }
    final now = DateTime.now();
    return _dao.updateResponsibilityPackRecord(
      ResponsibilityPackRow(
        id: existing.id,
        title: existing.title,
        description: existing.description,
        status: ResponsibilityPackStatus.archived.name,
        isSystemDefault: existing.isSystemDefault,
        createdAt: existing.createdAt.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  ResponsibilityItemStatus statusFor(ResponsibilityItem item, {DateTime? now}) {
    return _statusService.classify(item, now: now);
  }

  Duration? elapsedFor(ResponsibilityItem item, {DateTime? now}) {
    return _statusService.elapsedSinceLastDone(item, now: now);
  }

  Future<int> _ensureDefaultPackId(DateTime now) async {
    final packs = await _dao.listResponsibilityPacks(includeArchived: true);
    for (final pack in packs) {
      if (pack.isSystemDefault) {
        return pack.id;
      }
    }
    return _dao.insertResponsibilityPack(
      ResponsibilityPacksCompanion.insert(
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
    ResponsibilityItem? existingItem,
  }) async {
    final pack = await getPackById(packId);
    if (pack == null) {
      throw StateError('Responsibility pack not found.');
    }
    if (pack.status == ResponsibilityPackStatus.active) {
      return;
    }
    if (existingItem != null && existingItem.packId == pack.id) {
      return;
    }
    throw StateError('Archived responsibility pack cannot accept items.');
  }

  String? _fixedScheduleType(ResponsibilityItemConfig config) {
    return switch (config) {
      FixedTimeItemConfig fixed => fixed.scheduleType.name,
      _ => null,
    };
  }

  int? _fixedAnchorDate(ResponsibilityItemConfig config) {
    return switch (config) {
      FixedTimeItemConfig fixed => fixed.anchorDate?.millisecondsSinceEpoch,
      _ => null,
    };
  }

  String? _fixedTimeOfDay(ResponsibilityItemConfig config) {
    return switch (config) {
      FixedTimeItemConfig fixed => fixed.timeOfDay,
      _ => null,
    };
  }

  Duration? _stateExpectedInterval(ResponsibilityItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.expectedInterval,
      _ => null,
    };
  }

  Duration? _stateWarningAfter(ResponsibilityItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.warningAfter,
      _ => null,
    };
  }

  Duration? _stateDangerAfter(ResponsibilityItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.dangerAfter,
      _ => null,
    };
  }

  Duration? _resourceEstimatedDuration(ResponsibilityItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.estimatedDuration,
      _ => null,
    };
  }

  Duration? _resourceWarningBeforeDepletion(ResponsibilityItemConfig config) {
    return switch (config) {
      ResourceBasedItemConfig resource => resource.warningBeforeDepletion,
      _ => null,
    };
  }

  int? _durationMinutes(Duration? value) {
    return value?.inMinutes;
  }
}
