import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/default_pack_templates.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/pack_template.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/pack_template_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_management_sections.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';

void main() {
  testWidgets('pack management template entry opens picker and preview', (
    tester,
  ) async {
    await _pumpPackManagement(tester);

    expect(find.byKey(const Key('pack-template-entry-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-template-entry-action')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packTemplatePickerTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.packTemplateDefaultSectionTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.packTemplateCustomSectionTitle),
      findsOneWidget,
    );
    expect(find.text('家務'), findsOneWidget);
    expect(find.text('個人護理'), findsOneWidget);
    expect(find.text('養貓'), findsOneWidget);
    expect(find.text('5 個事項'), findsAtLeastNWidgets(2));
    expect(find.byKey(const Key('pack-template-custom-empty')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pack-template-row-default-housework')),
    );
    await tester.pumpAndSettle();

    expect(find.text('家務'), findsOneWidget);
    expect(find.text('生活場景：家務(模版)'), findsOneWidget);
    expect(find.text('倒垃圾'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byKey(const Key('pack-template-use-button')), findsOneWidget);
  });

  testWidgets('create from template creates pack and snackbar view action', (
    tester,
  ) async {
    await _pumpPackManagement(tester);

    await tester.tap(find.byKey(const Key('pack-template-entry-action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pack-template-row-default-housework')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pack-template-use-button')));
    await tester.pumpAndSettle();

    expect(find.text('已建立「家務(模版)」'), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.packTemplateViewAction));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('items-route')), findsOneWidget);
  });

  testWidgets('pack create dialog exposes template entry', (tester) async {
    await _pumpPackManagement(tester);

    await tester.tap(find.byKey(const Key('pack-management-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-dialog-template-entry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pack-dialog-template-entry')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packTemplatePickerTitle), findsOneWidget);
  });

  testWidgets('pack templates fit phone viewport', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await _pumpPackManagement(tester);
    await tester.tap(find.byKey(const Key('pack-template-entry-action')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPackManagement(
  WidgetTester tester, {
  AppDatabase? database,
  List<ItemPack>? packs,
  List<ItemBundle> itemBundles = const [],
  List<PackTemplate>? templates,
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
  final visiblePacks = packs ?? [_defaultPack()];
  final visibleTemplates = templates ?? defaultPackTemplates;
  final router = GoRouter(
    initialLocation: ItemPacksManagementPage.routePath,
    routes: [
      GoRoute(
        path: ItemPacksManagementPage.routePath,
        name: ItemPacksManagementPage.routeName,
        builder: (context, state) => const ItemPacksManagementPage(),
      ),
      GoRoute(
        path: ItemsManagementPage.routePath,
        name: ItemsManagementPage.routeName,
        builder: (context, state) => const Scaffold(
          body: KeyedSubtree(
            key: Key('items-route'),
            child: ItemsManagementContent(),
          ),
        ),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    router.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value(visiblePacks),
        ),
        packManagementItemsProvider.overrideWith(
          (ref) => Stream.value(itemBundles),
        ),
        packTemplatesProvider.overrideWith(
          (ref) => Stream.value(visibleTemplates),
        ),
        customPackTemplatesProvider.overrideWith(
          (ref) => Stream.value(
            visibleTemplates
                .where(
                  (template) => template.source == PackTemplateSource.custom,
                )
                .toList(growable: false),
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

ItemPack _defaultPack() {
  return ItemPack(
    id: 1,
    title: '一般',
    iconEmoji: '📌',
    orderIndex: 0,
    status: ItemPackStatus.active,
    isSystemDefault: true,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
