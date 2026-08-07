import 'dart:async';

import '../../../reminders/data/local/app_database.dart';
import '../../application/shared_pack_commands.dart';
import '../../application/shared_pack_ports.dart';
import '../../application/shared_pack_read_models.dart';
import '../../application/shared_pack_runtime_types.dart';
import '../../domain/shared_pack_errors.dart';
import '../../domain/shared_pack_ids.dart';
import '../../domain/shared_pack_models.dart';
import '../../domain/shared_pack_runtime_values.dart';
import 'shared_pack_cache_dao.dart';

/// Read-only mapping adapter over the already-projected Shared v6 cache.
final class DriftSharedCacheReadAdapter implements SharedCacheReadPort {
  DriftSharedCacheReadAdapter({
    required SharedPackCacheDao dao,
    required SharedUtcClock clock,
  }) : _dao = dao,
       _clock = clock;

  final SharedPackCacheDao _dao;
  final SharedUtcClock _clock;

  @override
  Stream<SharedPackListReadModel> watchPackList() {
    return _mapFailClosed(_dao.watchPackListCacheSnapshot(), _mapPackList);
  }

  @override
  Stream<SharedPackDetailReadModel?> watchPackDetail(RemotePackId packId) {
    return _mapFailClosed(
      _dao.watchPackDetailCacheSnapshot(packId.value),
      (snapshot) => _mapPackDetail(packId, snapshot),
    );
  }

  @override
  Future<SharedLocalPortResult<SharedMutationBase?>> readMutationBase(
    RemotePackId packId,
  ) async {
    try {
      final snapshot = await _dao.readMutationBaseCacheSnapshot(packId.value);
      if (snapshot == null) {
        return const SharedLocalPortSuccess(null);
      }
      _validatePackRow(snapshot.pack);
      final graph = _validatedMembershipGraph(packId, snapshot.memberships);
      for (final item in snapshot.activeItems) {
        _validateReadableItemRow(packId, item);
      }
      return SharedLocalPortSuccess(
        SharedMutationBase(
          remotePackId: packId,
          packVersion: RemotePackVersion(snapshot.pack.remotePackVersion),
          trust: _mapTrustState(snapshot.pack).trust,
          currentRole: graph.current.role,
          itemVersions: snapshot.activeItems
              .map(
                (row) => SharedItemVersionBase(
                  remoteItemId: RemoteItemId(row.remoteItemId),
                  itemVersion: RemoteItemVersion(row.remoteItemVersion),
                ),
              )
              .toList(growable: false),
          hasUnresolvedMutation: snapshot.hasUnresolvedMutation,
        ),
      );
    } catch (_) {
      return const SharedLocalPortFailure(
        SharedLocalPortFailureFamily.readFailed,
      );
    }
  }

  @override
  Stream<List<SharedPendingMutationMarker>> watchRecoveryMarkers() {
    return _mapFailClosed(
      _dao.watchPendingMutationMarkers(),
      (rows) => List<SharedPendingMutationMarker>.unmodifiable(
        rows.map(_mapPendingMarker),
      ),
    );
  }

  SharedPackListReadModel _mapPackList(SharedPackListCacheSnapshot snapshot) {
    final membershipsByPack = <String, List<SharedMembershipCacheRow>>{};
    for (final membership in snapshot.memberships) {
      membershipsByPack
          .putIfAbsent(membership.remotePackId, () => [])
          .add(membership);
    }
    final pendingByPack = <String, List<SharedPendingMutationRow>>{};
    final unmatchedPending = <SharedPendingMutationRow>[];
    final packIds = snapshot.packs.map((row) => row.remotePackId).toSet();
    for (final pending in snapshot.pending) {
      final target = pending.targetRemotePackId;
      if (target != null && packIds.contains(target)) {
        pendingByPack.putIfAbsent(target, () => []).add(pending);
      } else {
        unmatchedPending.add(pending);
      }
    }

    final packs = snapshot.packs
        .map((row) {
          _validatePackRow(row);
          final packId = RemotePackId(row.remotePackId);
          final graph = _validatedMembershipGraph(
            packId,
            membershipsByPack[row.remotePackId] ?? const [],
          );
          final trust = _mapTrustState(row);
          return SharedPackListEntry(
            remotePackId: packId,
            title: row.title,
            iconEmoji: row.iconEmoji,
            role: graph.current.role,
            trust: trust,
            lastVerifiedAt: trust.lastVerifiedAt,
            pending: _mapSinglePackPending(
              pendingByPack[row.remotePackId] ?? const [],
              trust.trust,
            ),
          );
        })
        .toList(growable: false);

    return SharedPackListReadModel(
      packs: packs,
      unresolved: UnresolvedMutationPresentation(
        entries: unmatchedPending
            .map((row) => _mapPendingPresentation(row, trust: null))
            .toList(growable: false),
      ),
    );
  }

