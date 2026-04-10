import 'dart:math';

import 'reminder.dart';

class DemoReminderDraft {
  const DemoReminderDraft({
    required this.title,
    this.note,
    required this.trackingMode,
    required this.triggerMode,
    required this.triggerOffsetDays,
    this.dueAt,
    required this.startAt,
    this.repeatType,
    required this.repeatInterval,
  });

  final String title;
  final String? note;
  final int trackingMode;
  final int triggerMode;
  final int triggerOffsetDays;
  final DateTime? dueAt;
  final DateTime startAt;
  final String? repeatType;
  final int repeatInterval;

  @Deprecated('Use trackingMode instead.')
  int get timeBasis => trackingMode;

  @Deprecated('Use triggerMode instead.')
  int get notifyStrategy => triggerMode;

  @Deprecated('Use triggerOffsetDays instead.')
  int get remindDays => triggerOffsetDays;

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
    const notes = <String>['這是 demo 資料', '可自行修改內容', '先建立再調整時間', '測試提醒流程'];
    const repeatTypes = <String?>[null, 'D', 'W', 'M', 'Y'];

    final trackingMode = rng.nextBool()
        ? ReminderTrackingMode.countdown
        : ReminderTrackingMode.accumulation;
    final countdownStrategies = <int>[
      ReminderTriggerMode.inRange,
      ReminderTriggerMode.immediate,
      ReminderTriggerMode.onPoint,
    ];
    final triggerMode = trackingMode == ReminderTrackingMode.countdown
        ? countdownStrategies[rng.nextInt(countdownStrategies.length)]
        : ReminderTriggerMode.inRange;
    final startAt = base.add(Duration(days: rng.nextInt(3)));
    final dueAt = trackingMode == ReminderTrackingMode.countdown
        ? startAt.add(
            Duration(days: 2 + rng.nextInt(20), hours: 8 + rng.nextInt(8)),
          )
        : null;
    final repeatType = repeatTypes[rng.nextInt(repeatTypes.length)];
    final repeatInterval = repeatType == null ? 1 : 1 + rng.nextInt(5);

    return DemoReminderDraft(
      title: titles[rng.nextInt(titles.length)],
      note: notes[rng.nextInt(notes.length)],
      trackingMode: trackingMode,
      triggerMode: triggerMode,
      triggerOffsetDays: rng.nextInt(6),
      dueAt: dueAt,
      startAt: startAt,
      repeatType: repeatType,
      repeatInterval: repeatInterval,
    );
  }
}
