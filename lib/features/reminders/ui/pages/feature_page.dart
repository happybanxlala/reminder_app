import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/backup_models.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/pack_template.dart';
import '../../presentation/activity_icon_mapper.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/attention_summary_providers.dart';
import '../../providers/backup_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/home_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/pack_template_providers.dart';
import '../../providers/resource_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/attention_service_providers.dart';
import '../../providers/stage_tracker_providers.dart';
import 'feature_management_sections.dart';
import 'stage_tracker_pages.dart';
import '../widgets/editor_form_components.dart';
import '../widgets/item_summary_dialog.dart';
import '../widgets/pack_picker.dart';
import '../widgets/reminder_components.dart';

typedef PreviewDatePicker =
    Future<DateTime?> Function(BuildContext context, DateTime initialDate);

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key});

  static const routeName = 'feature';
  static const routePath = '/feature';

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.manageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(ReminderSpacing.page),
        children: [
          Text(
            '整理你的生活照顧系統',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: ReminderSpacing.section),
          _FeatureEntryCard(
            itemKey: 'items-management',
            title: '要照顧的事',
            subtitle: '清潔、檢查、維護與需要完成的生活責任',
            icon: Icons.checklist_outlined,
            routeName: ItemsManagementPage.routeName,
          ),
          const SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'resources-management',
            title: '資源',
            subtitle: '追蹤庫存、補充與會耗盡的東西',
            icon: Icons.inventory_2_outlined,
            routeName: ResourceManagementPage.routeName,
          ),
          const SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'item-packs-management',
            title: '生活場景',
            subtitle: '用家務、健康、寵物或家庭脈絡分組',
            icon: Icons.category_outlined,
            routeName: ItemPacksManagementPage.routeName,
          ),
          const SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'stage-tracking',
            title: ReminderUiText.stageTrackerTitle,
            subtitle: '追蹤成長、重複階段與重要時間點',
            icon: Icons.auto_graph_outlined,
            routeName: StageTrackerManagementPage.routeName,
          ),
          const SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'item-activity',
            title: ReminderUiText.itemActivityFeatureTitle,
            subtitle: '查看最近處理、延期與跳過的紀錄',
            icon: Icons.dynamic_feed_outlined,
            routeName: ItemActivityPage.routeName,
          ),
          const SizedBox(height: 12),
          _FeatureEntryCard(
            itemKey: 'settings',
            title: ReminderUiText.settingsTitle,
            subtitle: '調整提醒風格、外觀與開發者工具',
            icon: Icons.settings_outlined,
            routeName: SettingsPage.routeName,
          ),
          const SizedBox(height: ReminderSpacing.section),
          ReminderPaperCard(
            backgroundColor: palette.surfaceWarm,
            child: Row(
              children: [
                ReminderIconBubble(
                  backgroundColor: palette.primaryWarmContainer,
                  child: Icon(
                    Icons.favorite_border,
                    color: palette.primaryWarm,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '平靜的系統，讓小責任保持可見。',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static const routeName = 'more';
  static const routePath = '/more';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: MoreContent());
  }
}

class MoreContent extends ConsumerWidget {
  const MoreContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDeveloperSettings = ref.watch(developerSettingsVisibleProvider);
    final reminderTime = ref.watch(notificationReminderTimeProvider);
    return ListView(
      key: const Key('more-page'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          ReminderUiText.moreTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ReminderEditorSection(
          key: const Key('more-common-section'),
          title: ReminderUiText.moreCommonSectionTitle,
          children: [
            _MoreEntryRow(
              key: const Key('more-resources-entry'),
              icon: Icons.inventory_2_outlined,
              title: ReminderUiText.moreResourcesTitle,
              subtitle: ReminderUiText.moreResourcesSubtitle,
              onTap: () => context.pushNamed(ResourceManagementPage.routeName),
            ),
            _MoreEntryRow(
              key: const Key('more-stage-trackers-entry'),
              icon: Icons.auto_graph_outlined,
              title: ReminderUiText.moreStageTrackersTitle,
              subtitle: ReminderUiText.moreStageTrackersSubtitle,
              onTap: () =>
                  context.pushNamed(StageTrackerManagementPage.routeName),
            ),
            _MoreEntryRow(
              key: const Key('more-packs-entry'),
              icon: Icons.category_outlined,
              title: ReminderUiText.morePacksTitle,
              subtitle: ReminderUiText.morePacksSubtitle,
              onTap: () => context.pushNamed(ItemPacksManagementPage.routeName),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReminderEditorSection(
          key: const Key('more-settings-section'),
          title: ReminderUiText.moreSettingsSectionTitle,
          children: [
            _MoreEntryRow(
              key: const Key('more-settings-entry'),
              icon: Icons.settings_outlined,
              title: ReminderUiText.settingsTitle,
              subtitle: ReminderUiText.moreSettingsSubtitle,
              onTap: () => context.pushNamed(SettingsPage.routeName),
            ),
            _MoreEntryRow(
              key: const Key('more-reminder-time-entry'),
              icon: Icons.schedule_outlined,
              title: ReminderUiText.notificationReminderTimeLabel,
              subtitle: reminderTime,
              onTap: () => context.pushNamed(SettingsPage.routeName),
            ),
          ],
        ),
        if (showDeveloperSettings) ...[
          const SizedBox(height: 12),
          ReminderEditorSection(
            key: const Key('more-developer-section'),
            title: ReminderUiText.moreDeveloperSectionTitle,
            children: [
              _MoreEntryRow(
                key: const Key('more-developer-settings-entry'),
                icon: Icons.bug_report_outlined,
                title: ReminderUiText.developerSettingsFeatureTitle,
                subtitle: ReminderUiText.previewDateHelp,
                onTap: () => context.pushNamed(DeveloperSettingsPage.routeName),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MoreEntryRow extends StatelessWidget {
  const _MoreEntryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.primaryWarm),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemActivityPage extends ConsumerStatefulWidget {
  const ItemActivityPage({super.key});

  static const routeName = 'item-activity';
  static const routePath = '/activity';
  static const legacyRoutePath = '/feature/item-activity';

  @override
  ConsumerState<ItemActivityPage> createState() => _ItemActivityPageState();
}

class _ItemActivityPageState extends ConsumerState<ItemActivityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.itemActivityFeatureTitle),
      ),
      body: const ItemActivityContent(),
    );
  }
}

class ItemActivityContent extends ConsumerStatefulWidget {
  const ItemActivityContent({super.key});

  @override
  ConsumerState<ItemActivityContent> createState() =>
      _ItemActivityContentState();
}

class _ItemActivityContentState extends ConsumerState<ItemActivityContent> {
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

    return ReminderRefreshable(
      onRefresh: () =>
          ref.read(itemActivityFeedControllerProvider.notifier).refresh(),
      child: ListView(
        key: const Key('item-activity-page'),
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(ReminderSpacing.page),
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
          const SizedBox(height: ReminderSpacing.listGap),
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
                padding: const EdgeInsets.only(bottom: ReminderSpacing.listGap),
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
        leading: Icon(itemActivityActionIcon(entry.record.actionType)),
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
  const SettingsPage({super.key, this.pickDate});

  static const routeName = 'settings';
  static const routePath = '/feature/settings';
  final PreviewDatePicker? pickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final currentTone = ref.watch(reminderToneProvider);
    final reminderTime = ref.watch(notificationReminderTimeProvider);
    final showDeveloperSettings = ref.watch(developerSettingsVisibleProvider);
    final overrideDate = ref.watch(developerDateOverrideProvider);
    final effectiveDate = ref.watch(effectivePreviewDateProvider);
    final isOverridden = overrideDate != null;
    final databaseVersion = ref.watch(appDatabaseProvider).schemaVersion;

    return ReminderEditorScaffold(
      title: ReminderUiText.settingsTitle,
      body: ListView(
        key: const Key('settings-page'),
        padding: const EdgeInsets.all(12),
        children: [
          ReminderEditorSection(
            key: const Key('settings-general-section'),
            title: ReminderUiText.settingsGeneralSectionTitle,
            children: [
              ReminderEditorPickerRow(
                key: const Key('settings-reminder-tone-row'),
                label: ReminderUiText.reminderToneSettingLabel,
                value: ReminderFormatters.reminderTone(currentTone),
                leading: Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: context.reminderPalette.primaryWarm,
                ),
                onTap: settingsAsync.isLoading
                    ? null
                    : () => _showReminderTonePicker(context, ref, currentTone),
              ),
              Text(
                ReminderFormatters.reminderToneDescription(currentTone),
                key: const Key('reminder-tone-description'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.reminderPalette.textSecondary,
                ),
              ),
              ReminderEditorPickerRow(
                key: const Key('settings-reminder-time-row'),
                label: ReminderUiText.notificationReminderTimeLabel,
                value: reminderTime,
                leading: Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: context.reminderPalette.primaryWarm,
                ),
                onTap: settingsAsync.isLoading
                    ? null
                    : () => _pickReminderTime(context, ref, reminderTime),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReminderEditorSection(
            key: const Key('settings-data-section'),
            title: ReminderUiText.settingsDataSectionTitle,
            children: [
              _SettingsActionRow(
                key: const Key('settings-backup-data-row'),
                label: ReminderUiText.backupDataLabel,
                value: ReminderUiText.backupDataDescription,
                icon: Icons.ios_share_outlined,
                onTap: () => _backupData(context, ref),
              ),
              _SettingsActionRow(
                key: const Key('settings-import-data-row'),
                label: ReminderUiText.importDataLabel,
                value: ReminderUiText.importDataDescription,
                icon: Icons.file_upload_outlined,
                onTap: () => _importData(context, ref),
              ),
              _SettingsActionRow(
                key: const Key('settings-reset-user-data-row'),
                label: ReminderUiText.resetUserDataLabel,
                value: ReminderUiText.resetUserDataDescription,
                icon: Icons.delete_forever_outlined,
                destructive: true,
                onTap: () => _resetUserData(context, ref),
              ),
            ],
          ),
          if (showDeveloperSettings) ...[
            const SizedBox(height: 12),
            ReminderEditorSection(
              key: const Key('settings-developer-section'),
              title: ReminderUiText.settingsDeveloperSectionTitle,
              children: [
                ReminderEditorPickerRow(
                  key: const Key('settings-preview-date-row'),
                  label: ReminderUiText.previewDateSettingLabel,
                  value: ReminderFormatters.date(effectiveDate),
                  leading: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: context.reminderPalette.primaryWarm,
                  ),
                  onTap: () => _pickPreviewDate(context, ref, effectiveDate),
                ),
                Text(
                  ReminderUiText.previewDateHelp,
                  key: const Key('settings-preview-date-help'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.reminderPalette.textSecondary,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('reset-preview-date-button'),
                    onPressed: isOverridden
                        ? () {
                            ref
                                    .read(
                                      developerDateOverrideProvider.notifier,
                                    )
                                    .state =
                                null;
                          }
                        : null,
                    child: const Text(ReminderUiText.clearPreviewDateLabel),
                  ),
                ),
                Text(
                  ReminderUiText.debugInfoSectionTitle,
                  key: const Key('settings-debug-info-title'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.reminderPalette.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-db-version'),
                  label: ReminderUiText.databaseVersionLabel,
                  value: '$databaseVersion',
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-date-source'),
                  label: ReminderUiText.dateSourceLabel,
                  value: isOverridden
                      ? ReminderUiText.dateSourcePreview
                      : ReminderUiText.dateSourceRealToday,
                ),
                _SettingsActionRow(
                  key: const Key('settings-reset-database-row'),
                  label: ReminderUiText.resetDatabaseLabel,
                  value: ReminderUiText.resetDatabaseUnavailable,
                  icon: Icons.delete_forever_outlined,
                  destructive: true,
                  enabled: false,
                  onTap: null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showReminderTonePicker(
    BuildContext context,
    WidgetRef ref,
    ReminderTone currentTone,
  ) async {
    final selected = await showModalBottomSheet<ReminderTone>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReminderUiText.reminderToneSettingLabel,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final tone in ReminderTone.values)
                _SettingsToneOption(
                  tone: tone,
                  selected: tone == currentTone,
                  onTap: () => Navigator.of(sheetContext).pop(tone),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) {
      return;
    }
    await ref.read(settingsRepositoryProvider).updateReminderTone(selected);
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(currentTime),
    );
    if (selected == null) {
      return;
    }
    final value = _formatTimeOfDay(selected);
    await ref
        .read(settingsRepositoryProvider)
        .updateNotificationReminderTime(value);
    await ref.read(attentionSyncServiceProvider).refresh();
  }

  Future<void> _pickPreviewDate(
    BuildContext context,
    WidgetRef ref,
    DateTime initialDate,
  ) async {
    final picker = pickDate ?? DeveloperSettingsPage.showPreviewDatePicker;
    final selected = await picker(context, initialDate);
    if (selected == null) {
      return;
    }
    ref.read(developerDateOverrideProvider.notifier).state =
        normalizePreviewDate(selected);
  }

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(reminderBackupServiceProvider).backupAndShare();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.backupSuccessMessage)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ReminderUiText.backupFailureMessage}: $error'),
        ),
      );
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: ReminderUiText.importConfirmTitle,
      message: ReminderUiText.importConfirmMessage,
      confirmLabel: ReminderUiText.importDataLabel,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      final imported = await ref
          .read(reminderBackupServiceProvider)
          .pickAndImport();
      if (!context.mounted) {
        return;
      }
      if (!imported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ReminderUiText.importCancelledMessage)),
        );
        return;
      }
      _invalidateReminderData(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.importSuccessMessage)),
      );
    } on BackupException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ReminderUiText.importFailureMessage}: $error'),
        ),
      );
    }
  }

  Future<void> _resetUserData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showResetDialog(context);
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(reminderBackupServiceProvider).resetDatabase();
      _invalidateReminderData(ref);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.resetSuccessMessage)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ReminderUiText.resetFailureMessage}: $error'),
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          dialogContext,
                        ).colorScheme.error,
                      )
                    : null,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showResetDialog(BuildContext context) async {
    var input = '';
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setState) => AlertDialog(
              title: const Text(ReminderUiText.resetConfirmTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(ReminderUiText.resetConfirmMessage),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-reset-confirm-field'),
                    decoration: const InputDecoration(
                      labelText: ReminderUiText.resetConfirmInputLabel,
                    ),
                    onChanged: (value) => setState(() => input = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  key: const Key('settings-reset-confirm-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  ),
                  onPressed: input == ReminderUiText.resetDatabaseConfirmWord
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text(ReminderUiText.resetUserDataLabel),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _invalidateReminderData(WidgetRef ref) {
    ref.invalidate(appSettingsProvider);
    ref.invalidate(itemPacksProvider);
    ref.invalidate(activeItemPacksProvider);
    ref.invalidate(itemsProvider);
    ref.invalidate(packManagementItemsProvider);
    ref.invalidate(itemActivityFeedControllerProvider);
    ref.invalidate(resourcesProvider);
    ref.invalidate(managedResourcesProvider);
    ref.invalidate(stageTrackersProvider);
    ref.invalidate(stageRulesProvider);
    ref.invalidate(stageRecordsProvider);
    ref.invalidate(systemStageTrackerProvider);
    ref.invalidate(customPackTemplatesProvider);
    ref.invalidate(packTemplatesProvider);
    ref.invalidate(dangerHomeAttentionEntriesProvider);
    ref.invalidate(warningHomeAttentionEntriesProvider);
    ref.invalidate(dangerHomeEntriesProvider);
    ref.invalidate(warningHomeEntriesProvider);
    ref.invalidate(upcomingStagesProvider);
    ref.invalidate(todayCompletedEntriesProvider);
    ref.invalidate(attentionSummaryProvider);
    ref.invalidate(liveAttentionSummaryProvider);
  }
}

TimeOfDay _parseTimeOfDay(String value) {
  final parts = value.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  return TimeOfDay(
    hour: hour == null || hour < 0 || hour > 23 ? 9 : hour,
    minute: minute == null || minute < 0 || minute > 59 ? 0 : minute,
  );
}

String _formatTimeOfDay(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _SettingsToneOption extends StatelessWidget {
  const _SettingsToneOption({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final ReminderTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('settings-tone-option-${tone.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReminderFormatters.reminderTone(tone),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ReminderFormatters.reminderToneDescription(tone),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 18, color: palette.primaryWarm),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsReadOnlyRow extends StatelessWidget {
  const _SettingsReadOnlyRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ReminderEditorPickerRow(
      label: label,
      value: value,
      readOnly: true,
      showChevron: false,
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.destructive = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool destructive;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final rowColor = destructive
        ? Theme.of(context).colorScheme.error
        : palette.textPrimary;
    final labelColor = destructive
        ? rowColor
        : enabled
        ? rowColor
        : palette.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: labelColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PackManagementContent extends ConsumerWidget {
  const PackManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(activeItemPacksProvider);
    return ReminderRefreshable(
      onRefresh: () async {
        ref.invalidate(activeItemPacksProvider);
        await Future<void>.delayed(Duration.zero);
      },
      child: ListView(
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(ReminderSpacing.page),
        children: [
          _PackTemplateEntryCard(
            onTap: () => _showPackTemplatePicker(context, ref),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('pack-management-add'),
              onPressed: () => _showPackDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text(ReminderUiText.addItemPack),
            ),
          ),
          const SizedBox(height: ReminderSpacing.section),
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
      ),
    );
  }

  Future<void> _showPackDialog(
    BuildContext context,
    WidgetRef ref, {
    ItemPack? pack,
  }) async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => PackFormDialog(
        pack: pack,
        showTemplateEntry: pack == null,
        onCreateFromTemplate: pack == null
            ? () {
                Future<void>.microtask(() {
                  if (context.mounted) {
                    _showPackTemplatePicker(context, ref);
                  }
                });
              }
            : null,
      ),
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
                  PopupMenuButton<_PackManagementMenuAction>(
                    key: Key('pack-overflow-${pack.id}'),
                    tooltip: ReminderUiText.itemActionMenuTitle,
                    onSelected: (action) =>
                        _handleMenuAction(context, ref, action),
                    itemBuilder: (menuContext) => [
                      const PopupMenuItem(
                        value: _PackManagementMenuAction.edit,
                        child: Text(ReminderUiText.editAction),
                      ),
                      const PopupMenuItem(
                        value: _PackManagementMenuAction.saveAsTemplate,
                        child: Text(ReminderUiText.packTemplateSaveAsLabel),
                      ),
                      PopupMenuItem(
                        value: _PackManagementMenuAction.archive,
                        child: Text(
                          ReminderUiText.archiveAction,
                          style: TextStyle(
                            color: Theme.of(menuContext).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _PackManagementMenuAction action,
  ) async {
    switch (action) {
      case _PackManagementMenuAction.edit:
        await _showEditDialog(context, ref);
        return;
      case _PackManagementMenuAction.saveAsTemplate:
        await _showSavePackTemplateDialog(context, ref, pack);
        return;
      case _PackManagementMenuAction.archive:
        await _showArchiveDialog(context, ref);
        return;
    }
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

enum _PackManagementMenuAction { edit, saveAsTemplate, archive }

class _PackTemplateEntryCard extends StatelessWidget {
  const _PackTemplateEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      key: const Key('pack-template-entry-card'),
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(14),
      child: InkWell(
        key: const Key('pack-template-entry-action'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ReminderIconBubble(
              backgroundColor: palette.primaryWarmContainer,
              child: Icon(
                Icons.auto_awesome_outlined,
                color: palette.primaryWarm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ReminderUiText.packTemplatesEntryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ReminderUiText.packTemplatesEntrySubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PackTemplatePickerResult {
  const _PackTemplatePickerResult.template(this.template)
    : createFromExisting = false;

  const _PackTemplatePickerResult.createFromExisting()
    : template = null,
      createFromExisting = true;

  final PackTemplate? template;
  final bool createFromExisting;
}

Future<void> _showPackTemplatePicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await showDialog<_PackTemplatePickerResult>(
    context: context,
    builder: (dialogContext) => const _PackTemplatePickerDialog(),
  );
  if (result == null || !context.mounted) {
    return;
  }
  final template = result.template;
  if (template != null) {
    await _showPackTemplatePreview(context, ref, template);
    return;
  }
  await _showCreateCustomTemplateFromPack(context, ref);
}

Future<void> _showPackTemplatePreview(
  BuildContext context,
  WidgetRef ref,
  PackTemplate template,
) async {
  final repository = ref.read(itemRepositoryProvider);
  final duplicate = await repository.activePackTitleExists(template.packName);
  if (!context.mounted) {
    return;
  }
  final useTemplate = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _PackTemplatePreviewDialog(
      template: template,
      duplicatePackName: duplicate,
    ),
  );
  if (useTemplate != true || !context.mounted) {
    return;
  }
  if (duplicate) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ReminderUiText.packTemplateDuplicateConfirmTitle),
        content: const Text(ReminderUiText.packTemplateDuplicateConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ReminderUiText.packTemplateContinueCreateAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
  }
  final created = await repository.createPackFromTemplate(template);
  if (!context.mounted) {
    return;
  }
  ref.invalidate(activeItemPacksProvider);
  ref.invalidate(itemManagementGroupsProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ReminderUiText.packTemplateCreatedMessage(created.packName),
      ),
      action: SnackBarAction(
        label: ReminderUiText.packTemplateViewAction,
        onPressed: () => context.goNamed(ItemsManagementPage.routeName),
      ),
    ),
  );
}

Future<void> _showCreateCustomTemplateFromPack(
  BuildContext context,
  WidgetRef ref,
) async {
  final packs =
      ref.read(activeItemPacksProvider).valueOrNull ?? const <ItemPack>[];
  final customPacks = packs.where((pack) => !pack.isSystemDefault).toList();
  final selected = await showDialog<ItemPack>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(ReminderUiText.packTemplateCreateFromExistingLabel),
      content: SizedBox(
        width: 420,
        child: customPacks.isEmpty
            ? const Text(ReminderUiText.noItemPacks)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final pack in customPacks)
                      _TemplatePackSelectionRow(pack: pack),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            MaterialLocalizations.of(dialogContext).cancelButtonLabel,
          ),
        ),
      ],
    ),
  );
  if (selected == null || !context.mounted) {
    return;
  }
  await _showSavePackTemplateDialog(context, ref, selected);
}

Future<void> _showSavePackTemplateDialog(
  BuildContext context,
  WidgetRef ref,
  ItemPack pack,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _SavePackTemplateDialog(pack: pack),
  );
}

class _PackTemplatePickerDialog extends ConsumerWidget {
  const _PackTemplatePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(packTemplatesProvider);
    return AlertDialog(
      title: const Text(ReminderUiText.packTemplatePickerTitle),
      content: SizedBox(
        width: 460,
        child: templatesAsync.when(
          data: (templates) {
            final defaults = templates
                .where(
                  (template) =>
                      template.source == PackTemplateSource.defaultTemplate,
                )
                .toList(growable: false);
            final custom = templates
                .where(
                  (template) => template.source == PackTemplateSource.custom,
                )
                .toList(growable: false);
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TemplateSectionTitle(
                    ReminderUiText.packTemplateDefaultSectionTitle,
                  ),
                  for (final template in defaults)
                    _TemplatePickerRow(template: template),
                  const SizedBox(height: 12),
                  _TemplateSectionTitle(
                    ReminderUiText.packTemplateCustomSectionTitle,
                  ),
                  if (custom.isEmpty)
                    const _TemplateEmptyCustomState()
                  else
                    for (final template in custom)
                      _TemplatePickerRow(template: template),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('pack-template-create-from-existing'),
                      onPressed: () => Navigator.of(context).pop(
                        const _PackTemplatePickerResult.createFromExisting(),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        ReminderUiText.packTemplateCreateFromExistingLabel,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

class _TemplateSectionTitle extends StatelessWidget {
  const _TemplateSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.reminderPalette.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TemplatePickerRow extends StatelessWidget {
  const _TemplatePickerRow({required this.template});

  final PackTemplate template;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('pack-template-row-${template.id}'),
          onTap: () => Navigator.of(
            context,
          ).pop(_PackTemplatePickerResult.template(template)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: palette.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              children: [
                Text(template.iconEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.templateName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ReminderUiText.packTemplateItemsCount(
                          template.items.length,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: palette.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateEmptyCustomState extends StatelessWidget {
  const _TemplateEmptyCustomState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pack-template-custom-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.reminderPalette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.reminderPalette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReminderUiText.packTemplateNoCustomTitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            ReminderUiText.packTemplateNoCustomSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.reminderPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackTemplatePreviewDialog extends StatelessWidget {
  const _PackTemplatePreviewDialog({
    required this.template,
    required this.duplicatePackName,
  });

  final PackTemplate template;
  final bool duplicatePackName;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return AlertDialog(
      title: Text(template.templateName),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReminderUiText.packTemplateWillCreateLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ReminderPaperCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: palette.surfaceWarm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ReminderUiText.packTemplatePackNameLabel}：${template.packName}',
                      key: const Key('pack-template-preview-pack-name'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReminderUiText.packTemplateItemsCount(
                        template.items.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (duplicatePackName) ...[
                const SizedBox(height: 8),
                Text(
                  ReminderUiText.packTemplateDuplicatePackWarning,
                  key: const Key('pack-template-duplicate-warning'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              for (final item in template.items)
                _TemplatePreviewItemRow(item: item),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('pack-template-use-button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(ReminderUiText.packTemplatePreviewCreateLabel),
        ),
      ],
    );
  }
}

class _TemplatePreviewItemRow extends StatelessWidget {
  const _TemplatePreviewItemRow({required this.item});

  final PackTemplateItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•'),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  key: Key('pack-template-preview-item-${item.title}'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _templateScheduleSummary(item.config),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.reminderPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _templateScheduleSummary(ItemConfig config) {
  return switch (config) {
    FixedItemConfig fixed => ReminderFormatters.fixedScheduleSummary(fixed),
    StateBasedItemConfig state => ReminderFormatters.attentionPolicySummary(
      state,
    ),
    _ => '',
  };
}

class _TemplatePackSelectionRow extends StatelessWidget {
  const _TemplatePackSelectionRow({required this.pack});

  final ItemPack pack;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('pack-template-source-pack-${pack.id}'),
      leading: Text(pack.iconEmoji),
      title: Text(pack.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(pack),
    );
  }
}

class _SavePackTemplateDialog extends ConsumerStatefulWidget {
  const _SavePackTemplateDialog({required this.pack});

  final ItemPack pack;

  @override
  ConsumerState<_SavePackTemplateDialog> createState() =>
      _SavePackTemplateDialogState();
}

class _SavePackTemplateDialogState
    extends ConsumerState<_SavePackTemplateDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pack.title);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(packManagementItemsProvider);
    final items =
        itemsAsync.valueOrNull
            ?.where((bundle) => bundle.item.packId == widget.pack.id)
            .where((bundle) => bundle.item.status == ItemLifecycleStatus.active)
            .toList(growable: false) ??
        const <ItemBundle>[];
    return AlertDialog(
      title: const Text(ReminderUiText.packTemplateSaveAsTitle),
      content: SizedBox(
        width: 440,
        child: itemsAsync.isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        key: const Key('pack-template-name-field'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: ReminderUiText.packTemplateNameLabel,
                        ),
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ? '請輸入模版名稱' : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ReminderUiText.packTemplateItemsCount(items.length),
                        key: const Key('pack-template-save-item-count'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (items.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ReminderUiText.packTemplateEmptyPackMessage,
                          key: const Key('pack-template-empty-pack-message'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        for (final bundle in items.take(7))
                          Text(
                            '• ${bundle.item.title}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('pack-template-save-button'),
          onPressed: _isSaving || items.isEmpty ? null : _save,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await ref
          .read(packTemplateRepositoryProvider)
          .savePackAsTemplate(
            packId: widget.pack.id,
            templateName: _nameController.text,
          );
      ref.invalidate(packTemplatesProvider);
      ref.invalidate(customPackTemplatesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class DeveloperSettingsPage extends ConsumerWidget {
  const DeveloperSettingsPage({super.key, this.pickDate});

  static const routeName = 'developer-settings';
  static const routePath = '/feature/developer-settings';
  final PreviewDatePicker? pickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsPage(pickDate: pickDate);
  }

  static Future<DateTime?> showPreviewDatePicker(
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
    required this.subtitle,
    required this.icon,
    required this.routeName,
  });

  final String itemKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      onTap: () => _openRoute(context),
      padding: const EdgeInsets.all(18),
      child: Row(
        key: Key('feature-entry-$itemKey'),
        children: [
          ReminderIconBubble(
            size: 64,
            child: Icon(icon, color: palette.primaryWarm, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.primaryWarm),
        ],
      ),
    );
  }

  void _openRoute(BuildContext context) {
    if (routeName == ItemsManagementPage.routeName ||
        routeName == StageTrackerManagementPage.routeName) {
      context.goNamed(routeName);
      return;
    }
    context.pushNamed(routeName);
  }
}
