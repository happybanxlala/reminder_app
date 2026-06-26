import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_widget/providers/home_widget_providers.dart';
import '../data/local/reminder_dao.dart';
import '../data/remote_shared_pack_repository.dart';
import '../data/remote_shared_pack_models.dart';
import '../data/remote_snapshot_import_service.dart';
import '../domain/item_pack.dart';
import '../domain/remote_backed_pack_refresh.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import '../presentation/text/reminder_ui_text.dart';
import 'attention_service_providers.dart';
import 'database_providers.dart';
import 'home_providers.dart';
import 'identity_providers.dart';
import 'item_providers.dart';
import 'remote_shared_pack_providers.dart';
import 'shared_pack_providers.dart';

class PackCareMemberView {
  const PackCareMemberView({
    required this.displayName,
    required this.roleLabel,
  });

  final String displayName;
  final String roleLabel;
}

class PackCareViewModel {
  const PackCareViewModel({
    required this.pack,
    required this.metadata,
    required this.members,
    required this.inviteState,
  });

  final ItemPack pack;
  final RemotePackSyncMetadataEntry? metadata;
  final List<PackCareMemberView> members;
  final RemotePackInviteState inviteState;

  bool get isAccessLost =>
      metadata?.syncState == RemotePackSyncState.accessLost ||
      metadata?.syncState == RemotePackSyncState.removed ||
      metadata?.currentUserRemoteStatus == RemoteUserStatus.removed;

  bool get isShared => pack.packType == ItemPackType.shared;

  bool get isRemoteBacked =>
      metadata?.syncKind == RemotePackSyncKind.remoteBacked;

  int get activeMemberCount => members.length;

  RemotePackInvite? get activeInvite => inviteState.activeInvite;

  bool get hasActiveInvite => inviteState.hasActiveInvite;

  String get rowStatusLabel {
    if (pack.isSystemDefault) {
      return ReminderUiText.systemDefaultPackLabel;
    }
    final syncState = metadata?.syncState;
    if (isAccessLost) {
      return '已無法存取';
    }
    if (syncState == RemotePackSyncState.pendingImport ||
        syncState == RemotePackSyncState.importing) {
      return ReminderUiText.syncPendingLabel;
    }
    if (syncState == RemotePackSyncState.failed ||
        syncState == RemotePackSyncState.conflict) {
      return ReminderUiText.syncFailedLabel;
    }
    if (syncState == RemotePackSyncState.stale) {
      return '有更新，點下拉同步';
    }
    if (hasActiveInvite) {
      return ReminderUiText.packCareInviteActiveLabel;
    }
    if (isShared) {
      return ReminderUiText.packCareMembersLabel(activeMemberCount);
    }
    return ReminderUiText.packCareLocalOnlyLabel;
  }

  String? get bannerText {
    final syncState = metadata?.syncState;
    if (syncState == RemotePackSyncState.pendingImport ||
        syncState == RemotePackSyncState.importing) {
      return ReminderUiText.packCareSyncWaitingBanner;
    }
    if (syncState == RemotePackSyncState.failed ||
        syncState == RemotePackSyncState.conflict) {
      return ReminderUiText.packCareSyncFailedBanner;
    }
    if (syncState == RemotePackSyncState.stale) {
      return ReminderUiText.packCareSyncStaleBanner;
    }
    return null;
  }
}

class PackCareInviteResult {
  const PackCareInviteResult.success({
    required this.invite,
    this.warningMessage,
  }) : errorMessage = null;

  const PackCareInviteResult.failure(this.errorMessage)
    : invite = null,
      warningMessage = null;

  final RemotePackInvite? invite;
  final String? warningMessage;
  final String? errorMessage;

  bool get succeeded => invite != null;
}

class PackCareJoinResult {
  const PackCareJoinResult.success({required this.packTitle})
    : errorMessage = null;

  const PackCareJoinResult.failure(this.errorMessage) : packTitle = null;

  final String? packTitle;
  final String? errorMessage;

  bool get succeeded => packTitle != null;
}

class PackCareRefreshResult {
  const PackCareRefreshResult.success({
    required this.message,
    this.warningMessage,
  }) : errorMessage = null;

  const PackCareRefreshResult.failure(this.errorMessage)
    : message = null,
      warningMessage = null;

