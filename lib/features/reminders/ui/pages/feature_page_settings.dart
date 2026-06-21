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
    final currentUserAsync = ref.watch(currentAppUserProvider);
    final supabaseRuntimeStatus = ref.watch(supabaseRuntimeStatusProvider);
    final remotePocState = ref.watch(remotePocControllerProvider);
    final remotePocTargetPackAsync = ref.watch(
      remotePocTargetSharedPackProvider,
    );
    final remotePocTargetPack = remotePocTargetPackAsync.maybeWhen(
      data: (pack) => pack,
      orElse: () => null,
    );
    final remotePocPackMappingAsync = remotePocTargetPack == null
        ? null
        : ref.watch(remotePocPackMappingProvider(remotePocTargetPack.id));
    final remotePocPackMapping = remotePocPackMappingAsync?.maybeWhen(
      data: (mapping) => mapping,
      orElse: () => null,
    );
    final remotePocFirstMappedItemAsync = remotePocTargetPack == null
        ? null
        : ref.watch(remotePocFirstMappedItemProvider(remotePocTargetPack.id));
    final remotePocFirstMappedItem = remotePocFirstMappedItemAsync?.maybeWhen(
      data: (bundle) => bundle,
      orElse: () => null,
    );

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
                  key: const Key('settings-debug-device-data-label'),
                  label: ReminderUiText.deviceDataLabel,
                  value: currentUserAsync.maybeWhen(
                    data: (user) => user.displayName,
                    orElse: () => ReminderUiText.loadingLabel,
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-local-user-id'),
                  label: ReminderUiText.localUserIdLabel,
                  value: currentUserAsync.maybeWhen(
                    data: (user) => _shortUserId(user.id),
                    orElse: () => '-',
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-identity-kind'),
                  label: ReminderUiText.identityKindLabel,
                  value: currentUserAsync.maybeWhen(
                    data: (user) => _identityKindLabel(user.identityKind),
                    orElse: () => '-',
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-binding-status'),
                  label: ReminderUiText.identityBindingStatusLabel,
                  value: currentUserAsync.maybeWhen(
                    data: (user) => user.remoteUserId == null
                        ? ReminderUiText.identityNotBoundLabel
                        : ReminderUiText.identityBoundLabel,
                    orElse: () => '-',
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-remote-provider'),
                  label: ReminderUiText.remoteProviderLabel,
                  value: currentUserAsync.maybeWhen(
                    data: (user) => user.remoteProvider == null
                        ? '-'
                        : _remoteProviderLabel(user.remoteProvider!),
                    orElse: () => '-',
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-remote-user-id'),
                  label: ReminderUiText.remoteUserIdLabel,
                  value: currentUserAsync.maybeWhen(
                    data: (user) => user.remoteUserId == null
                        ? '-'
                        : _shortUserId(user.remoteUserId!),
                    orElse: () => '-',
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-debug-supabase-config-status'),
                  label: ReminderUiText.supabaseConfigStatusLabel,
                  value: _supabaseRuntimeStatusLabel(supabaseRuntimeStatus),
                ),
                Text(
                  ReminderUiText.supabaseRemotePocSectionTitle,
                  key: const Key('settings-remote-poc-title'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.reminderPalette.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-shared-pack'),
                  label: ReminderUiText.remotePocSharedPackLabel,
                  value: _remotePocSharedPackValue(remotePocTargetPack),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-remote-pack'),
                  label: ReminderUiText.remotePocRemotePackLabel,
                  value: remotePocPackMappingAsync?.isLoading ?? false
                      ? ReminderUiText.loadingLabel
                      : remotePocPackMapping == null
                      ? ReminderUiText.remotePocNoRemoteMapping
                      : _shortUserId(remotePocPackMapping.remoteEntityId),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-mapped-item'),
                  label: ReminderUiText.remotePocMappedItemLabel,
                  value: remotePocFirstMappedItemAsync?.isLoading ?? false
                      ? ReminderUiText.loadingLabel
                      : remotePocFirstMappedItem == null
                      ? ReminderUiText.remotePocNotCreated
                      : remotePocFirstMappedItem.item.title,
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-last-operation'),
                  label: ReminderUiText.remotePocLastOperationLabel,
                  value:
                      remotePocState.lastMessage ??
                      ReminderUiText.remotePocNotRun,
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-snapshot-summary'),
                  label: ReminderUiText.remotePocSnapshotLabel,
                  value: _remotePocSnapshotSummaryValue(
                    remotePocState.snapshotSummary,
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-invite-code'),
                  label: ReminderUiText.remotePocInviteCodeLabel,
                  value:
                      remotePocState.lastCreatedInviteCode ??
                      ReminderUiText.remotePocNotCreated,
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-invite-expires'),
                  label: ReminderUiText.remotePocInviteExpiresLabel,
                  value: _remotePocDateTimeValue(
                    remotePocState.lastInviteExpiresAt,
                  ),
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-invite-max-uses'),
                  label: ReminderUiText.remotePocInviteMaxUsesLabel,
                  value: remotePocState.lastInviteMaxUses?.toString() ?? '-',
                ),
                _SettingsReadOnlyRow(
                  key: const Key('settings-remote-poc-joined-pack'),
                  label: ReminderUiText.remotePocJoinedPackLabel,
                  value: remotePocState.lastJoinedRemotePackId == null
                      ? ReminderUiText.remotePocNoRemoteMapping
                      : _shortUserId(remotePocState.lastJoinedRemotePackId!),
                ),
                _SettingsActionRow(
                  key: const Key(
                    'settings-create-anonymous-remote-identity-row',
                  ),
                  label: ReminderUiText.createAnonymousRemoteIdentityLabel,
                  value: ReminderUiText.identityKindAnonymousRemote,
                  icon: Icons.cloud_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _ensureAnonymousRemoteIdentity(context, ref),
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-create-profile-row'),
                  label: ReminderUiText.remotePocCreateProfileLabel,
                  value: ReminderUiText.remotePocNotCreated,
                  icon: Icons.account_circle_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) => controller.ensureRemoteProfile(),
                  ),
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-create-pack-row'),
                  label: ReminderUiText.remotePocCreatePackLabel,
                  value: remotePocPackMapping == null
                      ? ReminderUiText.remotePocNoRemoteMapping
                      : _shortUserId(remotePocPackMapping.remoteEntityId),
                  icon: Icons.cloud_upload_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) =>
                        controller.createRemotePack(remotePocTargetPack?.id),
                  ),
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-push-items-row'),
                  label: ReminderUiText.remotePocPushItemsLabel,
                  value: remotePocFirstMappedItem == null
                      ? ReminderUiText.remotePocNotCreated
                      : remotePocFirstMappedItem.item.title,
                  icon: Icons.playlist_add_check_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) =>
                        controller.pushMinimalItems(remotePocTargetPack?.id),
                  ),
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-create-invite-row'),
                  label: ReminderUiText.remotePocCreateInviteLabel,
                  value: remotePocPackMapping == null
                      ? ReminderUiText.remotePocNoRemoteMapping
                      : _shortUserId(remotePocPackMapping.remoteEntityId),
                  icon: Icons.key_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) => controller.createInviteCode(
                      remotePocPackMapping?.remoteEntityId,
                    ),
                  ),
                ),
                _SettingsInputRow(
                  key: const Key('settings-remote-poc-invite-input-row'),
                  fieldKey: const Key('settings-remote-poc-invite-input'),
                  label: ReminderUiText.remotePocInviteInputLabel,
                  initialValue: remotePocState.inviteCodeInput,
                  enabled: !remotePocState.isRunning,
                  onChanged: ref
                      .read(remotePocControllerProvider.notifier)
                      .updateInviteCodeInput,
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-join-invite-row'),
                  label: ReminderUiText.remotePocJoinInviteLabel,
                  value: remotePocState.lastJoinedRemotePackId == null
                      ? ReminderUiText.remotePocNoRemoteMapping
                      : _shortUserId(remotePocState.lastJoinedRemotePackId!),
                  icon: Icons.group_add_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) => controller.joinWithInviteCode(),
                  ),
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-complete-item-row'),
                  label: ReminderUiText.remotePocCompleteItemLabel,
                  value: remotePocFirstMappedItem == null
                      ? ReminderUiText.remotePocNotCreated
                      : remotePocFirstMappedItem.item.title,
                  icon: Icons.task_alt_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) => controller.completeFirstMappedItem(
                      remotePocTargetPack?.id,
                    ),
                  ),
                ),
                _SettingsActionRow(
                  key: const Key(
                    'settings-remote-poc-complete-snapshot-item-row',
                  ),
                  label: ReminderUiText.remotePocCompleteSnapshotItemLabel,
                  value:
                      remotePocState.firstSnapshotItem?.title ??
                      ReminderUiText.remotePocNotCreated,
                  icon: Icons.fact_check_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) => controller.completeFirstSnapshotItem(),
                  ),
                ),
                _SettingsActionRow(
                  key: const Key('settings-remote-poc-pull-snapshot-row'),
                  label: ReminderUiText.remotePocPullSnapshotLabel,
                  value: remotePocState.lastJoinedRemotePackId != null
                      ? _shortUserId(remotePocState.lastJoinedRemotePackId!)
                      : remotePocPackMapping == null
                      ? ReminderUiText.remotePocNoRemoteMapping
                      : _shortUserId(remotePocPackMapping.remoteEntityId),
                  icon: Icons.cloud_download_outlined,
                  enabled: !remotePocState.isRunning,
                  onTap: () => _runRemotePocAction(
                    context,
                    ref,
                    (controller) => controller.pullRemoteSnapshot(
                      localPackId: remotePocTargetPack?.id,
                      remotePackId: remotePocPackMapping?.remoteEntityId,
                    ),
                  ),
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

  String _shortUserId(String value) {
    return value.length <= 12 ? value : '${value.substring(0, 8)}...';
  }

  String _identityKindLabel(LocalUserIdentityKind kind) {
    return switch (kind) {
      LocalUserIdentityKind.local => ReminderUiText.identityKindLocal,
      LocalUserIdentityKind.anonymousRemote =>
        ReminderUiText.identityKindAnonymousRemote,
      LocalUserIdentityKind.linked => ReminderUiText.identityKindLinked,
      LocalUserIdentityKind.placeholder =>
        ReminderUiText.identityKindPlaceholder,
      LocalUserIdentityKind.removed => ReminderUiText.identityKindRemoved,
    };
  }

  String _remoteProviderLabel(AuthProviderType provider) {
    return switch (provider) {
      AuthProviderType.supabaseAnonymous =>
        ReminderUiText.remoteProviderSupabaseAnonymous,
      AuthProviderType.apple => ReminderUiText.remoteProviderApple,
      AuthProviderType.google => ReminderUiText.remoteProviderGoogle,
      AuthProviderType.email => ReminderUiText.remoteProviderEmail,
    };
  }

  String _supabaseRuntimeStatusLabel(SupabaseRuntimeStatus status) {
    return switch (status) {
      SupabaseRuntimeStatus.configured =>
        ReminderUiText.supabaseConfigConfigured,
      SupabaseRuntimeStatus.missingConfig =>
        ReminderUiText.supabaseConfigMissing,
      SupabaseRuntimeStatus.initializationFailed =>
        ReminderUiText.supabaseConfigInitializationFailed,
    };
  }

  String _remotePocSharedPackValue(ItemPack? pack) {
    if (pack == null) {
      return ReminderUiText.remotePocNoSharedPack;
    }
    return '${pack.title} #${pack.id}';
  }

  String _remotePocSnapshotSummaryValue(RemotePocSnapshotSummary? summary) {
    if (summary == null) {
      return ReminderUiText.remotePocNotRun;
    }
    return 'members ${summary.membersCount}, items ${summary.itemsCount}, completions ${summary.activeCompletionsCount}, events ${summary.activityEventsCount}';
  }

  String _remotePocDateTimeValue(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final local = value.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
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

  Future<void> _ensureAnonymousRemoteIdentity(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _runRemotePocAction(
      context,
      ref,
      (controller) => controller.ensureAnonymousRemoteIdentity(),
    );
  }

  Future<void> _runRemotePocAction(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function(RemotePocController controller) action,
  ) async {
    final message = await action(
      ref.read(remotePocControllerProvider.notifier),
    );
    ref.invalidate(currentAppUserProvider);
    ref.invalidate(currentAppUserIdProvider);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    ref.invalidate(currentAppUserProvider);
    ref.invalidate(currentAppUserIdProvider);
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

class _SettingsInputRow extends StatelessWidget {
  const _SettingsInputRow({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return TextFormField(
      key: fieldKey,
      initialValue: initialValue,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: enabled ? palette.textPrimary : palette.textMuted,
        fontWeight: FontWeight.w700,
      ),
      onChanged: onChanged,
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
