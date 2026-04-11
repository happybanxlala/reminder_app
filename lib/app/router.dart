import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/ui/pages/history_page.dart';
import '../features/reminders/ui/pages/management_page.dart';
import '../features/reminders/ui/pages/reminder_edit_page.dart';
import '../features/reminders/ui/pages/reminders_list_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RemindersListPage.routePath,
    routes: [
      GoRoute(
        path: RemindersListPage.routePath,
        name: RemindersListPage.routeName,
        builder: (context, state) => const RemindersListPage(),
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
        path: ReminderEditPage.taskNewRoutePath,
        name: ReminderEditPage.taskNewRouteName,
        builder: (context, state) =>
            const ReminderEditPage(mode: ReminderFormMode.taskCreate),
      ),
      GoRoute(
        path: ReminderEditPage.taskTemplateNewRoutePath,
        name: ReminderEditPage.taskTemplateNewRouteName,
        builder: (context, state) =>
            const ReminderEditPage(mode: ReminderFormMode.taskTemplateCreate),
      ),
      GoRoute(
        path: ReminderEditPage.taskTemplateEditRoutePath,
        name: ReminderEditPage.taskTemplateEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ReminderEditPage(
            mode: ReminderFormMode.taskTemplateEdit,
            id: id,
          );
        },
      ),
      GoRoute(
        path: ReminderEditPage.taskEditRoutePath,
        name: ReminderEditPage.taskEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ReminderEditPage(mode: ReminderFormMode.taskEdit, id: id);
        },
      ),
      GoRoute(
        path: ReminderEditPage.timelineNewRoutePath,
        name: ReminderEditPage.timelineNewRouteName,
        builder: (context, state) =>
            const ReminderEditPage(mode: ReminderFormMode.timelineCreate),
      ),
      GoRoute(
        path: ReminderEditPage.timelineEditRoutePath,
        name: ReminderEditPage.timelineEditRouteName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ReminderEditPage(mode: ReminderFormMode.timelineEdit, id: id);
        },
      ),
    ],
  );
});
