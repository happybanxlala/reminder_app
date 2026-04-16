import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/responsibility_timeline_dao.dart';
import 'timeline_providers.dart';

final responsibilityHistoryProvider =
    StreamProvider<List<ResponsibilityItemBundle>>((ref) {
      return Stream<List<ResponsibilityItemBundle>>.value(const []);
    });

final milestoneHistoryProvider =
    StreamProvider<List<TimelineMilestoneRecordBundle>>((ref) {
      return ref.watch(timelineRepositoryProvider).watchMilestoneHistory();
    });