  SharedPackDetailReadModel? _mapPackDetail(
    RemotePackId requestedPackId,
    SharedPackDetailCacheSnapshot snapshot,
  ) {
    final row = snapshot.pack;
    if (row == null) {
      return null;
    }
    if (row.remotePackId != requestedPackId.value) {
      throw StateError('Pack detail query returned a foreign root');
    }
    _validatePackRow(row);
    final graph = _validatedMembershipGraph(
      requestedPackId,
      snapshot.memberships,
    );
    final trust = _mapTrustState(row);
    return SharedPackDetailReadModel(
      remotePackId: requestedPackId,
      title: row.title,
      description: row.description,
      iconEmoji: row.iconEmoji,
      packVersion: RemotePackVersion(row.remotePackVersion),
      currentMembership: graph.current,
      members: graph.members,
      activeItems: snapshot.activeItems
          .map((item) => _mapItem(requestedPackId, item, graph.members))
          .toList(growable: false),
      trust: trust,
      pending: _mapSinglePackPending(snapshot.pending, trust.trust),
      lastVerifiedAt: trust.lastVerifiedAt,
    );
  }

  _MembershipGraph _validatedMembershipGraph(
    RemotePackId packId,
    List<SharedMembershipCacheRow> rows,
  ) {
    final members = rows
        .map((row) {
          if (row.remotePackId != packId.value) {
            throw StateError('Membership escaped exact Pack scope');
          }
          validateCanonicalDisplayName(row.displayName);
          return SharedMemberReadModel(
            remoteMemberId: RemoteMemberId(row.remoteMemberId),
            displayName: row.displayName,
            role: _mapRole(row.role),
            joinedAt: _utc(row.joinedAt),
          );
        })
        .toList(growable: false);
    final owners = rows.where((row) => row.role == 'owner').toList();
    final current = rows.where((row) => row.isCurrentMembership).toList();
    if (owners.length != 1 || current.length != 1) {
      throw StateError(
        'Projected Pack graph requires exactly one owner and current member',
      );
    }
    final currentRow = current.single;
    return _MembershipGraph(
      current: CurrentMembershipReadModel(
        remoteMemberId: RemoteMemberId(currentRow.remoteMemberId),
        displayName: currentRow.displayName,
        role: _mapRole(currentRow.role),
      ),
      members: List.unmodifiable(members),
    );
  }

  SharedItemReadModel _mapItem(
    RemotePackId packId,
    SharedItemCacheRow row,
    List<SharedMemberReadModel> members,
  ) {
    _validateReadableItemRow(packId, row);
    validateSharedTitle(row.title, 'title');
    validateSharedDescription(row.description);
    final thresholds = SharedItemThresholds(
      infoAfterMinutes: row.infoAfterMinutes,
      warningAfterMinutes: row.warningAfterMinutes,
      dangerAfterMinutes: row.dangerAfterMinutes,
    );
    final anchor = _utc(row.stateAnchorDate);
    return SharedItemReadModel(
      remotePackId: packId,
      remoteItemId: RemoteItemId(row.remoteItemId),
      title: row.title,
      description: row.description,
      stateAnchorDateUtc: anchor,
      thresholds: thresholds,
      attention: _deriveAttention(anchor, thresholds),
      completion: _mapCompletion(row, members),
      itemVersion: RemoteItemVersion(row.remoteItemVersion),
      createdAt: _utc(row.remoteCreatedAt),
      updatedAt: _utc(row.remoteUpdatedAt),
    );
  }

  SharedCompletionPresentation? _mapCompletion(
    SharedItemCacheRow row,
    List<SharedMemberReadModel> members,
  ) {
    final completedAt = row.completedAt;
    final actorId = row.completedByMemberId;
    if (completedAt == null && actorId == null) {
      return null;
    }
    if (completedAt == null || actorId == null) {
      throw StateError('Completion timestamp and actor must be paired');
    }
    final matches = members
        .where((member) => member.remoteMemberId.value == actorId)
        .toList();
    if (matches.length != 1) {
      throw StateError('Completion actor is not exactly one same-Pack member');
    }
    final actor = matches.single;
    final duplicateName =
        members
            .where((member) => member.displayName == actor.displayName)
            .length >
        1;
    return SharedCompletionPresentation(
      completedAt: _utc(completedAt),
      actor: ActorAttributionViewData(
        remoteMemberId: actor.remoteMemberId,
        displayLabel: actor.displayName,
        hasDuplicateDisplayName: duplicateName,
      ),
    );
  }

