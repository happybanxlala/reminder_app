import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/anonymous_remote_identity_service.dart';
import '../data/local/reminder_dao.dart';
import '../data/remote_shared_pack_data_source.dart';
import '../data/remote_shared_pack_models.dart';
import '../data/remote_shared_pack_repository.dart';
import '../data/supabase_config.dart';
import '../domain/item.dart';
import '../domain/item_pack.dart';
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

class RemotePocOperationState {
  const RemotePocOperationState({
    this.isRunning = false,
    this.lastAction,
    this.lastSucceeded,
    this.lastMessage,
    this.lastAt,
    this.snapshotSummary,
  });

  final bool isRunning;
  final String? lastAction;
  final bool? lastSucceeded;
  final String? lastMessage;
  final DateTime? lastAt;
  final RemotePocSnapshotSummary? snapshotSummary;

  RemotePocOperationState copyWith({
    bool? isRunning,
    String? lastAction,
    bool? lastSucceeded,
    String? lastMessage,
    DateTime? lastAt,
    RemotePocSnapshotSummary? snapshotSummary,
    bool clearSnapshotSummary = false,
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
    );
  }
}

class RemotePocController extends StateNotifier<RemotePocOperationState> {
  RemotePocController(this._ref) : super(const RemotePocOperationState());

  final Ref _ref;

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
        return _failureOutcome(result.failureReason);
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
        return _failureOutcome(result.failureReason);
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
        return _failureOutcome(result.failureReason);
      }
      final summary = result.value!;
      return _RemotePocOutcome(
        succeeded: true,
        message:
            '已推送 ${summary.pushedCount} 個 items，略過 ${summary.skippedCount} 個，失敗 ${summary.failedCount} 個',
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
        return _failureOutcome(result.failureReason);
      }
      return const _RemotePocOutcome(succeeded: true, message: '遠端 Item 已完成');
    });
  }

  Future<String> pullRemoteSnapshot({
    required int? localPackId,
    required String? remotePackId,
  }) {
    return _run('拉取 Remote Snapshot POC', () async {
      if (localPackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先建立 / 選擇 local shared pack',
        );
      }
      if (remotePackId == null) {
        return const _RemotePocOutcome(
          succeeded: false,
          message: '請先建立遠端 Pack',
        );
      }
      final result = await _ref
          .read(remoteSharedPackRepositoryProvider)
          .pullRemotePackSnapshot(remotePackId);
      if (!result.isSuccess) {
        return _failureOutcome(result.failureReason);
      }
      final snapshot = result.value!;
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
    );
    return outcome.message;
  }

  _RemotePocOutcome _failureOutcome(RemoteSharedPackFailureReason? reason) {
    return _RemotePocOutcome(
      succeeded: false,
      message: _failureMessage(reason),
    );
  }

  String _failureMessage(RemoteSharedPackFailureReason? reason) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing => 'Supabase 尚未設定',
      RemoteSharedPackFailureReason.remoteAuthRequired => '請先建立匿名遠端身份',
      RemoteSharedPackFailureReason.remoteProfileFailed =>
        '建立 Remote Profile 失敗',
      RemoteSharedPackFailureReason.remotePackAlreadyLinked =>
        '此 Pack 已有遠端 POC mapping',
      RemoteSharedPackFailureReason.remotePackCreateFailed => '請先建立遠端 Pack',
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
}

class _RemotePocOutcome {
  const _RemotePocOutcome({
    required this.succeeded,
    required this.message,
    this.snapshotSummary,
  });

  final bool succeeded;
  final String message;
  final RemotePocSnapshotSummary? snapshotSummary;
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
