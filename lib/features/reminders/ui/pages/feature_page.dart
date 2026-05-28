import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item_pack.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/database_providers.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
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

    return ListView(
      key: const Key('item-activity-page'),
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
              child: _ActivityEntryCard(entry: entry, previewDate: previewDate),
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
        leading: const Icon(Icons.history_outlined),
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
    final systemTrackerAsync = ref.watch(systemStageTrackerProvider);
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
              _SettingsSwitchRow(
                key: const Key('settings-show-system-tracker-row'),
                label: ReminderUiText.showSystemStageTrackerSetting,
                value: systemTrackerAsync.maybeWhen(
                  data: (tracker) => !tracker.isHidden,
                  orElse: () => true,
                ),
                enabled: !systemTrackerAsync.isLoading,
                icon: Icons.auto_graph_outlined,
                onChanged: (value) => _setSystemStageTrackerVisible(ref, value),
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

  Future<void> _setSystemStageTrackerVisible(
    WidgetRef ref,
    bool visible,
  ) async {
    final repository = ref.read(stageTrackerRepositoryProvider);
    if (visible) {
      await repository.showSystemStageTracker();
    } else {
      await repository.hideSystemStageTracker();
    }
    ref.invalidate(systemStageTrackerProvider);
    ref.invalidate(stageTrackersProvider);
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

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.primaryWarm),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            key: const Key('settings-show-system-tracker-switch'),
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
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
    return ListView(
      padding: const EdgeInsets.all(ReminderSpacing.page),
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

enum _PackManagementMenuAction { edit, archive }

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
