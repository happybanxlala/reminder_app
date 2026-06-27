import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/anonymous_remote_identity_service.dart';
import '../data/local/reminder_dao.dart';
import '../data/remote_backed_outbox_flush_service.dart';
import '../data/remote_backed_outbox_retry_service.dart';
import '../data/remote_backed_pack_refresh_service.dart';
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
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
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
    bool clearSnapshotSummary = false,
    bool clearInvite = false,
    bool clearJoinedRemotePackId = false,
    bool clearLastPulledRemoteSnapshot = false,
    bool clearSelectedRemoteItem = false,
    bool clearRealtimeTarget = false,
    bool clearRealtimeError = false,
    bool clearRemoteChanges = false,
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
      _ref.invalidate(remoteBackedOutboxSummaryProvider);
      _ref.invalidate(remoteBackedRecoverySummaryProvider);
      _ref.invalidate(remoteBackedPackRecoverySummaryProvider);
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
      _ref.invalidate(remoteBackedRecoverySummaryProvider);
      _ref.invalidate(remoteBackedPackRecoverySummaryProvider);
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

  Future<String> flushRemoteBackedOutbox() {
    return _run('Flush Pending Remote-backed Mutations POC', () async {
      final result = await _ref
          .read(remoteBackedOutboxFlushServiceProvider)
          .flushPendingRemoteBackedMutations();
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
