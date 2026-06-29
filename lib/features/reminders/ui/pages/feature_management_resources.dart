part of 'feature_management_sections.dart';

class _ResourceManagementDensity {
  const _ResourceManagementDensity._();

  static const pagePadding = 12.0;
  static const sectionGap = 10.0;
  static const itemGap = 6.0;
  static const itemPaddingVertical = 7.0;
  static const itemPaddingHorizontal = 10.0;
  static const cardRadius = 16.0;
  static const packChipSize = 26.0;

  static const itemPadding = EdgeInsets.symmetric(
    vertical: itemPaddingVertical,
    horizontal: itemPaddingHorizontal,
  );
}

class ResourceManagementPage extends StatelessWidget {
  const ResourceManagementPage({super.key});

  static const routeName = 'resources-management';
  static const routePath = '/feature/resources-management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('資源管理')),
      body: const ResourceManagementContent(),
    );
  }
}

class ResourceManagementContent extends ConsumerWidget {
  const ResourceManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReminderRefreshable(
      onRefresh: () async {
        final coordinator = ref.read(remoteBackedSyncCoordinatorProvider);
        final packIds = await coordinator.listRemoteBackedPackIds();
        await coordinator.refreshVisibleRemoteBackedPacks(packIds);
        ref.invalidate(managedResourcesProvider);
        await Future<void>.delayed(Duration.zero);
      },
      child: ListView(
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(_ResourceManagementDensity.pagePadding),
        children: const [ResourceManagementSection()],
      ),
    );
  }
}

