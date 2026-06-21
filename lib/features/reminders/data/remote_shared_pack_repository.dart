import 'package:drift/drift.dart';

import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/shared_pack.dart';
import 'anonymous_remote_identity_service.dart';
import 'identity_repository.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_data_source.dart';
import 'remote_shared_pack_models.dart';

class RemoteSharedPackRepository {
  const RemoteSharedPackRepository({
    required ReminderDao dao,
    required IdentityRepository identityRepository,
    required AnonymousRemoteIdentityService anonymousIdentityService,
    required RemoteSharedPackDataSource remoteDataSource,
    DateTime Function()? clock,
  }) : _dao = dao,
       _identityRepository = identityRepository,
       _anonymousIdentityService = anonymousIdentityService,
       _remoteDataSource = remoteDataSource,
       _clock = clock ?? DateTime.now;

  static const localEntityPack = 'pack';
  static const localEntityItem = 'item';
  static const remoteTablePacks = 'packs';
  static const remoteTableItems = 'items';

  final ReminderDao _dao;
  final IdentityRepository _identityRepository;
  final AnonymousRemoteIdentityService _anonymousIdentityService;
  final RemoteSharedPackDataSource _remoteDataSource;
  final DateTime Function() _clock;

  Future<RemotePocResult<RemoteProfile>> ensureRemoteProfile() async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    final localUser = identityResult.value!;
    try {
      final remoteProfileId = await _remoteDataSource.upsertCurrentProfile(
        displayName: localUser.displayName,
      );
      return RemotePocResult.success(RemoteProfile(id: remoteProfileId));
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteProfileFailed,
        error,
      );
    }
  }

  Future<RemotePocResult<RemotePackLinkResult>>
  createRemoteSharedPackFromLocalPack(int localPackId) async {
    final profileResult = await ensureRemoteProfile();
    if (!profileResult.isSuccess) {
      return RemotePocResult.failure(
        profileResult.failureReason,
        profileResult.error,
      );
    }

    final existingMapping = await _dao.getSyncMapping(
      localEntityType: localEntityPack,
      localEntityId: localPackId,
      remoteTable: remoteTablePacks,
    );
    if (existingMapping != null) {
      return RemotePocResult.success(
        RemotePackLinkResult(
          remotePackId: existingMapping.remoteEntityId,
          alreadyLinked: true,
        ),
      );
    }

    final pack = await _dao.getItemPackById(localPackId);
    if (pack == null || pack.packType != ItemPackType.shared) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.localPackNotShared,
      );
    }

    final localUser = await _identityRepository.getCurrentAppUser();
    if (!await _canActOnSharedPack(pack, localUser.id)) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.localUserNotPackMember,
      );
    }

    try {
      final remotePackId = await _remoteDataSource.createSharedPack(
        name: pack.title,
        description: pack.description,
      );
      await _upsertMapping(
        localEntityType: localEntityPack,
        localEntityId: localPackId,
        remoteTable: remoteTablePacks,
        remoteEntityId: remotePackId,
        syncState: SyncMappingState.pushed,
        markPushed: true,
      );
      return RemotePocResult.success(
        RemotePackLinkResult(remotePackId: remotePackId, alreadyLinked: false),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remotePackCreateFailed,
        error,
      );
    }
  }

  Future<RemotePocResult<RemoteItemPushSummary>> pushMinimalItems(
    int localPackId,
  ) async {
    final packMapping = await _dao.getSyncMapping(
      localEntityType: localEntityPack,
      localEntityId: localPackId,
      remoteTable: remoteTablePacks,
    );
    if (packMapping == null) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.remotePackCreateFailed,
      );
    }

    final pack = await _dao.getItemPackById(localPackId);
    if (pack == null || pack.packType != ItemPackType.shared) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.localPackNotShared,
      );
    }

    final localUser = await _identityRepository.getCurrentAppUser();
    if (!await _canActOnSharedPack(pack, localUser.id)) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.localUserNotPackMember,
      );
    }

    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    var pushed = 0;
    var skipped = 0;
    var failed = 0;
    final bundles = await _dao.listItemBundles(
      statuses: const {ItemLifecycleStatus.active, ItemLifecycleStatus.paused},
    );
    for (final bundle in bundles.where(
      (item) => item.item.packId == localPackId,
    )) {
      final existingMapping = await _dao.getSyncMapping(
        localEntityType: localEntityItem,
        localEntityId: bundle.item.id,
        remoteTable: remoteTableItems,
      );
      if (existingMapping != null) {
        skipped += 1;
        continue;
      }
      try {
        final remoteItemId = await _remoteDataSource.createPackItem(
          packId: packMapping.remoteEntityId,
          title: bundle.item.title,
          note: bundle.item.description,
        );
        await _upsertMapping(
          localEntityType: localEntityItem,
          localEntityId: bundle.item.id,
          remoteTable: remoteTableItems,
          remoteEntityId: remoteItemId,
          syncState: SyncMappingState.pushed,
          markPushed: true,
        );
        pushed += 1;
      } catch (_) {
        failed += 1;
      }
    }

    return RemotePocResult.success(
      RemoteItemPushSummary(
        pushedCount: pushed,
        skippedCount: skipped,
        failedCount: failed,
      ),
    );
  }

  Future<RemotePocResult<RemotePackInvite>> createRemotePackInvite(
    String remotePackId,
  ) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.createPackInvite(packId: remotePackId),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<RemoteJoinPackResult>> joinRemotePackWithInvite(
    String inviteCode,
  ) async {
    final profileResult = await ensureRemoteProfile();
    if (!profileResult.isSuccess) {
      return RemotePocResult.failure(
        profileResult.failureReason,
        profileResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.joinPackWithInvite(inviteCode: inviteCode),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<RemoteRevokeInviteResult>> revokeRemotePackInvite(
    String inviteId,
  ) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.revokePackInvite(inviteId: inviteId),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<RemoteItemCompletionResult>>
  completeRemoteItemForLocalItem(int localItemId) async {
    final itemMapping = await _dao.getSyncMapping(
      localEntityType: localEntityItem,
      localEntityId: localItemId,
      remoteTable: remoteTableItems,
    );
    if (itemMapping == null) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteItemPushFailed,
      );
    }

    final bundle = await _dao.getItemBundleById(localItemId);
    if (bundle == null) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteItemPushFailed,
      );
    }
    final localUser = await _identityRepository.getCurrentAppUser();
    if (!await _canActOnSharedPack(bundle.pack, localUser.id)) {
      return const RemotePocResult.failure(
        RemoteSharedPackFailureReason.localUserNotPackMember,
      );
    }

    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      final result = await _remoteDataSource.completePackItem(
        itemId: itemMapping.remoteEntityId,
        clientMutationId:
            'local_item_${localItemId}_${_clock().millisecondsSinceEpoch}',
      );
      if (result.status == RemoteItemCompletionStatus.alreadyCompleted) {
        return RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteItemAlreadyCompleted,
          result,
        );
      }
      return RemotePocResult.success(result);
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<RemoteItemCompletionResult>>
  completeRemoteItemByRemoteId(String remoteItemId) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      final result = await _remoteDataSource.completePackItem(
        itemId: remoteItemId,
        clientMutationId:
            'remote_item_${remoteItemId}_${_clock().millisecondsSinceEpoch}',
      );
      if (result.status == RemoteItemCompletionStatus.alreadyCompleted) {
        return RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteItemAlreadyCompleted,
          result,
        );
      }
      return RemotePocResult.success(result);
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<RemoteItemUndoResult>> undoRemoteItemByRemoteId(
    String remoteItemId,
  ) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.undoPackItemCompletion(
          itemId: remoteItemId,
          clientMutationId:
              'remote_item_undo_${remoteItemId}_${_clock().millisecondsSinceEpoch}',
        ),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<RemotePackSnapshot>> pullRemotePackSnapshot(
    String remotePackId,
  ) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.fetchPackSnapshot(remotePackId),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePocResult.failure(error.reason, error);
    } catch (error) {
      return RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        error,
      );
    }
  }

  Future<RemotePocResult<LocalUser>> _ensureAnonymousIdentity() async {
    final result = await _anonymousIdentityService
        .ensureAnonymousRemoteIdentity();
    return switch (result.status) {
      AnonymousRemoteIdentityStatus.success ||
      AnonymousRemoteIdentityStatus.alreadyLinked => RemotePocResult.success(
        result.user!,
      ),
      AnonymousRemoteIdentityStatus.configMissing => RemotePocResult.failure(
        RemoteSharedPackFailureReason.supabaseConfigMissing,
        result.error,
      ),
      AnonymousRemoteIdentityStatus.remoteAuthFailed => RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteAuthRequired,
        result.error,
      ),
    };
  }

  Future<bool> _canActOnSharedPack(ItemPack pack, String userId) async {
    if (pack.packType != ItemPackType.shared) {
      return false;
    }
    return _dao.isActivePackMember(packId: pack.id, userId: userId);
  }

  Future<int> _upsertMapping({
    required String localEntityType,
    required int localEntityId,
    required String remoteTable,
    required String remoteEntityId,
    required SyncMappingState syncState,
    bool markPushed = false,
  }) {
    final now = _clock().millisecondsSinceEpoch;
    return _dao.upsertSyncMapping(
      SyncMappingsCompanion.insert(
        localEntityType: localEntityType,
        localEntityId: localEntityId,
        remoteTable: remoteTable,
        remoteEntityId: remoteEntityId,
        syncState: syncState.storageValue,
        lastPushedAt: markPushed ? Value(now) : const Value.absent(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
