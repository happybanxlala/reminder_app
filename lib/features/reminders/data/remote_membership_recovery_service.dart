import '../domain/account_protection.dart';
import '../domain/remote_membership_recovery.dart';
import '../domain/remote_sync.dart';
import 'account_protection_service.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_models.dart';
import 'remote_shared_pack_repository.dart';
import 'remote_snapshot_import_service.dart';

class RemoteMembershipRecoveryService {
  const RemoteMembershipRecoveryService({
    required ReminderDao dao,
    required AccountProtectionService accountProtectionService,
    required RemoteSharedPackRepository remoteRepository,
    required RemoteSnapshotImportService importService,
  }) : _dao = dao,
       _accountProtectionService = accountProtectionService,
       _remoteRepository = remoteRepository,
       _importService = importService;

  final ReminderDao _dao;
  final AccountProtectionService _accountProtectionService;
  final RemoteSharedPackRepository _remoteRepository;
  final RemoteSnapshotImportService _importService;

  Future<RemotePocResult<List<RemoteRecoverablePack>>>
  discoverActiveMemberships() {
    return _remoteRepository.discoverActiveRemoteMemberships();
  }

  Future<RemoteMembershipRecoveryResult> restoreActiveMemberships({
    bool allowUnprotectedForDeveloperPoc = false,
  }) async {
    if (!allowUnprotectedForDeveloperPoc) {
      final accountStatus =
          (await _accountProtectionService.getStatus()).status;
      final blockedStatus = _blockedStatusForAccount(accountStatus);
      if (blockedStatus != null) {
        return RemoteMembershipRecoveryResult(
          status: blockedStatus,
          summary: _emptySummary(),
          message: blockedStatus.name,
        );
      }
    }

    final discovery = await discoverActiveMemberships();
    if (!discovery.isSuccess) {
      final status = _statusForFailure(discovery.failureReason);
      return RemoteMembershipRecoveryResult(
        status: status,
        summary: _emptySummary(),
        message: status.name,
      );
    }

    final memberships = discovery.value!;
    if (memberships.isEmpty) {
      return RemoteMembershipRecoveryResult(
        status: RemoteMembershipRecoveryStatus.nothingToRecover,
        summary: _emptySummary(),
        message: 'nothingToRecover',
      );
    }

    var eligible = 0;
    var created = 0;
    var refreshed = 0;
    var skipped = 0;
    var archivedSkipped = 0;
    var failed = 0;
    RemoteMembershipRecoveryStatus? firstFailureStatus;
    final localPackIds = <int>[];
    final warnings = <String>[];

    for (final membership in memberships) {
      if (membership.memberStatus != 'active') {
        skipped += 1;
        warnings.add('memberNotActive');
        continue;
      }
      if (membership.packStatus != 'active') {
        skipped += 1;
        archivedSkipped += 1;
        warnings.add('packNotActive');
        continue;
      }
      eligible += 1;
      final existingLocalPackId = await _localPackIdForRemotePack(
        membership.remotePackId,
      );
      if (existingLocalPackId != null &&
          await _hasUnresolvedOutbox(existingLocalPackId)) {
        warnings.add('pendingLocalMutations');
      }

      final pull = await _remoteRepository
          .pullRemotePackSnapshotForCurrentSession(membership.remotePackId);
      if (!pull.isSuccess) {
        failed += 1;
        final status = _statusForFailure(pull.failureReason);
        firstFailureStatus ??= status;
        warnings.add(_sanitizedFailure(pull.failureReason));
        continue;
      }

      final result = await _importService.importRemotePackSnapshot(
        snapshot: pull.value!,
        source: existingLocalPackId == null
            ? RemoteSnapshotImportSource.joinedRemotePack
            : RemoteSnapshotImportSource.localMappedPack,
      );
      if (!result.succeeded) {
        failed += 1;
        firstFailureStatus ??= RemoteMembershipRecoveryStatus.importFailed;
        warnings.add('importFailed');
        continue;
      }

      final localPackId = result.localPackId;
      if (localPackId != null) {
        localPackIds.add(localPackId);
      }
      switch (result.status) {
        case RemoteSnapshotImportStatus.success:
        case RemoteSnapshotImportStatus.partialImport:
          if (existingLocalPackId == null) {
            created += 1;
          } else {
            refreshed += 1;
          }
          if (result.status == RemoteSnapshotImportStatus.partialImport) {
            warnings.add('partialImport');
          }
        case RemoteSnapshotImportStatus.alreadyImported:
        case RemoteSnapshotImportStatus.updatedExistingMirror:
          refreshed += 1;
        case RemoteSnapshotImportStatus.failed:
        case RemoteSnapshotImportStatus.conflict:
          failed += 1;
          firstFailureStatus ??= RemoteMembershipRecoveryStatus.importFailed;
      }
    }

    final summary = RemoteMembershipRecoverySummary(
      discoveredCount: memberships.length,
      eligibleCount: eligible,
      createdLocalMirrorCount: created,
      refreshedExistingCount: refreshed,
      skippedCount: skipped,
      archivedSkippedCount: archivedSkipped,
      failedCount: failed,
      restoredLocalPackIds: localPackIds,
      warnings: warnings,
    );

    if (!summary.hasImportedAny) {
      return RemoteMembershipRecoveryResult(
        status: failed > 0
            ? firstFailureStatus ?? RemoteMembershipRecoveryStatus.importFailed
            : RemoteMembershipRecoveryStatus.nothingToRecover,
        summary: summary,
        message: failed > 0
            ? (firstFailureStatus ??
                      RemoteMembershipRecoveryStatus.importFailed)
                  .name
            : 'nothingToRecover',
      );
    }
    return RemoteMembershipRecoveryResult(
      status: failed == 0
          ? RemoteMembershipRecoveryStatus.restored
          : RemoteMembershipRecoveryStatus.partiallyRecovered,
      summary: summary,
      message: failed == 0 ? 'restored' : 'partiallyRecovered',
    );
  }

