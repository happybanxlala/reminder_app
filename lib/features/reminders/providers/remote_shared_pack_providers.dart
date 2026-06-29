import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_widget/providers/home_widget_providers.dart';
import '../data/anonymous_remote_identity_service.dart';
import '../data/local/app_database.dart';
import '../data/local/reminder_dao.dart';
import '../data/remote_backed_outbox_flush_service.dart';
import '../data/remote_backed_outbox_retry_service.dart';
import '../data/remote_backed_pack_refresh_service.dart';
import '../data/remote_membership_recovery_service.dart';
import '../data/remote_shared_pack_data_source.dart';
import '../data/remote_shared_pack_models.dart';
import '../data/remote_shared_pack_repository.dart';
import '../data/remote_shared_pack_realtime_data_source.dart';
import '../data/remote_snapshot_import_service.dart';
import '../data/supabase_config.dart';
import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/remote_backed_pack_refresh.dart';
import '../domain/remote_backed_recovery.dart';
import '../domain/remote_membership_recovery.dart';
import '../domain/remote_pack_freshness.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import 'attention_service_providers.dart';
import 'database_providers.dart';
import 'identity_providers.dart';

final remoteSharedPackDataSourceProvider = Provider<RemoteSharedPackDataSource>(
  (ref) {
    final runtime = ref.watch(supabaseRuntimeProvider);
    if (runtime.isAvailable) {
      return SupabaseRemoteSharedPackDataSource(runtime);
    }
    final reason = runtime.status == SupabaseRuntimeStatus.missingConfig
        ? RemoteSharedPackFailureReason.supabaseConfigMissing
        : RemoteSharedPackFailureReason.remoteNetworkFailed;
    return DisabledRemoteSharedPackDataSource(reason);
  },
);

final remoteSharedPackRepositoryProvider = Provider<RemoteSharedPackRepository>(
  (ref) {
    return RemoteSharedPackRepository(
      dao: ref.watch(appDatabaseProvider).reminderDao,
      identityRepository: ref.watch(identityRepositoryProvider),
      anonymousIdentityService: ref.watch(
        anonymousRemoteIdentityServiceProvider,
      ),
      remoteDataSource: ref.watch(remoteSharedPackDataSourceProvider),
    );
  },
);

final remoteSnapshotImportServiceProvider =
    Provider<RemoteSnapshotImportService>((ref) {
      return RemoteSnapshotImportService(
        dao: ref.watch(appDatabaseProvider).reminderDao,
        identityRepository: ref.watch(identityRepositoryProvider),
      );
    });

final remoteBackedOutboxFlushServiceProvider =
    Provider<RemoteBackedOutboxFlushService>((ref) {
      return RemoteBackedOutboxFlushService(
        dao: ref.watch(appDatabaseProvider).reminderDao,
        remoteClient: RemoteSharedPackOutboxRemoteClient(
          ref.watch(remoteSharedPackRepositoryProvider),
        ),
      );
    });

final remoteBackedOutboxRetryServiceProvider =
    Provider<RemoteBackedOutboxRetryService>((ref) {
      return RemoteBackedOutboxRetryService(
        dao: ref.watch(appDatabaseProvider).reminderDao,
        remoteClient: RemoteSharedPackOutboxRemoteClient(
          ref.watch(remoteSharedPackRepositoryProvider),
        ),
      );
    });

final remoteBackedPackRefreshServiceProvider =
    Provider<RemoteBackedPackRefreshService>((ref) {
      final remoteRepository = ref.watch(remoteSharedPackRepositoryProvider);
      final importService = ref.watch(remoteSnapshotImportServiceProvider);
      return RemoteBackedPackRefreshService(
        dao: ref.watch(appDatabaseProvider).reminderDao,
        pullRemotePackSnapshot: remoteRepository.pullRemotePackSnapshot,
        importRemotePackSnapshot: importService.importRemotePackSnapshot,
        reportPackSnapshotImported: remoteRepository.reportPackSnapshotImported,
      );
    });

final remoteMembershipRecoveryServiceProvider =
    Provider<RemoteMembershipRecoveryService>((ref) {
      return RemoteMembershipRecoveryService(
        dao: ref.watch(appDatabaseProvider).reminderDao,
        accountProtectionService: ref.watch(accountProtectionServiceProvider),
        remoteRepository: ref.watch(remoteSharedPackRepositoryProvider),
        importService: ref.watch(remoteSnapshotImportServiceProvider),
        reportPackSnapshotImported: ref
            .watch(remoteSharedPackRepositoryProvider)
            .reportPackSnapshotImported,
      );
    });

final remoteSharedPackRealtimeDataSourceProvider =
    Provider<RemoteSharedPackRealtimeDataSource>((ref) {
      final runtime = ref.watch(supabaseRuntimeProvider);
      if (runtime.isAvailable) {
        return SupabaseRemoteSharedPackRealtimeDataSource(runtime);
      }
      final reason = runtime.status == SupabaseRuntimeStatus.missingConfig
          ? RemoteSharedPackFailureReason.supabaseConfigMissing
          : RemoteSharedPackFailureReason.remoteNetworkFailed;
      return DisabledRemoteSharedPackRealtimeDataSource(reason);
    });

class RemotePocSnapshotSummary {
  const RemotePocSnapshotSummary({
    required this.membersCount,
    required this.itemsCount,
    required this.activeCompletionsCount,
    required this.activityEventsCount,
  });

  final int membersCount;
  final int itemsCount;
  final int activeCompletionsCount;
  final int activityEventsCount;
}

class RemoteBackedOutboxSummary {
  const RemoteBackedOutboxSummary({
    required this.pendingCount,
    required this.syncingCount,
    required this.failedCount,
    required this.conflictOrNoOpCount,
  });

  final int pendingCount;
  final int syncingCount;
  final int failedCount;
  final int conflictOrNoOpCount;

  int get total =>
      pendingCount + syncingCount + failedCount + conflictOrNoOpCount;
}

class RemoteSyncDebugSnapshot {
  const RemoteSyncDebugSnapshot({
    required this.currentLocalUser,
    required this.supabaseCurrentUserId,
    required this.supabaseSessionExists,
    required this.packs,
    required this.recentOutboxEntries,
  });

  final LocalUser currentLocalUser;
  final String? supabaseCurrentUserId;
  final bool supabaseSessionExists;
  final List<RemoteSyncDebugPack> packs;
  final List<SyncOutboxEntry> recentOutboxEntries;
}

class RemoteSyncDebugPack {
  const RemoteSyncDebugPack({
    required this.localPackId,
    required this.remotePackId,
    required this.syncState,
    required this.currentUserRemoteStatus,
    required this.currentUserRemoteRole,
    required this.pendingOutboxCount,
    required this.syncingOutboxCount,
    required this.failedOutboxCount,
    required this.lastFailedError,
  });

  final int localPackId;
  final String remotePackId;
  final RemotePackSyncState syncState;
  final RemoteUserStatus? currentUserRemoteStatus;
  final RemoteUserRole? currentUserRemoteRole;
  final int pendingOutboxCount;
  final int syncingOutboxCount;
  final int failedOutboxCount;
  final String? lastFailedError;
}

class RemotePocFreshnessSummary {
  const RemotePocFreshnessSummary({
    required this.totalCount,
    required this.upToDateCount,
    required this.possiblyStaleCount,
    required this.noSyncReportCount,
    required this.accessUnknownCount,
  });

  final int totalCount;
  final int upToDateCount;
  final int possiblyStaleCount;
  final int noSyncReportCount;
  final int accessUnknownCount;
}

enum RemotePocSnapshotTargetType { localMappedPack, joinedRemotePack }

enum RemoteRealtimeStatus {
  disabled,
  unavailable,
  connecting,
  subscribed,
  error,
}

