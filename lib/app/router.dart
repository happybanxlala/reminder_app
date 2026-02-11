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
          final reminderId = state.pathParameters['id'] ?? '';
          return ReminderEditPage(reminderId: reminderId);
        },
      ),
    ],
  );
});
