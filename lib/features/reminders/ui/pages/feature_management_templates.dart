part of 'feature_management_sections.dart';

const _templateCategories = ['家務', '照料貓咪', '財務管理', '其他'];

class _TemplatePickerDialog extends ConsumerWidget {
  const _TemplatePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(itemPackTemplatesProvider);
    return AlertDialog(
      title: const Text(ReminderUiText.applyTemplateAction),
      content: SizedBox(
        width: 560,
        height: 520,
        child: templatesAsync.when(
          data: (templates) {
            final builtin = templates
                .where(
                  (template) =>
                      template.source == ItemPackTemplateSource.builtin,
                )
                .toList(growable: false);
            final custom = templates
                .where(
                  (template) =>
                      template.source == ItemPackTemplateSource.custom,
                )
                .toList(growable: false);
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: ReminderUiText.templateBuiltInTab),
                      Tab(text: ReminderUiText.templateCustomTab),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _TemplateList(templates: builtin),
                        _TemplateList(templates: custom, allowDelete: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Center(child: CircularProgressIndicator()),
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

class _TemplateList extends ConsumerWidget {
  const _TemplateList({required this.templates, this.allowDelete = false});

  final List<ItemPackTemplate> templates;
  final bool allowDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (templates.isEmpty) {
      return const Center(child: Text(ReminderUiText.noCustomTemplates));
    }
    return ListView.separated(
      itemCount: templates.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final template = templates[index];
        return ListTile(
          key: Key('template-${template.id}'),
          title: Text(template.name),
          subtitle: Text('${template.category}｜${template.description}'),
          trailing: Wrap(
            spacing: 4,
            children: [
              if (allowDelete)
                IconButton(
                  key: Key('template-delete-${template.id}'),
                  onPressed: () async {
                    await ref
                        .read(itemRepositoryProvider)
                        .deleteCustomTemplate(template.id);
                  },
                  tooltip: ReminderUiText.deleteTemplateAction,
                  icon: const Icon(Icons.delete_outline),
                ),
              TextButton(
                key: Key('template-view-${template.id}'),
                onPressed: () async {
                  final applied = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) =>
                        _TemplateDetailDialog(template: template),
                  );
                  if (applied == true && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(ReminderUiText.templateDetailAction),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateDetailDialog extends ConsumerWidget {
  const _TemplateDetailDialog({required this.template});

  final ItemPackTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(template.name),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template.category),
              const SizedBox(height: 4),
              Text(template.description),
              const SizedBox(height: 16),
              const Text(ReminderUiText.templateItemsTitle),
              const SizedBox(height: 8),
              ...template.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text(
                    [
                      if ((item.description ?? '').trim().isNotEmpty)
                        item.description!.trim(),
                      ReminderFormatters.itemType(item.type),
                      _templateItemSummary(item.config),
                    ].join('｜'),
                  ),
                ),
              ),
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
          key: Key('template-apply-${template.id}'),
          onPressed: () async {
            await ref.read(itemRepositoryProvider).applyTemplate(template);
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(ReminderUiText.templateAppliedMessage),
              ),
            );
            Navigator.of(context).pop(true);
          },
          child: const Text(ReminderUiText.applyThisTemplateAction),
        ),
      ],
    );
  }

  String _templateItemSummary(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => ReminderFormatters.fixedScheduleSummary(fixed),
      StateBasedItemConfig state =>
        '留意 ${state.warningAfter.inDays} 天｜需要處理 ${state.dangerAfter.inDays} 天',
      _ => '',
    };
  }
}

class _SaveTemplateDialog extends StatefulWidget {
  const _SaveTemplateDialog({required this.pack});

  final ItemPack pack;

  @override
  State<_SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<_SaveTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _category = _templateCategories.first;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pack.title);
    _descriptionController = TextEditingController(
      text: widget.pack.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ReminderUiText.saveAsTemplateAction),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('template-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.templateNameFieldLabel,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? '請輸入模版名稱' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('template-category-field'),
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: ReminderUiText.templateCategoryFieldLabel,
              ),
              items: _templateCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _category = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('template-description-field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.templateDescriptionFieldLabel,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('template-save-button'),
          onPressed: _submit,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      ItemPackTemplateInput(
        name: _nameController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}
