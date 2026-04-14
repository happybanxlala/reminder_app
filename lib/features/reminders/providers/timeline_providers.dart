import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/timeline_models.dart';
import '../data/timeline_repository.dart';
import '../domain/timeline.dart';
import 'database_providers.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(appDatabaseProvider).taskTimelineDao);
});

final timelinesProvider = StreamProvider<List<Timeline>>((ref) {
  return ref.watch(timelineRepositoryProvider).watchTimelines();
});

final timelineByIdProvider = FutureProvider.autoDispose.family<Timeline?, int>((
  ref,
  id,
) {
  return ref.watch(timelineRepositoryProvider).getTimelineById(id);
});

final timelineDetailProvider = FutureProvider.autoDispose
    .family<TimelineDetail?, int>((ref, id) {
      return ref.watch(timelineRepositoryProvider).getTimelineDetailById(id);
    });
