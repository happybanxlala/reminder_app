import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/task_timeline_dao.dart';
import 'task_providers.dart';
import 'timeline_providers.dart';

final taskHistoryProvider = StreamProvider<List<TaskBundle>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTaskHistory();
});

final milestoneHistoryProvider =
    StreamProvider<List<TimelineMilestoneRecordBundle>>((ref) {
      return ref.watch(timelineRepositoryProvider).watchMilestoneHistory();
    });
