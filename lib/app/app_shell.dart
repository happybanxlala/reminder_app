import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/presentation/text/reminder_ui_text.dart';
import '../features/reminders/ui/pages/feature_page.dart';
import '../features/reminders/ui/pages/item_edit_page.dart';
import '../features/reminders/ui/pages/timeline_edit_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(navigationShell.currentIndex)),
        actions: [
          IconButton(
            key: const Key('feature-button'),
            onPressed: () => context.pushNamed(FeaturePage.routeName),
            icon: const Icon(Icons.widgets_outlined),
            tooltip: ReminderUiText.featureAction,
          ),
        ],
      ),
      body: navigationShell,
      floatingActionButton: _FabForBranch(index: navigationShell.currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: ReminderUiText.bottomNavToday,
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: ReminderUiText.bottomNavManage,
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: ReminderUiText.bottomNavTimeline,
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    return switch (index) {
      0 => ReminderUiText.bottomNavToday,
      1 => ReminderUiText.manageTitle,
      2 => ReminderUiText.timelineTitle,
      _ => ReminderUiText.appTitle,
    };
  }
}

class _FabForBranch extends StatelessWidget {
  const _FabForBranch({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 || 1 => FloatingActionButton(
        key: Key(index == 0 ? 'home-add-item-fab' : 'manage-add-item-fab'),
        onPressed: () => context.pushNamed(ItemEditPage.createRouteName),
        tooltip: ReminderUiText.addItem,
        child: const Icon(Icons.add_task),
      ),
      2 => FloatingActionButton(
        key: const Key('timeline-add-fab'),
        onPressed: () =>
            context.pushNamed(TimelineEditPage.timelineNewRouteName),
        tooltip: ReminderUiText.addTimeline,
        child: const Icon(Icons.add),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
