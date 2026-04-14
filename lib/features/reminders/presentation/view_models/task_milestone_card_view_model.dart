import '../../data/local/task_timeline_dao.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../formatters/reminder_formatters.dart';

class TaskCardViewModel {
  const TaskCardViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory TaskCardViewModel.fromBundle(TaskBundle bundle) {
    return TaskCardViewModel(
      id: bundle.task.id,
      title: bundle.task.titleSnapshot,
      subtitle: ReminderFormatters.taskSummary(bundle),
      status: bundle.task.status.name,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String status;
}

class MilestoneCardViewModel {
  const MilestoneCardViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory MilestoneCardViewModel.fromOccurrence(
    TimelineMilestoneOccurrence occurrence,
  ) {
    return MilestoneCardViewModel(
      id:
          occurrence.recordId ??
          Object.hash(
            occurrence.timelineId,
            occurrence.ruleId,
            occurrence.occurrenceIndex,
          ),
      title: occurrence.timelineTitle,
      subtitle: ReminderFormatters.milestoneSummary(occurrence),
      status: occurrence.status.name,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String status;
}
