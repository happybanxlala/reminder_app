import 'dart:async';

import '../domain/timeline.dart';
import '../domain/timeline_milestone_occurrence.dart';
import '../domain/timeline_milestone_record.dart';
import '../domain/timeline_milestone_rule.dart';
import '../domain/timeline_milestone_service.dart';
import 'home_models.dart';
import 'local/task_timeline_dao.dart';
import 'task_repository.dart';
import 'timeline_repository.dart';

class HomeRepository {
  HomeRepository({
    required TaskRepository taskRepository,
    required TimelineRepository timelineRepository,
    TimelineMilestoneService? milestoneService,
  }) : _taskRepository = taskRepository,
       _timelineRepository = timelineRepository,
       _milestoneService = milestoneService ?? const TimelineMilestoneService();

  final TaskRepository _taskRepository;
  final TimelineRepository _timelineRepository;
  final TimelineMilestoneService _milestoneService;

  Stream<List<HomeEntry>> watchTodayEntries({DateTime? now}) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _combineLatest(
      _taskRepository.watchTodayTasks(now: current),
      _watchTodayMilestoneOccurrences(current),
      (tasks, milestones) => [
        ...tasks.map(TaskHomeEntry.new),
        ...milestones.map(TimelineMilestoneHomeEntry.new),
      ],
    );
  }

  Stream<List<HomeEntry>> watchUpcomingEntries({DateTime? now}) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _combineLatest(
      _taskRepository.watchUpcomingTasks(now: current),
      _watchUpcomingMilestoneOccurrences(current),
      (tasks, milestones) => [
        ...tasks.map(TaskHomeEntry.new),
        ...milestones.map(TimelineMilestoneHomeEntry.new),
      ],
    );
  }

  Stream<List<TaskBundle>> watchOverdueTasks({DateTime? now}) {
    final current = _normalizeDate(now ?? DateTime.now());
    return _taskRepository.watchOverdueTasks(now: current);
  }

  Stream<List<TimelineMilestoneOccurrence>> _watchTodayMilestoneOccurrences(
    DateTime now,
  ) {
    return _combineLatest(
      _combineLatest(
        _timelineRepository.watchTimelines(),
        _timelineRepository.watchMilestoneRules(),
        (timelines, rules) => (timelines, rules),
      ),
      _timelineRepository.watchMilestoneRecords(),
      (tuple, records) => _computeTodayOccurrences(
        timelines: tuple.$1,
        rules: tuple.$2,
        records: records,
        now: now,
      ),
    );
  }

  Stream<List<TimelineMilestoneOccurrence>> _watchUpcomingMilestoneOccurrences(
    DateTime now,
  ) {
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
        now: now,
      ),
    );
  }

  List<TimelineMilestoneOccurrence> _computeTodayOccurrences({
    required List<Timeline> timelines,
    required List<TimelineMilestoneRule> rules,
    required List<TimelineMilestoneRecord> records,
    required DateTime now,
  }) {
    return [
      for (final timeline in timelines)
        ..._milestoneService.getTodayOccurrences(
          timeline,
          rules
              .where((rule) => rule.timelineId == timeline.id)
              .toList(growable: false),
          records
              .where((record) => record.timelineId == timeline.id)
              .toList(growable: false),
          now: now,
        ),
    ];
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

    void emitIfReady() {
      final valueA = latestA;
      final valueB = latestB;
      if (valueA != null && valueB != null) {
        controller.add(combine(valueA, valueB));
      }
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        subA = streamA.listen((value) {
          latestA = value;
          emitIfReady();
        });
        subB = streamB.listen((value) {
          latestB = value;
          emitIfReady();
        });
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
