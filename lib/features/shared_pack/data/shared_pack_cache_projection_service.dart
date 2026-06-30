import 'package:drift/drift.dart';

import '../../reminders/data/local/app_database.dart';
import '../remote/shared_pack_remote_dto.dart';

class SharedPackCacheProjectionService {
  SharedPackCacheProjectionService(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const sharedPackCacheIconEmoji = '👥';
  static const sharedPackCacheDescription = 'Shared Pack cache projection';
  static const _stateBasedType = 'stateBased';
  static const _activeStatus = 'active';
  static const _systemDefaultAttentionPolicy = 'systemDefault';
  static const _stateExpectedAfterMinutes = 0;
  static const _stateWarningAfterMinutes = 1440;
  static const _stateDangerAfterMinutes = 2880;

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<SharedPackPackShellProjectionResult> projectPackShell({
    required String remotePackId,
    required String packName,
  }) {
    return _db.transaction(() async {
      final syncTime = _clock().millisecondsSinceEpoch;
      final projection = await _ensurePackMapping(
        FetchSharedPackSnapshotRemoteResponse(
          remotePackId: remotePackId,
          packName: packName,
          requesterRole: 'member',
          items: const [],
        ),
        syncTime,
      );

      return SharedPackPackShellProjectionResult(
        localPackId: projection.localPackId,
        remotePackId: remotePackId,
        createdPack: projection.created,
        updatedPack: !projection.created,
      );
    });
  }

  Future<SharedPackRemotePackMappingRef?> resolveRemotePackMappingByLocalPackId(
    int localPackId,
  ) async {
    final mapping = await (_db.select(
      _db.sharedPackRemotePackMappings,
    )..where((t) => t.localPackId.equals(localPackId))).getSingleOrNull();

    if (mapping == null) {
      return null;
    }

    return SharedPackRemotePackMappingRef(
      localPackId: mapping.localPackId,
      remotePackId: mapping.remotePackId,
    );
  }

  Future<SharedPackRemoteItemMappingRef?> resolveRemoteItemMappingByLocalItemId(
    int localItemId,
  ) async {
    final mapping = await (_db.select(
      _db.sharedPackRemoteItemMappings,
    )..where((t) => t.localItemId.equals(localItemId))).getSingleOrNull();

    if (mapping == null) {
      return null;
    }

    return SharedPackRemoteItemMappingRef(
      localItemId: mapping.localItemId,
      remoteItemId: mapping.remoteItemId,
      localPackId: mapping.localPackId,
      remotePackId: mapping.remotePackId,
    );
  }

  Future<SharedPackCacheProjectionResult> projectSnapshot(
    FetchSharedPackSnapshotRemoteResponse snapshot,
  ) {
    return _db.transaction(() async {
      final syncTime = _clock().millisecondsSinceEpoch;
      final packProjection = await _ensurePackMapping(snapshot, syncTime);
      var createdItemsCount = 0;
      var updatedItemsCount = 0;
      final localItemIds = <int>[];

      for (final remoteItem in snapshot.items) {
        final itemProjection = await _projectSnapshotItem(
          remoteItem,
          localPackId: packProjection.localPackId,
          remotePackId: snapshot.remotePackId,
          syncTime: syncTime,
        );
        localItemIds.add(itemProjection.localItemId);
        if (itemProjection.created) {
          createdItemsCount += 1;
        } else {
          updatedItemsCount += 1;
        }
      }

      return SharedPackCacheProjectionResult(
        localPackId: packProjection.localPackId,
        remotePackId: snapshot.remotePackId,
        createdPack: packProjection.created,
        updatedPack: !packProjection.created,
        createdItemsCount: createdItemsCount,
        updatedItemsCount: updatedItemsCount,
        localItemIds: localItemIds,
      );
    });
  }

  Future<SharedPackItemStateProjectionResult> projectItemState(
    UpdateSharedPackItemStateRemoteResponse response,
  ) {
    return _db.transaction(() async {
      final mapping = await _itemMappingByRemoteId(response.remoteItemId);
      if (mapping == null) {
        return SharedPackItemStateProjectionResult.missingMapping(
          remoteItemId: response.remoteItemId,
          remotePackId: response.remotePackId,
        );
      }

      if (mapping.remotePackId != response.remotePackId) {
        throw StateError('Remote item mapping pack mismatch.');
      }

      final syncTime = _clock().millisecondsSinceEpoch;
      await (_db.update(
        _db.items,
      )..where((t) => t.id.equals(mapping.localItemId))).write(
        ItemsCompanion(
          lastDoneAt: response.lastCompletedAt == null
              ? const Value.absent()
              : Value(response.lastCompletedAt!.millisecondsSinceEpoch),
          updatedAt: Value(response.updatedAt.millisecondsSinceEpoch),
        ),
      );

      await (_db.update(
        _db.sharedPackRemoteItemMappings,
      )..where((t) => t.id.equals(mapping.id))).write(
        SharedPackRemoteItemMappingsCompanion(
          lastRemoteState: Value(response.state),
          lastRemoteCompletedAt: Value(
            response.lastCompletedAt?.millisecondsSinceEpoch,
          ),
          updatedAt: Value(syncTime),
          lastSyncedAt: Value(syncTime),
        ),
      );

      return SharedPackItemStateProjectionResult.projected(
        localItemId: mapping.localItemId,
        localPackId: mapping.localPackId,
        remoteItemId: response.remoteItemId,
        remotePackId: response.remotePackId,
      );
    });
  }

  Future<_PackProjection> _ensurePackMapping(
    FetchSharedPackSnapshotRemoteResponse snapshot,
    int syncTime,
  ) async {
    final existingMapping = await _packMappingByRemoteId(snapshot.remotePackId);
    if (existingMapping != null) {
      await (_db.update(
        _db.itemPacks,
      )..where((t) => t.id.equals(existingMapping.localPackId))).write(
        ItemPacksCompanion(
          title: Value(snapshot.packName),
          description: const Value(sharedPackCacheDescription),
          iconEmoji: const Value(sharedPackCacheIconEmoji),
          status: const Value(_activeStatus),
          isSystemDefault: const Value(false),
          updatedAt: Value(syncTime),
        ),
      );
      await (_db.update(
        _db.sharedPackRemotePackMappings,
      )..where((t) => t.id.equals(existingMapping.id))).write(
        SharedPackRemotePackMappingsCompanion(
          updatedAt: Value(syncTime),
          lastSyncedAt: Value(syncTime),
        ),
      );
      return _PackProjection(
        localPackId: existingMapping.localPackId,
        created: false,
      );
    }

    final localPackId = await _db
        .into(_db.itemPacks)
        .insert(
          ItemPacksCompanion.insert(
            title: snapshot.packName,
            description: const Value(sharedPackCacheDescription),
            iconEmoji: const Value(sharedPackCacheIconEmoji),
            orderIndex: const Value(0),
            status: const Value(_activeStatus),
            isSystemDefault: const Value(false),
            createdAt: syncTime,
            updatedAt: syncTime,
          ),
        );

    await _db
        .into(_db.sharedPackRemotePackMappings)
        .insert(
          SharedPackRemotePackMappingsCompanion.insert(
            localPackId: localPackId,
            remotePackId: snapshot.remotePackId,
            createdAt: syncTime,
            updatedAt: syncTime,
            lastSyncedAt: Value(syncTime),
          ),
        );

    return _PackProjection(localPackId: localPackId, created: true);
  }

  Future<_ItemProjection> _projectSnapshotItem(
    SharedPackSnapshotItemRemoteDto remoteItem, {
    required int localPackId,
    required String remotePackId,
    required int syncTime,
  }) async {
    final existingMapping = await _itemMappingByRemoteId(
      remoteItem.remoteItemId,
    );
    if (existingMapping != null) {
      if (existingMapping.localPackId != localPackId ||
          existingMapping.remotePackId != remotePackId) {
        throw StateError('Remote item mapping pack mismatch.');
      }

      await (_db.update(
        _db.items,
      )..where((t) => t.id.equals(existingMapping.localItemId))).write(
        ItemsCompanion(
          packId: Value(localPackId),
          title: Value(remoteItem.title),
          description: Value(remoteItem.notes),
          status: const Value(_activeStatus),
          lastDoneAt: remoteItem.lastCompletedAt == null
              ? const Value.absent()
              : Value(remoteItem.lastCompletedAt!.millisecondsSinceEpoch),
          updatedAt: Value(remoteItem.updatedAt.millisecondsSinceEpoch),
        ),
      );

      await (_db.update(
        _db.sharedPackRemoteItemMappings,
      )..where((t) => t.id.equals(existingMapping.id))).write(
        SharedPackRemoteItemMappingsCompanion(
          localPackId: Value(localPackId),
          remotePackId: Value(remotePackId),
          lastRemoteState: Value(remoteItem.state),
          lastRemoteCompletedAt: Value(
            remoteItem.lastCompletedAt?.millisecondsSinceEpoch,
          ),
          updatedAt: Value(syncTime),
          lastSyncedAt: Value(syncTime),
        ),
      );

      return _ItemProjection(
        localItemId: existingMapping.localItemId,
        created: false,
      );
    }

    final localItemId = await _db
        .into(_db.items)
        .insert(
          ItemsCompanion.insert(
            packId: localPackId,
            title: remoteItem.title,
            description: Value(remoteItem.notes),
            status: const Value(_activeStatus),
            type: _stateBasedType,
            attentionPolicySource: const Value(_systemDefaultAttentionPolicy),
            stateAnchorDate: Value(
              remoteItem.lastCompletedAt?.millisecondsSinceEpoch,
            ),
            stateExpectedAfterMinutes: const Value(_stateExpectedAfterMinutes),
            stateWarningAfterMinutes: const Value(_stateWarningAfterMinutes),
            stateDangerAfterMinutes: const Value(_stateDangerAfterMinutes),
            lastDoneAt: Value(
              remoteItem.lastCompletedAt?.millisecondsSinceEpoch,
            ),
            createdAt: remoteItem.createdAt.millisecondsSinceEpoch,
            updatedAt: remoteItem.updatedAt.millisecondsSinceEpoch,
          ),
        );

    await _db
        .into(_db.sharedPackRemoteItemMappings)
        .insert(
          SharedPackRemoteItemMappingsCompanion.insert(
            localItemId: localItemId,
            remoteItemId: remoteItem.remoteItemId,
            localPackId: localPackId,
            remotePackId: remotePackId,
            lastRemoteState: Value(remoteItem.state),
            lastRemoteCompletedAt: Value(
              remoteItem.lastCompletedAt?.millisecondsSinceEpoch,
            ),
            createdAt: syncTime,
            updatedAt: syncTime,
            lastSyncedAt: Value(syncTime),
          ),
        );

    return _ItemProjection(localItemId: localItemId, created: true);
  }

  Future<SharedPackRemotePackMappingRow?> _packMappingByRemoteId(
    String remotePackId,
  ) {
    return (_db.select(
      _db.sharedPackRemotePackMappings,
    )..where((t) => t.remotePackId.equals(remotePackId))).getSingleOrNull();
  }

  Future<SharedPackRemoteItemMappingRow?> _itemMappingByRemoteId(
    String remoteItemId,
  ) {
    return (_db.select(
      _db.sharedPackRemoteItemMappings,
    )..where((t) => t.remoteItemId.equals(remoteItemId))).getSingleOrNull();
  }
}

class SharedPackCacheProjectionResult {
  const SharedPackCacheProjectionResult({
    required this.localPackId,
    required this.remotePackId,
    required this.createdPack,
    required this.updatedPack,
    required this.createdItemsCount,
    required this.updatedItemsCount,
    required this.localItemIds,
  });

