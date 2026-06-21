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
    final remotePocSnapshotTargetType =
        remotePocState.snapshotTargetType ??
        (remotePocState.lastJoinedRemotePackId != null
            ? RemotePocSnapshotTargetType.joinedRemotePack
            : remotePocPackMapping != null
            ? RemotePocSnapshotTargetType.localMappedPack
            : null);

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
                _RemoteSnapshotViewer(
                  key: const Key('settings-remote-snapshot-viewer'),
                  snapshot: remotePocState.lastPulledRemoteSnapshot,
                  targetType: remotePocSnapshotTargetType,
                  targetRemotePackId:
                      remotePocState.lastJoinedRemotePackId ??
                      remotePocPackMapping?.remoteEntityId,
                  hasTarget:
                      remotePocState.lastJoinedRemotePackId != null ||
                      remotePocPackMapping != null,
                  lastRefreshAt: remotePocState.lastRefreshAt,
                  lastRefreshSucceeded: remotePocState.lastRefreshSucceeded,
                  summary: remotePocState.snapshotSummary,
                  shortId: _shortUserId,
                  dateTimeValue: _remotePocDateTimeValue,
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

class _RemoteSnapshotViewer extends StatelessWidget {
  const _RemoteSnapshotViewer({
    super.key,
    required this.snapshot,
    required this.targetType,
    required this.targetRemotePackId,
    required this.hasTarget,
    required this.lastRefreshAt,
    required this.lastRefreshSucceeded,
    required this.summary,
    required this.shortId,
    required this.dateTimeValue,
  });

  final RemotePackSnapshot? snapshot;
  final RemotePocSnapshotTargetType? targetType;
  final String? targetRemotePackId;
  final bool hasTarget;
  final DateTime? lastRefreshAt;
  final bool? lastRefreshSucceeded;
  final RemotePocSnapshotSummary? summary;
  final String Function(String value) shortId;
  final String Function(DateTime? value) dateTimeValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final snapshot = this.snapshot;
    return Container(
      key: const Key('settings-remote-snapshot-viewer-container'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: palette.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReminderUiText.remotePocViewerTitle,
            key: const Key('settings-remote-snapshot-viewer-title'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _viewerLine(
            context,
            key: const Key('settings-remote-snapshot-target'),
            label: ReminderUiText.remotePocViewerTargetLabel,
            value: _targetValue(),
          ),
          _viewerLine(
            context,
            key: const Key('settings-remote-snapshot-last-refresh'),
            label: ReminderUiText.remotePocViewerLastRefreshLabel,
            value: _lastRefreshValue(),
          ),
          if (!hasTarget) ...[
            const SizedBox(height: 8),
            _viewerMutedText(
              context,
              ReminderUiText.remotePocViewerNoTarget,
              key: const Key('settings-remote-snapshot-no-target'),
            ),
          ] else if (snapshot == null) ...[
            const SizedBox(height: 8),
            _viewerMutedText(
              context,
              ReminderUiText.remotePocViewerNoSnapshot,
              key: const Key('settings-remote-snapshot-empty'),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _viewerSectionTitle(
              context,
              ReminderUiText.remotePocViewerPackLabel,
            ),
            _viewerLine(
              context,
              key: const Key('settings-remote-snapshot-pack-name'),
              label: 'name',
              value: snapshot.name,
            ),
            _viewerLine(
              context,
              key: const Key('settings-remote-snapshot-pack-id'),
              label: 'remote id',
              value: shortId(snapshot.id),
            ),
            _viewerLine(
              context,
              key: const Key('settings-remote-snapshot-pack-host'),
              label: 'host',
              value: shortId(snapshot.hostUserId),
            ),
            _viewerLine(
              context,
              key: const Key('settings-remote-snapshot-pack-status'),
              label: 'status',
              value: snapshot.status,
            ),
            _viewerLine(
              context,
              key: const Key('settings-remote-snapshot-pack-updated'),
              label: 'updated',
              value: dateTimeValue(snapshot.updatedAt),
            ),
            if (summary != null)
              _viewerLine(
                context,
                key: const Key('settings-remote-snapshot-summary-line'),
                label: 'summary',
                value:
                    'members ${summary!.membersCount}, items ${summary!.itemsCount}, completions ${summary!.activeCompletionsCount}, events ${summary!.activityEventsCount}',
              ),
            const SizedBox(height: 10),
            _viewerSectionTitle(
              context,
              ReminderUiText.remotePocViewerMembersLabel,
            ),
            for (final member in snapshot.members)
              _viewerBullet(
                context,
                key: Key('settings-remote-snapshot-member-${member.id}'),
                text:
                    '${member.displayName?.trim().isNotEmpty == true ? member.displayName : shortId(member.userId)} | ${member.role} | ${member.status}',
              ),
            const SizedBox(height: 10),
            _viewerSectionTitle(
              context,
              ReminderUiText.remotePocViewerItemsLabel,
            ),
            for (final item in snapshot.items)
              _viewerBullet(
                context,
                key: Key('settings-remote-snapshot-item-${item.id}'),
                text: _itemValue(snapshot, item),
              ),
            const SizedBox(height: 10),
            _viewerSectionTitle(
              context,
              ReminderUiText.remotePocViewerActivityLabel,
            ),
            for (final event in snapshot.activityEvents.take(10))
              _viewerBullet(
                context,
                key: Key('settings-remote-snapshot-event-${event.id}'),
                text:
                    '${event.action} | ${event.entityType} | ${_actorValue(event)} | ${dateTimeValue(event.createdAt)}',
              ),
          ],
        ],
      ),
    );
  }

  String _targetValue() {
    final remoteId = targetRemotePackId;
    if (remoteId == null) {
      return ReminderUiText.remotePocNoRemoteMapping;
    }
    final type = switch (targetType) {
      RemotePocSnapshotTargetType.joinedRemotePack =>
        ReminderUiText.remotePocViewerJoinedTarget,
      RemotePocSnapshotTargetType.localMappedPack =>
        ReminderUiText.remotePocViewerLocalTarget,
      null =>
        hasTarget
            ? ReminderUiText.remotePocViewerLocalTarget
            : ReminderUiText.remotePocNoRemoteMapping,
    };
    return '$type ${shortId(remoteId)}';
  }

  String _lastRefreshValue() {
    if (lastRefreshAt == null) {
      return ReminderUiText.remotePocNotRun;
    }
    final status = lastRefreshSucceeded == false ? 'failed' : 'success';
    return '$status ${dateTimeValue(lastRefreshAt)}';
  }

  String _itemValue(RemotePackSnapshot snapshot, RemoteItemSnapshot item) {
    RemoteItemCompletionSnapshot? completion;
    for (final entry in snapshot.completions) {
      if (entry.itemId == item.id && entry.undoneAt == null) {
        completion = entry;
        break;
      }
    }
    final note = item.note == null || item.note!.trim().isEmpty
        ? ''
        : ' | ${_truncate(item.note!.trim())}';
    final assigned = item.assignedToUserId == null
        ? ''
        : ' | assigned ${shortId(item.assignedToUserId!)}';
    if (completion == null) {
      return '${item.title}$note | ${item.status}$assigned | ${ReminderUiText.remotePocViewerIncomplete}';
    }
    return '${item.title}$note | ${item.status}$assigned | completed by ${shortId(completion.completedByUserId)} at ${dateTimeValue(completion.completedAt)}';
  }

  String _actorValue(RemoteActivityEventSnapshot event) {
    final snapshot = event.actorDisplayNameSnapshot;
    if (snapshot != null && snapshot.trim().isNotEmpty) {
      return snapshot;
    }
    final actor = event.actorUserId;
    return actor == null ? '-' : shortId(actor);
  }

  String _truncate(String value) {
    return value.length <= 48 ? value : '${value.substring(0, 45)}...';
  }

  Widget _viewerSectionTitle(BuildContext context, String value) {
    final palette = context.reminderPalette;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _viewerLine(
    BuildContext context, {
    required Key key,
    required String label,
    required String value,
  }) {
    final palette = context.reminderPalette;
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewerBullet(
    BuildContext context, {
    required Key key,
    required String text,
  }) {
    final palette = context.reminderPalette;
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '- $text',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _viewerMutedText(
    BuildContext context,
    String text, {
    required Key key,
  }) {
    final palette = context.reminderPalette;
    return Text(
      text,
      key: key,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: palette.textMuted,
        fontWeight: FontWeight.w700,
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
