import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        path: ReminderEditPage.newRoutePath,
        name: ReminderEditPage.newRouteName,
        builder: (context, state) => const ReminderEditPage(),
      ),
      GoRoute(
        path: ReminderEditPage.editRoutePath,
        name: ReminderEditPage.editRouteName,
        builder: (context, state) {
          final reminderId = int.tryParse(state.pathParameters['id'] ?? '');
          return ReminderEditPage(
            mode: ReminderFormMode.reminderEdit,
            reminderId: reminderId,
          );
        },
      ),
      GoRoute(
        path: ReminderEditPage.recurringNewRoutePath,
        name: ReminderEditPage.recurringNewRouteName,
        builder: (context, state) =>
            const ReminderEditPage(mode: ReminderFormMode.seriesCreate),
      ),
      GoRoute(
        path: ReminderEditPage.recurringEditRoutePath,
        name: ReminderEditPage.recurringEditRouteName,
        builder: (context, state) {
          final seriesId = int.tryParse(state.pathParameters['id'] ?? '');
          return ReminderEditPage(
            mode: ReminderFormMode.seriesEdit,
            seriesId: seriesId,
          );
        },
      ),
    ],
  );
});
