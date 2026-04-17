import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/item_timeline_dao.dart';
import 'timeline_providers.dart';

final itemHistoryProvider = StreamProvider<List<ItemBundle>>((ref) {
  return Stream<List<ItemBundle>>.value(const []);
});

final milestoneHistoryProvider =
    StreamProvider<List<TimelineMilestoneRecordBundle>>((ref) {
      return ref.watch(timelineRepositoryProvider).watchMilestoneHistory();
    });
