import 'dart:async';

import '../domain/attention_summary.dart';
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

  AttentionSummary _buildSummary({
    required List<HomeAttentionEntry> dangerEntries,
    required List<HomeAttentionEntry> warningEntries,
    required List<StageOccurrence> stages,
    bool excludeRemoteBackedItems = false,
  }) {
    final visibleDangerEntries = excludeRemoteBackedItems
        ? dangerEntries.where(_isNotRemoteBackedItem)
        : dangerEntries;
    final visibleWarningEntries = excludeRemoteBackedItems
        ? warningEntries.where(_isNotRemoteBackedItem)
        : warningEntries;
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
    );
  }

  bool _isNotRemoteBackedItem(HomeAttentionEntry entry) {
    final itemEntry = entry.itemEntry;
    return itemEntry == null || !itemEntry.syncStatus.isRemoteBacked;
  }

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
