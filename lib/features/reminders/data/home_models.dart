import '../domain/item.dart';
import '../domain/timeline_milestone_occurrence.dart';
import 'local/item_timeline_dao.dart';

sealed class HomeEntry {
  const HomeEntry();
}

class ItemHomeEntry extends HomeEntry {
  const ItemHomeEntry({
    required this.bundle,
    required this.status,
    this.elapsed,
  });

  final ItemBundle bundle;
  final ItemStatus status;
  final Duration? elapsed;
}

class TimelineMilestoneHomeEntry extends HomeEntry {
  const TimelineMilestoneHomeEntry(this.occurrence);

  final TimelineMilestoneOccurrence occurrence;
}
