import '../domain/responsibility_item.dart';
import '../domain/timeline_milestone_occurrence.dart';
import 'local/responsibility_timeline_dao.dart';

sealed class HomeEntry {
  const HomeEntry();
}

class ResponsibilityItemHomeEntry extends HomeEntry {
  const ResponsibilityItemHomeEntry({
    required this.bundle,
    required this.status,
    this.elapsed,
  });

  final ResponsibilityItemBundle bundle;
  final ResponsibilityItemStatus status;
  final Duration? elapsed;
}

class TimelineMilestoneHomeEntry extends HomeEntry {
  const TimelineMilestoneHomeEntry(this.occurrence);

  final TimelineMilestoneOccurrence occurrence;
}
