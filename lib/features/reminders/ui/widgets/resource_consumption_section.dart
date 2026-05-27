import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/reminder_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/resource.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/resource_providers.dart';
import 'editor_form_components.dart';

class ResourceConsumptionSection extends ConsumerWidget {
  const ResourceConsumptionSection({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(itemConsumptionRulesProvider(itemId));
    final resourcesAsync = ref.watch(resourcesProvider);
    return KeyedSubtree(
      key: const Key('resource-consumption-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('add-resource-rule-button'),
              onPressed: () => _showAddResourceRuleDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text(ReminderUiText.addResourceBindingLabel),
            ),
          ),
          const SizedBox(height: 8),
          rulesAsync.when(
            data: (rules) => resourcesAsync.when(
              data: (resources) {
                final enabledRules = rules
                    .where((rule) => rule.isEnabled)
                    .toList(growable: false);
                if (enabledRules.isEmpty) {
                  return const Text('尚未綁定會消耗的資源。');
                }
                return Column(
                  children: [
                    for (final entry in enabledRules.asMap().entries)
                      _ResourceConsumptionRow(
                        key: Key('resource-consumption-row-${entry.key}'),
                        rule: entry.value,
                        resource: _findResource(
                          resources,
                          entry.value.resourceId,
                        ),
                      ),
                  ],
                );
              },
              error: (error, stack) => Text('讀取資源失敗: $error'),
              loading: () => const Text('正在讀取資源...'),
            ),
            error: (error, stack) => Text('讀取綁定失敗: $error'),
            loading: () => const Text('正在讀取綁定...'),
          ),
        ],
      ),
    );
  }

  Resource? _findResource(List<ResourceBundle> bundles, int resourceId) {
    for (final bundle in bundles) {
      if (bundle.resource.id == resourceId) {
        return bundle.resource;
      }
    }
    return null;
  }

  Future<void> _showAddResourceRuleDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final resources = await ref.read(resourcesProvider.future);
    final quantityResources = resources
        .map((bundle) => bundle.resource)
        .where((resource) => resource.config is QuantityBasedResourceConfig)
        .toList(growable: false);
    if (!context.mounted) {
      return;
    }
    if (quantityResources.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目前沒有可綁定的數量資源。')));
      return;
    }
    final input = await showDialog<_ResourceRuleDraft>(
      context: context,
      builder: (dialogContext) =>
          _ResourceRuleDialog(resources: quantityResources),
    );
    if (input == null) {
      return;
    }
    await ref
        .read(resourceRepositoryProvider)
        .createConsumptionRule(
          ResourceConsumptionRuleInput(
            resourceId: input.resourceId,
            itemId: itemId,
            consumeAmount: input.consumeAmount,
          ),
        );
  }
}

class _ResourceConsumptionRow extends ConsumerWidget {
  const _ResourceConsumptionRow({super.key, required this.rule, this.resource});

  final ResourceConsumptionRule rule;
  final Resource? resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = resource?.config;
    final unit = config is QuantityBasedResourceConfig ? config.unitLabel : '';
    final amount = unit.trim().isEmpty
        ? '${rule.consumeAmount}'
        : '${rule.consumeAmount} $unit';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resource?.title ?? '已不存在的資源',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '${ReminderUiText.resourceBindingConsumePrefix} $amount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('remove-resource-rule-${rule.id}'),
            tooltip: '移除綁定',
            onPressed: () async {
              await ref
                  .read(resourceRepositoryProvider)
                  .disableConsumptionRule(rule.id);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _ResourceRuleDraft {
  const _ResourceRuleDraft({
    required this.resourceId,
    required this.consumeAmount,
  });

  final int resourceId;
  final int consumeAmount;
}

class _ResourceRuleDialog extends StatefulWidget {
  const _ResourceRuleDialog({required this.resources});

  final List<Resource> resources;

  @override
  State<_ResourceRuleDialog> createState() => _ResourceRuleDialogState();
}

class _ResourceRuleDialogState extends State<_ResourceRuleDialog> {
  late int _resourceId;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _resourceId = widget.resources.first.id;
    _amountController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resources.firstWhere(
      (item) => item.id == _resourceId,
    );
    return AlertDialog(
      title: const Text(ReminderUiText.addResourceBindingLabel),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReminderEditorPickerRow(
              key: const Key('resource-rule-resource-field'),
              label: '資源',
              value: resource.title,
              onTap: _showResourcePicker,
            ),
            const SizedBox(height: 12),
            ReminderEditorNumberField(
              fieldKey: const Key('resource-rule-amount-field'),
              controller: _amountController,
              label: '完成時消耗',
              minimum: 1,
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
          key: const Key('resource-rule-save-button'),
          onPressed: _submit,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  Future<void> _showResourcePicker() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('資源', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final resource in widget.resources)
              ListTile(
                key: Key('resource-rule-option-${resource.id}'),
                title: Text(resource.title),
                trailing: resource.id == _resourceId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(resource.id),
              ),
          ],
        ),
      ),
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() {
      _resourceId = value;
    });
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 1;
    Navigator.of(context).pop(
      _ResourceRuleDraft(
        resourceId: _resourceId,
        consumeAmount: amount < 1 ? 1 : amount,
      ),
    );
  }
}
