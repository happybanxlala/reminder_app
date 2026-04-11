import '../domain/task_scheduler.dart';
import '../domain/timeline_calculator.dart';

class RemindersService {
  const RemindersService({
    this.taskScheduler = const TaskScheduler(),
    this.timelineCalculator = const TimelineCalculator(),
  });

  final TaskScheduler taskScheduler;
  final TimelineCalculator timelineCalculator;
}
