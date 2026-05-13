import '../domain/item.dart';
import '../domain/stage_occurrence.dart';
import 'local/reminder_dao.dart';

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

class StageHomeEntry extends HomeEntry {
  const StageHomeEntry(this.occurrence);

  final StageOccurrence occurrence;
}