  final String? message;
  final String? warningMessage;
  final String? errorMessage;

  bool get succeeded => errorMessage == null;
}

class SharedPackCareController {
  const SharedPackCareController(this._ref);

  final Ref _ref;

  Future<PackCareInviteResult> createInvite(ItemPack pack) async {
    return ensureActiveInviteForPack(pack);
  }

  Future<PackCareInviteResult> ensureActiveInviteForPack(ItemPack pack) async {
    final inviteTarget = await _prepareInviteTarget(pack);
    if (!inviteTarget.succeeded) {
      return PackCareInviteResult.failure(inviteTarget.errorMessage!);
    }

    final inviteResult = await _ref
        .read(remoteSharedPackRepositoryProvider)
        .ensureActiveInviteForPack(inviteTarget.remotePackId!);
    if (!inviteResult.isSuccess) {
      return PackCareInviteResult.failure(
        _sharedCareFailureMessage(inviteResult.failureReason),
      );
    }

    _invalidatePackCare(pack.id);
    return PackCareInviteResult.success(
      invite: inviteResult.value!,
      warningMessage: inviteTarget.warningMessage,
    );
  }

  Future<PackCareInviteResult> refreshInviteForPack(ItemPack pack) async {
    final inviteTarget = await _prepareInviteTarget(pack);
    if (!inviteTarget.succeeded) {
      return PackCareInviteResult.failure(inviteTarget.errorMessage!);
    }

    final inviteResult = await _ref
        .read(remoteSharedPackRepositoryProvider)
        .refreshInviteForPack(inviteTarget.remotePackId!);
    if (!inviteResult.isSuccess) {
      return PackCareInviteResult.failure(
        _sharedCareFailureMessage(inviteResult.failureReason),
      );
    }

    _invalidatePackCare(pack.id);
    return PackCareInviteResult.success(
      invite: inviteResult.value!,
      warningMessage: inviteTarget.warningMessage,
    );
  }

  Future<_InviteTargetResult> _prepareInviteTarget(ItemPack pack) async {
    if (pack.isSystemDefault) {
      return const _InviteTargetResult.failure(
        ReminderUiText.packCareRemoteUnavailable,
      );
    }

    if (pack.packType != ItemPackType.shared) {
      final converted = await _ref
          .read(sharedPackRepositoryProvider)
          .convertPackToShared(pack.id);
      if (!converted) {
        final refreshed = await _ref
            .read(itemRepositoryProvider)
            .getPackById(pack.id);
        if (refreshed?.packType != ItemPackType.shared) {
          return const _InviteTargetResult.failure(
            ReminderUiText.packCareRemoteUnavailable,
          );
        }
      }
    }

    final remoteRepository = _ref.read(remoteSharedPackRepositoryProvider);
    final linkResult = await remoteRepository
        .createRemoteSharedPackFromLocalPack(pack.id);
    if (!linkResult.isSuccess) {
      return _InviteTargetResult.failure(
        _sharedCareFailureMessage(linkResult.failureReason),
      );
    }

    String? warningMessage;
    final pushResult = await remoteRepository.pushMinimalItems(pack.id);
    if (!pushResult.isSuccess || (pushResult.value?.failedCount ?? 0) > 0) {
      warningMessage = '有些提醒可能稍後才會出現在對方裝置。';
    }

    return _InviteTargetResult.success(
      remotePackId: linkResult.value!.remotePackId,
      warningMessage: warningMessage,
    );
  }

  Future<PackCareJoinResult> joinWithInviteCode(String inviteCode) async {
    final code = normalizeInviteCode(inviteCode);
    if (code.isEmpty) {
      return const PackCareJoinResult.failure(
        ReminderUiText.packCareInviteInvalid,
      );
    }

    final remoteRepository = _ref.read(remoteSharedPackRepositoryProvider);
    final joinResult = await remoteRepository.joinRemotePackWithInvite(code);
    if (!joinResult.isSuccess) {
      return PackCareJoinResult.failure(
        _sharedCareFailureMessage(joinResult.failureReason),
      );
    }

    final remotePackId = joinResult.value!.remotePackId;
    final snapshotResult = await remoteRepository.pullRemotePackSnapshot(
      remotePackId,
    );
    if (!snapshotResult.isSuccess) {
      return PackCareJoinResult.failure(
        _sharedCareFailureMessage(snapshotResult.failureReason),
      );
    }

    final importResult = await _ref
        .read(remoteSnapshotImportServiceProvider)
        .importRemotePackSnapshot(
          snapshot: snapshotResult.value!,
          source: RemoteSnapshotImportSource.joinedRemotePack,
        );
    if (!importResult.succeeded || importResult.localPackId == null) {
      return const PackCareJoinResult.failure('已加入，但目前無法在此裝置顯示這個生活場景。請稍後再試。');
    }

    _invalidatePackCare(importResult.localPackId!);
    return PackCareJoinResult.success(packTitle: snapshotResult.value!.name);
  }