class RemotePocSelectedItem {
  const RemotePocSelectedItem({
    required this.item,
    required this.activeCompletion,
  });

  final RemoteItemSnapshot item;
  final RemoteItemCompletionSnapshot? activeCompletion;

  bool get hasActiveCompletion => activeCompletion != null;
}

class RemotePocOperationState {
  const RemotePocOperationState({
    this.isRunning = false,
    this.lastAction,
    this.lastSucceeded,
    this.lastMessage,
    this.lastAt,
    this.snapshotSummary,
    this.lastCreatedInviteCode,
    this.lastCreatedInviteId,
    this.lastInviteExpiresAt,
    this.lastInviteMaxUses,
    this.inviteCodeInput = '',
    this.lastJoinedRemotePackId,
    this.lastPulledRemoteSnapshot,
    this.snapshotTargetType,
    this.lastRefreshAt,
    this.lastRefreshSucceeded,
    this.selectedRemoteItemId,
    this.realtimeStatus = RemoteRealtimeStatus.disabled,
    this.realtimeTargetRemotePackId,
    this.hasRemoteChanges = false,
    this.remoteChangeCount = 0,
    this.lastRemoteChangeReceivedAt,
    this.lastRemoteChangeAction,
    this.lastRemoteChangeActorUserId,
    this.lastRealtimeErrorMessage,
    this.lastFreshnessSummary,
  });

  final bool isRunning;
  final String? lastAction;
  final bool? lastSucceeded;
  final String? lastMessage;
  final DateTime? lastAt;
  final RemotePocSnapshotSummary? snapshotSummary;
  final String? lastCreatedInviteCode;
  final String? lastCreatedInviteId;
  final DateTime? lastInviteExpiresAt;
  final int? lastInviteMaxUses;
  final String inviteCodeInput;
  final String? lastJoinedRemotePackId;
  final RemotePackSnapshot? lastPulledRemoteSnapshot;
  final RemotePocSnapshotTargetType? snapshotTargetType;
  final DateTime? lastRefreshAt;
  final bool? lastRefreshSucceeded;
  final String? selectedRemoteItemId;
  final RemoteRealtimeStatus realtimeStatus;
  final String? realtimeTargetRemotePackId;
  final bool hasRemoteChanges;
  final int remoteChangeCount;
  final DateTime? lastRemoteChangeReceivedAt;
  final String? lastRemoteChangeAction;
  final String? lastRemoteChangeActorUserId;
  final String? lastRealtimeErrorMessage;
  final RemotePocFreshnessSummary? lastFreshnessSummary;

  RemoteItemSnapshot? get firstSnapshotItem {
    final snapshot = lastPulledRemoteSnapshot;
    if (snapshot == null || snapshot.items.isEmpty) {
      return null;
    }
    return snapshot.items.first;
  }

  RemotePocSelectedItem? get selectedSnapshotItem {
    final snapshot = lastPulledRemoteSnapshot;
    final selectedId = selectedRemoteItemId;
    if (snapshot == null || selectedId == null) {
      return null;
    }
    RemoteItemSnapshot? item;
    for (final entry in snapshot.items) {
      if (entry.id == selectedId) {
        item = entry;
        break;
      }
    }
    if (item == null) {
      return null;
    }
    RemoteItemCompletionSnapshot? completion;
    for (final entry in snapshot.completions) {
      if (entry.itemId == item.id && entry.undoneAt == null) {
        completion = entry;
        break;
      }
    }
    return RemotePocSelectedItem(item: item, activeCompletion: completion);
  }

  RemotePocOperationState copyWith({
    bool? isRunning,
    String? lastAction,
    bool? lastSucceeded,
    String? lastMessage,
    DateTime? lastAt,
    RemotePocSnapshotSummary? snapshotSummary,
    String? lastCreatedInviteCode,
    String? lastCreatedInviteId,
    DateTime? lastInviteExpiresAt,
    int? lastInviteMaxUses,
    String? inviteCodeInput,
    String? lastJoinedRemotePackId,
    RemotePackSnapshot? lastPulledRemoteSnapshot,
    RemotePocSnapshotTargetType? snapshotTargetType,
    DateTime? lastRefreshAt,
    bool? lastRefreshSucceeded,
    String? selectedRemoteItemId,
    RemoteRealtimeStatus? realtimeStatus,
    String? realtimeTargetRemotePackId,
    bool? hasRemoteChanges,
    int? remoteChangeCount,
    DateTime? lastRemoteChangeReceivedAt,
    String? lastRemoteChangeAction,
    String? lastRemoteChangeActorUserId,
    String? lastRealtimeErrorMessage,
    RemotePocFreshnessSummary? lastFreshnessSummary,
    bool clearSnapshotSummary = false,
    bool clearInvite = false,
    bool clearJoinedRemotePackId = false,
    bool clearLastPulledRemoteSnapshot = false,
    bool clearSelectedRemoteItem = false,
    bool clearRealtimeTarget = false,
    bool clearRealtimeError = false,
    bool clearRemoteChanges = false,
    bool clearFreshnessSummary = false,
  }) {
    return RemotePocOperationState(
      isRunning: isRunning ?? this.isRunning,
      lastAction: lastAction ?? this.lastAction,
      lastSucceeded: lastSucceeded ?? this.lastSucceeded,
      lastMessage: lastMessage ?? this.lastMessage,
      lastAt: lastAt ?? this.lastAt,
      snapshotSummary: clearSnapshotSummary
          ? null
          : snapshotSummary ?? this.snapshotSummary,
      lastCreatedInviteCode: clearInvite
          ? null
          : lastCreatedInviteCode ?? this.lastCreatedInviteCode,
      lastCreatedInviteId: clearInvite
          ? null
          : lastCreatedInviteId ?? this.lastCreatedInviteId,
      lastInviteExpiresAt: clearInvite
          ? null
          : lastInviteExpiresAt ?? this.lastInviteExpiresAt,
      lastInviteMaxUses: clearInvite
          ? null
          : lastInviteMaxUses ?? this.lastInviteMaxUses,
      inviteCodeInput: inviteCodeInput ?? this.inviteCodeInput,
      lastJoinedRemotePackId: clearJoinedRemotePackId
          ? null
          : lastJoinedRemotePackId ?? this.lastJoinedRemotePackId,
      lastPulledRemoteSnapshot: clearLastPulledRemoteSnapshot
          ? null
          : lastPulledRemoteSnapshot ?? this.lastPulledRemoteSnapshot,
      snapshotTargetType: clearLastPulledRemoteSnapshot
          ? null
          : snapshotTargetType ?? this.snapshotTargetType,
      lastRefreshAt: clearLastPulledRemoteSnapshot
          ? null
          : lastRefreshAt ?? this.lastRefreshAt,
      lastRefreshSucceeded: lastRefreshSucceeded ?? this.lastRefreshSucceeded,
      selectedRemoteItemId:
          clearSelectedRemoteItem || clearLastPulledRemoteSnapshot
          ? null
          : selectedRemoteItemId ?? this.selectedRemoteItemId,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      realtimeTargetRemotePackId: clearRealtimeTarget
          ? null
          : realtimeTargetRemotePackId ?? this.realtimeTargetRemotePackId,
      hasRemoteChanges: clearRemoteChanges
          ? false
          : hasRemoteChanges ?? this.hasRemoteChanges,
      remoteChangeCount: clearRemoteChanges
          ? 0
          : remoteChangeCount ?? this.remoteChangeCount,
      lastRemoteChangeReceivedAt:
          lastRemoteChangeReceivedAt ?? this.lastRemoteChangeReceivedAt,
      lastRemoteChangeAction:
          lastRemoteChangeAction ?? this.lastRemoteChangeAction,
      lastRemoteChangeActorUserId:
          lastRemoteChangeActorUserId ?? this.lastRemoteChangeActorUserId,
      lastRealtimeErrorMessage: clearRealtimeError
          ? null
          : lastRealtimeErrorMessage ?? this.lastRealtimeErrorMessage,
      lastFreshnessSummary: clearFreshnessSummary
          ? null
          : lastFreshnessSummary ?? this.lastFreshnessSummary,
    );
  }
}

