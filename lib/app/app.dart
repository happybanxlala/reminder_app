import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/reminders/presentation/text/reminder_ui_text.dart';
import 'app_bootstrap.dart';
import 'router.dart';
import 'theme/reminder_theme.dart';

class ReminderApp extends ConsumerWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return AppBootstrap(
      child: MaterialApp.router(
        title: ReminderUiText.appTitle,
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
