import '../../data/local/daos.dart';
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

  factory MilestoneCardViewModel.fromBundle(MilestoneBundle bundle) {
    return MilestoneCardViewModel(
      id: bundle.milestone.id,
      title: bundle.timeline.title,
      subtitle: ReminderFormatters.milestoneSummary(bundle),
      status: bundle.milestone.status.name,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String status;
}
