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
      expect(find.byKey(const Key('add-stage-tracker-button')), findsOneWidget);

      await _disposeReminderApp(tester);
    },
  );

  testWidgets(
    'stage tracking branch shows empty state and has no self-push FAB',
    (tester) async {
      await _pumpShellRouter(tester);

      await tester.tapAt(
        tester.getBottomLeft(find.byType(NavigationBar)) +
            const Offset(650, -40),
      );
      await _pumpRoute(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('add-stage-tracker-button')), findsOneWidget);
      expect(find.text('還沒有階段追蹤。'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

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
                path: StageTrackerManagementPage.routePath,
                name: StageTrackerManagementPage.routeName,
                builder: (context, state) =>
                    const StageTrackerManagementContent(),
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
        builder: (context, state) => const StageTrackerManagementContent(),
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
