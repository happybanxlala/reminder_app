import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reminder.dart';

final remindersServiceProvider =
    StateNotifierProvider<RemindersService, List<Reminder>>((ref) {
      return RemindersService(
        seed: const [
          Reminder(id: '1', title: '買牛奶', note: '下班回家前去超商'),
          Reminder(id: '2', title: '繳信用卡帳單', note: '本月 25 日截止'),
        ],
      );
    });

class RemindersService extends StateNotifier<List<Reminder>> {
  RemindersService({List<Reminder> seed = const []}) : super(seed);

  Reminder? findById(String id) {
    for (final reminder in state) {
      if (reminder.id == id) return reminder;
    }
    return null;
  }

  void save({required String title, String? note, String? id}) {
    if (id == null || id.isEmpty) {
      final newReminder = Reminder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        note: note,
      );
      state = [...state, newReminder];
      return;
    }

    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(title: title, note: note)
        else
          reminder,
    ];
  }

  void remove(String id) {
    state = state.where((reminder) => reminder.id != id).toList();
  }

  void toggleComplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: !reminder.isCompleted)
        else
          reminder,
    ];
  }
}
