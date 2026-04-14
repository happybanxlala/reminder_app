import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/ui/pages/history_page.dart';
import '../features/reminders/ui/pages/home_page.dart';
import '../features/reminders/ui/pages/management_page.dart';
import '../features/reminders/ui/pages/task_edit_page.dart';
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
        path: TaskEditPage.taskNewRoutePath,
        name: TaskEditPage.taskNewRouteName,
        builder: (context, state) =>
            const TaskEditPage(mode: TaskEditMode.taskCreate),
      ),
      GoRoute(
        path: TaskEditPage.taskTemplateNewRoutePath,
        name: TaskEditPage.taskTemplateNewRouteName,
        builder: (context, state) =>
            const TaskEditPage(mode: TaskEditMode.taskTemplateCreate),
      ),
      GoRoute(
        path: TaskEditPage.taskTemplateEditRoutePath,
        name: TaskEditPage.taskTemplateEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TaskEditPage(mode: TaskEditMode.taskTemplateEdit, id: id);
        },
      ),
      GoRoute(
        path: TaskEditPage.taskEditRoutePath,
        name: TaskEditPage.taskEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TaskEditPage(mode: TaskEditMode.taskEdit, id: id);
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
