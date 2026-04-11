import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../formatters/reminder_formatters.dart';

class TemplateListItemViewModel {
  const TemplateListItemViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory TemplateListItemViewModel.fromDomain(TaskTemplate template) {
    return TemplateListItemViewModel(
      id: template.id,
      title: template.title,
      subtitle: ReminderFormatters.templateSummary(
        template.repeatRule,
        template.reminderRule,
      ),
      status: template.status.name,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String status;
}

class TimelineListItemViewModel {
  const TimelineListItemViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory TimelineListItemViewModel.fromDomain(Timeline timeline) {
    return TimelineListItemViewModel(
      id: timeline.id,
      title: timeline.title,
      subtitle: ReminderFormatters.timelineSummary(timeline),
      status: timeline.status.name,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String status;
}