class RemotePocController extends StateNotifier<RemotePocOperationState> {
  RemotePocController(this._ref) : super(const RemotePocOperationState());

  final Ref _ref;
  RemotePackChangeSubscription? _activeRealtimeSubscription;

  void updateInviteCodeInput(String value) {
    state = state.copyWith(inviteCodeInput: value);
  }

  void selectRemoteSnapshotItem(String itemId) {
    state = state.copyWith(selectedRemoteItemId: itemId);
  }

  Future<String> subscribeToRemoteChanges(String? remotePackId) async {
    if (remotePackId == null) {
      state = state.copyWith(
        realtimeStatus: RemoteRealtimeStatus.disabled,
        clearRealtimeTarget: true,
        lastAction: '開始監聽遠端變更 POC',
        lastSucceeded: false,
        lastMessage: '尚未有可監聽的遠端 Pack',
        lastAt: DateTime.now(),
      );
      return '尚未有可監聽的遠端 Pack';
    }

    final active = _activeRealtimeSubscription;
    if (active != null &&
        active.isActive &&
        active.remotePackId == remotePackId &&
        state.realtimeStatus == RemoteRealtimeStatus.subscribed) {
      state = state.copyWith(
        lastAction: '開始監聽遠端變更 POC',
        lastSucceeded: true,
        lastMessage: '已在監聽此遠端 Pack',
        lastAt: DateTime.now(),
      );
      return '已在監聽此遠端 Pack';
    }

    if (active != null && active.isActive) {
      await active.unsubscribe();
      _activeRealtimeSubscription = null;
    }

    state = state.copyWith(
      realtimeStatus: RemoteRealtimeStatus.connecting,
      realtimeTargetRemotePackId: remotePackId,
      clearRealtimeError: true,
      lastAction: '開始監聽遠端變更 POC',
      lastSucceeded: null,
      lastMessage: 'Realtime 連線中',
      lastAt: DateTime.now(),
    );

    final dataSource = _ref.read(remoteSharedPackRealtimeDataSourceProvider);
    _activeRealtimeSubscription = dataSource.subscribeToRemotePackChanges(
      remotePackId: remotePackId,
      onSignal: _handleRealtimeSignal,
      onError: _handleRealtimeError,
      onSubscribed: () {
        state = state.copyWith(
          realtimeStatus: RemoteRealtimeStatus.subscribed,
          realtimeTargetRemotePackId: remotePackId,
          clearRealtimeError: true,
          lastAction: '開始監聽遠端變更 POC',
          lastSucceeded: true,
          lastMessage: '已訂閱遠端變更',
          lastAt: DateTime.now(),
        );
      },
    );

    return 'Realtime 連線中';
  }

  Future<String> unsubscribeRemoteChanges() async {
    final active = _activeRealtimeSubscription;
    if (active != null && active.isActive) {
      await active.unsubscribe();
    }
    _activeRealtimeSubscription = null;
    state = state.copyWith(
      realtimeStatus: RemoteRealtimeStatus.disabled,
      clearRealtimeTarget: true,
      clearRealtimeError: true,
      lastAction: '停止監聽遠端變更 POC',
      lastSucceeded: true,
      lastMessage: '已停止監聽遠端變更',
      lastAt: DateTime.now(),
    );
    return '已停止監聽遠端變更';
  }

  void _handleRealtimeSignal(RemotePackChangeSignal signal) {
    if (signal.remotePackId != state.realtimeTargetRemotePackId) {
      return;
    }
    state = state.copyWith(
      hasRemoteChanges: true,
      remoteChangeCount: state.remoteChangeCount + 1,
      lastRemoteChangeReceivedAt: signal.receivedAt,
      lastRemoteChangeAction: signal.action,
      lastRemoteChangeActorUserId: signal.actorUserId,
      clearRealtimeError: true,
    );
  }

  void _handleRealtimeError(Object error) {
    final active = _activeRealtimeSubscription;
    if (active != null && active.isActive) {
      unawaited(active.unsubscribe());
    }
    _activeRealtimeSubscription = null;
    final status =
        error is RemoteSharedPackException &&
            error.reason == RemoteSharedPackFailureReason.supabaseConfigMissing
        ? RemoteRealtimeStatus.unavailable
        : RemoteRealtimeStatus.error;
    state = state.copyWith(
      realtimeStatus: status,
      clearRealtimeTarget: true,
      lastRealtimeErrorMessage: _realtimeErrorMessage(error),
      lastAction: '遠端變更監聽',
      lastSucceeded: false,
      lastMessage: _realtimeErrorMessage(error),
      lastAt: DateTime.now(),
    );
  }

  String _realtimeErrorMessage(Object error) {
    if (error is RemoteSharedPackException) {
      return switch (error.reason) {
        RemoteSharedPackFailureReason.supabaseConfigMissing => 'Supabase 尚未設定',
        RemoteSharedPackFailureReason.remoteAuthRequired => '請先建立匿名遠端身份',
        RemoteSharedPackFailureReason.remoteRlsRejected => '遠端資料被 RLS 拒絕',
        RemoteSharedPackFailureReason.remoteNetworkFailed => '網絡連線失敗',
        _ => '遠端變更監聽失敗',
      };
    }
    return '遠端變更監聽失敗';
  }

  Future<String> ensureAnonymousRemoteIdentity() {
    return _run('建立匿名遠端身份', () async {
      final result = await _ref
          .read(anonymousRemoteIdentityServiceProvider)
          .ensureAnonymousRemoteIdentity();
      _ref.invalidate(currentAppUserProvider);
      _ref.invalidate(currentAppUserIdProvider);
      return switch (result.status) {
        AnonymousRemoteIdentityStatus.success => const _RemotePocOutcome(
          succeeded: true,
          message: '匿名遠端身份已建立',
        ),
        AnonymousRemoteIdentityStatus.alreadyLinked => const _RemotePocOutcome(
          succeeded: true,
          message: '已建立匿名遠端身份',
        ),
        AnonymousRemoteIdentityStatus.configMissing => const _RemotePocOutcome(
          succeeded: false,
          message: 'Supabase 尚未設定',
        ),
        AnonymousRemoteIdentityStatus.remoteAuthFailed =>
          const _RemotePocOutcome(succeeded: false, message: '建立匿名遠端身份失敗'),
      };
    });
  }

  Future<String> ensureRemoteProfile() {
    return _run('建立 / 確認 Remote Profile', () async {
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .ensureRemoteProfile();
      _ref.invalidate(currentAppUserProvider);
      _ref.invalidate(currentAppUserIdProvider);
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      return _RemotePocOutcome(
        succeeded: true,
        message: 'Remote Profile 已確認：${_shortId(result.value!.id)}',
      );
    });
  }

