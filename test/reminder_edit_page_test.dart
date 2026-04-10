import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/reminder_repository.dart';
import 'package:reminder_app/features/reminders/domain/demo_reminder_draft.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';
import 'package:reminder_app/features/reminders/ui/pages/reminder_edit_page.dart';

void main() {
  testWidgets(
    'new reminder wizard hides scheduling fields until repeat choice',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicCategoriesProvider.overrideWith((ref) async => []),
            actionCategoriesProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: ReminderEditPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1：輸入任務內容'), findsOneWidget);
      expect(find.text('Step 2：是否需要重複'), findsOneWidget);
      expect(find.text('Step 3：選擇重複方式'), findsNothing);
      expect(find.byKey(const Key('edit-due-at-text')), findsNothing);
      expect(find.byKey(const Key('edit-remind-days-field')), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('wizard-repeat-once')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('wizard-repeat-once')));
      await tester.pumpAndSettle();

      expect(find.text('Step 4A：單次任務設定'), findsOneWidget);
      expect(find.byKey(const Key('edit-due-at-text')), findsOneWidget);
      expect(find.text('時間：暫不支援時間選擇，會依日期提醒。'), findsOneWidget);
    },
  );

  testWidgets('start based repeat wizard shows accumulation preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicCategoriesProvider.overrideWith((ref) async => []),
          actionCategoriesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: ReminderEditPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('wizard-repeat-recurring')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('wizard-repeat-recurring')));
    await tester.pumpAndSettle();
    expect(find.text('Step 3：選擇重複方式'), findsOneWidget);
    expect(find.byKey(const Key('wizard-accumulation-preview')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('wizard-repeat-pattern-start')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('wizard-repeat-pattern-start')));
    await tester.pumpAndSettle();

    expect(find.text('Step 4C：從某天開始設定'), findsOneWidget);
    expect(find.byKey(const Key('edit-start-at-text')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('wizard-accumulation-preview')))
          .data,
      startsWith('今天是第 '),
    );
  });

  testWidgets('demo random button fills edit fields', (tester) async {
    final draft = DemoReminderDraft(
      title: 'Demo 測試標題',
      note: 'Demo 測試備註',
      trackingMode: ReminderTrackingMode.countdown,
      triggerMode: ReminderTriggerMode.inRange,
      triggerOffsetDays: 3,
      dueAt: DateTime(2026, 3, 1, 10, 30),
      startAt: DateTime(2026, 2, 20, 9, 0),
      repeatType: 'W',
      repeatInterval: 4,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicCategoriesProvider.overrideWith((ref) async => []),
          actionCategoriesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: ReminderEditPage(demoDataFactory: _fixedDraft),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('random-fill-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('random-fill-button')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('edit-title-field')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    final titleField = tester.widget<TextFormField>(
      find.byKey(const Key('edit-title-field')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('edit-note-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final noteField = tester.widget<TextFormField>(
      find.byKey(const Key('edit-note-field')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('edit-remind-days-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final remindDaysField = tester.widget<TextFormField>(
      find.byKey(const Key('edit-remind-days-field')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('edit-repeat-interval-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final repeatIntervalField = tester.widget<TextFormField>(
      find.byKey(const Key('edit-repeat-interval-field')),
    );

    expect(titleField.controller?.text, draft.title);
    expect(noteField.controller?.text, draft.note);
    expect(remindDaysField.controller?.text, '3');
    expect(repeatIntervalField.controller?.text, '4');

    final dueText = tester.widget<Text>(
      find.byKey(const Key('edit-due-at-text')),
    );
    expect(dueText.data, isNot('未設定'));
    expect(
      find.byKey(const ValueKey<String?>('repeat-type-W')),
      findsOneWidget,
    );
  });
}

DemoReminderDraft _fixedDraft() {
  return DemoReminderDraft(
    title: 'Demo 測試標題',
    note: 'Demo 測試備註',
    trackingMode: ReminderTrackingMode.countdown,
    triggerMode: ReminderTriggerMode.inRange,
    triggerOffsetDays: 3,
    dueAt: DateTime(2026, 3, 1, 10, 30),
    startAt: DateTime(2026, 2, 20, 9, 0),
    repeatType: 'W',
    repeatInterval: 4,
  );
}