  Future<PackCareRefreshResult> refreshSharedState(ItemPack pack) async {
    final metadata = await _ref
        .read(appDatabaseProvider)
        .reminderDao
        .getRemotePackSyncMetadataForLocalPack(pack.id);
    if (metadata?.syncKind != RemotePackSyncKind.remoteBacked) {
      return const PackCareRefreshResult.failure(
        ReminderUiText.packCareRemoteUnavailable,
      );
    }

    final result = await _ref
        .read(remoteBackedPackRefreshServiceProvider)
        .refreshPack(pack.id);
    _invalidatePackCare(result.summary.localPackId);
    if (result.succeeded) {
      _refreshDerivedLocalSurfaces();
      return PackCareRefreshResult.success(
        message: ReminderUiText.packCareRefreshSuccess,
        warningMessage:
            result.status ==
                RemoteBackedPackRefreshStatus.hasPendingLocalMutations
            ? ReminderUiText.packCareRefreshPendingWarning
            : null,
      );
    }

    return PackCareRefreshResult.failure(_refreshFailureMessage(result.status));
  }

  void _invalidatePackCare(int packId) {
    _ref.invalidate(activeItemPacksProvider);
    _ref.invalidate(itemManagementGroupsProvider);
    _ref.invalidate(dangerHomeAttentionEntriesProvider);
    _ref.invalidate(warningHomeAttentionEntriesProvider);
    _ref.invalidate(dangerHomeEntriesProvider);
    _ref.invalidate(warningHomeEntriesProvider);
    _ref.invalidate(todayCompletedEntriesProvider);
    _ref.invalidate(packCareViewModelProvider);
    _ref.invalidate(packMembersProvider(packId));
    _ref.invalidate(currentAppUserProvider);
    _ref.invalidate(currentAppUserIdProvider);
  }

  void _refreshDerivedLocalSurfaces() {
    unawaited(
      _bestEffort(() async {
        await _ref.read(homeWidgetActionServiceProvider).refreshSnapshot();
      }),
    );
    unawaited(
      _bestEffort(() => _ref.read(attentionSyncServiceProvider).refresh()),
    );
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Derived surfaces are refreshed opportunistically from local data.
    }
  }
}

class _InviteTargetResult {
  const _InviteTargetResult.success({
    required this.remotePackId,
    this.warningMessage,
  }) : errorMessage = null;

  const _InviteTargetResult.failure(this.errorMessage)
    : remotePackId = null,
      warningMessage = null;

  final String? remotePackId;
  final String? warningMessage;
  final String? errorMessage;

  bool get succeeded => remotePackId != null;
}

final sharedPackCareControllerProvider = Provider<SharedPackCareController>((
  ref,
) {
  return SharedPackCareController(ref);
});

final packCareViewModelProvider =
    FutureProvider.family<PackCareViewModel, ItemPack>((ref, pack) async {
      final dao = ref.watch(appDatabaseProvider).reminderDao;
      final currentPack = await dao.getItemPackById(pack.id) ?? pack;
      final metadata = await dao.getRemotePackSyncMetadataForLocalPack(
        currentPack.id,
      );
      final currentUser = await ref.watch(currentAppUserProvider.future);
      final members = currentPack.packType == ItemPackType.shared
          ? await _loadActiveMembers(dao, currentPack.id, currentUser.id)
          : const <PackCareMemberView>[];
      final inviteState = await _loadInviteState(ref, dao, currentPack.id);
      return PackCareViewModel(
        pack: currentPack,
        metadata: metadata,
        members: members,
        inviteState: inviteState,
      );
    });

