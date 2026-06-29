import 'package:drift/drift.dart';

import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/remote_pack_freshness.dart';
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
  static const localEntityResource = 'resource';
  static const localEntityStageTracker = 'stage_tracker';
  static const localEntityStageRule = 'stage_rule';
  static const localEntityStageRecord = 'stage_record';
  static const localEntityStageAcknowledgement = 'stage_acknowledgement';
  static const remoteTablePacks = 'packs';
  static const remoteTableItems = 'items';
  static const remoteTableResources = 'resources';
  static const remoteTableStageTrackers = 'stage_trackers';
  static const remoteTableStageRules = 'stage_rules';
  static const remoteTableStageRecords = 'stage_records';
  static const remoteTableStageAcknowledgements = 'stage_acknowledgements';

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
    return ensureActiveInviteForPack(remotePackId);
  }

  Future<RemotePocResult<RemotePackInviteState>> fetchPackInviteState(
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
        await _remoteDataSource.fetchPackInviteState(packId: remotePackId),
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

  Future<RemotePocResult<RemotePackInvite>> ensureActiveInviteForPack(
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
        await _remoteDataSource.ensureActivePackInvite(packId: remotePackId),
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

  Future<RemotePocResult<RemotePackInvite>> refreshInviteForPack(
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
        await _remoteDataSource.refreshPackInvite(packId: remotePackId),
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

  Future<RemotePocResult<List<RemoteRecoverablePack>>>
  discoverActiveRemoteMemberships() async {
    try {
      return RemotePocResult.success(
        await _remoteDataSource.fetchActiveMembershipPacks(),
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

  Future<RemotePocResult<RemoteItemCreateResult>> createRemoteItemForPack({
    required String remotePackId,
    required String title,
    String? note,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.createPackItemV2(
          packId: remotePackId,
          title: title,
          note: note,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteItemMutationResult>> updateRemoteItemByRemoteId({
    required String remoteItemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.updatePackItem(
          itemId: remoteItemId,
          title: title,
          note: note,
          assignedToUserId: assignedToUserId,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteItemMutationResult>>
  archiveRemoteItemByRemoteId({
    required String remoteItemId,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.archivePackItem(
          itemId: remoteItemId,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteResourceCreateResult>>
  createRemoteResourceForPack({
    required String remotePackId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.createPackResource(
          packId: remotePackId,
          title: title,
          description: description,
          type: type,
          config: config,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteResourceMutationResult>>
  updateRemoteResourceByRemoteId({
    required String remoteResourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.updatePackResource(
          resourceId: remoteResourceId,
          title: title,
          description: description,
          config: config,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteResourceMutationResult>>
  archiveRemoteResourceByRemoteId({
    required String remoteResourceId,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.archivePackResource(
          resourceId: remoteResourceId,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteResourceEventResult>>
  applyRemoteResourceEventByRemoteId({
    required String remoteResourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.applyResourceEvent(
          resourceId: remoteResourceId,
          changeType: changeType,
          deltaValue: deltaValue,
          newValue: newValue,
          unit: unit,
          clientMutationId: clientMutationId,
          metadata: metadata,
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

  Future<RemotePocResult<RemoteStageTrackerCreateResult>>
  createRemoteStageTrackerForPack({
    required String remotePackId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    List<Map<String, Object?>> initialRules = const [],
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.createPackStageTracker(
          packId: remotePackId,
          title: title,
          subjectName: subjectName,
          trackingStartDate: trackingStartDate,
          trackingEndDate: trackingEndDate,
          initialRules: initialRules,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageTrackerByRemoteId({
    required String remoteStageTrackerId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.updatePackStageTracker(
          stageTrackerId: remoteStageTrackerId,
          title: title,
          subjectName: subjectName,
          trackingStartDate: trackingStartDate,
          trackingEndDate: trackingEndDate,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  archiveRemoteStageTrackerByRemoteId({
    required String remoteStageTrackerId,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }

    try {
      return RemotePocResult.success(
        await _remoteDataSource.archivePackStageTracker(
          stageTrackerId: remoteStageTrackerId,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  createRemoteStageRuleByRemoteTrackerId({
    required String remoteStageTrackerId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.createPackStageRule(
          stageTrackerId: remoteStageTrackerId,
          fields: fields,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageRuleByRemoteId({
    required String remoteStageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.updatePackStageRule(
          stageRuleId: remoteStageRuleId,
          fields: fields,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageRuleStatusByRemoteId({
    required String remoteStageRuleId,
    required String status,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.updatePackStageRuleStatus(
          stageRuleId: remoteStageRuleId,
          status: status,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  createRemoteStageRecordByRemoteTrackerId({
    required String remoteStageTrackerId,
    String? remoteStageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.createPackStageRecord(
          stageTrackerId: remoteStageTrackerId,
          stageRuleId: remoteStageRuleId,
          fields: fields,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageRecordByRemoteId({
    required String remoteStageRecordId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.updatePackStageRecord(
          stageRecordId: remoteStageRecordId,
          fields: fields,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageMutationResult>>
  archiveRemoteStageRecordByRemoteId({
    required String remoteStageRecordId,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.archivePackStageRecord(
          stageRecordId: remoteStageRecordId,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemoteStageAcknowledgementResult>>
  acknowledgeRemoteStageRecordByRemoteId({
    required String remoteStageRecordId,
    String? clientMutationId,
  }) async {
    final identityResult = await _ensureAnonymousIdentity();
    if (!identityResult.isSuccess) {
      return RemotePocResult.failure(
        identityResult.failureReason,
        identityResult.error,
      );
    }
    try {
      return RemotePocResult.success(
        await _remoteDataSource.acknowledgePackStageRecord(
          stageRecordId: remoteStageRecordId,
          clientMutationId: clientMutationId,
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

  Future<RemotePocResult<RemotePackSnapshot>>
  pullRemotePackSnapshotForCurrentSession(String remotePackId) async {
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

  Future<RemotePackSnapshotReportResult> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  }) async {
    try {
      await _remoteDataSource.reportPackSnapshotImported(
        remotePackId: remotePackId,
        latestActivityEventId: latestActivityEventId,
        latestActivityAt: latestActivityAt,
      );
      return const RemotePackSnapshotReportResult(
        status: RemotePackSnapshotReportStatus.reported,
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePackSnapshotReportResult(
        status: _snapshotReportStatus(error.reason),
        message: _sanitizedFailure(error.reason),
      );
    } catch (_) {
      return const RemotePackSnapshotReportResult(
        status: RemotePackSnapshotReportStatus.unknownFailure,
        message: 'unknownFailure',
      );
    }
  }

  Future<RemotePackFreshnessQueryResult> getPackMemberFreshness({
    required String remotePackId,
  }) async {
    try {
      return RemotePackFreshnessQueryResult(
        status: RemotePackFreshnessQueryStatus.loaded,
        members: await _remoteDataSource.getPackMemberFreshness(
          remotePackId: remotePackId,
        ),
      );
    } on RemoteSharedPackException catch (error) {
      return RemotePackFreshnessQueryResult(
        status: _freshnessQueryStatus(error.reason),
        message: _sanitizedFailure(error.reason),
      );
    } catch (_) {
      return const RemotePackFreshnessQueryResult(
        status: RemotePackFreshnessQueryStatus.unknownFailure,
        message: 'unknownFailure',
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

  RemotePackSnapshotReportStatus _snapshotReportStatus(
    RemoteSharedPackFailureReason reason,
  ) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing =>
        RemotePackSnapshotReportStatus.configMissing,
      RemoteSharedPackFailureReason.remoteAuthRequired =>
        RemotePackSnapshotReportStatus.remoteAuthRequired,
      RemoteSharedPackFailureReason.remoteRlsRejected =>
        RemotePackSnapshotReportStatus.accessDenied,
      RemoteSharedPackFailureReason.localUserNotPackMember =>
        RemotePackSnapshotReportStatus.notMember,
      RemoteSharedPackFailureReason.remoteNetworkFailed =>
        RemotePackSnapshotReportStatus.networkFailed,
      _ => RemotePackSnapshotReportStatus.unknownFailure,
    };
  }

  RemotePackFreshnessQueryStatus _freshnessQueryStatus(
    RemoteSharedPackFailureReason reason,
  ) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing =>
        RemotePackFreshnessQueryStatus.configMissing,
      RemoteSharedPackFailureReason.remoteAuthRequired =>
        RemotePackFreshnessQueryStatus.remoteAuthRequired,
      RemoteSharedPackFailureReason.remoteRlsRejected =>
        RemotePackFreshnessQueryStatus.accessDenied,
      RemoteSharedPackFailureReason.localUserNotPackMember =>
        RemotePackFreshnessQueryStatus.notMember,
      RemoteSharedPackFailureReason.remoteNetworkFailed =>
        RemotePackFreshnessQueryStatus.networkFailed,
      _ => RemotePackFreshnessQueryStatus.unknownFailure,
    };
  }

  String _sanitizedFailure(RemoteSharedPackFailureReason reason) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing => 'configMissing',
      RemoteSharedPackFailureReason.remoteAuthRequired => 'remoteAuthRequired',
      RemoteSharedPackFailureReason.remoteRlsRejected => 'accessDenied',
      RemoteSharedPackFailureReason.localUserNotPackMember => 'notMember',
      RemoteSharedPackFailureReason.remoteNetworkFailed => 'networkFailed',
      _ => 'unknownFailure',
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
