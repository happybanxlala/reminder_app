import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import '../features/reminders/ui/pages/feature_management_sections.dart';
import '../features/reminders/ui/pages/feature_page.dart';
import '../features/reminders/ui/pages/home_page.dart';
import '../features/reminders/ui/pages/item_edit_page.dart';
import '../features/reminders/ui/pages/item_history_page.dart';
import '../features/reminders/ui/pages/resource_edit_page.dart';
import '../features/reminders/ui/pages/resource_history_page.dart';
import '../features/reminders/ui/pages/stage_tracker_pages.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: HomePage.routePath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: HomePage.routePath,
                name: HomePage.routeName,
                builder: (context, state) => const HomeContent(),
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
        path: StageTrackerManagementPage.routePath,
        name: StageTrackerManagementPage.routeName,
        builder: (context, state) => const StageTrackerManagementPage(),
      ),
      GoRoute(
        path: ResourceManagementPage.routePath,
        name: ResourceManagementPage.routeName,
        builder: (context, state) => const ResourceManagementPage(),
      ),
      GoRoute(
        path: ItemsManagementPage.legacyRoutePath,
        redirect: (context, state) => ItemsManagementPage.routePath,
      ),
      GoRoute(
        path: ItemActivityPage.legacyRoutePath,
        redirect: (context, state) => ItemActivityPage.routePath,
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
      GoRoute(
        path: DeveloperSettingsPage.routePath,
        name: DeveloperSettingsPage.routeName,
        builder: (context, state) => const DeveloperSettingsPage(),
      ),
      GoRoute(
        path: ItemEditPage.createRoutePath,
        name: ItemEditPage.createRouteName,
        builder: (context, state) => ItemEditPage(
          mode: ItemEditMode.create,
          lockedPackId: state.extra as int?,
        ),
      ),
      GoRoute(
        path: ItemEditPage.editRoutePath,
        name: ItemEditPage.editRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ItemEditPage(
            mode: ItemEditMode.edit,
            id: id,
            lockedPackId: state.extra as int?,
          );
        },
      ),
      GoRoute(
        path: ItemHistoryPage.routePath,
        name: ItemHistoryPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ItemHistoryPage(itemId: id ?? 0);
        },
      ),
      GoRoute(
        path: ResourceEditPage.routePath,
        name: ResourceEditPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ResourceEditPage(resourceId: id ?? 0);
        },
      ),
      GoRoute(
        path: ResourceHistoryPage.routePath,
        name: ResourceHistoryPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ResourceHistoryPage(resourceId: id ?? 0);
        },
      ),
      GoRoute(
        path: StageTrackerDetailPage.routePath,
        name: StageTrackerDetailPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return StageTrackerDetailPage(stageTrackerId: id ?? 0);
        },
      ),
      GoRoute(
        path: StageTrackerTimelinePage.routePath,
        name: StageTrackerTimelinePage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return StageTrackerTimelinePage(stageTrackerId: id ?? 0);
        },
      ),
      GoRoute(
        path: StageTrackerSchedulePage.routePath,
        name: StageTrackerSchedulePage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return StageTrackerSchedulePage(stageTrackerId: id ?? 0);
        },
      ),
      GoRoute(
        path: StageTrackerHistoryPage.routePath,
        name: StageTrackerHistoryPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return StageTrackerHistoryPage(stageTrackerId: id ?? 0);
        },
      ),
    ],
  );
});
