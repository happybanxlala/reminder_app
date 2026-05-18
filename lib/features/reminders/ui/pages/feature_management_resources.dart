part of 'feature_management_sections.dart';

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

class ResourceManagementContent extends StatelessWidget {
  const ResourceManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ReminderSpacing.page),
      children: const [ResourceManagementSection()],
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
        _SectionHeader(
          title: '資源管理',
          actions: [
            FilledButton.icon(
              key: const Key('add-resource-button'),
              onPressed: () async {
                final input = await showDialog<ResourceInput>(
                  context: context,
                  builder: (dialogContext) => const _ResourceFormDialog(),
                );
                if (input != null && context.mounted) {
                  await ref
                      .read(resourceRepositoryProvider)
                      .createResource(input);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('新增資源'),
            ),
          ],
        ),
        const SizedBox(height: ReminderSpacing.listGap),
        resourcesAsync.when(
          data: (resources) {
            if (resources.isEmpty) {
              return const ReminderEmptyState(message: '目前沒有要留意的資源。');
            }
            return Column(
              children: resources
                  .map(
                    (bundle) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: ReminderSpacing.listGap,
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

enum _ManagedResourceMenuAction { adjust, edit, details, history, archive }

class _ManagedResourceCard extends ConsumerWidget {
  const _ManagedResourceCard({required this.bundle, required this.previewDate});

  final ResourceBundle bundle;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(resourceRepositoryProvider);
    final resource = bundle.resource;
    final status = repository.statusFor(resource, now: previewDate);
    final palette = context.reminderPalette;
    return ReminderRailCard(
      key: Key('resource-card-${resource.id}'),
      railColor: _resourceManagementStatusColor(status, palette),
      padding: const EdgeInsets.all(ReminderSpacing.cardCompact),
      child: InkWell(
        onTap: () => _showResourceDetailDialog(
          context,
          resource: resource,
          status: status,
          previewDate: previewDate,
        ),
        child: Row(
          children: [
            ReminderIconBubble(
              size: 54,
              backgroundColor: palette.statusWarningContainer,
              child: Icon(
                Icons.inventory_2_outlined,
                color: palette.domainResource,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        resource.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ReminderBadge(
                        label: ReminderFormatters.resourceType(resource.type),
                        color: palette.domainResource,
                        backgroundColor: palette.statusWarningContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${ReminderFormatters.resourceStatus(status)} · ${ReminderFormatters.resourceSummary(resource, now: previewDate)}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: Key('resource-refill-${resource.id}'),
              onPressed: () =>
                  _showResourceRefillDialog(context, ref, resource),
              child: const Text('補充'),
            ),
            PopupMenuButton<_ManagedResourceMenuAction>(
              key: Key('resource-overflow-${resource.id}'),
              tooltip: ReminderUiText.itemActionMenuTitle,
              onSelected: (action) => _handleResourceMenuAction(
                context,
                ref,
                resource,
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
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _ManagedResourceMenuAction.archive,
                  child: Text('封存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResourceMenuAction(
    BuildContext context,
    WidgetRef ref,
    Resource resource, {
    required _ManagedResourceMenuAction action,
    required ResourceStatus status,
  }) async {
    switch (action) {
      case _ManagedResourceMenuAction.adjust:
        await _showResourceAdjustDialog(context, ref, resource);
        return;
      case _ManagedResourceMenuAction.edit:
        final input = await showDialog<ResourceInput>(
          context: context,
          builder: (dialogContext) => _ResourceFormDialog(resource: resource),
        );
        if (input == null || !context.mounted) {
          return;
        }
        await ref
            .read(resourceRepositoryProvider)
            .updateResource(resource.id, input);
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
      case _ManagedResourceMenuAction.archive:
        final confirmed = await _showItemActionConfirmation(
          context,
          title: '封存資源',
          message: '封存後不會出現在資源管理，也不會被 item 完成時扣量；歷史紀錄與綁定會保留。',
          confirmLabel: '封存',
          isDestructive: true,
        );
        if (confirmed == true) {
          await ref
              .read(resourceRepositoryProvider)
              .archiveResource(resource.id);
        }
        return;
    }
  }

  Future<void> _showResourceRefillDialog(
    BuildContext context,
    WidgetRef ref,
    Resource resource,
  ) async {
    final input = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _NumberInputDialog(
        title: '補充資源',
        label: resource.config is TimeBasedResourceConfig ? '新增可用天數' : '新增數量',
        initialValue: '1',
      ),
    );
    if (input == null) {
      return;
    }
    await ref
        .read(resourceRepositoryProvider)
        .refillResource(
          resource.id,
          actionAt: previewDate,
          addedDays: resource.config is TimeBasedResourceConfig ? input : null,
          addedQuantity: resource.config is QuantityBasedResourceConfig
              ? input
              : null,
        );
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
    final input = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _NumberInputDialog(
        title: '調整庫存',
        label: '目前數量',
        initialValue: '${config.currentQuantity}',
        allowZero: true,
      ),
    );
    if (input == null) {
      return;
    }
    await ref
        .read(resourceRepositoryProvider)
        .adjustResourceQuantity(
          resource.id,
          newQuantity: input,
          actionAt: previewDate,
        );
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
  const _ResourceFormDialog({this.resource});

  final Resource? resource;

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

  @override
  void initState() {
    super.initState();
    final resource = widget.resource;
    if (resource == null) {
      return;
    }
    _type = resource.type;
    _titleController.text = resource.title;
    _descriptionController.text = resource.description ?? '';
    _selectedPackId = resource.packId;
    switch (resource.config) {
      case TimeBasedResourceConfig config:
        _durationController.text = '${config.durationDays}';
        _warningDaysController.text = '${config.warningBeforeDays}';
        _dangerDaysController.text = '${config.dangerBeforeDays}';
      case QuantityBasedResourceConfig config:
        _quantityController.text = '${config.currentQuantity}';
        _unitController.text = config.unitLabel;
        _warningQuantityController.text = '${config.warningThreshold}';
        _dangerQuantityController.text = '${config.dangerThreshold}';
      default:
        break;
    }
  }

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
      title: Text(widget.resource == null ? '新增資源' : '編輯資源'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('resource-title-field'),
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '名稱'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? '請輸入名稱' : null,
                ),
                const SizedBox(height: 12),
                if (widget.resource == null) ...[
                  DropdownButtonFormField<int?>(
                    key: const Key('resource-pack-field'),
                    initialValue: _selectedPackId,
                    decoration: const InputDecoration(
                      labelText: ReminderUiText.packFieldLabel,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(ReminderUiText.unassignedPackOption),
                      ),
                      ...packs.map(
                        (pack) => DropdownMenuItem<int?>(
                          value: pack.id,
                          child: Text(packDisplayLabel(pack)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPackId = value;
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('resource-add-pack-button'),
                      onPressed: _createPackInline,
                      icon: const Icon(Icons.add),
                      label: const Text(ReminderUiText.addItemPack),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: ReminderUiText.packFieldLabel,
                    ),
                    child: Text(
                      _packReadonlyLabel(packs, widget.resource!.packId),
                      key: const Key('resource-pack-readonly'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '備註'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ResourceType>(
                  key: const Key('resource-type-field'),
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: '資源類型'),
                  items: ResourceType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(ReminderFormatters.resourceType(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.resource == null
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _type = value;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                if (_type == ResourceType.timeBased) ...[
                  _numberField(_durationController, '大約還能用幾天'),
                  const SizedBox(height: 12),
                  _numberField(_warningDaysController, '剩幾天開始提醒'),
                  const SizedBox(height: 12),
                  _numberField(_dangerDaysController, '剩幾天進入危急'),
                ] else ...[
                  _numberField(_quantityController, '目前有多少'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: '單位'),
                  ),
                  const SizedBox(height: 12),
                  _numberField(_warningQuantityController, '剩多少開始提醒'),
                  const SizedBox(height: 12),
                  _numberField(_dangerQuantityController, '剩多少進入危急'),
                ],
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

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final existingConfig = widget.resource?.config;
    final config = _type == ResourceType.timeBased
        ? TimeBasedResourceConfig(
            anchorDate: existingConfig is TimeBasedResourceConfig
                ? existingConfig.anchorDate
                : DateTime(now.year, now.month, now.day),
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
        packId: widget.resource?.packId ?? _selectedPackId,
      ),
    );
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

  String _packReadonlyLabel(List<ItemPack> packs, int packId) {
    for (final pack in packs) {
      if (pack.id == packId) {
        return packDisplayLabel(pack);
      }
    }
    return ReminderUiText.unassignedPackTitle;
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
}

class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    this.allowZero = false,
  });

  final String title;
  final String label;
  final String initialValue;
  final bool allowZero;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late String _inputValue;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _inputValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextFormField(
        autofocus: true,
        initialValue: _inputValue,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _inputValue = value;
        },
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_inputValue.trim());
            final minimum = widget.allowZero ? 0 : 1;
            if (value == null || value < minimum) {
              setState(() {
                _errorText = widget.allowZero ? '請輸入 0 或以上' : '請輸入 1 或以上';
              });
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }
}
