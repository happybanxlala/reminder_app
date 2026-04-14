import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/task_timeline_dao.dart';
import '../data/task_repository.dart';
import '../domain/task_template.dart';
import 'database_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(appDatabaseProvider).taskTimelineDao);
});

final overdueTasksProvider = StreamProvider<List<TaskBundle>>((ref) {
  return ref.watch(taskRepositoryProvider).watchOverdueTasks();
});

final taskTemplatesProvider = StreamProvider<List<TaskTemplate>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTemplates();
});

final taskBundleProvider = FutureProvider.family<TaskBundle?, int>((ref, id) {
  return ref.watch(taskRepositoryProvider).getTaskById(id);
});

final taskTemplateProvider = FutureProvider.family<TaskTemplate?, int>((
  ref,
  id,
) {
  return ref.watch(taskRepositoryProvider).getTemplateById(id);
});
