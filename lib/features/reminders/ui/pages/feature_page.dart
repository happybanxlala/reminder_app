import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/reminder_dao.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item_pack.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/settings_providers.dart';
import 'feature_management_sections.dart';
import 'stage_tracker_pages.dart';
import '../widgets/item_summary_dialog.dart';
import '../widgets/pack_picker.dart';

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
            itemKey: 'resources-management',
            title: '資源管理',
            icon: Icons.inventory_2_outlined,
            routeName: ResourceManagementPage.routeName,
          ),
          SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'stage-trackers',
            title: ReminderUiText.stageTrackerManagementFeatureTitle,
            icon: Icons.auto_graph_outlined,
            routeName: StageTrackerManagementPage.routeName,
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
  static const routePath = '/manage';
  static const legacyRoutePath = '/feature/items-management';

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
        title: const Text(ReminderUiText.itemPacksManagementFeatureTitle),
      ),
      body: const PackManagementContent(),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';
  static const routePath = '/feature/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final currentTone = ref.watch(reminderToneProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.userSettingsFeatureTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            ReminderUiText.reminderToneSettingsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(ReminderUiText.reminderToneSettingsDescription),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReminderTone>(
            key: const Key('reminder-tone-field'),
            initialValue: currentTone,
            decoration: const InputDecoration(
              labelText: ReminderUiText.reminderToneSettingsTitle,
            ),
            items: ReminderTone.values
                .map(
                  (tone) => DropdownMenuItem(
                    value: tone,
                    child: Text(ReminderFormatters.reminderTone(tone)),
                  ),
                )
                .toList(growable: false),
            onChanged: settingsAsync.isLoading
                ? null
                : (value) async {
                    if (value == null) {
                      return;
                    }
                    await ref
                        .read(settingsRepositoryProvider)
                        .updateReminderTone(value);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            ReminderFormatters.reminderToneDescription(currentTone),
            key: const Key('reminder-tone-description'),
          ),
          const SizedBox(height: 24),
          ListTile(
            key: const Key('pack-management-settings-entry'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.category_outlined),
            title: const Text(ReminderUiText.itemPacksManagementFeatureTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(ItemPacksManagementPage.routeName),
          ),
        ],
      ),
    );
  }
}

class PackManagementContent extends ConsumerWidget {
  const PackManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(activeItemPacksProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('pack-management-add'),
            onPressed: () => _showPackDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text(ReminderUiText.addItemPack),
          ),
        ),
        const SizedBox(height: 16),
        packsAsync.when(
          data: (packs) {
            if (packs.isEmpty) {
              return const Text(ReminderUiText.noItemPacks);
            }
            final customPacks = packs
                .where((pack) => !pack.isSystemDefault)
                .toList(growable: false);
            return Column(
              children: [
                for (final pack in packs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PackManagementTile(
                      pack: pack,
                      customPacks: customPacks,
                    ),
                  ),
              ],
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Future<void> _showPackDialog(
    BuildContext context,
    WidgetRef ref, {
    ItemPack? pack,
  }) async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => PackFormDialog(pack: pack),
    );
    if (input == null || !context.mounted) {
      return;
    }
    final repository = ref.read(itemRepositoryProvider);
    if (pack == null) {
      await repository.createPack(input);
    } else {
      await repository.updatePack(pack.id, input);
    }
  }
}

class _PackManagementTile extends ConsumerWidget {
  const _PackManagementTile({required this.pack, required this.customPacks});

  final ItemPack pack;
  final List<ItemPack> customPacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customIndex = customPacks.indexWhere((item) => item.id == pack.id);
    final isSystemDefault = pack.isSystemDefault;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('pack-management-pack-${pack.id}'),
        leading: Text(
          pack.iconEmoji,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        title: Text(pack.title),
        subtitle: Text(
          isSystemDefault ? ReminderUiText.systemDefaultPackLabel : '自訂生活場景',
        ),
        trailing: isSystemDefault
            ? null
            : Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    key: Key('pack-up-${pack.id}'),
                    onPressed: customIndex > 0
                        ? () => ref
                              .read(itemRepositoryProvider)
                              .movePackUp(pack.id)
                        : null,
                    tooltip: '上',
                    icon: const Icon(Icons.keyboard_arrow_up),
                  ),
                  IconButton(
                    key: Key('pack-down-${pack.id}'),
                    onPressed:
                        customIndex >= 0 && customIndex < customPacks.length - 1
                        ? () => ref
                              .read(itemRepositoryProvider)
                              .movePackDown(pack.id)
                        : null,
                    tooltip: '下',
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  IconButton(
                    key: Key('pack-edit-${pack.id}'),
                    onPressed: () => _showEditDialog(context, ref),
                    tooltip: ReminderUiText.editAction,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    key: Key('pack-archive-${pack.id}'),
                    onPressed: () => _showArchiveDialog(context, ref),
                    tooltip: ReminderUiText.archiveAction,
                    icon: const Icon(Icons.archive_outlined),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => PackFormDialog(pack: pack),
    );
    if (input == null || !context.mounted) {
      return;
    }
    await ref.read(itemRepositoryProvider).updatePack(pack.id, input);
  }

  Future<void> _showArchiveDialog(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(itemRepositoryProvider);
    final contentCount = await repository.countPackManagedContents(pack.id);
    if (!context.mounted) {
      return;
    }
    if (contentCount == 0) {
      await repository.archivePackWithContents(pack.id);
      return;
    }
    final action = await showDialog<_ArchivePackAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ReminderUiText.archivePackConfirmTitle),
        content: const Text(ReminderUiText.archivePackConfirmMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ArchivePackAction.cancel),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ArchivePackAction.move),
            child: const Text('移到「一般」'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ArchivePackAction.archive),
            child: const Text('一起封存內容'),
          ),
        ],
      ),
    );
    if (action == null || action == _ArchivePackAction.cancel) {
      return;
    }
    switch (action) {
      case _ArchivePackAction.archive:
        await repository.archivePackWithContents(pack.id);
        return;
      case _ArchivePackAction.move:
        await repository.archivePackAndMoveContentsToDefault(pack.id);
        return;
      case _ArchivePackAction.cancel:
        return;
    }
  }
}

enum _ArchivePackAction { archive, move, cancel }

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
