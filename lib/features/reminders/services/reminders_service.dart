import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminder_repository.dart';
import '../domain/reminder.dart';

@Deprecated('Use reminderRepositoryProvider and stream providers directly.')
final remindersServiceProvider = Provider<RemindersService>((ref) {
  return RemindersService(ref.watch(reminderRepositoryProvider));
});

class RemindersService {
  const RemindersService(this._repository);

  final ReminderRepository _repository;

  Stream<List<ReminderModel>> watchAll() => _repository.watchAll();
}
