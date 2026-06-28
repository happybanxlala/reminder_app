part of 'feature_management_sections.dart';

class _CreateItemDialog extends ConsumerStatefulWidget {
  const _CreateItemDialog({this.initialPackId});

  final int? initialPackId;

  @override
  ConsumerState<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends ConsumerState<_CreateItemDialog> {
  static const _unassignedPackValue = 'unassigned';

  final _stepOneFormKey = GlobalKey<FormState>();
  final _stepTwoFormKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final ItemConfigFormController _configController;

  int _stepIndex = 0;
  late String _selectedPackValue;
  List<ResourceBindingDraft> _resourceBindingDrafts = const [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _configController = ItemConfigFormController();
    _selectedPackValue = widget.initialPackId == null
        ? _unassignedPackValue
        : _packValue(widget.initialPackId!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _configController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePacksAsync = ref.watch(activeItemPacksProvider);
    final resourcesAsync = ref.watch(resourcesProvider);
    _configController.reminderTone = ref.watch(reminderToneProvider);
    return AlertDialog(
      title: Text(
        _stepIndex == 0 ? ReminderUiText.addItem : ReminderUiText.confirmAction,
      ),
      content: SizedBox(
        width: 480,
        child: activePacksAsync.when(
          data: (packs) {
            final resources =
                resourcesAsync.valueOrNull ?? const <ResourceBundle>[];
            return SingleChildScrollView(
              child: Form(
                key: _stepIndex == 0 ? _stepOneFormKey : _stepTwoFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _stepIndex == 0
                      ? _buildStepOne(context, packs)
                      : _buildStepTwo(packs, resources),
                ),
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
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildStepOne(BuildContext context, List<ItemPack> packs) {
    final packOptions = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: _unassignedPackValue,
        child: Text(ReminderUiText.unassignedPackOption),
      ),
      ...packs
          .where((pack) => !pack.isSystemDefault)
          .map(
            (pack) => DropdownMenuItem<String>(
              value: _packValue(pack.id),
              child: Text(packDisplayLabel(pack)),
            ),
          ),
    ];

    return [
      EditorTitleField(controller: _titleController),
      const SizedBox(height: 12),
      DropdownButtonFormField<ItemType>(
        key: const Key('create-item-type-field'),
        initialValue: _configController.type,
        decoration: const InputDecoration(
          labelText: ReminderUiText.itemTypeFieldLabel,
        ),
        items: ItemType.values
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(ReminderFormatters.itemType(value)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _configController.type = value;
          });
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const Key('create-pack-field'),
        initialValue: _selectedPackValue,
        decoration: const InputDecoration(
          labelText: ReminderUiText.packFieldLabel,
        ),
        items: packOptions,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _selectedPackValue = value;
          });
        },
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          key: const Key('create-item-add-pack-button'),
          onPressed: _createPackInline,
          child: const Text(ReminderUiText.addItemPack),
        ),
      ),
    ];
  }

  List<Widget> _buildStepTwo(
    List<ItemPack> packs,
    List<ResourceBundle> resources,
  ) {
    return [
      Text(
        _titleController.text.trim(),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(ReminderFormatters.itemType(_configController.type)),
      const SizedBox(height: 12),
      ItemConfigFormSection(
        controller: _configController,
        onChanged: () => setState(() {}),
        showAttentionFields: false,
      ),
      const SizedBox(height: 12),
      ResourceBindingDraftSection(
        drafts: _resourceBindingDrafts,
        resources: resources,
        packId: _resolvedPackId(packs),
        onChanged: (drafts) {
          setState(() {
            _resourceBindingDrafts = drafts;
          });
        },
      ),
    ];
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_stepIndex == 0) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('create-item-next-button'),
          onPressed: () {
            if (!_stepOneFormKey.currentState!.validate()) {
              return;
            }
            setState(() {
              _stepIndex = 1;
            });
          },
          child: const Text(ReminderUiText.nextStepAction),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _isSaving
            ? null
            : () {
                setState(() {
                  _stepIndex = 0;
                });
              },
        child: const Text(ReminderUiText.previousPageAction),
      ),
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(
        key: const Key('create-item-confirm-button'),
        onPressed: _isSaving ? null : _submit,
        child: const Text(ReminderUiText.confirmAction),
      ),
    ];
  }

  Future<void> _submit() async {
    if (!_stepTwoFormKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(itemRepositoryProvider);
    final packId = switch (_selectedPackValue) {
      _unassignedPackValue => null,
      _ => int.tryParse(_selectedPackValue.replaceFirst('pack-', '')),
    };

    setState(() {
      _isSaving = true;
    });
    try {
      await repository.createItem(
        ItemInput(
          title: _titleController.text.trim(),
          type: _configController.type,
          config: _configController.buildConfigForCreate(),
          packId: packId,
        ),
        resourceBindings: _resourceBindingDrafts
            .map((draft) => draft.toInput())
            .toList(growable: false),
      );
      if (packId != null && await repository.isRemoteBackedPack(packId)) {
        unawaited(
          ref
              .read(remoteBackedSyncCoordinatorProvider)
              .syncAfterRemoteBackedMutation(packId),
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _packValue(int id) => 'pack-$id';

  int? _resolvedPackId(List<ItemPack> packs) {
    if (_selectedPackValue == _unassignedPackValue) {
      for (final pack in packs) {
        if (pack.isSystemDefault) {
          return pack.id;
        }
      }
      return null;
    }
    return int.tryParse(_selectedPackValue.replaceFirst('pack-', ''));
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
      _selectedPackValue = _packValue(packId);
    });
  }
}