  Future<String> createRemotePack(int? localPackId) {
    return _run('建立遠端共同 Pack POC', () async {
      if (localPackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先建立 / 選擇 local shared pack',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .createRemoteSharedPackFromLocalPack(localPackId);
      _ref.invalidate(remotePocPackMappingProvider(localPackId));
      _ref.invalidate(remotePocFirstMappedItemProvider(localPackId));
      _ref.invalidate(currentAppUserProvider);
      _ref.invalidate(currentAppUserIdProvider);
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      final link = result.value!;
      if (link.alreadyLinked) {
        return _RemotePocOutcome(
          succeeded: true,
          message: '此 Pack 已有遠端 POC mapping：${_shortId(link.remotePackId)}',
        );
      }
      return _RemotePocOutcome(
        succeeded: true,
        message: '已建立遠端 Pack：${_shortId(link.remotePackId)}',
      );
    });
  }

  Future<String> pushMinimalItems(int? localPackId) {
    return _run('推送 Minimal Items POC', () async {
      if (localPackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先建立 / 選擇 local shared pack',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .pushMinimalItems(localPackId);
      _ref.invalidate(remotePocFirstMappedItemProvider(localPackId));
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      final summary = result.value!;
      return _RemotePocOutcome(
        succeeded: true,
        message:
            '已推送 ${summary.pushedCount} 個 items，略過 ${summary.skippedCount} 個，失敗 ${summary.failedCount} 個',
      );
    });
  }

  Future<String> createInviteCode(String? remotePackId) {
    return _run('建立 Invite Code POC', () async {
      if (remotePackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先建立遠端 Pack',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .createRemotePackInvite(remotePackId);
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      final invite = result.value!;
      return _RemotePocOutcome(
        succeeded: true,
        message: 'Invite Code 已建立：${invite.inviteCode}',
        invite: invite,
      );
    });
  }

  Future<String> joinWithInviteCode() {
    return _run('加入遠端 Pack POC', () async {
      final inviteCode = state.inviteCodeInput.trim();
      if (inviteCode.isEmpty) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請輸入 Invite Code',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .joinRemotePackWithInvite(inviteCode);
      _ref.invalidate(currentAppUserProvider);
      _ref.invalidate(currentAppUserIdProvider);
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      final join = result.value!;
      final status = join.status == RemoteJoinPackStatus.alreadyMember
          ? 'already member'
          : 'joined';
      return _RemotePocOutcome(
        succeeded: true,
        message: '加入遠端 Pack：$status ${_shortId(join.remotePackId)}',
        joinedRemotePackId: join.remotePackId,
      );
    });
  }

  Future<String> refreshRemoteSyncDebugSnapshot() async {
    _ref.invalidate(remoteSyncDebugSnapshotProvider);
    return 'Remote sync debug 已刷新';
  }

  Future<String> resetStuckSyncingRemoteBackedOutbox() async {
    return _run('重設卡住的 remote-backed outbox', () async {
      final dao = _ref.read(appDatabaseProvider).reminderDao;
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(seconds: 30));
      final metadata = await dao.listRemotePackSyncMetadataEntries();
      final resettablePackIds = metadata
          .where(
            (entry) =>
                entry.syncKind == RemotePackSyncKind.remoteBacked &&
                entry.syncState != RemotePackSyncState.accessLost &&
                entry.syncState != RemotePackSyncState.removed &&
                entry.currentUserRemoteStatus != RemoteUserStatus.removed,
          )
          .map((entry) => entry.localPackId)
          .toSet();
      if (resettablePackIds.isEmpty) {
        _invalidateRemoteSyncDebug();
        return const _RemotePocOutcome(
          succeeded: true,
          message: '沒有可重設的 remote-backed outbox',
        );
      }

      final entries = await dao.listSyncOutboxEntries(
        statuses: {SyncOutboxStatus.syncing},
      );
      var resetCount = 0;
      final nowMillis = now.millisecondsSinceEpoch;
      for (final entry in entries) {
        if (!resettablePackIds.contains(entry.localPackId) ||
            entry.resolvedAt != null) {
          continue;
        }
        final lastTouched = entry.lastAttemptAt ?? entry.updatedAt;
        if (!lastTouched.isBefore(cutoff)) {
          continue;
        }
        await dao.updateSyncOutboxEntry(
          entry.id,
          SyncOutboxCompanion(
            status: Value(SyncOutboxStatus.pending.storageValue),
            lastError: const Value('debug_reset_stuck_syncing'),
            updatedAt: Value(nowMillis),
          ),
        );
        resetCount++;
      }
      _invalidateRemoteSyncDebug();
      return _RemotePocOutcome(
        succeeded: true,
        message: '已重設 $resetCount 筆卡住的 outbox',
      );
    });
  }

  Future<String> completeFirstMappedItem(int? localPackId) {
    return _run('完成遠端 Item POC', () async {
      if (localPackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先建立 / 選擇 local shared pack',
        );
      }
      final mappedItem = await _ref.read(
        remotePocFirstMappedItemProvider(localPackId).future,
      );
      if (mappedItem == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先推送 Minimal Items',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .completeRemoteItemForLocalItem(mappedItem.item.id);
      if (result.failureReason ==
          RemoteSharedPackFailureReason.remoteItemAlreadyCompleted) {
        return const _RemotePocOutcome(
          succeeded: true,
          message: '遠端 Item 已經完成，不覆寫完成者',
        );
      }
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      return const _RemotePocOutcome(succeeded: true, message: '遠端 Item 已完成');
    });
  }

  Future<String> completeFirstSnapshotItem() {
    return _run('完成 Snapshot 第一個 Remote Item POC', () async {
      final item = state.firstSnapshotItem;
      if (item == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先拉取 Remote Snapshot',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .completeRemoteItemByRemoteId(item.id);
      if (result.failureReason ==
          RemoteSharedPackFailureReason.remoteItemAlreadyCompleted) {
        return const _RemotePocOutcome(
          succeeded: true,
          message: 'Snapshot Remote Item 已經完成',
        );
      }
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      return const _RemotePocOutcome(
        succeeded: true,
        message: 'Snapshot Remote Item 已完成',
      );
    });
  }

  Future<String> completeSelectedSnapshotItem() {
    return _run('完成選擇的 Remote Item', () async {
      final selected = state.selectedSnapshotItem;
      if (selected == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '尚未選擇 remote item',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .completeRemoteItemByRemoteId(selected.item.id);
      if (result.failureReason ==
          RemoteSharedPackFailureReason.remoteItemAlreadyCompleted) {
        return const _RemotePocOutcome(
          succeeded: true,
          message: 'Remote Item 已經完成，不覆寫完成者。請按「刷新遠端 Snapshot」。',
        );
      }
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      return const _RemotePocOutcome(
        succeeded: true,
        message: '已完成選擇的 Remote Item。請按「刷新遠端 Snapshot」。',
      );
    });
  }

  Future<String> undoSelectedSnapshotItem() {
    return _run('復原選擇的 Remote Item', () async {
      final selected = state.selectedSnapshotItem;
      if (selected == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '尚未選擇 remote item',
        );
      }
      if (!selected.hasActiveCompletion) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '此 Remote Item 尚未完成',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .undoRemoteItemByRemoteId(selected.item.id);
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason, result.error);
      }
      final undo = result.value!;
      if (undo.status == RemoteItemUndoStatus.alreadyNotCompleted) {
        return const _RemotePocOutcome(
          succeeded: true,
          message: 'Remote Item 目前未完成，無需復原。請按「刷新遠端 Snapshot」。',
        );
      }
      return const _RemotePocOutcome(
        succeeded: true,
        message: '已復原選擇的 Remote Item。請按「刷新遠端 Snapshot」。',
      );
    });
  }

  Future<String> pullRemoteSnapshot({
    required int? localPackId,
    required String? remotePackId,
  }) {
    return _run('刷新遠端 Snapshot', () async {
      final targetRemotePackId = state.lastJoinedRemotePackId ?? remotePackId;
      if (targetRemotePackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '尚未有可讀取的遠端 Pack。請先建立遠端 Pack 或加入 Invite Code。',
          refreshAttempted: true,
        );
      }
      final targetType = state.lastJoinedRemotePackId != null
          ? RemotePocSnapshotTargetType.joinedRemotePack
          : RemotePocSnapshotTargetType.localMappedPack;
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .pullRemotePackSnapshot(targetRemotePackId);
      if (!result.isSuccess) {
        return _RemotePocOutcome(
          succeeded: false,
          message: _failureMessage(result.failureReason, result.error),
          refreshAttempted: true,
          snapshotTargetType: targetType,
        );
      }
      final snapshot = result.value!;
      final selectedId = state.selectedRemoteItemId;
      String? nextSelectedId;
      if (selectedId != null) {
        for (final item in snapshot.items) {
          if (item.id == selectedId) {
            nextSelectedId = selectedId;
            break;
          }
        }
      }
      final summary = RemotePocSnapshotSummary(
        membersCount: snapshot.members.length,
        itemsCount: snapshot.items.length,
        activeCompletionsCount: snapshot.completions.length,
        activityEventsCount: snapshot.activityEvents.length,
      );
      return _RemotePocOutcome(
        succeeded: true,
        message:
            'Remote Snapshot：members ${summary.membersCount}, items ${summary.itemsCount}, completions ${summary.activeCompletionsCount}, events ${summary.activityEventsCount}',
        snapshotSummary: summary,
        snapshot: snapshot,
        snapshotTargetType: targetType,
        refreshAttempted: true,
        selectedRemoteItemId: nextSelectedId,
        clearSelectedRemoteItem: nextSelectedId == null,
        clearRemoteChanges: true,
      );
    });
  }