Future<RemotePackInviteState> _loadInviteState(
  Ref ref,
  ReminderDao dao,
  int packId,
) async {
  final mapping = await dao.getSyncMapping(
    localEntityType: RemoteSharedPackRepository.localEntityPack,
    localEntityId: packId,
    remoteTable: RemoteSharedPackRepository.remoteTablePacks,
  );
  if (mapping == null) {
    return const RemotePackInviteState();
  }
  final result = await ref
      .read(remoteSharedPackRepositoryProvider)
      .fetchPackInviteState(mapping.remoteEntityId);
  if (!result.isSuccess) {
    return const RemotePackInviteState();
  }
  return result.value!;
}

Future<List<PackCareMemberView>> _loadActiveMembers(
  ReminderDao dao,
  int packId,
  String currentUserId,
) async {
  final members = await dao.listPackMembers(packId);
  final users = await dao.listLocalUsers();
  final usersById = {for (final user in users) user.id: user};
  return members
      .where((member) => member.status == PackMemberStatus.active)
      .map((member) {
        final user = usersById[member.userId];
        return PackCareMemberView(
          displayName: member.userId == currentUserId
              ? '你'
              : user?.displayName ?? '照顧成員',
          roleLabel: switch (member.role) {
            PackMemberRole.host => '建立者',
            PackMemberRole.member => '成員',
          },
        );
      })
      .toList(growable: false);
}

String _sharedCareFailureMessage(RemoteSharedPackFailureReason? reason) {
  return switch (reason) {
    RemoteSharedPackFailureReason.remoteInviteInvalid =>
      ReminderUiText.packCareInviteInvalid,
    RemoteSharedPackFailureReason.remoteInviteExpired =>
      ReminderUiText.packCareInviteExpired,
    RemoteSharedPackFailureReason.remoteInviteMaxUsesReached =>
      ReminderUiText.packCareInviteMaxUsesReached,
    RemoteSharedPackFailureReason.remoteInviteAlreadyRevoked =>
      ReminderUiText.packCareInviteInvalid,
    RemoteSharedPackFailureReason.remoteInviteNotHost => '目前無法建立邀請。',
    RemoteSharedPackFailureReason.remoteRlsRejected => '遠端資料庫權限不足，請稍後再試。',
    RemoteSharedPackFailureReason.supabaseConfigMissing ||
    RemoteSharedPackFailureReason.remoteAuthRequired ||
    RemoteSharedPackFailureReason.remoteProfileFailed ||
    RemoteSharedPackFailureReason.remotePackCreateFailed ||
    RemoteSharedPackFailureReason.remoteNetworkFailed ||
    RemoteSharedPackFailureReason.remoteUnknownFailure ||
    RemoteSharedPackFailureReason.malformedRemoteData ||
    RemoteSharedPackFailureReason.localPackNotShared ||
    RemoteSharedPackFailureReason.localUserNotPackMember ||
    RemoteSharedPackFailureReason.remoteItemPushFailed ||
    RemoteSharedPackFailureReason.remoteItemAlreadyCompleted ||
    RemoteSharedPackFailureReason.remotePackAlreadyLinked ||
    null => ReminderUiText.packCareRemoteUnavailable,
  };
}

String _refreshFailureMessage(RemoteBackedPackRefreshStatus status) {
  return switch (status) {
    RemoteBackedPackRefreshStatus.accessLost =>
      ReminderUiText.packCareRefreshAccessLost,
    RemoteBackedPackRefreshStatus.configMissing ||
    RemoteBackedPackRefreshStatus.remoteAuthRequired ||
    RemoteBackedPackRefreshStatus.remoteRlsRejected ||
    RemoteBackedPackRefreshStatus.networkFailed ||
    RemoteBackedPackRefreshStatus.importFailed ||
    RemoteBackedPackRefreshStatus.partialImport ||
    RemoteBackedPackRefreshStatus.unknownFailure =>
      ReminderUiText.packCareRefreshFailed,
    RemoteBackedPackRefreshStatus.notRemoteBacked ||
    RemoteBackedPackRefreshStatus.missingRemoteMapping =>
      ReminderUiText.packCareRemoteUnavailable,
    RemoteBackedPackRefreshStatus.refreshed ||
    RemoteBackedPackRefreshStatus.hasPendingLocalMutations =>
      ReminderUiText.packCareRefreshSuccess,
  };
}
