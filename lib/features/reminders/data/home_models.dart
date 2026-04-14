import '../domain/timeline_milestone_occurrence.dart';
import 'local/task_timeline_dao.dart';

sealed class HomeEntry {
  const HomeEntry();
}

class TaskHomeEntry extends HomeEntry {
  const TaskHomeEntry(this.bundle);

  final TaskBundle bundle;
}

class TimelineMilestoneHomeEntry extends HomeEntry {
  const TimelineMilestoneHomeEntry(this.occurrence);

  final TimelineMilestoneOccurrence occurrence;
}
