import '../domain/reminder.dart';

class RemindersRepository {
  const RemindersRepository();

  List<Reminder> getSeedReminders() {
    return const [
      Reminder(id: '1', title: '買牛奶', note: '下班回家前去超商'),
      Reminder(id: '2', title: '繳信用卡帳單', note: '本月 25 日截止'),
    ];
  }
}