  Future<String> importLastPulledSnapshot() {
    return _run('匯入 Remote Snapshot 到本機 Mirror POC', () async {
      final snapshot = state.lastPulledRemoteSnapshot;
      if (snapshot == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先拉取 Remote Snapshot',
        );
      }
      final targetType = state.snapshotTargetType;
      final source = switch (targetType) {
        RemotePocSnapshotTargetType.joinedRemotePack =>
          RemoteSnapshotImportSource.joinedRemotePack,
        RemotePocSnapshotTargetType.localMappedPack =>
          RemoteSnapshotImportSource.localMappedPack,
        null => RemoteSnapshotImportSource.manualDeveloperImport,
      };
      final result = await _ref
          .read(remoteSnapshotImportServiceProvider)
          .importRemotePackSnapshot(snapshot: snapshot, source: source);
      return _RemotePocOutcome(
        succeeded: result.succeeded,
        message:
            'Mirror import：${_importStatusLabel(result.status)}，items +${result.itemsCreated}/${result.itemsUpdated}，completions +${result.completionsCreated}/${result.completionsUpdated}，events +${result.activityCreated}/${result.activityUpdated}，skipped ${result.skipped}',
        snapshot: snapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: targetType,
      );
    });
  }

  Future<String> refreshAndImportRemoteBackedPack(int? localPackId) {
    return _run('刷新並匯入 Remote-backed Pack POC', () async {
      if (localPackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '目前沒有可刷新的 local pack',
        );
      }
      final result = await _ref
          .read(remoteBackedPackRefreshServiceProvider)
          .refreshPack(localPackId);
      return _RemotePocOutcome(
        succeeded: result.succeeded,
        message: _refreshResultMessage(result),
        snapshotSummary: state.snapshotSummary,
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotTargetType: state.snapshotTargetType,
        refreshAttempted: true,
        clearRemoteChanges: result.succeeded,
      );
    });
  }

  Future<String> retryRetryableFailedMutations() {
    return _run('Retry retryable failed mutations POC', () async {
      final result = await _ref
          .read(remoteBackedOutboxRetryServiceProvider)
          .retryAllRetryableFailedMutations();
      _invalidateRemoteSyncDebug();
      return _RemotePocOutcome(
        succeeded: !result.hasFailure,
        message:
            'Recovery retry：processed ${result.processedCount}, retried ${result.retriedCount}, synced ${result.syncedCount}, no-op ${result.noOpCount}, failed ${result.failedCount}, skipped ${result.skippedCount}',
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: state.snapshotTargetType,
      );
    });
  }

  Future<String> refreshStaleRemoteBackedPacks() {
    return _run('Refresh stale remote-backed packs POC', () async {
      final metadata = await _ref
          .read(appDatabaseProvider)
          .reminderDao
          .listRemotePackSyncMetadataEntries();
      final stalePacks = metadata
          .where(
            (entry) =>
                entry.syncKind == RemotePackSyncKind.remoteBacked &&
                RemoteBackedRecoveryClassifier.isPackStale(entry),
          )
          .toList(growable: false);
      var refreshed = 0;
      var failed = 0;
      for (final entry in stalePacks) {
        final result = await _ref
            .read(remoteBackedPackRefreshServiceProvider)
            .refreshPack(entry.localPackId);
        if (result.succeeded) {
          refreshed++;
        } else {
          failed++;
        }
      }
      _invalidateRemoteSyncDebug();
      return _RemotePocOutcome(
        succeeded: failed == 0,
        message:
            'Stale pack refresh：targets ${stalePacks.length}, refreshed $refreshed, failed $failed',
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: state.snapshotTargetType,
        refreshAttempted: true,
        clearRemoteChanges: failed == 0 && stalePacks.isNotEmpty,
      );
    });
  }

  Future<String> restoreRecoveredRemoteMemberships() {
    return _run('Restore active remote memberships POC', () async {
      final result = await _ref
          .read(remoteMembershipRecoveryServiceProvider)
          .restoreActiveMemberships();
      _ref.invalidate(remoteBackedRecoverySummaryProvider);
      _ref.invalidate(remoteBackedPackRecoverySummaryProvider);
      if (result.succeeded) {
        _invalidateRecoveredLocalSurfaces(result.summary.restoredLocalPackIds);
        await _refreshDerivedLocalSurfaces();
      }
      return _RemotePocOutcome(
        succeeded: result.succeeded,
        message: _membershipRecoveryResultMessage(result),
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: state.snapshotTargetType,
        refreshAttempted: result.succeeded,
        clearRemoteChanges: result.succeeded,
      );
    });
  }

  Future<String> refreshMemberFreshness(String? remotePackId) {
    return _run('刷新成員同步狀態 POC', () async {
      if (remotePackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '尚未有可查詢的遠端 Pack',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .getPackMemberFreshness(remotePackId: remotePackId);
      if (!result.succeeded) {
        return _RemotePocOutcome(
          succeeded: false,
          message: _freshnessFailureMessage(result.status),
        );
      }
      final summary = _freshnessSummary(result.members);
      return _RemotePocOutcome(
        succeeded: true,
        message:
            'Member freshness：members ${summary.totalCount}, up-to-date ${summary.upToDateCount}, stale ${summary.possiblyStaleCount}, no-report ${summary.noSyncReportCount}, unknown ${summary.accessUnknownCount}',
        freshnessSummary: summary,
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: state.snapshotTargetType,
      );
    });
  }

  Future<String> reportCurrentPackSnapshotImported(String? remotePackId) {
    return _run('回報我已取得此 Pack 資料 POC', () async {
      if (remotePackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '尚未有可回報的遠端 Pack',
        );
      }
      final latest = _latestActivity(state.lastPulledRemoteSnapshot);
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .reportPackSnapshotImported(
            remotePackId: remotePackId,
            latestActivityEventId: latest?.id,
            latestActivityAt: latest?.createdAt,
          );
      if (!result.succeeded) {
        return _RemotePocOutcome(
          succeeded: false,
          message: _snapshotReportFailureMessage(result.status),
        );
      }
      return _RemotePocOutcome(
        succeeded: true,
        message: '已回報我已取得此 Pack 資料',
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: state.snapshotTargetType,
      );
    });
  }

  Future<String> flushRemoteBackedOutbox() {
    return _run('Flush Pending Remote-backed Mutations POC', () async {
      final result = await _ref
          .read(remoteBackedOutboxFlushServiceProvider)
          .flushPendingRemoteBackedMutations();
      _invalidateRemoteSyncDebug();
      return _RemotePocOutcome(
        succeeded: result.failed == 0,
        message:
            'Outbox flush：processed ${result.processed}, synced ${result.synced}, no-op ${result.noOp}, failed ${result.failed}. 請手動刷新 Remote Snapshot 後再匯入 mirror。',
        snapshot: state.lastPulledRemoteSnapshot,
        snapshotSummary: state.snapshotSummary,
        snapshotTargetType: state.snapshotTargetType,
      );
    });
  }

  Future<String> _run(
    String action,
    Future<_RemotePocOutcome> Function() operation,
  ) async {
    if (state.isRunning) {
      return state.lastMessage ?? 'Remote POC 操作執行中';
    }
    state = state.copyWith(isRunning: true, lastAction: action);
    late final _RemotePocOutcome outcome;
    try {
      outcome = await operation();
    } catch (_) {
      outcome = const _RemotePocOutcome(
        succeeded: false,
        message: '遠端操作失敗，請查看 debug log',
      );
    }
    state = state.copyWith(
      isRunning: false,
      lastAction: action,
      lastSucceeded: outcome.succeeded,
      lastMessage: outcome.message,
      lastAt: DateTime.now(),
      snapshotSummary: outcome.snapshotSummary,
      lastCreatedInviteCode: outcome.invite?.inviteCode,
      lastCreatedInviteId: outcome.invite?.inviteId,
      lastInviteExpiresAt: outcome.invite?.expiresAt,
      lastInviteMaxUses: outcome.invite?.maxUses,
      lastJoinedRemotePackId: outcome.joinedRemotePackId,
      lastPulledRemoteSnapshot: outcome.snapshot,
      snapshotTargetType: outcome.snapshotTargetType,
      lastRefreshAt: outcome.refreshAttempted ? DateTime.now() : null,
      lastRefreshSucceeded: outcome.refreshAttempted ? outcome.succeeded : null,
      selectedRemoteItemId: outcome.selectedRemoteItemId,
      clearSelectedRemoteItem: outcome.clearSelectedRemoteItem,
      clearRemoteChanges: outcome.clearRemoteChanges,
      lastFreshnessSummary: outcome.freshnessSummary,
    );
    return outcome.message;
  }

  _RemotePocOutcome _failureOutcome(
    RemoteSharedPackFailureReason? reason, [
    Object? error,
  ]) {
    return _RemotePocOutcome(
      succeeded: false,
      message: _failureMessage(reason, error),
    );
  }

  String _failureMessage(
    RemoteSharedPackFailureReason? reason, [
    Object? error,
  ]) {
    if (error is RemoteSharedPackException) {
      final safeDebugMessage = error.safeDebugMessage;
      if (safeDebugMessage != null) {
        return safeDebugMessage;
      }
    }
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing => 'Supabase 尚未設定',
      RemoteSharedPackFailureReason.remoteAuthRequired => '請先建立匿名遠端身份',
      RemoteSharedPackFailureReason.remoteProfileFailed =>
        '建立 Remote Profile 失敗',
      RemoteSharedPackFailureReason.remotePackAlreadyLinked =>
        '此 Pack 已有遠端 POC mapping',
      RemoteSharedPackFailureReason.remotePackCreateFailed => '請先建立遠端 Pack',
      RemoteSharedPackFailureReason.remoteInviteNotHost =>
        '只有 Host 可以建立或管理 Invite',
      RemoteSharedPackFailureReason.remoteInviteInvalid => 'Invite Code 無效',
      RemoteSharedPackFailureReason.remoteInviteExpired => 'Invite Code 已過期',
      RemoteSharedPackFailureReason.remoteInviteMaxUsesReached =>
        'Invite Code 使用次數已滿',
      RemoteSharedPackFailureReason.remoteInviteAlreadyRevoked =>
        'Invite Code 已撤銷',
      RemoteSharedPackFailureReason.localPackNotShared => '此 Pack 尚未轉為共同 Pack',
      RemoteSharedPackFailureReason.localUserNotPackMember =>
        '你不是此 Pack 的 active member',
      RemoteSharedPackFailureReason.remoteItemPushFailed =>
        '請先推送 Minimal Items',
      RemoteSharedPackFailureReason.remoteItemAlreadyCompleted =>
        '遠端 Item 已經完成，不覆寫完成者',
      RemoteSharedPackFailureReason.remoteRlsRejected => '遠端資料被 RLS 拒絕',
      RemoteSharedPackFailureReason.remoteNetworkFailed => '網絡連線失敗',
      RemoteSharedPackFailureReason.remoteUnknownFailure ||
      RemoteSharedPackFailureReason.malformedRemoteData ||
      null => '遠端操作失敗，請查看 debug log',
    };
  }

  String _shortId(String value) {
    return value.length <= 12 ? value : '${value.substring(0, 8)}...';
  }

  String _importStatusLabel(RemoteSnapshotImportStatus status) {
    return switch (status) {
      RemoteSnapshotImportStatus.success => 'success',
      RemoteSnapshotImportStatus.alreadyImported => 'already imported',
      RemoteSnapshotImportStatus.updatedExistingMirror => 'updated',
      RemoteSnapshotImportStatus.partialImport => 'partial',
      RemoteSnapshotImportStatus.failed => 'failed',
      RemoteSnapshotImportStatus.conflict => 'conflict',
    };
  }

  String _refreshResultMessage(RemoteBackedPackRefreshResult result) {
    final summary = result.summary;
    final details =
        'items +${summary.importedItemCount}/${summary.updatedItemCount}，'
        'completions +${summary.importedCompletionCount}/${summary.updatedCompletionCount}，'
        'events +${summary.importedActivityCount}/${summary.updatedActivityCount}';
    final warning = summary.warnings.isEmpty
        ? ''
        : '，warnings ${summary.warnings.length}';
    return switch (result.status) {
      RemoteBackedPackRefreshStatus.refreshed =>
        'Manual refresh：refreshed，$details$warning',
      RemoteBackedPackRefreshStatus.hasPendingLocalMutations =>
        'Manual refresh：refreshed with pending local mutations，$details$warning',
      RemoteBackedPackRefreshStatus.partialImport =>
        'Manual refresh：partial import，$details$warning',
      RemoteBackedPackRefreshStatus.notRemoteBacked =>
        'Manual refresh：not remote-backed',
      RemoteBackedPackRefreshStatus.missingRemoteMapping =>
        'Manual refresh：missing remote mapping',
      RemoteBackedPackRefreshStatus.configMissing =>
        'Manual refresh：config missing',
      RemoteBackedPackRefreshStatus.remoteAuthRequired =>
        'Manual refresh：remote auth required',
      RemoteBackedPackRefreshStatus.remoteRlsRejected =>
        'Manual refresh：remote RLS rejected',
      RemoteBackedPackRefreshStatus.accessLost => 'Manual refresh：access lost',
      RemoteBackedPackRefreshStatus.networkFailed =>
        'Manual refresh：network failed',
      RemoteBackedPackRefreshStatus.importFailed =>
        'Manual refresh：import failed',
      RemoteBackedPackRefreshStatus.unknownFailure =>
        'Manual refresh：unknown failure',
    };
  }

  String _membershipRecoveryResultMessage(
    RemoteMembershipRecoveryResult result,
  ) {
    final summary = result.summary;
    final details =
        'discovered ${summary.discoveredCount}, eligible ${summary.eligibleCount}, created ${summary.createdLocalMirrorCount}, refreshed ${summary.refreshedExistingCount}, skipped ${summary.skippedCount}, failed ${summary.failedCount}';
    final warning = summary.warnings.isEmpty
        ? ''
        : ', warnings ${summary.warnings.length}';
    return switch (result.status) {
      RemoteMembershipRecoveryStatus.restored =>
        'Membership recovery：restored，$details$warning',
      RemoteMembershipRecoveryStatus.partiallyRecovered =>
        'Membership recovery：partial，$details$warning',
      RemoteMembershipRecoveryStatus.nothingToRecover =>
        'Membership recovery：no active remote packs',
      RemoteMembershipRecoveryStatus.accountNotProtected =>
        'Membership recovery：account binding required',
      RemoteMembershipRecoveryStatus.remoteSessionMissing =>
        'Membership recovery：remote session missing',
      RemoteMembershipRecoveryStatus.configMissing =>
        'Membership recovery：config missing',
      RemoteMembershipRecoveryStatus.remoteAuthRequired =>
        'Membership recovery：remote auth required',
      RemoteMembershipRecoveryStatus.accessDenied =>
        'Membership recovery：remote RLS rejected',
      RemoteMembershipRecoveryStatus.networkFailed =>
        'Membership recovery：network failed',
      RemoteMembershipRecoveryStatus.importFailed =>
        'Membership recovery：import failed，$details$warning',
      RemoteMembershipRecoveryStatus.unknownFailure =>
        'Membership recovery：unknown failure',
    };
  }

  RemotePocFreshnessSummary _freshnessSummary(
    List<RemotePackMemberFreshness> members,
  ) {
    var upToDate = 0;
    var possiblyStale = 0;
    var noSyncReport = 0;
    var accessUnknown = 0;
    for (final member in members) {
      switch (member.status) {
        case RemotePackFreshnessStatus.upToDate:
          upToDate++;
        case RemotePackFreshnessStatus.possiblyStale:
          possiblyStale++;
        case RemotePackFreshnessStatus.noSyncReport:
          noSyncReport++;
        case RemotePackFreshnessStatus.accessUnknown:
          accessUnknown++;
      }
    }
    return RemotePocFreshnessSummary(
      totalCount: members.length,
      upToDateCount: upToDate,
      possiblyStaleCount: possiblyStale,
      noSyncReportCount: noSyncReport,
      accessUnknownCount: accessUnknown,
    );
  }

  RemoteActivityEventSnapshot? _latestActivity(RemotePackSnapshot? snapshot) {
    if (snapshot == null) {
      return null;
    }
    RemoteActivityEventSnapshot? latest;
    for (final event in snapshot.activityEvents) {
      if (latest == null ||
          event.createdAt.isAfter(latest.createdAt) ||
          (event.createdAt.isAtSameMomentAs(latest.createdAt) &&
              event.id.compareTo(latest.id) > 0)) {
        latest = event;
      }
    }
    return latest;
  }

  String _freshnessFailureMessage(RemotePackFreshnessQueryStatus status) {
    return switch (status) {
      RemotePackFreshnessQueryStatus.notMember ||
      RemotePackFreshnessQueryStatus.accessDenied => '無法查看此 Pack 的同步狀態',
      RemotePackFreshnessQueryStatus.configMissing => 'Supabase 尚未設定',
      RemotePackFreshnessQueryStatus.remoteAuthRequired => '請先建立遠端身份',
      RemotePackFreshnessQueryStatus.networkFailed => '網絡連線失敗',
      RemotePackFreshnessQueryStatus.unknownFailure ||
      RemotePackFreshnessQueryStatus.loaded => '同步狀態查詢失敗',
    };
  }

  String _snapshotReportFailureMessage(RemotePackSnapshotReportStatus status) {
    return switch (status) {
      RemotePackSnapshotReportStatus.notMember ||
      RemotePackSnapshotReportStatus.accessDenied => '無法回報此 Pack 的同步狀態',
      RemotePackSnapshotReportStatus.configMissing => 'Supabase 尚未設定',
      RemotePackSnapshotReportStatus.remoteAuthRequired => '請先建立遠端身份',
      RemotePackSnapshotReportStatus.networkFailed => '網絡連線失敗',
      RemotePackSnapshotReportStatus.unknownFailure ||
      RemotePackSnapshotReportStatus.reported => '同步狀態回報失敗',
    };
  }

  void _invalidateRecoveredLocalSurfaces(List<int> localPackIds) {
    _invalidateRemoteSyncDebug();
    for (final localPackId in localPackIds) {
      _ref.invalidate(remoteBackedPackRecoverySummaryProvider(localPackId));
    }
  }

  void _invalidateRemoteSyncDebug() {
    _ref.invalidate(remoteSyncDebugSnapshotProvider);
    _ref.invalidate(remoteBackedOutboxSummaryProvider);
    _ref.invalidate(remoteBackedRecoverySummaryProvider);
    _ref.invalidate(remoteBackedPackRecoverySummaryProvider);
  }

  Future<void> _refreshDerivedLocalSurfaces() async {
    await Future.wait([
      _bestEffort(() async {
        await _ref.read(homeWidgetActionServiceProvider).refreshSnapshot();
      }),
      _bestEffort(() => _ref.read(attentionSyncServiceProvider).refresh()),
    ]).timeout(const Duration(milliseconds: 500), onTimeout: () => const []);
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Recovery refreshes derived surfaces only from local mirror data.
    }
  }

  @override
  void dispose() {
    final active = _activeRealtimeSubscription;
    if (active != null && active.isActive) {
      unawaited(active.unsubscribe());
    }
    _activeRealtimeSubscription = null;
    super.dispose();
  }
}

