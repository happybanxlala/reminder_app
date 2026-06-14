part of 'feature_page.dart';

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