class ResourceManagementSection extends ConsumerWidget {
  const ResourceManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(managedResourcesProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResourceManagementHeader(
          onAddResource: () async {
            final input = await showDialog<ResourceInput>(
              context: context,
              builder: (dialogContext) => const _ResourceFormDialog(),
            );
            if (input != null && context.mounted) {
              final resourceId = await ref
                  .read(resourceRepositoryProvider)
                  .createResource(input);
              final bundle = await ref
                  .read(resourceRepositoryProvider)
                  .getResourceById(resourceId);
              if (bundle != null) {
                unawaited(
                  ref
                      .read(remoteBackedSyncCoordinatorProvider)
                      .syncAfterRemoteBackedMutation(bundle.resource.packId),
                );
              }
            }
          },
        ),
        const SizedBox(height: _ResourceManagementDensity.sectionGap),
        resourcesAsync.when(
          data: (resources) {
            if (resources.isEmpty) {
              return const _ResourceCompactEmptyState();
            }
            return Column(
              children: resources
                  .map(
                    (bundle) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: _ResourceManagementDensity.itemGap,
                      ),
                      child: _ManagedResourceCard(
                        bundle: bundle,
                        previewDate: previewDate,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ResourceManagementHeader extends StatelessWidget {
  const _ResourceManagementHeader({required this.onAddResource});

  final VoidCallback onAddResource;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('資源管理', style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton.filled(
          key: const Key('add-resource-button'),
          onPressed: onAddResource,
          tooltip: '新增資源',
          icon: const Icon(Icons.add),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
      ],
    );
  }
}

class _ResourceCompactEmptyState extends StatelessWidget {
  const _ResourceCompactEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: double.infinity,
      padding: _ResourceManagementDensity.itemPadding,
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        '目前沒有要留意的資源。',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
      ),
    );
  }
}

class _ResourcePackEmojiChip extends StatelessWidget {
  const _ResourcePackEmojiChip({required this.pack});

  final ItemPack pack;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Tooltip(
      message: pack.title,
      child: Semantics(
        label: '生活場景 ${pack.title}',
        child: Container(
          key: Key('resource-pack-chip-${pack.id}'),
          width: _ResourceManagementDensity.packChipSize,
          height: _ResourceManagementDensity.packChipSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceWarm,
            shape: BoxShape.circle,
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Text(pack.iconEmoji, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}

enum _ManagedResourceMenuAction {
  adjust,
  edit,
  details,
  history,
  archive,
  retrySync,
}

class _ManagedResourceCard extends ConsumerWidget {
  const _ManagedResourceCard({required this.bundle, required this.previewDate});

  final ResourceBundle bundle;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(resourceRepositoryProvider);
    final resource = bundle.resource;
    final status = repository.statusFor(resource, now: previewDate);
    final syncStatus = ref
        .watch(resourceSyncStatusProvider(resource.id))
        .maybeWhen(
          data: (value) => value,
          orElse: () => ResourceSyncStatus.localOnly,
        );
    final syncLabel = _resourceSyncStatusLabel(syncStatus);
    final palette = context.reminderPalette;
    return ReminderRailCard(
      key: Key('resource-card-${resource.id}'),
      railColor: _resourceManagementStatusColor(status, palette),
      padding: _ResourceManagementDensity.itemPadding,
      radius: _ResourceManagementDensity.cardRadius,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              key: Key('resource-card-body-${resource.id}'),
              onTap: () => _showResourceDetailDialog(
                context,
                resource: resource,
                status: status,
                previewDate: previewDate,
              ),
              borderRadius: BorderRadius.circular(
                _ResourceManagementDensity.cardRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ResourcePackEmojiChip(pack: bundle.pack),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resource.title,
                              key: Key('resource-title-${resource.id}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ReminderFormatters.resourceCompactRemainingSummary(
                              resource,
                              now: previewDate,
                            ),
                            key: Key('resource-compact-summary-${resource.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _resourceManagementStatusColor(
                                    status,
                                    palette,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      if (syncLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          syncLabel,
                          key: Key('resource-sync-label-${resource.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: Key('resource-refill-${resource.id}'),
            onPressed: syncStatus.isAccessLost
                ? null
                : () => _showResourceRefillDialog(context, ref, resource),
            tooltip: '補充',
            icon: const Icon(Icons.add_rounded),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
          PopupMenuButton<_ManagedResourceMenuAction>(
            key: Key('resource-overflow-${resource.id}'),
            tooltip: ReminderUiText.itemActionMenuTitle,
            enabled: !syncStatus.isAccessLost,
            onSelected: (action) => _handleResourceMenuAction(
              context,
              ref,
              bundle,
              action: action,
              status: status,
            ),
            itemBuilder: (menuContext) => [
              if (resource.config is QuantityBasedResourceConfig)
                const PopupMenuItem(
                  value: _ManagedResourceMenuAction.adjust,
                  child: Text('調整'),
                ),
              const PopupMenuItem(
                value: _ManagedResourceMenuAction.edit,
                child: Text(ReminderUiText.editAction),
              ),
              const PopupMenuItem(
                value: _ManagedResourceMenuAction.details,
                child: Text(ReminderUiText.itemDetailAction),
              ),
              const PopupMenuItem(
                value: _ManagedResourceMenuAction.history,
                child: Text('歷史紀錄'),
              ),
              if (syncStatus.hasFailedMutation ||
                  (syncStatus.lastSyncError?.trim().isNotEmpty ?? false))
                const PopupMenuItem(
                  value: _ManagedResourceMenuAction.retrySync,
                  child: Text(ReminderUiText.packCareRetrySync),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ManagedResourceMenuAction.archive,
                child: Text(ReminderUiText.archiveAction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleResourceMenuAction(
    BuildContext context,
    WidgetRef ref,
    ResourceBundle bundle, {
    required _ManagedResourceMenuAction action,
    required ResourceStatus status,
  }) async {
    final resource = bundle.resource;
    switch (action) {
      case _ManagedResourceMenuAction.adjust:
        await _showResourceAdjustDialog(context, ref, resource);
        return;
      case _ManagedResourceMenuAction.edit:
        context.pushNamed(
          ResourceEditPage.routeName,
          pathParameters: {'id': resource.id.toString()},
        );
        return;
      case _ManagedResourceMenuAction.details:
        await _showResourceDetailDialog(
          context,
          resource: resource,
          status: status,
          previewDate: previewDate,
        );
        return;
      case _ManagedResourceMenuAction.history:
        context.pushNamed(
          ResourceHistoryPage.routeName,
          pathParameters: {'id': resource.id.toString()},
        );
        return;
      case _ManagedResourceMenuAction.retrySync:
        await _retryRemoteBackedPackSync(context, ref, bundle.pack);
        return;
      case _ManagedResourceMenuAction.archive:
        final confirmed = await _showItemActionConfirmation(
          context,
          title: '刪除資源',
          message: '刪除後會從列表隱藏，既有歷史紀錄會保留。確定要刪除嗎？',
          confirmLabel: ReminderUiText.archiveAction,
          isDestructive: true,
        );
        if (confirmed == true) {
          final archived = await ref
              .read(resourceRepositoryProvider)
              .archiveResource(resource.id);
          if (archived) {
            unawaited(
              ref
                  .read(remoteBackedSyncCoordinatorProvider)
                  .syncAfterRemoteBackedMutation(resource.packId),
            );
          }
        }
        return;
    }
  }

  Future<void> _showResourceRefillDialog(
    BuildContext context,
    WidgetRef ref,
    Resource resource,
  ) async {
    final input = await showDialog<_ResourceActionDialogResult>(
      context: context,
      builder: (dialogContext) =>
          _ResourceRefillDialog(resource: resource, actionDate: previewDate),
    );
    if (input == null) {
      return;
    }
    final updated = await ref
        .read(resourceRepositoryProvider)
        .refillResource(
          resource.id,
          actionAt: previewDate,
          addedDays: resource.config is TimeBasedResourceConfig
              ? input.value
              : null,
          addedQuantity: resource.config is QuantityBasedResourceConfig
              ? input.value
              : null,
          remark: input.remark,
        );
    if (updated) {
      unawaited(
        ref
            .read(remoteBackedSyncCoordinatorProvider)
            .syncAfterRemoteBackedMutation(resource.packId),
      );
    }
  }

  Future<void> _showResourceAdjustDialog(
    BuildContext context,
    WidgetRef ref,
    Resource resource,
  ) async {
    final config = resource.config;
    if (config is! QuantityBasedResourceConfig) {
      return;
    }
    final input = await showDialog<_ResourceActionDialogResult>(
      context: context,
      builder: (dialogContext) =>
          _ResourceAdjustDialog(resource: resource, config: config),
    );
    if (input == null) {
      return;
    }
    final updated = await ref
        .read(resourceRepositoryProvider)
        .adjustResourceQuantity(
          resource.id,
          newQuantity: input.value,
          actionAt: previewDate,
          remark: input.remark,
        );
    if (updated) {
      unawaited(
        ref
            .read(remoteBackedSyncCoordinatorProvider)
            .syncAfterRemoteBackedMutation(resource.packId),
      );
    }
  }
}

Color _resourceManagementStatusColor(
  ResourceStatus status,
  ReminderPalette palette,
) {
  return switch (status) {
    ResourceStatus.normal => palette.statusNormal,
    ResourceStatus.warning => palette.statusWarning,
    ResourceStatus.danger => palette.statusDanger,
    ResourceStatus.unknown => palette.statusUnknown,
  };
}

String? _resourceSyncStatusLabel(ResourceSyncStatus status) {
  return compactRemoteBackedSyncStatusLabel(
    isRemoteBacked: status.isRemoteBacked,
    isAccessLost: status.isAccessLost,
    hasFailedMutation: status.hasFailedMutation,
    isStale: status.isStale,
    pendingMutationStatus: status.pendingMutationStatus,
    lastSyncError: status.lastSyncError,
  );
}

Future<void> _showResourceDetailDialog(
  BuildContext context, {
  required Resource resource,
  required ResourceStatus status,
  required DateTime previewDate,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ResourceDetailDialog(
      resource: resource,
      status: status,
      previewDate: previewDate,
    ),
  );
}

class _ResourceDetailDialog extends ConsumerWidget {
  const _ResourceDetailDialog({
    required this.resource,
    required this.status,
    required this.previewDate,
  });

  final Resource resource;
  final ResourceStatus status;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = resource.config;
    final bindingsAsync = config is QuantityBasedResourceConfig
        ? ref.watch(resourceBindingsProvider(resource.id))
        : const AsyncValue<List<ResourceBinding>>.data([]);
    return AlertDialog(
      key: Key('resource-detail-dialog-${resource.id}'),
      title: Text(resource.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResourceDetailRow(
                label: '狀態',
                value: ReminderFormatters.resourceStatus(status),
              ),
              _ResourceDetailRow(
                label: '類型',
                value: ReminderFormatters.resourceType(resource.type),
              ),
              if ((resource.description ?? '').trim().isNotEmpty)
                _ResourceDetailRow(
                  label: '備註',
                  value: resource.description!.trim(),
                ),
              _ResourceDetailRow(
                label: config is TimeBasedResourceConfig ? '可用天數' : '目前數量',
                value: ReminderFormatters.resourceSummary(
                  resource,
                  now: previewDate,
                ),
              ),
              const SizedBox(height: 12),
              Text('提醒準則', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(_resourceThresholdSummary(config)),
              if (config is QuantityBasedResourceConfig) ...[
                const SizedBox(height: 16),
                Text('綁定 item', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                bindingsAsync.when(
                  data: (bindings) {
                    if (bindings.isEmpty) {
                      return const Text('尚未綁定任何 item。');
                    }
                    return Column(
                      children: bindings
                          .map(
                            (binding) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(binding.item.title),
                              subtitle: Text(
                                '每次完成扣 ${binding.rule.consumeAmount} ${config.unitLabel}｜${binding.rule.isEnabled ? '啟用中' : '已停用'}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                  error: (error, stack) => Text('讀取綁定失敗: $error'),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

class _ResourceDetailRow extends StatelessWidget {
  const _ResourceDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

String _resourceThresholdSummary(ResourceConfig config) {
  return switch (config) {
    TimeBasedResourceConfig time =>
      '大約剩 ${time.warningBeforeDays} 天提醒；剩 ${time.dangerBeforeDays} 天進入危急。',
    QuantityBasedResourceConfig quantity =>
      '剩 ${quantity.warningThreshold} ${quantity.unitLabel}提醒；剩 ${quantity.dangerThreshold} ${quantity.unitLabel}進入危急。',
    _ => '尚未設定。',
  };
}

class _ResourceFormDialog extends ConsumerStatefulWidget {
  const _ResourceFormDialog();

  @override
  ConsumerState<_ResourceFormDialog> createState() =>
      _ResourceFormDialogState();
}

class _ResourceFormDialogState extends ConsumerState<_ResourceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '20');
  final _warningDaysController = TextEditingController(text: '3');
  final _dangerDaysController = TextEditingController(text: '1');
  final _quantityController = TextEditingController(text: '5');
  final _unitController = TextEditingController(text: '個');
  final _warningQuantityController = TextEditingController(text: '2');
  final _dangerQuantityController = TextEditingController(text: '1');
  ResourceType _type = ResourceType.quantityBased;
  int? _selectedPackId;
  late DateTime _anchorDate = _today();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _warningDaysController.dispose();
    _dangerDaysController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _warningQuantityController.dispose();
    _dangerQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(activeItemPacksProvider);
    final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
    return AlertDialog(
      title: const Text(ReminderUiText.addResourceTitle),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReminderEditorSection(
                  key: const Key('resource-create-section-basic-info'),
                  title: ReminderUiText.basicInfoSectionTitle,
                  children: [
                    EditorTitleField(
                      controller: _titleController,
                      fieldKey: const Key('resource-title-field'),
                      labelText: ReminderUiText.resourceNameFieldLabel,
                      hintText: ReminderUiText.resourceNameFieldHint,
                      requiredErrorText:
                          ReminderUiText.resourceNameFieldRequiredError,
                    ),
                    EditorNoteField(
                      controller: _descriptionController,
                      fieldKey: const Key('resource-note-field'),
                    ),
                    ReminderEditorPickerRow(
                      key: const Key('resource-pack-picker-row'),
                      label: ReminderUiText.packFieldLabel,
                      value: _selectedPackLabel(packs),
                      onTap: () => _showPackPicker(_packOptions(packs)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ReminderEditorSection(
                  key: const Key('resource-create-section-type'),
                  title: ReminderUiText.resourceTypeSectionTitle,
                  children: [
                    ReminderEditorSelectableCard(
                      key: const Key('resource-type-quantity-card'),
                      selected: _type == ResourceType.quantityBased,
                      title: ReminderUiText.quantityResourceTitle,
                      description: ReminderUiText.quantityResourceDescription,
                      icon: Icons.inventory_2_outlined,
                      onTap: () => _setType(ResourceType.quantityBased),
                    ),
                    ReminderEditorSelectableCard(
                      key: const Key('resource-type-time-card'),
                      selected: _type == ResourceType.timeBased,
                      title: ReminderUiText.timeBasedResourceTitle,
                      description: ReminderUiText.timeBasedResourceDescription,
                      icon: Icons.hourglass_bottom_outlined,
                      onTap: () => _setType(ResourceType.timeBased),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ReminderEditorSection(
                  key: const Key('resource-create-section-settings'),
                  title: ReminderUiText.resourceSettingsSectionTitle,
                  children: [
                    if (_type == ResourceType.timeBased)
                      ReminderEditorNumberField(
                        fieldKey: const Key('resource-available-days-field'),
                        controller: _durationController,
                        label: ReminderUiText.availableDaysLabel,
                        suffixText: ReminderUiText.dayUnit,
                        minimum: 1,
                      )
                    else ...[
                      ReminderEditorNumberField(
                        fieldKey: const Key('resource-initial-quantity-field'),
                        controller: _quantityController,
                        label: ReminderUiText.initialQuantityLabel,
                      ),
                      TextFormField(
                        key: const Key('resource-unit-field'),
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: ReminderUiText.resourceUnitLabel,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ReminderEditorAdvancedSection(
                  key: const Key('resource-create-section-thresholds'),
                  title: ReminderUiText.resourceThresholdSectionTitle,
                  toggleKey: const Key('resource-create-toggle-thresholds'),
                  children: [
                    if (_type == ResourceType.timeBased) ...[
                      ReminderEditorNumberField(
                        fieldKey: const Key('resource-warning-days-field'),
                        controller: _warningDaysController,
                        label: ReminderUiText.warningDaysLabel,
                        suffixText: ReminderUiText.dayUnit,
                      ),
                      ReminderEditorNumberField(
                        fieldKey: const Key('resource-danger-days-field'),
                        controller: _dangerDaysController,
                        label: ReminderUiText.dangerDaysLabel,
                        suffixText: ReminderUiText.dayUnit,
                      ),
                      ReminderEditorDateRow(
                        key: const Key('resource-anchor-date-row'),
                        label: ReminderUiText.startCountingDateLabel,
                        date: _anchorDate,
                        onTap: _pickAnchorDate,
                      ),
                    ] else ...[
                      ReminderEditorNumberField(
                        fieldKey: const Key('resource-warning-quantity-field'),
                        controller: _warningQuantityController,
                        label: ReminderUiText.warningQuantityLabel,
                        suffixText: _unitLabel,
                      ),
                      ReminderEditorNumberField(
                        fieldKey: const Key('resource-danger-quantity-field'),
                        controller: _dangerQuantityController,
                        label: ReminderUiText.dangerQuantityLabel,
                        suffixText: _unitLabel,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('resource-save-button'),
          onPressed: _submit,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  String get _unitLabel =>
      _unitController.text.trim().isEmpty ? '個' : _unitController.text.trim();

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final config = _type == ResourceType.timeBased
        ? TimeBasedResourceConfig(
            anchorDate: _anchorDate,
            durationDays: _positiveInt(_durationController),
            warningBeforeDays: _nonNegativeInt(_warningDaysController),
            dangerBeforeDays: _nonNegativeInt(_dangerDaysController),
          )
        : QuantityBasedResourceConfig(
            currentQuantity: _nonNegativeInt(_quantityController),
            unitLabel: _unitController.text.trim().isEmpty
                ? '個'
                : _unitController.text.trim(),
            warningThreshold: _nonNegativeInt(_warningQuantityController),
            dangerThreshold: _nonNegativeInt(_dangerQuantityController),
          );
    Navigator.of(context).pop(
      ResourceInput(
        title: _titleController.text.trim(),
        description: _normalizeOptionalText(_descriptionController.text),
        type: _type,
        config: config,
        packId: _selectedPackId,
      ),
    );
  }

  void _setType(ResourceType type) {
    if (_type == type) {
      return;
    }
    setState(() {
      _type = type;
    });
  }

  List<_ResourceCreatePackOption> _packOptions(List<ItemPack> packs) {
    return [
      _ResourceCreatePackOption(id: null, label: packCreateUndecidedLabel()),
      ...packs
          .where((pack) => !pack.isSystemDefault)
          .map(
            (pack) => _ResourceCreatePackOption(
              id: pack.id,
              label: packDisplayLabel(pack),
            ),
          ),
    ];
  }

  Future<void> _showPackPicker(
    List<_ResourceCreatePackOption> packOptions,
  ) async {
    final selection =
        await showModalBottomSheet<_ResourceCreatePackPickerSelection>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  ReminderUiText.packFieldLabel,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final option in packOptions)
                  ListTile(
                    key: Key('resource-pack-option-${option.id ?? 'none'}'),
                    title: Text(option.label),
                    trailing: _selectedPackId == option.id
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(
                      sheetContext,
                    ).pop(_ResourceCreatePackPickerSelection(id: option.id)),
                  ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('resource-add-pack-button'),
                    onPressed: () => Navigator.of(sheetContext).pop(
                      const _ResourceCreatePackPickerSelection.createPack(),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(ReminderUiText.addItemPack),
                  ),
                ),
              ],
            ),
          ),
        );
    if (selection == null || !mounted) {
      return;
    }
    if (selection.createPack) {
      await _createPackInline();
      return;
    }
    setState(() {
      _selectedPackId = selection.id;
    });
  }

  Future<void> _createPackInline() async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => const PackFormDialog(),
    );
    if (input == null || !mounted) {
      return;
    }
    final packId = await ref.read(itemRepositoryProvider).createPack(input);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedPackId = packId;
    });
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _anchorDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  String _selectedPackLabel(List<ItemPack> packs) {
    final selectedPackId = _selectedPackId;
    if (selectedPackId == null) {
      return packCreateUndecidedLabel();
    }
    for (final pack in packs) {
      if (pack.id == selectedPackId) {
        return packDisplayLabel(pack);
      }
    }
    return ReminderUiText.selectPackPlaceholder;
  }

  int _positiveInt(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  int _nonNegativeInt(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null || parsed < 0) {
      return 0;
    }
    return parsed;
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

class _ResourceCreatePackOption {
  const _ResourceCreatePackOption({required this.id, required this.label});

  final int? id;
  final String label;
}

class _ResourceCreatePackPickerSelection {
  const _ResourceCreatePackPickerSelection({required this.id})
    : createPack = false;

  const _ResourceCreatePackPickerSelection.createPack()
    : id = null,
      createPack = true;

  final int? id;
  final bool createPack;
}

class _ResourceActionDialogResult {
  const _ResourceActionDialogResult({required this.value, this.remark});

  final int value;
  final String? remark;
}

class _ResourceRefillDialog extends StatefulWidget {
  const _ResourceRefillDialog({
    required this.resource,
    required this.actionDate,
  });

  final Resource resource;
  final DateTime actionDate;

  @override
  State<_ResourceRefillDialog> createState() => _ResourceRefillDialogState();
}

class _ResourceRefillDialogState extends State<_ResourceRefillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.resource.config;
    final isTimeBased = config is TimeBasedResourceConfig;
    return AlertDialog(
      title: const Text(ReminderUiText.refillResourceTitle),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReminderEditorSection(
                  key: const Key('resource-refill-editor-section'),
                  title: ReminderUiText.resourceActionSectionTitle,
                  children: [
                    ReminderEditorNumberField(
                      fieldKey: isTimeBased
                          ? const Key('resource-refill-days-field')
                          : const Key('resource-refill-quantity-field'),
                      controller: _amountController,
                      label: isTimeBased
                          ? ReminderUiText.addAvailableDaysLabel
                          : ReminderUiText.refillQuantityLabel,
                      suffixText: isTimeBased
                          ? ReminderUiText.dayUnit
                          : _quantityUnitLabel(config),
                      minimum: 1,
                      onChanged: () => setState(() {}),
                    ),
                    _ResourceActionPreview(
                      key: const Key('resource-refill-preview'),
                      text: _refillPreviewText(config),
                    ),
                    EditorNoteField(
                      controller: _noteController,
                      fieldKey: const Key('resource-refill-note-field'),
                      labelText: ReminderUiText.resourceActionNoteLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('resource-refill-submit'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(ReminderUiText.refillAction),
        ),
      ],
    );
  }

  String _refillPreviewText(ResourceConfig config) {
    final value = _nonNegativeInput(_amountController);
    if (config is QuantityBasedResourceConfig) {
      final after = config.currentQuantity + value;
      return '${ReminderUiText.resourceHistoryCurrentLabel} ${config.currentQuantity} ${config.unitLabel}，${ReminderUiText.afterRefillPreviewLabel} $after ${config.unitLabel}';
    }
    if (config is TimeBasedResourceConfig) {
      final refill = const ResourceRefillService().refillTimeBased(
        config,
        actionDate: widget.actionDate,
        addedDays: value < 1 ? 1 : value,
      );
      final depletion = refill.anchorDate.add(
        Duration(days: refill.durationDays - 1),
      );
      return '${ReminderUiText.estimatedRunOutDateLabel}：${ReminderFormatters.date(depletion)}';
    }
    return '';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    Navigator.of(context).pop(
      _ResourceActionDialogResult(
        value: _positiveInput(_amountController),
        remark: _normalizeOptionalText(_noteController.text),
      ),
    );
  }
}

class _ResourceAdjustDialog extends StatefulWidget {
  const _ResourceAdjustDialog({required this.resource, required this.config});

  final Resource resource;
  final QuantityBasedResourceConfig config;

  @override
  State<_ResourceAdjustDialog> createState() => _ResourceAdjustDialogState();
}

class _ResourceAdjustDialogState extends State<_ResourceAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.config.currentQuantity}',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ReminderUiText.adjustResourceTitle),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReminderEditorSection(
                  key: const Key('resource-adjust-editor-section'),
                  title: ReminderUiText.resourceActionSectionTitle,
                  children: [
                    ReminderEditorNumberField(
                      fieldKey: const Key('resource-adjust-quantity-field'),
                      controller: _quantityController,
                      label: ReminderUiText.adjustQuantityLabel,
                      suffixText: widget.config.unitLabel,
                      minimum: 0,
                      onChanged: () => setState(() {}),
                    ),
                    _ResourceActionPreview(
                      key: const Key('resource-adjust-preview'),
                      text: _adjustPreviewText(),
                    ),
                    EditorNoteField(
                      controller: _noteController,
                      fieldKey: const Key('resource-adjust-note-field'),
                      labelText: ReminderUiText.resourceActionReasonLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('resource-adjust-submit'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(ReminderUiText.adjustAction),
        ),
      ],
    );
  }

  String _adjustPreviewText() {
    final value = _nonNegativeInput(_quantityController);
    return '${ReminderUiText.resourceHistoryCurrentLabel} ${widget.config.currentQuantity} ${widget.config.unitLabel}，${ReminderUiText.afterAdjustPreviewLabel} $value ${widget.config.unitLabel}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    Navigator.of(context).pop(
      _ResourceActionDialogResult(
        value: _nonNegativeInput(_quantityController),
        remark: _normalizeOptionalText(_noteController.text),
      ),
    );
  }
}

class _ResourceActionPreview extends StatelessWidget {
  const _ResourceActionPreview({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String? _quantityUnitLabel(ResourceConfig config) {
  return config is QuantityBasedResourceConfig ? config.unitLabel : null;
}

int _positiveInput(TextEditingController controller) {
  final parsed = int.tryParse(controller.text.trim());
  return parsed == null || parsed < 1 ? 1 : parsed;
}

int _nonNegativeInput(TextEditingController controller) {
  final parsed = int.tryParse(controller.text.trim());
  return parsed == null || parsed < 0 ? 0 : parsed;
}

String? _normalizeOptionalText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
