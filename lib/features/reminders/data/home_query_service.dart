import 'dart:async';

import 'local/task_timeline_dao.dart';
import 'task_repository.dart';
import 'timeline_repository.dart';

sealed class HomeItem {
  const HomeItem();
}

class TaskHomeItem extends HomeItem {
  const TaskHomeItem(this.bundle);

  final TaskBundle bundle;
}

class MilestoneHomeItem extends HomeItem {
  const MilestoneHomeItem(this.bundle);

  final MilestoneBundle bundle;
}

class HomeQueryService {
  HomeQueryService({
    required TaskRepository taskRepository,
    required TimelineRepository timelineRepository,
  }) : _taskRepository = taskRepository,
       _timelineRepository = timelineRepository;

  final TaskRepository _taskRepository;
  final TimelineRepository _timelineRepository;

  Stream<List<HomeItem>> watchTodayItems() {
    return _combineLatest(
      _taskRepository.watchTodayTasks(),
      _timelineRepository.watchTodayMilestones(),
      (tasks, milestones) => [
        ...tasks.map(TaskHomeItem.new),
        ...milestones.map(MilestoneHomeItem.new),
      ],
    );
  }

  Stream<List<HomeItem>> watchUpcomingItems() {
    return _combineLatest(
      _taskRepository.watchUpcomingTasks(),
      _timelineRepository.watchUpcomingMilestones(),
      (tasks, milestones) => [
        ...tasks.map(TaskHomeItem.new),
        ...milestones.map(MilestoneHomeItem.new),
      ],
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
}
