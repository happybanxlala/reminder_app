import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'task_providers.dart';
import 'timeline_providers.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    taskRepository: ref.watch(taskRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final todayHomeEntriesProvider = StreamProvider<List<HomeEntry>>((ref) {
  return ref.watch(homeRepositoryProvider).watchTodayEntries();
});

final upcomingHomeEntriesProvider = StreamProvider<List<HomeEntry>>((ref) {
  return ref.watch(homeRepositoryProvider).watchUpcomingEntries();
});
