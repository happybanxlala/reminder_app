import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/timeline_models.dart';
import '../data/timeline_repository.dart';
import '../domain/timeline.dart';
import 'developer_settings_providers.dart';
import 'database_providers.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(appDatabaseProvider).itemTimelineDao);
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

final previewTimelineDetailProvider = FutureProvider.autoDispose
    .family<TimelineDetail?, int>((ref, id) {
      final previewDate = ref.watch(effectivePreviewDateProvider);
      return ref
          .watch(timelineRepositoryProvider)
          .getTimelineDetailById(id, now: previewDate);
    });
