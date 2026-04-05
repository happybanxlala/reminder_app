import 'dart:math';

import 'reminder.dart';

class DemoReminderDraft {
  const DemoReminderDraft({
    required this.title,
    this.note,
    required this.timeBasis,
    required this.notifyStrategy,
    required this.remindDays,
    this.dueAt,
    required this.startAt,
    this.repeatType,
    required this.repeatInterval,
  });

  final String title;
  final String? note;
  final int timeBasis;
  final int notifyStrategy;
  final int remindDays;
  final DateTime? dueAt;
  final DateTime startAt;
  final String? repeatType;
  final int repeatInterval;

  static DemoReminderDraft random({Random? random, DateTime? now}) {
    final rng = random ?? Random();
    final base = now ?? DateTime.now();

    const titles = <String>[
      '繳信用卡費',
      '喝水提醒',
      '健身訓練',
      '買日用品',
      '聯絡客戶',
      '備份資料',
      '閱讀 20 分鐘',
    ];
    const notes = <String>[
      '這是 demo 資料',
      '可自行修改內容',
      '先建立再調整時間',
      '測試提醒流程',
    ];
    const repeatTypes = <String?>[null, 'D', 'W', 'M', 'Y'];

    final timeBasis = rng.nextBool()
        ? ReminderTimeBasis.countdown
        : ReminderTimeBasis.countUp;
    final countdownStrategies = <int>[
      ReminderNotifyStrategy.inRange,
      ReminderNotifyStrategy.immediate,
      ReminderNotifyStrategy.onPoint,
    ];
    final notifyStrategy = timeBasis == ReminderTimeBasis.countdown
        ? countdownStrategies[rng.nextInt(countdownStrategies.length)]
        : ReminderNotifyStrategy.inRange;
    final startAt = base.add(Duration(days: rng.nextInt(3)));
    final dueAt = timeBasis == ReminderTimeBasis.countdown
        ? startAt.add(Duration(days: 2 + rng.nextInt(20), hours: 8 + rng.nextInt(8)))
        : null;
    final repeatType = repeatTypes[rng.nextInt(repeatTypes.length)];
    final repeatInterval = repeatType == null ? 1 : 1 + rng.nextInt(5);

    return DemoReminderDraft(
      title: titles[rng.nextInt(titles.length)],
      note: notes[rng.nextInt(notes.length)],
      timeBasis: timeBasis,
      notifyStrategy: notifyStrategy,
      remindDays: rng.nextInt(6),
      dueAt: dueAt,
      startAt: startAt,
      repeatType: repeatType,
      repeatInterval: repeatInterval,
    );
  }
}
