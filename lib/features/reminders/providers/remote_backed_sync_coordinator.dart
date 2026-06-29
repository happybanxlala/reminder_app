import 'dart:async';

import '../data/local/reminder_dao.dart';
import '../data/remote_backed_outbox_flush_service.dart';
import '../data/remote_backed_pack_refresh_service.dart';
import '../domain/remote_backed_pack_refresh.dart';
import '../domain/remote_sync.dart';
import '../presentation/text/reminder_ui_text.dart';

enum RemoteBackedSyncStatus {
  notRemoteBacked,
  synced,
  pending,
  failed,
  refreshed,
  partialRefresh,
  accessLost,
}

class RemoteBackedSyncResult {
  const RemoteBackedSyncResult({
    required this.status,
    required this.message,
    this.flushResult,
    this.refreshResult,
  });

  final RemoteBackedSyncStatus status;
  final String message;
  final RemoteBackedOutboxFlushResult? flushResult;
  final RemoteBackedPackRefreshResult? refreshResult;

  bool get succeeded =>
      status == RemoteBackedSyncStatus.synced ||
      status == RemoteBackedSyncStatus.pending ||
      status == RemoteBackedSyncStatus.refreshed ||
      status == RemoteBackedSyncStatus.partialRefresh;
}

class RemoteBackedSyncCoordinator {
  const RemoteBackedSyncCoordinator({
    required ReminderDao dao,
    required RemoteBackedOutboxFlushService flushService,
    required RemoteBackedPackRefreshService refreshService,
    FutureOr<void> Function(int? localPackId)? onLocalDataChanged,
    Future<void> Function()? refreshDerivedLocalSurfaces,
  }) : _dao = dao,
       _flushService = flushService,
       _refreshService = refreshService,
       _onLocalDataChanged = onLocalDataChanged,
       _refreshDerivedLocalSurfaces = refreshDerivedLocalSurfaces;

  final ReminderDao _dao;
  final RemoteBackedOutboxFlushService _flushService;
  final RemoteBackedPackRefreshService _refreshService;
  final FutureOr<void> Function(int? localPackId)? _onLocalDataChanged;
  final Future<void> Function()? _refreshDerivedLocalSurfaces;

  Future<List<int>> listRemoteBackedPackIds({
    Iterable<int>? localPackIds,
  }) async {
    final requested = localPackIds?.toSet();
    final metadata = await _dao.listRemotePackSyncMetadataEntries();
    return [
      for (final entry in metadata)
        if (entry.syncKind == RemotePackSyncKind.remoteBacked &&
            (requested == null || requested.contains(entry.localPackId)))
          entry.localPackId,
    ];
  }

