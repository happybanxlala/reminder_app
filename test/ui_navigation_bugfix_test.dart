import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/app_shell.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_management_sections.dart';
import 'package:reminder_app/features/reminders/ui/pages/stage_tracker_pages.dart';
import 'package:reminder_app/features/reminders/ui/widgets/reminder_components.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';

void main() {
  testWidgets('rail card lays out and hit-tests inside a scrolling page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              ReminderRailCard(
                railColor: Colors.orange,
                child: Text('Needs action card'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Needs action card'), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.text('Needs action card')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await gesture.removePointer();
  });

  testWidgets(
    'feature hub opens shell branch routes without navigator key assertion',
    (tester) async {
      final router = await _pumpFeatureHubRouter(tester);

      expect(find.text('整理你的生活照顧系統'), findsOneWidget);

      await tester.tap(find.text('要照顧的事'));
      await _pumpRoute(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('add-item-button')), findsOneWidget);

      router.go(FeaturePage.routePath);
      await _pumpRoute(tester);
      await tester.tap(
        find.byKey(const Key('feature-entry-stage-tracking')),
        warnIfMissed: false,
      );
      await _pumpRoute(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('stage-tracker-content-add-button')),
        findsOneWidget,
      );

      await _disposeReminderApp(tester);
    },
  );

  testWidgets(
    'bottom navigation uses home items activity more and More opens entries',
    (tester) async {
      final router = await _pumpShellRouter(tester);

      expect(find.text(ReminderUiText.bottomNavHome), findsAtLeastNWidgets(1));
      expect(find.text(ReminderUiText.bottomNavItems), findsOneWidget);
      expect(find.text(ReminderUiText.bottomNavActivity), findsOneWidget);
      expect(find.text(ReminderUiText.bottomNavMore), findsOneWidget);
      expect(find.text(ReminderUiText.bottomNavStageTracker), findsNothing);

      await tester.tap(find.text(ReminderUiText.bottomNavMore));
      await _pumpRoute(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('more-page')), findsOneWidget);
      expect(find.byKey(const Key('more-resources-entry')), findsOneWidget);
      expect(
        find.byKey(const Key('more-stage-trackers-entry')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('more-packs-entry')), findsOneWidget);
      expect(find.byKey(const Key('more-settings-entry')), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.byKey(const Key('more-stage-trackers-entry')));
      await _pumpRoute(tester);
      expect(find.byKey(const Key('stage-tracker-grid')), findsOneWidget);

      router.go(MorePage.routePath);
      await _pumpRoute(tester);
      await tester.tap(find.byKey(const Key('more-settings-entry')));
      await _pumpRoute(tester);
      expect(find.byKey(const Key('settings-page')), findsOneWidget);

      await _disposeReminderApp(tester);
    },
  );
}

Future<GoRouter> _pumpShellRouter(WidgetTester tester) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'test-home',
                builder: (context, state) => const Center(child: Text('Home')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ItemsManagementPage.routePath,
                name: ItemsManagementPage.routeName,
                builder: (context, state) => const ItemsManagementContent(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ItemActivityPage.routePath,
                name: ItemActivityPage.routeName,
                builder: (context, state) => const ItemActivityContent(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MorePage.routePath,
                name: MorePage.routeName,
                builder: (context, state) => const MoreContent(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: FeaturePage.routePath,
        name: FeaturePage.routeName,
        builder: (context, state) => const FeaturePage(),
      ),
      GoRoute(
        path: ResourceManagementPage.routePath,
        name: ResourceManagementPage.routeName,
        builder: (context, state) => const ResourceManagementPage(),
      ),
      GoRoute(
        path: StageTrackerManagementPage.routePath,
        name: StageTrackerManagementPage.routeName,
        builder: (context, state) => const StageTrackerManagementPage(),
      ),
      GoRoute(
        path: ItemPacksManagementPage.routePath,
        name: ItemPacksManagementPage.routeName,
        builder: (context, state) => const ItemPacksManagementPage(),
      ),
      GoRoute(
        path: SettingsPage.routePath,
        name: SettingsPage.routeName,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await _pumpRoute(tester);
  return router;
}

Future<GoRouter> _pumpFeatureHubRouter(WidgetTester tester) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);
  final router = GoRouter(
    initialLocation: FeaturePage.routePath,
    routes: [
      GoRoute(
        path: FeaturePage.routePath,
        name: FeaturePage.routeName,
        builder: (context, state) => const FeaturePage(),
      ),
      GoRoute(
        path: ItemsManagementPage.routePath,
        name: ItemsManagementPage.routeName,
        builder: (context, state) => const ItemsManagementContent(),
      ),
      GoRoute(
        path: StageTrackerManagementPage.routePath,
        name: StageTrackerManagementPage.routeName,
        builder: (context, state) => const StageTrackerManagementPage(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await _pumpRoute(tester);
  return router;
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _disposeReminderApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}