  SharedItemAttention _deriveAttention(
    UtcInstant anchor,
    SharedItemThresholds thresholds,
  ) {
    final difference = _clock.nowUtc().value.difference(anchor.value);
    final elapsedMinutes = difference.isNegative ? 0 : difference.inMinutes;
    if (elapsedMinutes >= thresholds.dangerAfterMinutes) {
      return SharedItemAttention.danger;
    }
    if (elapsedMinutes >= thresholds.warningAfterMinutes) {
      return SharedItemAttention.warning;
    }
    return SharedItemAttention.normal;
  }

  void _validatePackRow(SharedPackCacheRow row) {
    RemotePackId(row.remotePackId);
    RemotePackVersion(row.remotePackVersion);
    validateSharedTitle(row.title, 'title');
    validateSharedDescription(row.description);
    validateSharedIcon(row.iconEmoji);
    _utc(row.remoteCreatedAt);
    _utc(row.remoteUpdatedAt);
  }

  void _validateReadableItemRow(RemotePackId packId, SharedItemCacheRow row) {
    if (row.remotePackId != packId.value ||
        row.type != 'stateBased' ||
        row.lifecycleStatus != 'active') {
      throw StateError('Shared Item is outside the readable v1 scope');
    }
    RemoteItemId(row.remoteItemId);
    RemoteItemVersion(row.remoteItemVersion);
  }

  TrustPresentation _mapTrustState(SharedPackCacheRow row) {
    final trust = switch (row.trustState) {
      'verified' => SharedCacheTrust.verified,
      'needsRevalidation' => SharedCacheTrust.needsRevalidation,
      'inaccessible' => SharedCacheTrust.inaccessible,
      _ => throw StateError('Unknown Shared cache trust state'),
    };
    final reason = row.trustFailureReason == null
        ? null
        : _mapTrustFailureReason(row.trustFailureReason!);
    final validReason = switch (trust) {
      SharedCacheTrust.verified => reason == null,
      SharedCacheTrust.needsRevalidation =>
        reason != null &&
            reason != SharedTrustFailureReason.permissionDenied &&
            reason != SharedTrustFailureReason.packNotFound,
      SharedCacheTrust.inaccessible =>
        reason == SharedTrustFailureReason.permissionDenied ||
            reason == SharedTrustFailureReason.packNotFound,
    };
    if (!validReason) {
      throw StateError('Malformed Shared cache trust/reason combination');
    }
    return TrustPresentation(
      trust: trust,
      reason: reason,
      lastVerifiedAt: _utc(row.lastVerifiedAt),
      canRefreshOrRecheck: true,
      mutationBlocked: trust != SharedCacheTrust.verified,
    );
  }

  PendingRecoveryPresentation? _mapSinglePackPending(
    List<SharedPendingMutationRow> rows,
    SharedCacheTrust trust,
  ) {
    if (rows.isEmpty) {
      return null;
    }
    if (rows.length != 1) {
      throw StateError('Read model cannot represent multiple Pack pendings');
    }
    return _mapPendingPresentation(rows.single, trust: trust);
  }

  PendingRecoveryPresentation _mapPendingPresentation(
    SharedPendingMutationRow row, {
    required SharedCacheTrust? trust,
  }) {
    final operation = _mapMutationOperation(row.operationName);
    if (row.targetRemotePackId == null &&
        operation != SharedMutationOperation.createSharedPack &&
        operation != SharedMutationOperation.joinSharedPack) {
      throw StateError('Only create/join pending may have no Pack target');
    }
    final actions = switch (trust) {
      SharedCacheTrust.inaccessible => const [
        PendingRecoveryAction.accessRecheck,
      ],
      SharedCacheTrust.verified || SharedCacheTrust.needsRevalidation => const [
        PendingRecoveryAction.refresh,
        PendingRecoveryAction.sameIdReplay,
      ],
      null =>
        row.targetRemotePackId == null
            ? const [PendingRecoveryAction.sameIdReplay]
            : const [
                PendingRecoveryAction.refresh,
                PendingRecoveryAction.sameIdReplay,
              ],
    };
    return PendingRecoveryPresentation(
      operation: operation,
      targetRemotePackId: row.targetRemotePackId == null
          ? null
          : RemotePackId(row.targetRemotePackId!),
      createdAt: _utc(row.createdAt),
      availableActions: actions,
    );
  }

