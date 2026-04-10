import '../../domain/demo_reminder_draft.dart';
import '../../domain/recurring_reminder.dart';
import '../../domain/reminder.dart';
import '../../domain/repeat_rule.dart';

class ReminderFormDraft {
  const ReminderFormDraft({
    required this.title,
    this.note,
    required this.trackingMode,
    required this.triggerMode,
    required this.triggerOffsetDays,
    this.repeatRule,
    this.dueAt,
    this.startAt,
    this.topicCategoryId,
    this.actionCategoryId,
    this.readOnly = false,
  });

  factory ReminderFormDraft.createDefault() {
    return ReminderFormDraft(
      title: '',
      note: null,
      trackingMode: ReminderTrackingMode.countdown,
      triggerMode: ReminderTriggerMode.inRange,
      triggerOffsetDays: 0,
      startAt: DateTime.now(),
    );
  }

  factory ReminderFormDraft.fromReminder(ReminderModel reminder) {
    return ReminderFormDraft(
      title: reminder.title,
      note: reminder.note,
      trackingMode: reminder.trackingMode,
      triggerMode: reminder.triggerMode,
      triggerOffsetDays: reminder.triggerOffsetDays ?? 0,
      repeatRule: reminder.repeatRule,
      dueAt: reminder.dueAt,
      startAt: reminder.startAt,
      topicCategoryId: reminder.topicCategoryId,
      actionCategoryId: reminder.actionCategoryId,
    );
  }

  factory ReminderFormDraft.fromRecurringReminder(
    RecurringReminderModel reminder,
  ) {
    return ReminderFormDraft(
      title: reminder.title,
      note: reminder.note,
      trackingMode: reminder.trackingMode,
      triggerMode: reminder.triggerMode,
      triggerOffsetDays: reminder.triggerOffsetDays ?? 0,
      repeatRule: reminder.repeatRule,
      topicCategoryId: reminder.topicCategoryId,
      actionCategoryId: reminder.actionCategoryId,
      readOnly: reminder.status == RecurringReminderStatus.canceled,
    );
  }

  factory ReminderFormDraft.fromDemo(DemoReminderDraft draft) {
    return ReminderFormDraft(
      title: draft.title,
      note: draft.note,
      trackingMode: draft.trackingMode,
      triggerMode: draft.triggerMode,
      triggerOffsetDays: draft.triggerOffsetDays,
      repeatRule: _repeatRuleFromDemoDraft(draft),
      dueAt: draft.dueAt,
      startAt: draft.startAt,
    );
  }

  final String title;
  final String? note;
  final int trackingMode;
  final int triggerMode;
  final int triggerOffsetDays;
  final String? repeatRule;
  final DateTime? dueAt;
  final DateTime? startAt;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final bool readOnly;
}

enum ReminderWizardRepeatChoice { once, recurring }

enum ReminderWizardRepeatPattern { fixedTime, fromStart }

enum ReminderWizardAccumulationDisplay { day, week, year }

class ReminderWizardDraft {
  const ReminderWizardDraft({
    required this.title,
    this.note,
    this.repeatChoice,
    this.repeatPattern,
    required this.trackingMode,
    required this.triggerMode,
    required this.triggerOffsetDays,
    this.repeatType,
    required this.repeatInterval,
    this.dueAt,
    this.startAt,
    this.topicCategoryId,
    this.actionCategoryId,
    this.accumulationDisplay = ReminderWizardAccumulationDisplay.day,
    this.readOnly = false,
  });

  factory ReminderWizardDraft.empty() {
    return ReminderWizardDraft(
      title: '',
      trackingMode: ReminderTrackingMode.countdown,
      triggerMode: ReminderTriggerMode.inRange,
      triggerOffsetDays: 0,
      repeatInterval: 1,
      startAt: DateTime.now(),
    );
  }

