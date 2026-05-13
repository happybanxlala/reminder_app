import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_models.dart';
import '../data/home_repository.dart';
import '../domain/stage_occurrence.dart';
import 'developer_settings_providers.dart';
import 'item_providers.dart';
import 'stage_tracker_providers.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    itemRepository: ref.watch(itemRepositoryProvider),
    stageTrackerRepository: ref.watch(stageTrackerRepositoryProvider),
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

final upcomingStagesProvider = StreamProvider<List<StageOccurrence>>((ref) {
  final previewDate = ref.watch(effectivePreviewDateProvider);
  return ref
      .watch(homeRepositoryProvider)
      .watchUpcomingStages(now: previewDate);
});
