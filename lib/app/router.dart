import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/ui/pages/home_page.dart';
import '../features/reminders/ui/pages/feature_page.dart';
import '../features/reminders/ui/pages/item_edit_page.dart';
import '../features/reminders/ui/pages/management_page.dart';
import '../features/reminders/ui/pages/timeline_edit_page.dart';
import '../features/reminders/ui/pages/timeline_milestone_history_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: HomePage.routePath,
    routes: [
      GoRoute(
        path: HomePage.routePath,
        name: HomePage.routeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: FeaturePage.routePath,
        name: FeaturePage.routeName,
        builder: (context, state) => const FeaturePage(),
      ),
      GoRoute(
        path: ItemActivityPage.routePath,
        name: ItemActivityPage.routeName,
        builder: (context, state) => const ItemActivityPage(),
      ),
      GoRoute(
        path: ItemsManagementPage.routePath,
        name: ItemsManagementPage.routeName,
        builder: (context, state) => const ItemsManagementPage(),
      ),
      GoRoute(
        path: ItemPacksManagementPage.routePath,
        name: ItemPacksManagementPage.routeName,
        builder: (context, state) => const ItemPacksManagementPage(),
      ),
      GoRoute(
        path: TimelineManagementPage.routePath,
        name: TimelineManagementPage.routeName,
        builder: (context, state) => const TimelineManagementPage(),
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
        path: ManagementPage.routePath,
        name: ManagementPage.routeName,
        builder: (context, state) => const ManagementPage(),
      ),
      GoRoute(
        path: ItemEditPage.createRoutePath,
        name: ItemEditPage.createRouteName,
        builder: (context, state) =>
            const ItemEditPage(mode: ItemEditMode.create),
      ),
      GoRoute(
        path: ItemEditPage.editRoutePath,
        name: ItemEditPage.editRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ItemEditPage(mode: ItemEditMode.edit, id: id);
        },
      ),
      GoRoute(
        path: TimelineEditPage.timelineNewRoutePath,
        name: TimelineEditPage.timelineNewRouteName,
        builder: (context, state) =>
            const TimelineEditPage(mode: TimelineEditMode.create),
      ),
      GoRoute(
        path: TimelineEditPage.timelineEditRoutePath,
        name: TimelineEditPage.timelineEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TimelineEditPage(mode: TimelineEditMode.edit, id: id);
        },
      ),
      GoRoute(
        path: TimelineMilestoneHistoryPage.routePath,
        name: TimelineMilestoneHistoryPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TimelineMilestoneHistoryPage(timelineId: id ?? 0);
        },
      ),
    ],
  );
});
