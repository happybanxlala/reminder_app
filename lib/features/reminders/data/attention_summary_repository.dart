import 'dart:async';

import '../domain/attention_summary.dart';
import '../domain/remote_sync.dart';
import '../domain/stage_occurrence.dart';
import 'home_models.dart';
import 'home_repository.dart';

class AttentionSummaryRepository {
  AttentionSummaryRepository({required HomeAttentionSource homeRepository})
    : _homeRepository = homeRepository;

  final HomeAttentionSource _homeRepository;

  Future<AttentionSummary> getSummary({
    DateTime? now,
    bool excludeRemoteBackedItems = false,
  }) async {
    final current = now ?? DateTime.now();
    final results = await Future.wait<Object>([
      _homeRepository.watchDangerAttentionEntries(now: current).first,
      _homeRepository.watchWarningAttentionEntries(now: current).first,
      _homeRepository.watchUpcomingStages(now: current).first,
    ]);
    return _buildSummary(
      dangerEntries: results[0] as List<HomeAttentionEntry>,
      warningEntries: results[1] as List<HomeAttentionEntry>,
      stages: results[2] as List<StageOccurrence>,
      excludeRemoteBackedItems: excludeRemoteBackedItems,
    );
  }

  Future<AttentionSummary> getNotificationSummary({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final results = await Future.wait<Object>([
      _homeRepository.watchDangerAttentionEntries(now: current).first,
      _homeRepository.watchWarningAttentionEntries(now: current).first,
      _homeRepository.watchUpcomingStages(now: current).first,
    ]);
    return _buildSummary(
      dangerEntries: results[0] as List<HomeAttentionEntry>,
      warningEntries: results[1] as List<HomeAttentionEntry>,
      stages: results[2] as List<StageOccurrence>,
      notificationSafe: true,
    );
  }

  Stream<AttentionSummary> watchSummary({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _combineLatest3(
      _homeRepository.watchDangerAttentionEntries(now: current),
      _homeRepository.watchWarningAttentionEntries(now: current),
      _homeRepository.watchUpcomingStages(now: current),
      (dangerEntries, warningEntries, stages) => _buildSummary(
        dangerEntries: dangerEntries,
        warningEntries: warningEntries,
        stages: stages,
      ),
    ).distinct();
  }

  Stream<AttentionSummary> watchNotificationSummary({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _combineLatest3(
      _homeRepository.watchDangerAttentionEntries(now: current),
      _homeRepository.watchWarningAttentionEntries(now: current),
      _homeRepository.watchUpcomingStages(now: current),
      (dangerEntries, warningEntries, stages) => _buildSummary(
        dangerEntries: dangerEntries,
        warningEntries: warningEntries,
        stages: stages,
        notificationSafe: true,
      ),
    ).distinct();
  }

  AttentionSummary _buildSummary({
    required List<HomeAttentionEntry> dangerEntries,
    required List<HomeAttentionEntry> warningEntries,
    required List<StageOccurrence> stages,
    bool excludeRemoteBackedItems = false,
    bool notificationSafe = false,
  }) {
    final remoteBackedEntries = [
      ...dangerEntries.where(_isRemoteBackedItem),
      ...warningEntries.where(_isRemoteBackedItem),
    ];
    final syncLabels = _notificationSyncLabels(remoteBackedEntries);
    final visibleDangerEntries = _visibleEntries(
      dangerEntries,
      excludeRemoteBackedItems: excludeRemoteBackedItems,
      notificationSafe: notificationSafe,
    );
    final visibleWarningEntries = _visibleEntries(
      warningEntries,
      excludeRemoteBackedItems: excludeRemoteBackedItems,
      notificationSafe: notificationSafe,
    );
    return AttentionSummary(
      dangerItemCount: visibleDangerEntries
          .where((entry) => entry.type == HomeAttentionEntryType.item)
          .length,
      warningItemCount: visibleWarningEntries
          .where((entry) => entry.type == HomeAttentionEntryType.item)
          .length,
      dangerResourceCount: visibleDangerEntries
          .where((entry) => entry.type == HomeAttentionEntryType.resource)
          .length,
      warningResourceCount: visibleWarningEntries
          .where((entry) => entry.type == HomeAttentionEntryType.resource)
          .length,
      stageUpcomingCount: stages.length,
      remoteBackedItemCount: remoteBackedEntries.length,
      pendingSyncItemCount: remoteBackedEntries
          .where((entry) => _syncLabel(entry) == _pendingSyncLabel)
          .length,
      failedSyncItemCount: remoteBackedEntries
          .where((entry) => _syncLabel(entry) == _failedSyncLabel)
          .length,
      staleSyncItemCount: remoteBackedEntries
          .where((entry) => _syncLabel(entry) == _staleSyncLabel)
          .length,
      accessLostRemoteBackedItemCount: remoteBackedEntries
          .where((entry) => _syncLabel(entry) == _accessLostSyncLabel)
          .length,
      notificationSyncLabels: syncLabels,
    );
  }

  Iterable<HomeAttentionEntry> _visibleEntries(
    List<HomeAttentionEntry> entries, {
    required bool excludeRemoteBackedItems,
    required bool notificationSafe,
  }) {
    if (excludeRemoteBackedItems) {
      return entries.where(_isNotRemoteBackedItem);
    }
    if (notificationSafe) {
      return entries.where(_isNotificationVisibleEntry);
    }
    return entries;
  }

  bool _isNotRemoteBackedItem(HomeAttentionEntry entry) {
    final itemEntry = entry.itemEntry;
    return itemEntry == null || !itemEntry.syncStatus.isRemoteBacked;
  }

  bool _isRemoteBackedItem(HomeAttentionEntry entry) {
    return entry.itemEntry?.syncStatus.isRemoteBacked ?? false;
  }

  bool _isNotificationVisibleEntry(HomeAttentionEntry entry) {
    final syncStatus = entry.itemEntry?.syncStatus;
    if (syncStatus == null || !syncStatus.isRemoteBacked) {
      return true;
    }
    if (syncStatus.isAccessLost) {
      return false;
    }
    if (syncStatus.hasPendingMutation &&
        syncStatus.pendingMutationAction == SyncOutboxActionType.completeItem) {
      return false;
    }
    return true;
  }

  List<String> _notificationSyncLabels(List<HomeAttentionEntry> entries) {
    final labels = <String>[];
    for (final label in [
      _pendingSyncLabel,
      _failedSyncLabel,
      _staleSyncLabel,
      _accessLostSyncLabel,
    ]) {
      if (entries.any((entry) => _syncLabel(entry) == label)) {
        labels.add(label);
      }
    }
    return labels;
  }

  String? _syncLabel(HomeAttentionEntry entry) {
    final syncStatus = entry.itemEntry?.syncStatus;
    if (syncStatus == null || !syncStatus.isRemoteBacked) {
      return null;
    }
    if (syncStatus.isAccessLost) {
      return _accessLostSyncLabel;
    }
    if (syncStatus.hasPendingMutation) {
      return _pendingSyncLabel;
    }
    if (syncStatus.hasFailedMutation) {
      return _failedSyncLabel;
    }
    if (syncStatus.isStale) {
      return _staleSyncLabel;
    }
    return null;
  }

  static const _pendingSyncLabel = '等待同步';
  static const _failedSyncLabel = '同步失敗';
  static const _staleSyncLabel = '有新的更新，請刷新';
  static const _accessLostSyncLabel = '已無法存取';

  Stream<T> _combineLatest3<A, B, C, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    T Function(A a, B b, C c) combine,
  ) {
    late StreamController<T> controller;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    StreamSubscription<C>? subC;
    A? latestA;
    B? latestB;
    C? latestC;
    var streamAClosed = false;
    var streamBClosed = false;
    var streamCClosed = false;

    void emitIfReady() {
      final valueA = latestA;
      final valueB = latestB;
      final valueC = latestC;
      if (valueA != null && valueB != null && valueC != null) {
        controller.add(combine(valueA, valueB, valueC));
      }
    }

    Future<void> closeIfDone() async {
      if (streamAClosed &&
          streamBClosed &&
          streamCClosed &&
          !controller.isClosed) {
        await controller.close();
      }
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        subA = streamA.listen(
          (value) {
            latestA = value;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () async {
            streamAClosed = true;
            await closeIfDone();
          },
        );
        subB = streamB.listen(
          (value) {
            latestB = value;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () async {
            streamBClosed = true;
            await closeIfDone();
          },
        );
        subC = streamC.listen(
          (value) {
            latestC = value;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () async {
            streamCClosed = true;
            await closeIfDone();
          },
        );
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
        await subC?.cancel();
      },
    );
    return controller.stream;
  }
}
