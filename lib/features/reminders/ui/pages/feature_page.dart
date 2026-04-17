import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/text/reminder_ui_text.dart';
import 'feature_management_sections.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key});

  static const routeName = 'feature';
  static const routePath = '/feature';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.featurePageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FeatureEntryCard(
            itemKey: 'item-activity',
            title: ReminderUiText.itemActivityFeatureTitle,
            icon: Icons.dynamic_feed_outlined,
            routeName: ItemActivityPage.routeName,
          ),
          SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'items-management',
            title: ReminderUiText.itemsManagementFeatureTitle,
            icon: Icons.checklist_rtl_outlined,
            routeName: ItemsManagementPage.routeName,
          ),
          SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'item-packs-management',
            title: ReminderUiText.itemPacksManagementFeatureTitle,
            icon: Icons.inventory_2_outlined,
            routeName: ItemPacksManagementPage.routeName,
          ),
          SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'timeline-management',
            title: ReminderUiText.timelineManagementFeatureTitle,
            icon: Icons.timeline_outlined,
            routeName: TimelineManagementPage.routeName,
          ),
          SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'settings',
            title: ReminderUiText.userSettingsFeatureTitle,
            icon: Icons.settings_outlined,
            routeName: SettingsPage.routeName,
          ),
          SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'developer-settings',
            title: ReminderUiText.developerSettingsFeatureTitle,
            icon: Icons.code_outlined,
            routeName: DeveloperSettingsPage.routeName,
          ),
        ],
      ),
    );
  }
}

class ItemActivityPage extends StatelessWidget {
  const ItemActivityPage({super.key});

  static const routeName = 'item-activity';
  static const routePath = '/feature/item-activity';

  @override
  Widget build(BuildContext context) {
    return const _FeaturePlaceholderPage(
      title: ReminderUiText.itemActivityFeatureTitle,
      message: ReminderUiText.itemActivityPlaceholderMessage,
    );
  }
}

class ItemsManagementPage extends StatelessWidget {
  const ItemsManagementPage({super.key});

  static const routeName = 'items-management';
  static const routePath = '/feature/items-management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.itemsManagementFeatureTitle),
      ),
      body: const DefaultItemsManagementContent(),
    );
  }
}

class ItemPacksManagementPage extends StatelessWidget {
  const ItemPacksManagementPage({super.key});

  static const routeName = 'item-packs-management';
  static const routePath = '/feature/item-packs-management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ReminderUiText.itemPacksManagementFeatureTitle),
      ),
      body: const ItemPacksManagementContent(),
    );
  }
}

class TimelineManagementPage extends StatelessWidget {
  const TimelineManagementPage({super.key});

  static const routeName = 'timeline-management';
  static const routePath = '/feature/timeline-management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ReminderUiText.timelineManagementFeatureTitle),
      ),
      body: const TimelineManagementContent(),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';
  static const routePath = '/feature/settings';

  @override
  Widget build(BuildContext context) {
    return const _FeaturePlaceholderPage(
      title: ReminderUiText.userSettingsFeatureTitle,
      message: ReminderUiText.userSettingsPlaceholderMessage,
    );
  }
}

class DeveloperSettingsPage extends StatelessWidget {
  const DeveloperSettingsPage({super.key});

  static const routeName = 'developer-settings';
  static const routePath = '/feature/developer-settings';

  @override
  Widget build(BuildContext context) {
    return const _FeaturePlaceholderPage(
      title: ReminderUiText.developerSettingsFeatureTitle,
      message: ReminderUiText.developerSettingsPlaceholderMessage,
    );
  }
}

class _FeatureEntryCard extends StatelessWidget {
  const _FeatureEntryCard({
    required this.itemKey,
    required this.title,
    required this.icon,
    required this.routeName,
  });

  final String itemKey;
  final String title;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: Key('feature-entry-$itemKey'),
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(routeName),
      ),
    );
  }
}

class _FeaturePlaceholderPage extends StatelessWidget {
  const _FeaturePlaceholderPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