  final int localPackId;
  final String remotePackId;
  final bool createdPack;
  final bool updatedPack;
  final int createdItemsCount;
  final int updatedItemsCount;
  final List<int> localItemIds;
}

class SharedPackItemStateProjectionResult {
  const SharedPackItemStateProjectionResult._({
    required this.status,
    required this.remoteItemId,
    required this.remotePackId,
    this.localItemId,
    this.localPackId,
  });

  factory SharedPackItemStateProjectionResult.projected({
    required int localItemId,
    required int localPackId,
    required String remoteItemId,
    required String remotePackId,
  }) {
    return SharedPackItemStateProjectionResult._(
      status: SharedPackItemStateProjectionStatus.projected,
      localItemId: localItemId,
      localPackId: localPackId,
      remoteItemId: remoteItemId,
      remotePackId: remotePackId,
    );
  }

  factory SharedPackItemStateProjectionResult.missingMapping({
    required String remoteItemId,
    required String remotePackId,
  }) {
    return SharedPackItemStateProjectionResult._(
      status: SharedPackItemStateProjectionStatus.missingMapping,
      remoteItemId: remoteItemId,
      remotePackId: remotePackId,
    );
  }

  final SharedPackItemStateProjectionStatus status;
  final int? localItemId;
  final int? localPackId;
  final String remoteItemId;
  final String remotePackId;
}

enum SharedPackItemStateProjectionStatus { projected, missingMapping }

class SharedPackPackShellProjectionResult {
  const SharedPackPackShellProjectionResult({
    required this.localPackId,
    required this.remotePackId,
    required this.createdPack,
    required this.updatedPack,
  });

  final int localPackId;
  final String remotePackId;
  final bool createdPack;
  final bool updatedPack;
}

class SharedPackRemotePackMappingRef {
  const SharedPackRemotePackMappingRef({
    required this.localPackId,
    required this.remotePackId,
  });

  final int localPackId;
  final String remotePackId;
}

class SharedPackRemoteItemMappingRef {
  const SharedPackRemoteItemMappingRef({
    required this.localItemId,
    required this.remoteItemId,
    required this.localPackId,
    required this.remotePackId,
  });

  final int localItemId;
  final String remoteItemId;
  final int localPackId;
  final String remotePackId;
}

class _PackProjection {
  const _PackProjection({required this.localPackId, required this.created});

  final int localPackId;
  final bool created;
}

class _ItemProjection {
  const _ItemProjection({required this.localItemId, required this.created});

  final int localItemId;
  final bool created;
}
