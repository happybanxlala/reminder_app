import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/item_timeline_dao.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import 'feature_management_sections.dart';
import '../widgets/item_summary_dialog.dart';

typedef PreviewDatePicker =
    Future<DateTime?> Function(BuildContext context, DateTime initialDate);

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

class ItemActivityPage extends ConsumerStatefulWidget {
  const ItemActivityPage({super.key});

  static const routeName = 'item-activity';
  static const routePath = '/feature/item-activity';

  @override
  ConsumerState<ItemActivityPage> createState() => _ItemActivityPageState();
}

class _ItemActivityPageState extends ConsumerState<ItemActivityPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final state = ref.watch(itemActivityFeedControllerProvider);

    if (_searchController.text != state.query) {
      _searchController.value = _searchController.value.copyWith(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
        composing: TextRange.empty,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.itemActivityFeatureTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('item-activity-search-field'),
            controller: _searchController,
            onChanged: (value) {
              ref
                  .read(itemActivityFeedControllerProvider.notifier)
                  .setQuery(value);
            },
            decoration: InputDecoration(
              hintText: ReminderUiText.itemActivitySearchHint,
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: state.query.trim().isEmpty
                  ? null
                  : IconButton(
                      key: const Key('item-activity-search-clear'),
                      onPressed: () {
                        ref
                            .read(itemActivityFeedControllerProvider.notifier)
                            .setQuery('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null && state.items.isEmpty)
            Text(state.errorMessage!)
          else if (state.items.isEmpty)
            Text(
              state.isSearching
                  ? ReminderUiText.noActivitySearchResults
                  : ReminderUiText.noRecentActivity,
            )
          else ...[
            ...state.items.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityEntryCard(
                  entry: entry,
                  previewDate: previewDate,
                ),
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(state.errorMessage!),
            ],
            if (state.canLoadMoreAttempt) ...[
              const SizedBox(height: 4),
              Center(
                child: state.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )
                    : OutlinedButton(
                        key: const Key('item-activity-load-more'),
                        onPressed: () {
                          ref
                              .read(itemActivityFeedControllerProvider.notifier)
                              .loadMore();
                        },
                        child: const Text(ReminderUiText.loadMoreAction),
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActivityEntryCard extends StatelessWidget {
  const _ActivityEntryCard({required this.entry, required this.previewDate});

  final ItemActivityEntry entry;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final packTitle = entry.pack.isSystemDefault
        ? ReminderUiText.unassignedPackTitle
        : entry.pack.title;
    final actionLabel = ReminderFormatters.itemActionType(
      entry.record.actionType,
    );

    return Card(
      child: ListTile(
        key: Key('item-activity-entry-${entry.record.id}'),
        onTap: () => showItemSummaryDialog(
          context,
          entry.bundle,
          previewDate: previewDate,
        ),
        title: Text(entry.itemTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(actionLabel),
            Text(
              '${ReminderUiText.itemActivityTimeLabel}：${ReminderFormatters.dateTime(entry.record.updatedAt)}',
            ),
            Text('${ReminderUiText.itemActivityPackLabel}：$packTitle'),
          ],
        ),
      ),
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
      body: const ItemsManagementContent(),
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
        title: const Text(ReminderUiText.itemsManagementFeatureTitle),
      ),
      body: const ItemsManagementContent(),
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

class DeveloperSettingsPage extends ConsumerWidget {
  const DeveloperSettingsPage({super.key, this.pickDate});

  static const routeName = 'developer-settings';
  static const routePath = '/feature/developer-settings';
  final PreviewDatePicker? pickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrideDate = ref.watch(developerDateOverrideProvider);
    final effectiveDate = ref.watch(effectivePreviewDateProvider);
    final isOverridden = overrideDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.developerSettingsFeatureTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ReminderUiText.developerPreviewDateTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    key: const Key('developer-preview-date-tile'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      ReminderUiText.developerPreviewDateCurrentLabel,
                    ),
                    subtitle: Text(ReminderFormatters.date(effectiveDate)),
                  ),
                  ListTile(
                    key: const Key('developer-preview-status-tile'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      ReminderUiText.developerPreviewDateOverrideStatusLabel,
                    ),
                    subtitle: Text(
                      isOverridden
                          ? ReminderUiText.developerPreviewDateOverrideEnabled
                          : ReminderUiText.developerPreviewDateOverrideDisabled,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        key: const Key('pick-preview-date-button'),
                        onPressed: () =>
                            _pickPreviewDate(context, ref, effectiveDate),
                        child: const Text(
                          ReminderUiText.developerPreviewDatePickAction,
                        ),
                      ),
                      OutlinedButton(
                        key: const Key('reset-preview-date-button'),
                        onPressed: isOverridden
                            ? () {
                                ref
                                        .read(
                                          developerDateOverrideProvider
                                              .notifier,
                                        )
                                        .state =
                                    null;
                              }
                            : null,
                        child: const Text(
                          ReminderUiText.developerPreviewDateResetAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPreviewDate(
    BuildContext context,
    WidgetRef ref,
    DateTime initialDate,
  ) async {
    final picker = pickDate ?? _showPreviewDatePicker;
    final selected = await picker(context, initialDate);
    if (selected == null) {
      return;
    }
    ref.read(developerDateOverrideProvider.notifier).state =
        normalizePreviewDate(selected);
  }

  static Future<DateTime?> _showPreviewDatePicker(
    BuildContext context,
    DateTime initialDate,
  ) {
    final today = normalizePreviewDate(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year + 10),
      currentDate: today,
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
