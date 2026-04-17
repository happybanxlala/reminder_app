import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_models.dart';
import '../data/home_repository.dart';
import '../domain/timeline_milestone_occurrence.dart';
import 'developer_settings_providers.dart';
import 'item_providers.dart';
import 'timeline_providers.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    itemRepository: ref.watch(itemRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final dangerHomeEntriesProvider = StreamProvider<List<ItemHomeEntry>>((ref) {
  final previewDate = ref.watch(effectivePreviewDateProvider);
  return ref.watch(homeRepositoryProvider).watchDangerItems(now: previewDate);
});

final warningHomeEntriesProvider = StreamProvider<List<ItemHomeEntry>>((ref) {
  final previewDate = ref.watch(effectivePreviewDateProvider);
  return ref.watch(homeRepositoryProvider).watchWarningItems(now: previewDate);
});

final upcomingTimelineMilestonesProvider =
    StreamProvider<List<TimelineMilestoneOccurrence>>((ref) {
      final previewDate = ref.watch(effectivePreviewDateProvider);
      return ref
          .watch(homeRepositoryProvider)
          .watchUpcomingTimelineMilestones(now: previewDate);
    });
