import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/remote_backed_pack_refresh.dart';
import '../domain/remote_sync.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_models.dart';
import 'remote_shared_pack_repository.dart';
import 'remote_snapshot_import_service.dart';

typedef RemotePackSnapshotPuller =
    Future<RemotePocResult<RemotePackSnapshot>> Function(String remotePackId);

typedef RemotePackSnapshotImporter =
    Future<RemoteSnapshotImportResult> Function({
      required RemotePackSnapshot snapshot,
      required RemoteSnapshotImportSource source,
    });

class RemoteBackedPackRefreshService {
  const RemoteBackedPackRefreshService({
    required ReminderDao dao,
    required RemotePackSnapshotPuller pullRemotePackSnapshot,
    required RemotePackSnapshotImporter importRemotePackSnapshot,
    DateTime Function()? clock,
  }) : _dao = dao,
       _pullRemotePackSnapshot = pullRemotePackSnapshot,
       _importRemotePackSnapshot = importRemotePackSnapshot,
       _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final RemotePackSnapshotPuller _pullRemotePackSnapshot;
  final RemotePackSnapshotImporter _importRemotePackSnapshot;
  final DateTime Function() _clock;

  Future<RemoteBackedPackRefreshResult> refreshPack(int localPackId) async {
    final pack = await _dao.getItemPackById(localPackId);
    final metadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      localPackId,
    );
    final mapping = await _dao.getSyncMapping(
      localEntityType: RemoteSharedPackRepository.localEntityPack,
      localEntityId: localPackId,
      remoteTable: RemoteSharedPackRepository.remoteTablePacks,
    );
    final remotePackId = _remotePackId(metadata, mapping?.remoteEntityId);
    final staleBeforeRefresh = metadata?.syncState == RemotePackSyncState.stale;
    final outboxSummary = await _outboxSummary(localPackId);
    final baseSummary = RemoteBackedPackRefreshSummary(
      localPackId: localPackId,
      remotePackId: remotePackId,
      hasPendingLocalMutations: outboxSummary.hasUnresolved,
      pendingMutationCount: outboxSummary.pendingCount,
      failedMutationCount: outboxSummary.failedCount,
      staleBeforeRefresh: staleBeforeRefresh,
      staleAfterRefresh: staleBeforeRefresh,
      warnings: _outboxWarnings(outboxSummary),
    );

    if (pack == null || (metadata == null && mapping == null)) {
      return RemoteBackedPackRefreshResult(
        status: RemoteBackedPackRefreshStatus.notRemoteBacked,
        summary: baseSummary,
        message: 'notRemoteBacked',
      );
    }
    if (remotePackId == null || remotePackId.trim().isEmpty) {
      return RemoteBackedPackRefreshResult(
        status: RemoteBackedPackRefreshStatus.missingRemoteMapping,
        summary: baseSummary,
        message: 'missingRemoteMapping',
      );
    }

    final pullResult = await _pullRemotePackSnapshot(remotePackId);
    if (!pullResult.isSuccess) {
      final status = _failureStatus(pullResult.failureReason, metadata);
      await _markPackFailure(
        localPackId: localPackId,
        metadata: metadata,
        status: status,
        lastSyncError: _sanitizedFailure(pullResult.failureReason),
      );
      return RemoteBackedPackRefreshResult(
        status: status,
        summary: baseSummary,
        message: _sanitizedFailure(pullResult.failureReason),
      );
    }

    final snapshot = pullResult.value!;
    final importResult = await _importRemotePackSnapshot(
      snapshot: snapshot,
      source: mapping == null
          ? RemoteSnapshotImportSource.manualDeveloperImport
          : RemoteSnapshotImportSource.localMappedPack,
    );
    final importedSummary = _summaryFromImport(
      localPackId: importResult.localPackId ?? localPackId,
      remotePackId: snapshot.id,
      importResult: importResult,
      outboxSummary: outboxSummary,
      staleBeforeRefresh: staleBeforeRefresh,
    );

    if (!importResult.succeeded) {
      await _markPackFailure(
        localPackId: importResult.localPackId ?? localPackId,
        metadata: await _dao.getRemotePackSyncMetadataForLocalPack(
          importResult.localPackId ?? localPackId,
        ),
        status: RemoteBackedPackRefreshStatus.importFailed,
        lastSyncError: 'importFailed',
      );
      return RemoteBackedPackRefreshResult(
        status: RemoteBackedPackRefreshStatus.importFailed,
        summary: importedSummary,
        message: 'importFailed',
      );
    }

