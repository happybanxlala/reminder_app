import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reminder.dart';
import 'reminder_wizard_draft.dart';

final reminderWizardDraftProvider =
    StateNotifierProvider<ReminderWizardDraftNotifier, ReminderWizardDraft>(
      (ref) => ReminderWizardDraftNotifier(),
    );

class ReminderWizardDraftNotifier extends StateNotifier<ReminderWizardDraft> {
  ReminderWizardDraftNotifier() : super(ReminderWizardDraft.empty());

  void initialize(ReminderFormDraft draft, {bool waitForRepeatChoice = false}) {
    state = ReminderWizardDraft.fromFormDraft(
      draft,
      waitForRepeatChoice: waitForRepeatChoice,
    );
  }

  void applyDemo(ReminderFormDraft draft) {
    state = ReminderWizardDraft.fromFormDraft(draft);
  }

  void setTitle(String value) {
    state = state.copyWith(title: value);
  }

  void setNote(String value) {
    state = state.copyWith(note: value.trim().isEmpty ? null : value);
  }

  void setRepeatChoice(ReminderWizardRepeatChoice value) {
    if (value == ReminderWizardRepeatChoice.once) {
      state = state.copyWith(
        repeatChoice: value,
        repeatPattern: null,
        trackingMode: ReminderTrackingMode.countdown,
        triggerMode: ReminderTriggerMode.inRange,
        repeatType: null,
      );
      return;
    }

    state = state.copyWith(repeatChoice: value);
  }

  void setRepeatPattern(ReminderWizardRepeatPattern value) {
    if (value == ReminderWizardRepeatPattern.fixedTime) {
      state = state.copyWith(
        repeatPattern: value,
        trackingMode: ReminderTrackingMode.countdown,
        triggerMode: ReminderTriggerMode.inRange,
        repeatType: state.repeatType ?? 'D',
        repeatInterval: state.repeatInterval < 1 ? 1 : state.repeatInterval,
        dueAt: state.dueAt ?? DateTime.now(),
      );
      return;
    }

    state = state.copyWith(
      repeatPattern: value,
      trackingMode: ReminderTrackingMode.accumulation,
      triggerMode: ReminderTriggerMode.inRange,
      repeatType: state.repeatType ?? 'D',
      repeatInterval: state.repeatInterval < 1 ? 1 : state.repeatInterval,
      dueAt: null,
      startAt: state.startAt ?? DateTime.now(),
    );
  }

  void setTriggerMode(int value) {
    state = state.copyWith(triggerMode: value);
  }

  void setTriggerOffsetDays(int value) {
    state = state.copyWith(triggerOffsetDays: value);
  }

  void setDueAt(DateTime? value) {
    state = state.copyWith(dueAt: value);
  }

  void setStartAt(DateTime value) {
    state = state.copyWith(startAt: value);
  }

  void setRepeatType(String? value) {
    state = state.copyWith(repeatType: value);
  }

  void setRepeatInterval(int value) {
    state = state.copyWith(repeatInterval: value);
  }

  void setTopicCategoryId(int? value) {
    state = state.copyWith(topicCategoryId: value);
  }

  void setActionCategoryId(int? value) {
    state = state.copyWith(actionCategoryId: value);
  }

  void setAccumulationDisplay(ReminderWizardAccumulationDisplay value) {
    state = state.copyWith(accumulationDisplay: value);
  }
}
