import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_models.dart';
import '../data/home_repository.dart';
import '../domain/timeline_milestone_occurrence.dart';
import 'responsibility_providers.dart';
import 'timeline_providers.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    responsibilityRepository: ref.watch(responsibilityRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final dangerHomeEntriesProvider =
    StreamProvider<List<ResponsibilityItemHomeEntry>>((ref) {
      return ref.watch(homeRepositoryProvider).watchDangerItems();
    });

final warningHomeEntriesProvider =
    StreamProvider<List<ResponsibilityItemHomeEntry>>((ref) {
      return ref.watch(homeRepositoryProvider).watchWarningItems();
    });

final upcomingTimelineMilestonesProvider =
    StreamProvider<List<TimelineMilestoneOccurrence>>((ref) {
      return ref
          .watch(homeRepositoryProvider)
          .watchUpcomingTimelineMilestones();
    });