    final refreshedMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      importResult.localPackId ?? localPackId,
    );
    if (_isAccessLost(refreshedMetadata)) {
      await _markPackAccessLost(refreshedMetadata);
      return RemoteBackedPackRefreshResult(
        status: RemoteBackedPackRefreshStatus.accessLost,
        summary: importedSummary.copyWith(staleAfterRefresh: false),
        message: 'accessLost',
      );
    }

    if (importResult.status == RemoteSnapshotImportStatus.partialImport) {
      await _markPackStale(refreshedMetadata);
      return RemoteBackedPackRefreshResult(
        status: RemoteBackedPackRefreshStatus.partialImport,
        summary: importedSummary.copyWith(staleAfterRefresh: true),
        message: 'partialImport',
      );
    }

    if (outboxSummary.hasUnresolved) {
      await _markPackStale(refreshedMetadata);
      await _markOutboxItemsStale(importResult.localPackId ?? localPackId);
      return RemoteBackedPackRefreshResult(
        status: RemoteBackedPackRefreshStatus.hasPendingLocalMutations,
        summary: importedSummary.copyWith(staleAfterRefresh: true),
        message: 'hasPendingLocalMutations',
      );
    }

    return RemoteBackedPackRefreshResult(
      status: RemoteBackedPackRefreshStatus.refreshed,
      summary: importedSummary.copyWith(staleAfterRefresh: false),
      message: 'refreshed',
    );
  }

  String? _remotePackId(
    RemotePackSyncMetadataEntry? metadata,
    String? mappedRemotePackId,
  ) {
    final metadataRemotePackId = metadata?.remotePackId.trim();
    if (metadataRemotePackId != null && metadataRemotePackId.isNotEmpty) {
      return metadataRemotePackId;
    }
    final mappingRemotePackId = mappedRemotePackId?.trim();
    if (mappingRemotePackId != null && mappingRemotePackId.isNotEmpty) {
      return mappingRemotePackId;
    }
    return null;
  }

  Future<_RefreshOutboxSummary> _outboxSummary(int localPackId) async {
    final entries = await _dao.listSyncOutboxEntries();
    var pending = 0;
    var failed = 0;
    for (final entry in entries) {
      if (entry.localPackId != localPackId) {
        continue;
      }
      switch (entry.status) {
        case SyncOutboxStatus.pending || SyncOutboxStatus.syncing:
          pending++;
        case SyncOutboxStatus.failed ||
            SyncOutboxStatus.conflict ||
            SyncOutboxStatus.noOp:
          failed++;
        case SyncOutboxStatus.synced || SyncOutboxStatus.cancelled:
          break;
      }
    }
    return _RefreshOutboxSummary(pendingCount: pending, failedCount: failed);
  }

  List<String> _outboxWarnings(_RefreshOutboxSummary summary) {
    final warnings = <String>[];
    if (summary.pendingCount > 0) {
      warnings.add('尚有等待同步的本機操作');
    }
    if (summary.failedCount > 0) {
      warnings.add('尚有同步失敗的本機操作');
    }
    return warnings;
  }

  RemoteBackedPackRefreshStatus _failureStatus(
    RemoteSharedPackFailureReason? reason,
    RemotePackSyncMetadataEntry? metadata,
  ) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing =>
        RemoteBackedPackRefreshStatus.configMissing,
      RemoteSharedPackFailureReason.remoteAuthRequired =>
        RemoteBackedPackRefreshStatus.remoteAuthRequired,
      RemoteSharedPackFailureReason.remoteRlsRejected =>
        _isAccessLost(metadata)
            ? RemoteBackedPackRefreshStatus.accessLost
            : RemoteBackedPackRefreshStatus.remoteRlsRejected,
      RemoteSharedPackFailureReason.remoteNetworkFailed =>
        RemoteBackedPackRefreshStatus.networkFailed,
      _ => RemoteBackedPackRefreshStatus.unknownFailure,
    };
  }

  String _sanitizedFailure(RemoteSharedPackFailureReason? reason) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing => 'configMissing',
      RemoteSharedPackFailureReason.remoteAuthRequired => 'remoteAuthRequired',
      RemoteSharedPackFailureReason.remoteRlsRejected => 'remoteRlsRejected',
      RemoteSharedPackFailureReason.remoteNetworkFailed => 'networkFailed',
      RemoteSharedPackFailureReason.malformedRemoteData =>
        'malformedRemoteData',
      _ => 'unknownFailure',
    };
  }

  Future<void> _markPackFailure({
    required int localPackId,
    required RemotePackSyncMetadataEntry? metadata,
    required RemoteBackedPackRefreshStatus status,
    required String lastSyncError,
  }) async {
    final current =
        metadata ??
        await _dao.getRemotePackSyncMetadataForLocalPack(localPackId);
    if (current == null) {
      return;
    }
    final now = _clock().millisecondsSinceEpoch;
    final nextState = switch (status) {
      RemoteBackedPackRefreshStatus.accessLost =>
        RemotePackSyncState.accessLost,
      RemoteBackedPackRefreshStatus.networkFailed
          when current.syncState == RemotePackSyncState.stale =>
        RemotePackSyncState.stale,
      _ => RemotePackSyncState.failed,
    };
    await _dao.updateRemotePackSyncMetadata(
      current.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(nextState.storageValue),
        lastSyncError: Value(lastSyncError),
        accessLostAt: status == RemoteBackedPackRefreshStatus.accessLost
            ? Value(now)
            : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _markPackStale(RemotePackSyncMetadataEntry? metadata) async {
    if (metadata == null || _isAccessLost(metadata)) {
      return;
    }
    final now = _clock().millisecondsSinceEpoch;
    await _dao.updateRemotePackSyncMetadata(
      metadata.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.stale.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _markPackAccessLost(
    RemotePackSyncMetadataEntry? metadata,
  ) async {
    if (metadata == null) {
      return;
    }
    final now = _clock().millisecondsSinceEpoch;
    await _dao.updateRemotePackSyncMetadata(
      metadata.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
        accessLostAt: Value(now),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _markOutboxItemsStale(int localPackId) async {
    final entries = await _dao.listSyncOutboxEntries(
      statuses: {
        SyncOutboxStatus.pending,
        SyncOutboxStatus.syncing,
        SyncOutboxStatus.failed,
        SyncOutboxStatus.conflict,
        SyncOutboxStatus.noOp,
      },
    );
    final now = _clock().millisecondsSinceEpoch;
    for (final entry in entries) {
      if (entry.localPackId != localPackId) {
        continue;
      }
      final localItemId = _localItemIdFromOutbox(entry);
      if (localItemId == null) {
        continue;
      }
      final itemMetadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
        localItemId,
      );
      if (itemMetadata == null) {
        continue;
      }
      await _dao.updateRemoteItemSyncMetadata(
        itemMetadata.id,
        RemoteItemSyncMetadataCompanion(
          syncState: Value(RemoteItemSyncState.stale.storageValue),
          lastSyncError: const Value(null),
          updatedAt: Value(now),
        ),
      );
    }
  }

  int? _localItemIdFromOutbox(SyncOutboxEntry entry) {
    try {
      final payload = jsonDecode(entry.payloadJson);
      if (payload is Map<String, Object?>) {
        final value = payload['localItemId'];
        if (value is int) {
          return value;
        }
        if (value is String) {
          return int.tryParse(value);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _isAccessLost(RemotePackSyncMetadataEntry? metadata) {
    return metadata?.syncState == RemotePackSyncState.accessLost ||
        metadata?.syncState == RemotePackSyncState.removed ||
        metadata?.currentUserRemoteStatus == RemoteUserStatus.removed;
  }

  RemoteBackedPackRefreshSummary _summaryFromImport({
    required int localPackId,
    required String remotePackId,
    required RemoteSnapshotImportResult importResult,
    required _RefreshOutboxSummary outboxSummary,
    required bool staleBeforeRefresh,
  }) {
    final warnings = [
      ..._outboxWarnings(outboxSummary),
      ...importResult.warnings,
    ];
    return RemoteBackedPackRefreshSummary(
      localPackId: localPackId,
      remotePackId: remotePackId,
      importedItemCount: importResult.itemsCreated,
      updatedItemCount: importResult.itemsUpdated,
      importedCompletionCount: importResult.completionsCreated,
      updatedCompletionCount: importResult.completionsUpdated,
      importedActivityCount: importResult.activityCreated,
      updatedActivityCount: importResult.activityUpdated,
      hasPendingLocalMutations: outboxSummary.hasUnresolved,
      pendingMutationCount: outboxSummary.pendingCount,
      failedMutationCount: outboxSummary.failedCount,
      staleBeforeRefresh: staleBeforeRefresh,
      staleAfterRefresh: false,
      warnings: List.unmodifiable(warnings),
    );
  }
}

class _RefreshOutboxSummary {
  const _RefreshOutboxSummary({
    required this.pendingCount,
    required this.failedCount,
  });

  final int pendingCount;
  final int failedCount;

  bool get hasUnresolved => pendingCount > 0 || failedCount > 0;
}

extension on RemoteBackedPackRefreshSummary {
  RemoteBackedPackRefreshSummary copyWith({required bool staleAfterRefresh}) {
    return RemoteBackedPackRefreshSummary(
      localPackId: localPackId,
      remotePackId: remotePackId,
      importedItemCount: importedItemCount,
      updatedItemCount: updatedItemCount,
      importedCompletionCount: importedCompletionCount,
      updatedCompletionCount: updatedCompletionCount,
      importedActivityCount: importedActivityCount,
      updatedActivityCount: updatedActivityCount,
      hasPendingLocalMutations: hasPendingLocalMutations,
      pendingMutationCount: pendingMutationCount,
      failedMutationCount: failedMutationCount,
      staleBeforeRefresh: staleBeforeRefresh,
      staleAfterRefresh: staleAfterRefresh,
      warnings: warnings,
    );
  }
}