class _RemotePocOutcome {
  const _RemotePocOutcome({
    required this.succeeded,
    required this.message,
    this.snapshotSummary,
    this.invite,
    this.joinedRemotePackId,
    this.snapshot,
    this.snapshotTargetType,
    this.refreshAttempted = false,
    this.selectedRemoteItemId,
    this.clearSelectedRemoteItem = false,
    this.clearRemoteChanges = false,
    this.freshnessSummary,
  });

  final bool succeeded;
  final String message;
  final RemotePocSnapshotSummary? snapshotSummary;
  final RemotePackInvite? invite;
  final String? joinedRemotePackId;
  final RemotePackSnapshot? snapshot;
  final RemotePocSnapshotTargetType? snapshotTargetType;
  final bool refreshAttempted;
  final String? selectedRemoteItemId;
  final bool clearSelectedRemoteItem;
  final bool clearRemoteChanges;
  final RemotePocFreshnessSummary? freshnessSummary;
}

final remotePocControllerProvider =
    StateNotifierProvider<RemotePocController, RemotePocOperationState>((ref) {
      return RemotePocController(ref);
    });

final remotePocTargetSharedPackProvider = FutureProvider<ItemPack?>((
  ref,
) async {
  final packs = await ref
      .watch(appDatabaseProvider)
      .reminderDao
      .listItemPacks();
  for (final pack in packs) {
    if (pack.packType == ItemPackType.shared) {
      return pack;
    }
  }
  return null;
});

