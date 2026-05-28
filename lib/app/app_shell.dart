import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/presentation/text/reminder_ui_text.dart';
import '../features/reminders/ui/pages/item_edit_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(navigationShell.currentIndex))),
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
            label: ReminderUiText.bottomNavHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: ReminderUiText.bottomNavItems,
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: ReminderUiText.bottomNavActivity,
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: ReminderUiText.bottomNavMore,
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    return switch (index) {
      0 => ReminderUiText.bottomNavHome,
      1 => ReminderUiText.bottomNavItems,
      2 => ReminderUiText.bottomNavActivity,
      3 => ReminderUiText.bottomNavMore,
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
        child: const Icon(Icons.add_circle_outline),
      ),
      2 || 3 => const SizedBox.shrink(),
      _ => const SizedBox.shrink(),
    };
  }
}
