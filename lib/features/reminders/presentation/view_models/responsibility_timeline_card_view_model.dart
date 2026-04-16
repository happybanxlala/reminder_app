import '../../data/home_models.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../formatters/reminder_formatters.dart';

class ResponsibilityCardViewModel {
  const ResponsibilityCardViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory ResponsibilityCardViewModel.fromEntry(
    ResponsibilityItemHomeEntry entry,
  ) {
    return ResponsibilityCardViewModel(
      id: entry.bundle.item.id,
      title: entry.bundle.item.title,
      subtitle: ReminderFormatters.responsibilityHomeSummary(entry),
      status: entry.status.name,
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
