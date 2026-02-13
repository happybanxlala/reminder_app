import 'dart:math';

class DemoReminderDraft {
  const DemoReminderDraft({
    required this.title,
    this.note,
    required this.remindDays,
    required this.dueAt,
    this.repeatType,
    required this.repeatInterval,
  });

  final String title;
  final String? note;
  final int remindDays;
  final DateTime dueAt;
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
    const repeatTypes = <String?>[null, 'D', 'W', 'N', 'Y'];

    final dueAt = base
        .add(Duration(days: rng.nextInt(21), hours: 8 + rng.nextInt(12)));
    final repeatType = repeatTypes[rng.nextInt(repeatTypes.length)];
    final repeatInterval = repeatType == null ? 1 : 1 + rng.nextInt(5);

    return DemoReminderDraft(
      title: titles[rng.nextInt(titles.length)],
      note: notes[rng.nextInt(notes.length)],
      remindDays: rng.nextInt(6),
      dueAt: dueAt,
      repeatType: repeatType,
      repeatInterval: repeatInterval,
    );
  }
}
