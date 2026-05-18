import 'dart:async';

import '../domain/item.dart';
import '../domain/item_status_service.dart';
import '../domain/resource.dart';
import '../domain/resource_status_service.dart';
import '../domain/stage_occurrence.dart';
import 'home_models.dart';
import 'item_repository.dart';
import 'resource_repository.dart';
import 'stage_tracker_repository.dart';

abstract class HomeAttentionSource {
  Stream<List<HomeAttentionEntry>> watchDangerAttentionEntries({DateTime? now});

  Stream<List<HomeAttentionEntry>> watchWarningAttentionEntries({
    DateTime? now,
  });

  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now});

  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now});

  Stream<List<StageOccurrence>> watchUpcomingStages({DateTime? now});

  Stream<List<TodayCompletedEntry>> watchTodayCompletedEntries({DateTime? now});
}

class HomeRepository implements HomeAttentionSource {
  HomeRepository({
    required ItemRepository itemRepository,
    required ResourceRepository resourceRepository,
    required StageTrackerRepository stageTrackerRepository,
  }) : _itemRepository = itemRepository,
       _resourceRepository = resourceRepository,
       _stageTrackerRepository = stageTrackerRepository;

  final ItemRepository _itemRepository;
  final ResourceRepository _resourceRepository;
  final StageTrackerRepository _stageTrackerRepository;
  static const _itemStatusService = ItemStatusService();
  static const _resourceStatusService = ResourceStatusService();

  @override
  Stream<List<HomeAttentionEntry>> watchDangerAttentionEntries({
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _watchAttentionEntries(
      itemStatus: ItemStatus.danger,
      resourceStatus: ResourceStatus.danger,
      severity: HomeAttentionSeverity.danger,
      now: current,
    );
  }

  @override
  Stream<List<HomeAttentionEntry>> watchWarningAttentionEntries({
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _watchAttentionEntries(
      itemStatus: ItemStatus.warning,
      resourceStatus: ResourceStatus.warning,
      severity: HomeAttentionSeverity.warning,
      now: current,
    );
  }

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

  @override
  Stream<List<TodayCompletedEntry>> watchTodayCompletedEntries({
    DateTime? now,
  }) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _combineLatest3(
      _itemRepository.watchDoneActionEntriesForDate(current),
      _resourceRepository.watchCompletedActionEntriesForDate(current),
      _stageTrackerRepository.watchAcknowledgedActionEntriesForDate(current),
      (itemActions, resourceActions, stageActions) {
        final entries = <TodayCompletedEntry>[
          for (final entry in itemActions) TodayCompletedEntry.itemDone(entry),
          for (final entry in resourceActions)
            TodayCompletedEntry.resource(entry),
          for (final entry in stageActions)
            TodayCompletedEntry.stageAcknowledged(entry),
        ];
        entries.sort(_compareTodayCompletedEntries);
        return entries;
      },
    );
  }

  Stream<List<HomeAttentionEntry>> _watchAttentionEntries({
    required ItemStatus itemStatus,
    required ResourceStatus resourceStatus,
    required HomeAttentionSeverity severity,
    required DateTime now,
  }) {
    final itemStream = itemStatus == ItemStatus.danger
        ? watchDangerItems(now: now)
        : watchWarningItems(now: now);
    final resourceStream = _resourceRepository.watchResourcesByStatus(
      resourceStatus,
      now: now,
    );

    return _combineLatest(itemStream, resourceStream, (items, resources) {
      final entries = <HomeAttentionEntry>[
        for (final item in items)
          HomeAttentionEntry.item(
            entry: item,
            severity: severity,
            urgencyDate: _itemUrgencyDate(item, now: now),
          ),
        for (final resource in resources)
          HomeAttentionEntry.resource(
            bundle: resource,
            severity: severity,
            urgencyDate: _resourceUrgencyDate(resource.resource),
          ),
      ];
      entries.sort(
        severity == HomeAttentionSeverity.danger
            ? (a, b) => _compareDangerEntries(a, b, now)
            : _compareWarningEntries,
      );
      return entries;
    });
  }

  DateTime? _itemUrgencyDate(ItemHomeEntry entry, {required DateTime now}) {
    final item = entry.bundle.item;
    return switch (item.config) {
      FixedItemConfig _ =>
        _itemStatusService.currentFixedCycle(item, now: now)?.dueDate,
      StateBasedItemConfig config => _stateBasedDangerDate(config),
      _ => null,
    };
  }

  DateTime? _stateBasedDangerDate(StateBasedItemConfig config) {
    final anchorDate = config.anchorDate;
    if (anchorDate == null) {
      return null;
    }
    final dangerDay = config.dangerAfter.inDays <= 0
        ? 1
        : config.dangerAfter.inDays;
    return _normalizeDate(anchorDate).add(Duration(days: dangerDay - 1));
  }

  DateTime? _resourceUrgencyDate(Resource resource) {
    return switch (resource.config) {
      TimeBasedResourceConfig config => _resourceStatusService.depletionDate(
        config,
      ),
      QuantityBasedResourceConfig _ => null,
      _ => null,
    };
  }

  int _compareDangerEntries(
    HomeAttentionEntry a,
    HomeAttentionEntry b,
    DateTime now,
  ) {
    final bucketA = _dangerUrgencyBucket(a, now);
    final bucketB = _dangerUrgencyBucket(b, now);
    if (bucketA != bucketB) {
      return bucketA.compareTo(bucketB);
    }
    return _compareAttentionEntries(a, b, nullsLast: false);
  }

  int _dangerUrgencyBucket(HomeAttentionEntry entry, DateTime now) {
    final urgencyDate = entry.urgencyDate;
    if (urgencyDate == null || !urgencyDate.isAfter(now)) {
      return 0;
    }
    return 1;
  }

  int _compareWarningEntries(HomeAttentionEntry a, HomeAttentionEntry b) {
    return _compareAttentionEntries(a, b, nullsLast: true);
  }

  int _compareAttentionEntries(
    HomeAttentionEntry a,
    HomeAttentionEntry b, {
    required bool nullsLast,
  }) {
    final dateCompare = _compareNullableDate(
      a.urgencyDate,
      b.urgencyDate,
      nullsLast: nullsLast,
    );
    if (dateCompare != 0) {
      return dateCompare;
    }
    final typeCompare = a.type.index.compareTo(b.type.index);
    if (typeCompare != 0) {
      return typeCompare;
    }
    final createdCompare = a.createdAt.compareTo(b.createdAt);
    if (createdCompare != 0) {
      return createdCompare;
    }
    return a.sourceId.compareTo(b.sourceId);
  }

  int _compareTodayCompletedEntries(
    TodayCompletedEntry a,
    TodayCompletedEntry b,
  ) {
    final dateCompare = b.actionDate.compareTo(a.actionDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    final typeCompare = a.type.index.compareTo(b.type.index);
    if (typeCompare != 0) {
      return typeCompare;
    }
    return a.stableKey.compareTo(b.stableKey);
  }

  int _compareNullableDate(
    DateTime? a,
    DateTime? b, {
    required bool nullsLast,
  }) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return nullsLast ? 1 : 0;
    }
    if (b == null) {
      return nullsLast ? -1 : 0;
    }
    return a.compareTo(b);
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

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
