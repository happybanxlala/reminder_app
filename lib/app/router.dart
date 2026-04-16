import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/ui/pages/history_page.dart';
import '../features/reminders/ui/pages/home_page.dart';
import '../features/reminders/ui/pages/management_page.dart';
import '../features/reminders/ui/pages/responsibility_item_edit_page.dart';
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
        path: ManagementPage.routePath,
        name: ManagementPage.routeName,
        builder: (context, state) => const ManagementPage(),
      ),
      GoRoute(
        path: HistoryPage.routePath,
        name: HistoryPage.routeName,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: ResponsibilityItemEditPage.createRoutePath,
        name: ResponsibilityItemEditPage.createRouteName,
        builder: (context, state) => const ResponsibilityItemEditPage(
          mode: ResponsibilityItemEditMode.create,
        ),
      ),
      GoRoute(
        path: ResponsibilityItemEditPage.editRoutePath,
        name: ResponsibilityItemEditPage.editRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ResponsibilityItemEditPage(
            mode: ResponsibilityItemEditMode.edit,
            id: id,
          );
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
