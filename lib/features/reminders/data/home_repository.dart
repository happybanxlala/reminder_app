import 'dart:async';

import '../domain/item.dart';
import '../domain/stage_occurrence.dart';
import 'home_models.dart';
import 'item_repository.dart';
import 'stage_tracker_repository.dart';

abstract class HomeAttentionSource {
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now});

  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now});

  Stream<List<StageOccurrence>> watchUpcomingStages({DateTime? now});
}

class HomeRepository implements HomeAttentionSource {
  HomeRepository({
    required ItemRepository itemRepository,
    required StageTrackerRepository stageTrackerRepository,
  }) : _itemRepository = itemRepository,
       _stageTrackerRepository = stageTrackerRepository;

  final ItemRepository _itemRepository;
  final StageTrackerRepository _stageTrackerRepository;

  @override
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _itemRepository
        .watchItemsByStatus(ItemStatus.danger, now: current)
        .map(
          (items) => items
              .map(
                (item) => ItemHomeEntry(
                  bundle: item,
                  status: ItemStatus.danger,
                  elapsed: _itemRepository.elapsedFor(item.item, now: current),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _itemRepository
        .watchItemsByStatus(ItemStatus.warning, now: current)
        .map(
          (items) => items
              .map(
                (item) => ItemHomeEntry(
                  bundle: item,
                  status: ItemStatus.warning,
                  elapsed: _itemRepository.elapsedFor(item.item, now: current),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<StageOccurrence>> watchUpcomingStages({DateTime? now}) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _combineLatest(
      _combineLatest(
        _stageTrackerRepository.watchStageTrackers(),
        _stageTrackerRepository.watchStageRules(),
        (trackers, rules) => (trackers, rules),
      ),
      _stageTrackerRepository.watchStageRecords(),
      (tuple, records) =>
          _stageTrackerRepository.computeHomeAttentionOccurrences(
            trackers: tuple.$1,
            rules: tuple.$2,
            records: records,
            now: current,
          ),
    );
  }

  Stream<T> _combineLatest<A, B, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    T Function(A a, B b) combine,
  ) {
    late StreamController<T> controller;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    A? latestA;
    B? latestB;
    var streamAClosed = false;
    var streamBClosed = false;

    void emitIfReady() {
      final valueA = latestA;
      final valueB = latestB;
      if (valueA != null && valueB != null) {
        controller.add(combine(valueA, valueB));
      }
    }

    Future<void> closeIfDone() async {
      if (streamAClosed && streamBClosed && !controller.isClosed) {
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
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