  SharedPendingMutationMarker _mapPendingMarker(SharedPendingMutationRow row) {
    final status = switch (row.status) {
      'awaitingResolution' => SharedPendingMutationStatus.awaitingResolution,
      _ => throw StateError('Unknown pending mutation status'),
    };
    return SharedPendingMutationMarker(
      operation: _mapMutationOperation(row.operationName),
      clientRequestId: ClientRequestId(row.clientRequestId),
      payloadFingerprint: SharedPayloadFingerprint(row.payloadFingerprint),
      targetRemotePackId: row.targetRemotePackId == null
          ? null
          : RemotePackId(row.targetRemotePackId!),
      createdAt: _utc(row.createdAt),
      status: status,
    );
  }

  SharedMutationOperation _mapMutationOperation(String value) =>
      switch (value) {
        'createSharedPack' => SharedMutationOperation.createSharedPack,
        'updateSharedPackMetadata' =>
          SharedMutationOperation.updateSharedPackMetadata,
        'createSharedItem' => SharedMutationOperation.createSharedItem,
        'updateSharedItem' => SharedMutationOperation.updateSharedItem,
        'archiveSharedItem' => SharedMutationOperation.archiveSharedItem,
        'completeSharedItem' => SharedMutationOperation.completeSharedItem,
        'getOrCreateInviteCode' =>
          SharedMutationOperation.getOrCreateInviteCode,
        'rotateInviteCode' => SharedMutationOperation.rotateInviteCode,
        'joinSharedPack' => SharedMutationOperation.joinSharedPack,
        _ => throw StateError('Unknown pending mutation operation'),
      };

  SharedRole _mapRole(String value) => switch (value) {
    'owner' => SharedRole.owner,
    'member' => SharedRole.member,
    _ => throw StateError('Unknown Shared membership role'),
  };

  SharedTrustFailureReason _mapTrustFailureReason(String value) =>
      switch (value) {
        'remoteOutcomeUnknown' => SharedTrustFailureReason.remoteOutcomeUnknown,
        'projectionFailed' => SharedTrustFailureReason.projectionFailed,
        'snapshotValidationFailed' =>
          SharedTrustFailureReason.snapshotValidationFailed,
        'unsupportedSnapshotSchema' =>
          SharedTrustFailureReason.unsupportedSnapshotSchema,
        'sameVersionContentConflict' =>
          SharedTrustFailureReason.sameVersionContentConflict,
        'snapshotIntegrityFailed' =>
          SharedTrustFailureReason.snapshotIntegrityFailed,
        'staleMutationBase' => SharedTrustFailureReason.staleMutationBase,
        'permissionDenied' => SharedTrustFailureReason.permissionDenied,
        'packNotFound' => SharedTrustFailureReason.packNotFound,
        _ => throw StateError('Unknown Shared trust failure reason'),
      };

  UtcInstant _utc(int epochMilliseconds) => UtcInstant(
    DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true),
  );
}

final class _MembershipGraph {
  const _MembershipGraph({required this.current, required this.members});

  final CurrentMembershipReadModel current;
  final List<SharedMemberReadModel> members;
}

Stream<R> _mapFailClosed<T, R>(Stream<T> source, R Function(T value) mapper) {
  late StreamController<R> controller;
  StreamSubscription<T>? subscription;
  var closed = false;

  void fail(Object error, StackTrace stackTrace) {
    if (closed) {
      return;
    }
    closed = true;
    controller.addError(error, stackTrace);
    scheduleMicrotask(() async {
      await subscription?.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    });
  }

  controller = StreamController<R>(
    sync: true,
    onListen: () {
      subscription = source.listen(
        (value) {
          if (closed) {
            return;
          }
          try {
            controller.add(mapper(value));
          } catch (error, stackTrace) {
            fail(error, stackTrace);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          fail(error, stackTrace);
        },
        onDone: () {
          if (!closed) {
            closed = true;
            unawaited(controller.close());
          }
        },
      );
    },
    onCancel: () {
      closed = true;
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
