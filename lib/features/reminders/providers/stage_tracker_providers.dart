import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stage_tracker_models.dart';
import '../data/stage_tracker_repository.dart';
import '../domain/stage_tracker.dart';
import 'database_providers.dart';
import 'developer_settings_providers.dart';
import 'item_providers.dart';

final stageTrackerRepositoryProvider = Provider<StageTrackerRepository>((ref) {
  return StageTrackerRepository(
    ref.watch(appDatabaseProvider).reminderDao,
    itemRepository: ref.watch(itemRepositoryProvider),
  );
});

final stageTrackersProvider = StreamProvider<List<StageTracker>>((ref) {
  return ref.watch(stageTrackerRepositoryProvider).watchStageTrackers();
});

final stageTrackerByIdProvider = FutureProvider.autoDispose
    .family<StageTracker?, int>((ref, id) {
      return ref.watch(stageTrackerRepositoryProvider).getStageTrackerById(id);
    });

final stageTrackerDetailProvider = FutureProvider.autoDispose
    .family<StageTrackerDetail?, int>((ref, id) {
      final previewDate = ref.watch(effectivePreviewDateProvider);
      return ref
          .watch(stageTrackerRepositoryProvider)
          .getStageTrackerDetailById(id, now: previewDate);
    });
