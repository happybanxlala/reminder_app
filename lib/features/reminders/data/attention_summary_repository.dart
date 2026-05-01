import 'dart:async';

import '../domain/attention_summary.dart';
import '../domain/timeline_milestone_occurrence.dart';
import 'home_models.dart';
import 'home_repository.dart';

class AttentionSummaryRepository {
  AttentionSummaryRepository({required HomeAttentionSource homeRepository})
    : _homeRepository = homeRepository;

  final HomeAttentionSource _homeRepository;

  Future<AttentionSummary> getSummary({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final results = await Future.wait<Object>([
      _homeRepository.watchDangerItems(now: current).first,
      _homeRepository.watchWarningItems(now: current).first,
      _homeRepository.watchUpcomingTimelineMilestones(now: current).first,
    ]);
    return _buildSummary(
      dangerItems: results[0] as List<ItemHomeEntry>,
      warningItems: results[1] as List<ItemHomeEntry>,
      timelineMilestones: results[2] as List<TimelineMilestoneOccurrence>,
    );
  }

  Stream<AttentionSummary> watchSummary({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _combineLatest3(
      _homeRepository.watchDangerItems(now: current),
      _homeRepository.watchWarningItems(now: current),
      _homeRepository.watchUpcomingTimelineMilestones(now: current),
      (dangerItems, warningItems, timelineMilestones) => _buildSummary(
        dangerItems: dangerItems,
        warningItems: warningItems,
        timelineMilestones: timelineMilestones,
      ),
    ).distinct();
  }

  AttentionSummary _buildSummary({
    required List<ItemHomeEntry> dangerItems,
    required List<ItemHomeEntry> warningItems,
    required List<TimelineMilestoneOccurrence> timelineMilestones,
  }) {
    return AttentionSummary(
      dangerCount: dangerItems.length,
      warningCount: warningItems.length,
      timelineUpcomingCount: timelineMilestones.length,
    );
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