  Future<bool> hasLocalMirrorForRemotePack(String remotePackId) async {
    return await _localPackIdForRemotePack(remotePackId) != null;
  }

  Future<int?> _localPackIdForRemotePack(String remotePackId) async {
    final mapping = await _dao.getSyncMappingByRemote(
      localEntityType: RemoteSharedPackRepository.localEntityPack,
      remoteTable: RemoteSharedPackRepository.remoteTablePacks,
      remoteEntityId: remotePackId,
    );
    return mapping?.localEntityId;
  }

  Future<bool> _hasUnresolvedOutbox(int localPackId) async {
    final entries = await _dao.listSyncOutboxEntries();
    return entries.any((entry) {
      if (entry.localPackId != localPackId) {
        return false;
      }
      return switch (entry.status) {
        SyncOutboxStatus.pending ||
        SyncOutboxStatus.syncing ||
        SyncOutboxStatus.failed ||
        SyncOutboxStatus.conflict ||
        SyncOutboxStatus.noOp => true,
        SyncOutboxStatus.synced || SyncOutboxStatus.cancelled => false,
      };
    });
  }

  RemoteMembershipRecoveryStatus? _blockedStatusForAccount(
    AccountProtectionStatus status,
  ) {
    return switch (status) {
      AccountProtectionStatus.linkedProtected => null,
      AccountProtectionStatus.remoteSessionMissing =>
        RemoteMembershipRecoveryStatus.remoteSessionMissing,
      AccountProtectionStatus.localOnly =>
        RemoteMembershipRecoveryStatus.accountNotProtected,
      AccountProtectionStatus.anonymousUnprotected =>
        RemoteMembershipRecoveryStatus.accountNotProtected,
      AccountProtectionStatus.unsupported =>
        RemoteMembershipRecoveryStatus.accountNotProtected,
      AccountProtectionStatus.unavailable =>
        RemoteMembershipRecoveryStatus.unknownFailure,
    };
  }

  RemoteMembershipRecoveryStatus _statusForFailure(
    RemoteSharedPackFailureReason? reason,
  ) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing =>
        RemoteMembershipRecoveryStatus.configMissing,
      RemoteSharedPackFailureReason.remoteAuthRequired =>
        RemoteMembershipRecoveryStatus.remoteAuthRequired,
      RemoteSharedPackFailureReason.remoteRlsRejected =>
        RemoteMembershipRecoveryStatus.accessDenied,
      RemoteSharedPackFailureReason.remoteNetworkFailed =>
        RemoteMembershipRecoveryStatus.networkFailed,
      _ => RemoteMembershipRecoveryStatus.unknownFailure,
    };
  }

  String _sanitizedFailure(RemoteSharedPackFailureReason? reason) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing => 'configMissing',
      RemoteSharedPackFailureReason.remoteAuthRequired => 'remoteAuthRequired',
      RemoteSharedPackFailureReason.remoteRlsRejected => 'remoteRlsRejected',
      RemoteSharedPackFailureReason.remoteNetworkFailed => 'networkFailed',
      _ => 'unknownFailure',
    };
  }

  RemoteMembershipRecoverySummary _emptySummary() {
    return const RemoteMembershipRecoverySummary(
      discoveredCount: 0,
      eligibleCount: 0,
      createdLocalMirrorCount: 0,
      refreshedExistingCount: 0,
      skippedCount: 0,
      archivedSkippedCount: 0,
      failedCount: 0,
    );
  }
}
