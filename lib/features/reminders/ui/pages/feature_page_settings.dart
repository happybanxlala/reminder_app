part of 'feature_page.dart';

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
          const SizedBox(height: 12),
          ReminderEditorSection(
            key: const Key('settings-shared-pack-section'),
            title: ReminderUiText.sharedPackLabel,
            children: [
              _SettingsActionRow(
                key: const Key('settings-enter-invite-code-row'),
                label: ReminderUiText.sharedPackEnterInviteCodeLabel,
                value: ReminderUiText.sharedPackUnavailableLabel,
                icon: Icons.group_add_outlined,
                onTap: () => _showSharedPackJoinShell(context),
              ),
            ],
          ),
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

  Future<void> _showSharedPackJoinShell(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => const _SharedPackJoinShellDialog(),
    );
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

class _SharedPackJoinShellDialog extends ConsumerStatefulWidget {
  const _SharedPackJoinShellDialog();

  @override
  ConsumerState<_SharedPackJoinShellDialog> createState() =>
      _SharedPackJoinShellDialogState();
}

class _SharedPackJoinShellDialogState
    extends ConsumerState<_SharedPackJoinShellDialog> {
  final _inviteCodeController = TextEditingController();

  var _isPreviewing = false;
  var _isJoining = false;
  SharedPackInvitePreviewUiModel? _preview;
  String? _errorMessage;
  String? _joinMessage;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final controller = ref.watch(sharedPackUiControllerProvider);
    final availability = controller.availability;
    final canUseRemote = availability.isEnabled;
    final normalizedCode = normalizeSharedPackInviteCode(
      _inviteCodeController.text,
    );
    final canPreview =
        canUseRemote && normalizedCode.isNotEmpty && !_isPreviewing;
    final canJoin =
        canUseRemote &&
        _preview?.isJoinable == true &&
        normalizedCode.isNotEmpty &&
        !_isJoining;
    return AlertDialog(
      title: const Text(ReminderUiText.sharedPackJoinShellTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(ReminderUiText.sharedPackJoinShellMessage),
            const SizedBox(height: 12),
            TextField(
              key: const Key('shared-pack-invite-code-field'),
              controller: _inviteCodeController,
              enabled: canUseRemote,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: ReminderUiText.sharedPackInviteCodeFieldLabel,
                hintText: ReminderUiText.sharedPackInviteCodePreviewValue,
              ),
              onChanged: (value) {
                setState(() {
                  _preview = null;
                  _joinMessage = null;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              canUseRemote
                  ? ReminderUiText.sharedPackJoinInputHelp
                  : availability.reason,
              key: const Key('shared-pack-join-setup-required-message'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
            ),
            if (_isPreviewing) ...[
              const SizedBox(height: 12),
              const Row(
                key: Key('shared-pack-preview-loading'),
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(ReminderUiText.sharedPackPreviewLoadingMessage),
                ],
              ),
            ],
            if (_preview != null) ...[
              const SizedBox(height: 12),
              ReminderPaperCard(
                key: const Key('shared-pack-preview-result'),
                padding: const EdgeInsets.all(12),
                backgroundColor: palette.surfaceWarm,
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, color: palette.primaryWarm),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _preview!.packName ??
                            ReminderUiText.sharedPackPreviewUnavailableMessage,
                      ),
                    ),
                    if (_preview!.isJoinable)
                      Icon(Icons.check, color: palette.primaryWarm),
                  ],
                ),
              ),
            ],
            if (_joinMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _joinMessage!,
                key: const Key('shared-pack-join-success'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                key: const Key('shared-pack-join-error'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
        TextButton(
          key: const Key('shared-pack-preview-invite-button'),
          onPressed: canPreview ? _previewInvite : null,
          child: const Text(ReminderUiText.sharedPackPreviewInviteLabel),
        ),
        FilledButton(
          key: const Key('shared-pack-join-button'),
          onPressed: canJoin ? _joinByInvite : null,
          child: const Text(ReminderUiText.sharedPackJoinLabel),
        ),
      ],
    );
  }

  Future<void> _previewInvite() async {
    final normalizedCode = _normalizeFieldValue();
    setState(() {
      _isPreviewing = true;
      _errorMessage = null;
      _joinMessage = null;
      _preview = null;
    });

    final result = await ref
        .read(sharedPackUiControllerProvider)
        .previewInvite(inviteCode: normalizedCode);
    if (!mounted) {
      return;
    }

    setState(() {
      _isPreviewing = false;
      if (result.isSuccess) {
        final preview = result.requireValue;
        _preview = preview;
        if (!preview.isJoinable) {
          _errorMessage = ReminderUiText.sharedPackPreviewUnavailableMessage;
        }
      } else {
        _errorMessage = result.error!.message;
      }
    });
  }

  Future<void> _joinByInvite() async {
    final normalizedCode = _normalizeFieldValue();
    setState(() {
      _isJoining = true;
      _errorMessage = null;
      _joinMessage = null;
    });

    final result = await ref
        .read(sharedPackUiControllerProvider)
        .joinByInvite(inviteCode: normalizedCode);
    if (!mounted) {
      return;
    }

    setState(() {
      _isJoining = false;
      if (result.isSuccess) {
        _joinMessage = ReminderUiText.sharedPackJoinSuccessMessage(
          result.requireValue.packName,
        );
      } else {
        _errorMessage = result.error!.message;
      }
    });
  }

  String _normalizeFieldValue() {
    final normalized = normalizeSharedPackInviteCode(
      _inviteCodeController.text,
    );
    final grouped = groupSharedPackInviteCode(normalized);
    _inviteCodeController.value = TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
    return normalized;
  }
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