  factory ReminderWizardDraft.fromFormDraft(
    ReminderFormDraft draft, {
    bool waitForRepeatChoice = false,
  }) {
    final repeatRule = RepeatRule.parse(draft.repeatRule);
    final isRecurring = repeatRule != null;
    final trackingMode = draft.trackingMode;
    return ReminderWizardDraft(
      title: draft.title,
      note: draft.note,
      repeatChoice: waitForRepeatChoice
          ? null
          : (isRecurring
                ? ReminderWizardRepeatChoice.recurring
                : ReminderWizardRepeatChoice.once),
      repeatPattern: isRecurring
          ? (trackingMode == ReminderTrackingMode.countdown
                ? ReminderWizardRepeatPattern.fixedTime
                : ReminderWizardRepeatPattern.fromStart)
          : null,
      trackingMode: trackingMode,
      triggerMode: draft.triggerMode,
      triggerOffsetDays: draft.triggerOffsetDays,
      repeatType: repeatRule?.kind,
      repeatInterval: repeatRule?.interval ?? 1,
      dueAt: draft.dueAt,
      startAt: draft.startAt ?? DateTime.now(),
      topicCategoryId: draft.topicCategoryId,
      actionCategoryId: draft.actionCategoryId,
      readOnly: draft.readOnly,
    );
  }

  final String title;
  final String? note;
  final ReminderWizardRepeatChoice? repeatChoice;
  final ReminderWizardRepeatPattern? repeatPattern;
  final int trackingMode;
  final int triggerMode;
  final int triggerOffsetDays;
  final String? repeatType;
  final int repeatInterval;
  final DateTime? dueAt;
  final DateTime? startAt;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final ReminderWizardAccumulationDisplay accumulationDisplay;
  final bool readOnly;

  String? get repeatRule {
    if (repeatChoice != ReminderWizardRepeatChoice.recurring ||
        repeatType == null) {
      return null;
    }
    return '$repeatType$repeatInterval';
  }

  ReminderWizardDraft copyWith({
    String? title,
    Object? note = _notSet,
    Object? repeatChoice = _notSet,
    Object? repeatPattern = _notSet,
    int? trackingMode,
    int? triggerMode,
    int? triggerOffsetDays,
    Object? repeatType = _notSet,
    int? repeatInterval,
    Object? dueAt = _notSet,
    Object? startAt = _notSet,
    Object? topicCategoryId = _notSet,
    Object? actionCategoryId = _notSet,
    ReminderWizardAccumulationDisplay? accumulationDisplay,
    bool? readOnly,
  }) {
    return ReminderWizardDraft(
      title: title ?? this.title,
      note: note == _notSet ? this.note : note as String?,
      repeatChoice: repeatChoice == _notSet
          ? this.repeatChoice
          : repeatChoice as ReminderWizardRepeatChoice?,
      repeatPattern: repeatPattern == _notSet
          ? this.repeatPattern
          : repeatPattern as ReminderWizardRepeatPattern?,
      trackingMode: trackingMode ?? this.trackingMode,
      triggerMode: triggerMode ?? this.triggerMode,
      triggerOffsetDays: triggerOffsetDays ?? this.triggerOffsetDays,
      repeatType: repeatType == _notSet
          ? this.repeatType
          : repeatType as String?,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      dueAt: dueAt == _notSet ? this.dueAt : dueAt as DateTime?,
      startAt: startAt == _notSet ? this.startAt : startAt as DateTime?,
      topicCategoryId: topicCategoryId == _notSet
          ? this.topicCategoryId
          : topicCategoryId as int?,
      actionCategoryId: actionCategoryId == _notSet
          ? this.actionCategoryId
          : actionCategoryId as int?,
      accumulationDisplay: accumulationDisplay ?? this.accumulationDisplay,
      readOnly: readOnly ?? this.readOnly,
    );
  }
}

const Object _notSet = Object();

String? _repeatRuleFromDemoDraft(DemoReminderDraft draft) {
  if (draft.repeatType == null) {
    return null;
  }
  return '${draft.repeatType}${draft.repeatInterval}';
}
