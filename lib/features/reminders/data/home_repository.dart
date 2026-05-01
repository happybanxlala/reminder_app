import 'dart:async';

import '../domain/item.dart';
import '../domain/timeline.dart';
import '../domain/timeline_milestone_occurrence.dart';
import '../domain/timeline_milestone_record.dart';
import '../domain/timeline_milestone_rule.dart';
import '../domain/timeline_milestone_service.dart';
import 'home_models.dart';
import 'item_repository.dart';
import 'timeline_repository.dart';

abstract class HomeAttentionSource {
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now});

  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now});

  Stream<List<TimelineMilestoneOccurrence>> watchUpcomingTimelineMilestones({
    DateTime? now,
  });
}

class HomeRepository implements HomeAttentionSource {
  HomeRepository({
    required ItemRepository itemRepository,
    required TimelineRepository timelineRepository,
    TimelineMilestoneService? milestoneService,
  }) : _itemRepository = itemRepository,
       _timelineRepository = timelineRepository,
       _milestoneService = milestoneService ?? const TimelineMilestoneService();

  final ItemRepository _itemRepository;
  final TimelineRepository _timelineRepository;
  final TimelineMilestoneService _milestoneService;

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
  Stream<List<TimelineMilestoneOccurrence>> watchUpcomingTimelineMilestones({
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _combineLatest(
      _combineLatest(
        _timelineRepository.watchTimelines(),
        _timelineRepository.watchMilestoneRules(),
        (timelines, rules) => (timelines, rules),
      ),
      _timelineRepository.watchMilestoneRecords(),
      (tuple, records) => _computeUpcomingOccurrences(
        timelines: tuple.$1,
        rules: tuple.$2,
        records: records,
        now: current,
      ),
    );
  }

  List<TimelineMilestoneOccurrence> _computeUpcomingOccurrences({
    required List<Timeline> timelines,
    required List<TimelineMilestoneRule> rules,
    required List<TimelineMilestoneRecord> records,
    required DateTime now,
  }) {
    return [
      for (final timeline in timelines)
        ..._milestoneService.getUpcomingOccurrences(
          timeline,
          rules
              .where((rule) => rule.timelineId == timeline.id)
              .toList(growable: false),
          records
              .where((record) => record.timelineId == timeline.id)
              .toList(growable: false),
          TimelineMilestoneRange(
            start: now,
            end: now.add(const Duration(days: 366)),
          ),
          now: now,
        ),
    ]..sort((a, b) => a.targetDate.compareTo(b.targetDate));
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