  Future<RemoteBackedSyncResult> flushPendingMutations({
    int? localPackId,
  }) async {
    final result = await _flushService.flushPendingRemoteBackedMutations();
    await _afterLocalDataChanged(localPackId);
    if (result.failed > 0 || result.conflict > 0) {
      return RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.failed,
        message: ReminderUiText.syncRetryLaterLabel,
        flushResult: result,
      );
    }
    if (result.processed == 0) {
      return RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.synced,
        message: ReminderUiText.syncUpdatedLabel,
        flushResult: result,
      );
    }
    return RemoteBackedSyncResult(
      status: RemoteBackedSyncStatus.synced,
      message: ReminderUiText.syncUpdatedLabel,
      flushResult: result,
    );
  }

  Future<RemoteBackedSyncResult> refreshRemoteBackedPack(
    int localPackId,
  ) async {
    if (!await _dao.isRemoteBackedPack(localPackId)) {
      return const RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.notRemoteBacked,
        message: ReminderUiText.packCareRemoteUnavailable,
      );
    }

    final flushResult = await flushPendingMutations(localPackId: localPackId);
    final unresolved = await _unresolvedOutboxSummary(localPackId);
    if (unresolved.hasFailed) {
      return RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.failed,
        message: ReminderUiText.syncRetryLaterLabel,
        flushResult: flushResult.flushResult,
      );
    }
    if (unresolved.hasPending) {
      return RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.pending,
        message: ReminderUiText.syncPendingLabel,
        flushResult: flushResult.flushResult,
      );
    }

    final refreshResult = await _refreshService.refreshPack(localPackId);
    await _afterLocalDataChanged(refreshResult.summary.localPackId);

    final status = _statusForRefresh(refreshResult);
    return RemoteBackedSyncResult(
      status: status,
      message: _messageForRefreshStatus(status),
      flushResult: flushResult.flushResult,
      refreshResult: refreshResult,
    );
  }

  Future<List<RemoteBackedSyncResult>> refreshVisibleRemoteBackedPacks(
    Iterable<int> localPackIds,
  ) async {
    final remotePackIds = await listRemoteBackedPackIds(
      localPackIds: localPackIds,
    );
    final results = <RemoteBackedSyncResult>[];
    for (final packId in remotePackIds) {
      try {
        results.add(await refreshRemoteBackedPack(packId));
      } catch (_) {
        results.add(
          const RemoteBackedSyncResult(
            status: RemoteBackedSyncStatus.failed,
            message: ReminderUiText.packCareMemberUpdateFailed,
          ),
        );
      }
    }
    return results;
  }

  Future<RemoteBackedSyncResult> syncAfterRemoteBackedMutation(
    int localPackId,
  ) async {
    if (!await _dao.isRemoteBackedPack(localPackId)) {
      return const RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.notRemoteBacked,
        message: ReminderUiText.packCareRemoteUnavailable,
      );
    }
    try {
      return await flushPendingMutations(localPackId: localPackId);
    } catch (_) {
      await _afterLocalDataChanged(localPackId);
      return const RemoteBackedSyncResult(
        status: RemoteBackedSyncStatus.failed,
        message: ReminderUiText.syncRetryLaterLabel,
      );
    }
  }

  Future<_CoordinatorOutboxSummary> _unresolvedOutboxSummary(
    int localPackId,
  ) async {
    final entries = await _dao.listSyncOutboxEntries(
      statuses: {
        SyncOutboxStatus.pending,
        SyncOutboxStatus.syncing,
        SyncOutboxStatus.failed,
        SyncOutboxStatus.conflict,
      },
    );
    var pending = 0;
    var failed = 0;
    for (final entry in entries) {
      if (entry.localPackId != localPackId) {
        continue;
      }
      switch (entry.status) {
        case SyncOutboxStatus.pending || SyncOutboxStatus.syncing:
          pending++;
        case SyncOutboxStatus.failed || SyncOutboxStatus.conflict:
          failed++;
        case SyncOutboxStatus.synced ||
            SyncOutboxStatus.cancelled ||
            SyncOutboxStatus.noOp:
          break;
      }
    }
    return _CoordinatorOutboxSummary(
      pendingCount: pending,
      failedCount: failed,
    );
  }

  Future<void> _afterLocalDataChanged(int? localPackId) async {
    await _onLocalDataChanged?.call(localPackId);
    final refreshDerived = _refreshDerivedLocalSurfaces;
    if (refreshDerived != null) {
      unawaited(refreshDerived());
    }
  }

  RemoteBackedSyncStatus _statusForRefresh(
    RemoteBackedPackRefreshResult result,
  ) {
    return switch (result.status) {
      RemoteBackedPackRefreshStatus.refreshed =>
        RemoteBackedSyncStatus.refreshed,
      RemoteBackedPackRefreshStatus.partialImport =>
        RemoteBackedSyncStatus.partialRefresh,
      RemoteBackedPackRefreshStatus.hasPendingLocalMutations =>
        RemoteBackedSyncStatus.pending,
      RemoteBackedPackRefreshStatus.accessLost =>
        RemoteBackedSyncStatus.accessLost,
      RemoteBackedPackRefreshStatus.notRemoteBacked ||
      RemoteBackedPackRefreshStatus.missingRemoteMapping =>
        RemoteBackedSyncStatus.notRemoteBacked,
      RemoteBackedPackRefreshStatus.configMissing ||
      RemoteBackedPackRefreshStatus.remoteAuthRequired ||
      RemoteBackedPackRefreshStatus.remoteRlsRejected ||
      RemoteBackedPackRefreshStatus.networkFailed ||
      RemoteBackedPackRefreshStatus.importFailed ||
      RemoteBackedPackRefreshStatus.unknownFailure =>
        RemoteBackedSyncStatus.failed,
    };
  }

  String _messageForRefreshStatus(RemoteBackedSyncStatus status) {
    return switch (status) {
      RemoteBackedSyncStatus.refreshed ||
      RemoteBackedSyncStatus.synced => ReminderUiText.packCareUpdated,
      RemoteBackedSyncStatus.pending => ReminderUiText.syncPendingLabel,
      RemoteBackedSyncStatus.partialRefresh => ReminderUiText.packCareUpdated,
      RemoteBackedSyncStatus.accessLost =>
        ReminderUiText.packCareRefreshAccessLost,
      RemoteBackedSyncStatus.notRemoteBacked =>
        ReminderUiText.packCareRemoteUnavailable,
      RemoteBackedSyncStatus.failed =>
        ReminderUiText.packCareMemberUpdateFailed,
    };
  }
}

class _CoordinatorOutboxSummary {
  const _CoordinatorOutboxSummary({
    required this.pendingCount,
    required this.failedCount,
  });

  final int pendingCount;
  final int failedCount;

  bool get hasPending => pendingCount > 0;
  bool get hasFailed => failedCount > 0;
}