final remotePocPackMappingProvider = FutureProvider.family<SyncMapping?, int>((
  ref,
  packId,
) {
  return ref
      .watch(appDatabaseProvider)
      .reminderDao
      .getSyncMapping(
        localEntityType: RemoteSharedPackRepository.localEntityPack,
        localEntityId: packId,
        remoteTable: RemoteSharedPackRepository.remoteTablePacks,
      );
});

final remoteBackedOutboxSummaryProvider =
    FutureProvider<RemoteBackedOutboxSummary>((ref) async {
      final entries = await ref
          .watch(appDatabaseProvider)
          .reminderDao
          .listSyncOutboxEntries();
      var pending = 0;
      var syncing = 0;
      var failed = 0;
      var conflictOrNoOp = 0;
      for (final entry in entries) {
        switch (entry.status) {
          case SyncOutboxStatus.pending:
            pending++;
          case SyncOutboxStatus.syncing:
            syncing++;
          case SyncOutboxStatus.failed:
            failed++;
          case SyncOutboxStatus.conflict || SyncOutboxStatus.noOp:
            conflictOrNoOp++;
          case SyncOutboxStatus.synced || SyncOutboxStatus.cancelled:
            break;
        }
      }
      return RemoteBackedOutboxSummary(
        pendingCount: pending,
        syncingCount: syncing,
        failedCount: failed,
        conflictOrNoOpCount: conflictOrNoOp,
      );
    });

