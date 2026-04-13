import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/ui/pages/history_page.dart';
import '../features/reminders/ui/pages/home_page.dart';
import '../features/reminders/ui/pages/management_page.dart';
import '../features/reminders/ui/pages/task_timeline_editor_page.dart';

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
        path: TaskTimelineEditorPage.taskNewRoutePath,
        name: TaskTimelineEditorPage.taskNewRouteName,
        builder: (context, state) => const TaskTimelineEditorPage(
          mode: TaskTimelineEditorMode.taskCreate,
        ),
      ),
      GoRoute(
        path: TaskTimelineEditorPage.taskTemplateNewRoutePath,
        name: TaskTimelineEditorPage.taskTemplateNewRouteName,
        builder: (context, state) => const TaskTimelineEditorPage(
          mode: TaskTimelineEditorMode.taskTemplateCreate,
        ),
      ),
      GoRoute(
        path: TaskTimelineEditorPage.taskTemplateEditRoutePath,
        name: TaskTimelineEditorPage.taskTemplateEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.taskTemplateEdit,
            id: id,
          );
        },
      ),
      GoRoute(
        path: TaskTimelineEditorPage.taskEditRoutePath,
        name: TaskTimelineEditorPage.taskEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.taskEdit,
            id: id,
          );
        },
      ),
      GoRoute(
        path: TaskTimelineEditorPage.timelineNewRoutePath,
        name: TaskTimelineEditorPage.timelineNewRouteName,
        builder: (context, state) => const TaskTimelineEditorPage(
          mode: TaskTimelineEditorMode.timelineCreate,
        ),
      ),
      GoRoute(
        path: TaskTimelineEditorPage.timelineEditRoutePath,
        name: TaskTimelineEditorPage.timelineEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.timelineEdit,
            id: id,
          );
        },
      ),
    ],
  );
});
