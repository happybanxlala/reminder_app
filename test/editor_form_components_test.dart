import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/ui/widgets/editor_form_components.dart';

void main() {
  testWidgets('ReminderEditorSection renders title and children', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ReminderEditorSection(title: '基本資料', children: const [Text('事項名稱')]),
      ),
    );

    expect(find.text('基本資料'), findsOneWidget);
    expect(find.text('事項名稱'), findsOneWidget);
  });

  testWidgets('collapsible ReminderEditorSection expands and collapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ReminderEditorSection(
          title: '進階設定',
          collapsible: true,
          initiallyExpanded: false,
          toggleKey: const Key('editor-section-toggle-test'),
          children: const [Text('進階內容')],
        ),
      ),
    );

    expect(find.text('進階內容'), findsNothing);
    await tester.tap(find.byKey(const Key('editor-section-toggle-test')));
    await tester.pumpAndSettle();
    expect(find.text('進階內容'), findsOneWidget);
    await tester.tap(find.byKey(const Key('editor-section-toggle-test')));
    await tester.pumpAndSettle();
    expect(find.text('進階內容'), findsNothing);
  });

  testWidgets('ReminderEditorPickerRow renders label and value', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ReminderEditorPickerRow(label: '生活場景', value: '🐱 貓咪')),
    );

    expect(find.text('生活場景'), findsOneWidget);
    expect(find.text('🐱 貓咪'), findsOneWidget);
  });

  testWidgets('ReminderEditorSelectableCard renders selected state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ReminderEditorSelectableCard(
          selected: true,
          title: '固定節奏',
          description: '有明確日期、每週、每月要做的事',
          icon: Icons.event_repeat_outlined,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('固定節奏'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('ReminderEditorNumberField validates minimum value', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '0');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(
        Form(
          key: formKey,
          child: ReminderEditorNumberField(
            fieldKey: const Key('number-field'),
            controller: controller,
            label: '預期處理間隔',
            minimum: 1,
          ),
        ),
      ),
    );

    expect(find.text('預期處理間隔'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('請輸入 1 或以上整數'), findsOneWidget);
  });

  testWidgets('ReminderEditorBottomBar renders save button with SafeArea', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
        child: MaterialApp(
          theme: ReminderTheme.light(),
          home: Scaffold(
            bottomNavigationBar: ReminderEditorBottomBar(
              onSave: () {
                saved = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('editor-bottom-save-bar')), findsOneWidget);
    expect(find.byKey(const Key('save-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-button')));
    expect(saved, isTrue);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ReminderTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}