final remoteSyncDebugSnapshotProvider = FutureProvider<RemoteSyncDebugSnapshot>(
  (ref) async {
    final dao = ref.watch(appDatabaseProvider).reminderDao;
    final currentLocalUser = await ref
        .watch(identityRepositoryProvider)
        .getCurrentAppUser();
    final runtime = ref.watch(supabaseRuntimeProvider);
    final entries = await dao.listSyncOutboxEntries();
    final metadata = await dao.listRemotePackSyncMetadataEntries();
    final remoteBackedPacks = metadata
        .where((entry) => entry.syncKind == RemotePackSyncKind.remoteBacked)
        .toList(growable: false);
    final packs = <RemoteSyncDebugPack>[];

    for (final pack in remoteBackedPacks) {
      final packEntries = entries
          .where((entry) => entry.localPackId == pack.localPackId)
          .toList(growable: false);
      SyncOutboxEntry? lastFailed;
      for (final entry in packEntries) {
        if (entry.status != SyncOutboxStatus.failed ||
            entry.lastError == null) {
          continue;
        }
        if (lastFailed == null ||
            entry.updatedAt.isAfter(lastFailed.updatedAt)) {
          lastFailed = entry;
        }
      }
      packs.add(
        RemoteSyncDebugPack(
          localPackId: pack.localPackId,
          remotePackId: pack.remotePackId,
          syncState: pack.syncState,
          currentUserRemoteStatus: pack.currentUserRemoteStatus,
          currentUserRemoteRole: pack.currentUserRemoteRole,
          pendingOutboxCount: packEntries
              .where((entry) => entry.status == SyncOutboxStatus.pending)
              .length,
          syncingOutboxCount: packEntries
              .where((entry) => entry.status == SyncOutboxStatus.syncing)
              .length,
          failedOutboxCount: packEntries
              .where((entry) => entry.status == SyncOutboxStatus.failed)
              .length,
          lastFailedError: lastFailed?.lastError,
        ),
      );
    }

    final recentOutbox = entries.reversed.take(10).toList(growable: false);
    return RemoteSyncDebugSnapshot(
      currentLocalUser: currentLocalUser,
      supabaseCurrentUserId: runtime.client?.auth.currentUser?.id,
      supabaseSessionExists: runtime.client?.auth.currentSession != null,
      packs: packs,
      recentOutboxEntries: recentOutbox,
    );
  },
);

final remoteBackedRecoverySummaryProvider =
    FutureProvider<RemoteBackedSyncProblemSummary>((ref) async {
      final dao = ref.watch(appDatabaseProvider).reminderDao;
      final entries = await dao.listSyncOutboxEntries();
      final metadata = await dao.listRemotePackSyncMetadataEntries();
      return _buildRecoverySummary(entries: entries, packMetadata: metadata);
    });

final remoteBackedPackRecoverySummaryProvider =
    FutureProvider.family<RemoteBackedPackRecoverySummary, int>((
      ref,
      localPackId,
    ) async {
      final dao = ref.watch(appDatabaseProvider).reminderDao;
      final entries = await dao.listSyncOutboxEntries();
      final metadata = await dao.listRemotePackSyncMetadataEntries();
      final summary = _buildRecoverySummary(
        entries: entries.where((entry) => entry.localPackId == localPackId),
        packMetadata: metadata.where(
          (entry) => entry.localPackId == localPackId,
        ),
      );
      return RemoteBackedPackRecoverySummary(
        localPackId: localPackId,
        pendingCount: summary.pendingCount,
        syncingCount: summary.syncingCount,
        retryableFailedCount: summary.retryableFailedCount,
        nonRetryableFailedCount: summary.nonRetryableFailedCount,
        noOpCount: summary.noOpCount,
        conflictCount: summary.conflictCount,
        accessLostCount: summary.accessLostCount,
        stalePackCount: summary.stalePackCount,
        firstFailedMutation: summary.firstFailedMutation,
      );
    });

final remotePocFirstMappedItemProvider =
    FutureProvider.family<ItemBundle?, int>((ref, packId) async {
      final dao = ref.watch(appDatabaseProvider).reminderDao;
      final mappings = await dao.listSyncMappings();
      final mappedItemIds = mappings
          .where(
            (mapping) =>
                mapping.localEntityType ==
                    RemoteSharedPackRepository.localEntityItem &&
                mapping.remoteTable ==
                    RemoteSharedPackRepository.remoteTableItems,
          )
          .map((mapping) => mapping.localEntityId)
          .toSet();
      if (mappedItemIds.isEmpty) {
        return null;
      }
      final bundles = await dao.listItemBundles(
        statuses: const {
          ItemLifecycleStatus.active,
          ItemLifecycleStatus.paused,
        },
      );
      for (final bundle in bundles) {
        if (bundle.item.packId == packId &&
            mappedItemIds.contains(bundle.item.id)) {
          return bundle;
        }
      }
      return null;
    });

RemoteBackedSyncProblemSummary _buildRecoverySummary({
  required Iterable<SyncOutboxEntry> entries,
  required Iterable<RemotePackSyncMetadataEntry> packMetadata,
}) {
  final metadataByPackId = {
    for (final entry in packMetadata) entry.localPackId: entry,
  };
  var pending = 0;
  var syncing = 0;
  var retryableFailed = 0;
  var nonRetryableFailed = 0;
  var noOp = 0;
  var conflict = 0;
  RemoteBackedMutationRecoveryView? firstFailed;

  for (final entry in entries) {
    final payload = _decodeOutboxPayload(entry.payloadJson);
    final localItemId = _intPayload(payload, 'localItemId');
    final view = RemoteBackedRecoveryClassifier.classifyMutation(
      entry,
      packMetadata: metadataByPackId[entry.localPackId],
      localItemId: localItemId,
    );
    switch (view.recoveryState) {
      case RemoteBackedRecoveryState.pending:
        pending++;
      case RemoteBackedRecoveryState.syncing:
        syncing++;
      case RemoteBackedRecoveryState.retryableFailed:
        retryableFailed++;
        firstFailed ??= view;
      case RemoteBackedRecoveryState.nonRetryableFailed:
        nonRetryableFailed++;
        firstFailed ??= view;
      case RemoteBackedRecoveryState.noOp:
        noOp++;
      case RemoteBackedRecoveryState.conflict:
        conflict++;
      case RemoteBackedRecoveryState.synced ||
          RemoteBackedRecoveryState.cancelled ||
          RemoteBackedRecoveryState.stale ||
          RemoteBackedRecoveryState.accessLost:
        break;
    }
  }

  var accessLost = 0;
  var stalePack = 0;
  for (final metadata in metadataByPackId.values) {
    if (RemoteBackedRecoveryClassifier.isAccessLost(metadata)) {
      accessLost++;
    } else if (RemoteBackedRecoveryClassifier.isPackStale(metadata)) {
      stalePack++;
    }
  }

  return RemoteBackedSyncProblemSummary(
    pendingCount: pending,
    syncingCount: syncing,
    retryableFailedCount: retryableFailed,
    nonRetryableFailedCount: nonRetryableFailed,
    noOpCount: noOp,
    conflictCount: conflict,
    accessLostCount: accessLost,
    stalePackCount: stalePack,
    firstFailedMutation: firstFailed,
  );
}

Map<String, Object?> _decodeOutboxPayload(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } catch (_) {
    return const {};
  }
  if (decoded is Map<String, Object?>) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    return Map<String, Object?>.from(decoded);
  }
  return const {};
}

int? _intPayload(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}
