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
import '../../domain/shared_pack.dart';
import '../../presentation/activity_icon_mapper.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/attention_summary_providers.dart';
import '../../providers/backup_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/home_providers.dart';
import '../../providers/identity_providers.dart';
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

part 'feature_page_more.dart';
part 'feature_page_activity.dart';
part 'feature_page_settings.dart';
part 'feature_page_packs.dart';

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
