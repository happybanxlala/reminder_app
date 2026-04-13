import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_query_service.dart';
import 'task_providers.dart';
import 'timeline_providers.dart';

final homeQueryServiceProvider = Provider<HomeQueryService>((ref) {
  return HomeQueryService(
    taskRepository: ref.watch(taskRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final todayHomeItemsProvider = StreamProvider<List<HomeItem>>((ref) {
  return ref.watch(homeQueryServiceProvider).watchTodayItems();
});

final upcomingHomeItemsProvider = StreamProvider<List<HomeItem>>((ref) {
  return ref.watch(homeQueryServiceProvider).watchUpcomingItems();
});
