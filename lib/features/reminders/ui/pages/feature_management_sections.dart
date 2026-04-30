import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/item_repository.dart';
import '../../data/local/item_timeline_dao.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/management_item_card_view_model.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/timeline_providers.dart';
import 'item_edit_page.dart';
import 'item_history_page.dart';
import 'timeline_edit_page.dart';
import 'timeline_milestone_history_page.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/item_config_form_section.dart';
import '../widgets/item_summary_dialog.dart';

class ItemsManagementContent extends ConsumerStatefulWidget {
  const ItemsManagementContent({super.key});

  @override
  ConsumerState<ItemsManagementContent> createState() =>
      _ItemsManagementContentState();
}

class _ItemsManagementContentState
    extends ConsumerState<ItemsManagementContent> {
  final Set<int> _expandedPackIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(itemManagementGroupsProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(
                title: ReminderUiText.itemsManagementFeatureTitle,
                actions: [
                  FilledButton(
                    key: const Key('add-item-button'),
                    onPressed: () => _showCreateItemDialog(context, ref),
                    child: const Text(ReminderUiText.addItem),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(ReminderUiText.noDefaultItemPack),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: ReminderUiText.itemsManagementFeatureTitle,
              actions: [
                FilledButton(
                  key: const Key('add-item-button'),
                  onPressed: () => _showCreateItemDialog(context, ref),
                  child: const Text(ReminderUiText.addItem),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ItemManagementGroupCard(
                  group: group,
                  previewDate: previewDate,
                  expanded: _expandedPackIds.contains(group.pack.id),
                  onToggle: () {
                    setState(() {
                      if (!_expandedPackIds.add(group.pack.id)) {
                        _expandedPackIds.remove(group.pack.id);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stack) => Center(child: Text('讀取失敗: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class ItemPacksManagementContent extends StatelessWidget {
  const ItemPacksManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ItemsManagementContent();
  }
}

class TimelineManagementContent extends ConsumerWidget {
  const TimelineManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelinesAsync = ref.watch(timelinesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: ReminderUiText.timelineManagementFeatureTitle,
          actions: [
            FilledButton(
              key: const Key('add-timeline-button'),
              onPressed: () {
                context.pushNamed(TimelineEditPage.timelineNewRouteName);
              },
              child: const Text(ReminderUiText.addTimeline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        timelinesAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text(ReminderUiText.noTimelines);
            }
            return Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TimelineCard(timeline: item),
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

Future<void> _showCreateItemDialog(
  BuildContext context,
  WidgetRef ref, {
  int? initialPackId,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateItemDialog(initialPackId: initialPackId),
  );
}

Future<void> _showPackDialog(
  BuildContext context,
  WidgetRef ref, {
  ItemPack? pack,
}) async {
  if (pack?.isSystemDefault ?? false) {
    return;
  }
  final input = await showDialog<ItemPackInput>(
    context: context,
    builder: (dialogContext) => _PackFormDialog(pack: pack),
  );
  if (input == null || !context.mounted) {
    return;
  }

  final repository = ref.read(itemRepositoryProvider);
  if (pack == null) {
    await repository.createPack(input);
    return;
  }

  final updated = await repository.updatePack(pack.id, input);
  if (!updated && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('此 pack 目前不可編輯。')));
  }
}

class _ItemManagementGroupCard extends ConsumerWidget {
  const _ItemManagementGroupCard({
    required this.group,
    required this.previewDate,
    required this.expanded,
    required this.onToggle,
  });

  final ItemManagementGroup group;
  final DateTime previewDate;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(itemRepositoryProvider);
    final pack = group.pack;
    final items = group.items;
    final isUnassigned = group.isUnassigned;

    return Card(
      key: Key('pack-section-${pack.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            isUnassigned
                                ? ReminderUiText.unassignedPackTitle
                                : pack.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      if (!isUnassigned &&
                          (pack.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(pack.description!.trim()),
                      ],
                      const SizedBox(height: 4),
                      Text('${items.length} ${ReminderUiText.itemCountLabel}'),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    IconButton(
                      key: Key('pack-add-item-${pack.id}'),
                      onPressed: () => _showCreateItemDialog(
                        context,
                        ref,
                        initialPackId: isUnassigned ? null : pack.id,
                      ),
                      tooltip: ReminderUiText.addItem,
                      icon: const Icon(Icons.add),
                    ),
                    if (!isUnassigned)
                      IconButton(
                        key: Key('pack-edit-${pack.id}'),
                        onPressed: () =>
                            _showPackDialog(context, ref, pack: pack),
                        tooltip: ReminderUiText.editAction,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (!pack.isSystemDefault)
                      IconButton(
                        key: Key('pack-archive-${pack.id}'),
                        onPressed: () async {
                          final canArchive = await repository.canArchivePack(
                            pack.id,
                          );
                          if (!context.mounted || !canArchive) {
                            return;
                          }
                          final managedItemCount = await repository
                              .countPackManagedItems(pack.id);
                          if (!context.mounted) {
                            return;
                          }
                          if (managedItemCount > 0) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text(
                                  ReminderUiText.archivePackConfirmTitle,
                                ),
                                content: const Text(
                                  ReminderUiText.archivePackConfirmMessage,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: Text(
                                      MaterialLocalizations.of(
                                        dialogContext,
                                      ).cancelButtonLabel,
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text(
                                      ReminderUiText.archiveAction,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) {
                              return;
                            }
                          }
                          await repository.archivePack(pack.id);
                        },
                        tooltip: ReminderUiText.archiveAction,
                        icon: const Icon(Icons.archive_outlined),
                      ),
                    IconButton(
                      key: Key('pack-toggle-${pack.id}'),
                      onPressed: onToggle,
                      tooltip: expanded
                          ? ReminderUiText.collapseAction
                          : ReminderUiText.expandAction,
                      icon: Icon(
                        expanded
                            ? Icons.expand_less_outlined
                            : Icons.expand_more_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text(ReminderUiText.emptyPackHint)
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ManagedItemCard(
                      bundle: item,
                      previewDate: previewDate,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManagedItemCard extends ConsumerWidget {
  const _ManagedItemCard({required this.bundle, required this.previewDate});

  final ItemBundle bundle;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ManagementItemCardViewModel.fromBundle(
      bundle,
      now: previewDate,
    );

    return Card(
      key: Key('item-card-${bundle.item.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            showItemSummaryDialog(context, bundle, previewDate: previewDate),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          viewModel.typeIcon,
                          key: Key('item-type-icon-${bundle.item.id}'),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bundle.item.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (viewModel.isPaused) ...[
                          const Icon(
                            Icons.pause_circle_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            viewModel.status.label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: viewModel.status.color),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: Key('item-edit-${bundle.item.id}'),
                onPressed: () {
                  context.pushNamed(
                    ItemEditPage.editRouteName,
                    pathParameters: {'id': bundle.item.id.toString()},
                  );
                },
                tooltip: ReminderUiText.editAction,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: Key('item-overflow-${bundle.item.id}'),
                onPressed: () => _showManagedItemActionSheet(
                  context,
                  ref,
                  bundle,
                  previewDate,
                  viewModel,
                ),
                tooltip: ReminderUiText.itemActionMenuTitle,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ManagedItemMenuAction {
  complete,
  skip,
  details,
  history,
  pause,
  resume,
  archive,
}

Future<void> _showManagedItemActionSheet(
  BuildContext context,
  WidgetRef ref,
  ItemBundle bundle,
  DateTime previewDate,
  ManagementItemCardViewModel viewModel,
) async {
  final selected = await showModalBottomSheet<_ManagedItemMenuAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ReminderUiText.itemActionMenuTitle,
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              _ItemActionSheetTile(
                key: Key('item-menu-complete-${bundle.item.id}'),
                label: ReminderUiText.completeAction,
                enabled: viewModel.canComplete,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ManagedItemMenuAction.complete),
              ),
              _ItemActionSheetTile(
                key: Key('item-menu-skip-${bundle.item.id}'),
                label: ReminderUiText.skipAction,
                enabled: viewModel.canSkip,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ManagedItemMenuAction.skip),
              ),
              const Divider(height: 16),
              _ItemActionSheetTile(
                key: Key('item-menu-details-${bundle.item.id}'),
                label: ReminderUiText.itemDetailAction,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ManagedItemMenuAction.details),
              ),
              _ItemActionSheetTile(
                key: Key('item-menu-history-${bundle.item.id}'),
                label: ReminderUiText.itemHistoryAction,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ManagedItemMenuAction.history),
              ),
              const Divider(height: 16),
              _ItemActionSheetTile(
                key: Key(
                  viewModel.canResume
                      ? 'item-menu-resume-${bundle.item.id}'
                      : 'item-menu-pause-${bundle.item.id}',
                ),
                label: viewModel.canResume
                    ? ReminderUiText.resumeAction
                    : ReminderUiText.pauseAction,
                enabled: viewModel.canResume || viewModel.canPause,
                onTap: () => Navigator.of(sheetContext).pop(
                  viewModel.canResume
                      ? _ManagedItemMenuAction.resume
                      : _ManagedItemMenuAction.pause,
                ),
              ),
              _ItemActionSheetTile(
                key: Key('item-menu-archive-${bundle.item.id}'),
                label: ReminderUiText.archiveAction,
                isDestructive: true,
                enabled: viewModel.canArchive,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ManagedItemMenuAction.archive),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (selected == null || !context.mounted) {
    return;
  }

  final repository = ref.read(itemRepositoryProvider);
  switch (selected) {
    case _ManagedItemMenuAction.complete:
      await _handleManagedItemComplete(
        context,
        repository,
        bundle,
        previewDate,
        viewModel,
      );
      return;
    case _ManagedItemMenuAction.skip:
      if (!viewModel.canSkip) {
        return;
      }
      await repository.skip(bundle.item.id, actionAt: previewDate);
      return;
    case _ManagedItemMenuAction.details:
      await showItemSummaryDialog(context, bundle, previewDate: previewDate);
      return;
    case _ManagedItemMenuAction.history:
      context.pushNamed(
        ItemHistoryPage.routeName,
        pathParameters: {'id': bundle.item.id.toString()},
      );
      return;
    case _ManagedItemMenuAction.pause:
      final confirmed = await _showItemActionConfirmation(
        context,
        title: ReminderUiText.pauseItemConfirmTitle,
        message: ReminderUiText.pauseItemConfirmMessage,
        confirmLabel: ReminderUiText.pauseAction,
      );
      if (confirmed == true) {
        await repository.pauseItem(bundle.item.id);
      }
      return;
    case _ManagedItemMenuAction.resume:
      await repository.resumeItem(bundle.item.id);
      return;
    case _ManagedItemMenuAction.archive:
      final confirmed = await _showItemActionConfirmation(
        context,
        title: ReminderUiText.archiveItemConfirmTitle,
        message: ReminderUiText.archiveItemConfirmMessage,
        confirmLabel: ReminderUiText.archiveAction,
        isDestructive: true,
      );
      if (confirmed == true) {
        await repository.archiveItem(bundle.item.id);
      }
      return;
  }
}

Future<void> _handleManagedItemComplete(
  BuildContext context,
  ItemRepository repository,
  ItemBundle bundle,
  DateTime previewDate,
  ManagementItemCardViewModel viewModel,
) async {
  if (!viewModel.canComplete) {
    return;
  }

  if (viewModel.requireCompletionConfirmation) {
    final confirmed = await _showItemActionConfirmation(
      context,
      title: ReminderUiText.stateCompleteConfirmTitle,
      message: ReminderUiText.stateCompleteConfirmMessage,
      confirmLabel: ReminderUiText.completeAction,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
  }

  final addedDays = bundle.item.type == ItemType.resourceBased
      ? await _showResourceAddedDaysDialog(
          context,
          initialValue:
              (bundle.item.config as ResourceBasedItemConfig).durationDays,
        )
      : null;
  if (bundle.item.type == ItemType.resourceBased && addedDays == null) {
    return;
  }

  await repository.markDone(
    bundle.item.id,
    doneAt: previewDate,
    addedDays: addedDays,
  );
}

Future<bool?> _showItemActionConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
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
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class _ItemActionSheetTile extends StatelessWidget {
  const _ItemActionSheetTile({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final destructiveColor = Theme.of(context).colorScheme.error;
    final effectiveTextColor = !enabled
        ? Theme.of(context).disabledColor
        : isDestructive
        ? destructiveColor
        : null;
    return ListTile(
      enabled: enabled,
      textColor: effectiveTextColor,
      onTap: enabled ? onTap : null,
      title: Text(label),
    );
  }
}

class _CreateItemDialog extends ConsumerStatefulWidget {
  const _CreateItemDialog({this.initialPackId});

  final int? initialPackId;

  @override
  ConsumerState<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends ConsumerState<_CreateItemDialog> {
  static const _unassignedPackValue = 'unassigned';
  static const _newPackValue = 'new-pack';

  final _stepOneFormKey = GlobalKey<FormState>();
  final _stepTwoFormKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final ItemConfigFormController _configController;

  int _stepIndex = 0;
  late String _selectedPackValue;
  ItemPackInput? _pendingPack;
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
    return AlertDialog(
      title: Text(
        _stepIndex == 0 ? ReminderUiText.addItem : ReminderUiText.confirmAction,
      ),
      content: SizedBox(
        width: 480,
        child: activePacksAsync.when(
          data: (packs) => SingleChildScrollView(
            child: Form(
              key: _stepIndex == 0 ? _stepOneFormKey : _stepTwoFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _stepIndex == 0
                    ? _buildStepOne(context, packs)
                    : _buildStepTwo(),
              ),
            ),
          ),
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
              child: Text(pack.title),
            ),
          ),
      if (_pendingPack != null)
        DropdownMenuItem<String>(
          value: _newPackValue,
          child: Text(
            '${_pendingPack!.title} (${ReminderUiText.pendingPackSuffix})',
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
          onPressed: () async {
            final input = await showDialog<ItemPackInput>(
              context: context,
              builder: (dialogContext) => const _PackFormDialog(),
            );
            if (input == null) {
              return;
            }
            setState(() {
              _pendingPack = input;
              _selectedPackValue = _newPackValue;
            });
          },
          child: const Text(ReminderUiText.addItemPack),
        ),
      ),
    ];
  }

  List<Widget> _buildStepTwo() {
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
    final newPack = _selectedPackValue == _newPackValue ? _pendingPack : null;
    final packId = switch (_selectedPackValue) {
      _unassignedPackValue => null,
      _newPackValue => null,
      _ => int.tryParse(_selectedPackValue.replaceFirst('pack-', '')),
    };

    setState(() {
      _isSaving = true;
    });
    try {
      await repository.createItemWithOptionalNewPack(
        item: ItemInput(
          title: _titleController.text.trim(),
          type: _configController.type,
          config: _configController.buildConfig(),
          packId: packId,
        ),
        newPack: newPack,
      );
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
}

Future<int?> _showResourceAddedDaysDialog(
  BuildContext context, {
  required int initialValue,
}) async {
  var inputValue = '$initialValue';
  String? errorText;
  final result = await showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text(ReminderUiText.resourceCompletionDialogTitle),
        content: TextFormField(
          autofocus: true,
          initialValue: inputValue,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            inputValue = value;
          },
          decoration: InputDecoration(
            labelText: ReminderUiText.resourceCompletionDialogLabel,
            helperText: ReminderUiText.resourceCompletionDialogHelper,
            errorText: errorText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(inputValue.trim());
              if (value == null || value <= 0) {
                setState(() {
                  errorText = ReminderUiText.resourceCompletionDialogError;
                });
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text(ReminderUiText.saveAction),
          ),
        ],
      ),
    ),
  );
  return result;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actions});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    );
  }
}

class _PackFormDialog extends StatefulWidget {
  const _PackFormDialog({this.pack});

  final ItemPack? pack;

  @override
  State<_PackFormDialog> createState() => _PackFormDialogState();
}

class _PackFormDialogState extends State<_PackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool get _isEdit => widget.pack != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.pack?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.pack?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEdit ? ReminderUiText.editItemPack : ReminderUiText.addItemPack,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('pack-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.packTitleFieldLabel,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '請輸入責任包名稱';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('pack-description-field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.packDescriptionFieldLabel,
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
          key: const Key('pack-save-button'),
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
      ItemPackInput(
        title: _titleController.text.trim(),
        description: _normalizeOptionalText(_descriptionController.text),
      ),
    );
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.timeline});

  final Timeline timeline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(previewTimelineDetailProvider(timeline.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeline.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(ReminderFormatters.timelineSummary(timeline)),
                    ],
                  ),
                ),
                Text(ReminderFormatters.timelineStatus(timeline.status)),
              ],
            ),
            const SizedBox(height: 12),
            detailAsync.when(
              data: (detail) {
                final ruleDetails = detail?.milestoneRuleDetails ?? const [];
                if (ruleDetails.isEmpty) {
                  return const Text(ReminderUiText.timelineRuleMissingMessage);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(ReminderUiText.milestoneRulesTitle),
                    const SizedBox(height: 8),
                    ...ruleDetails.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        key: Key(
                          'timeline-rule-${timeline.id}-${item.rule.id}',
                        ),
                        title: Text(
                          ReminderFormatters.timelineMilestoneRuleSummary(
                            item.rule,
                          ),
                        ),
                        subtitle: Text(
                          item.nextMilestone == null
                              ? ReminderUiText.timelineRuleUpcomingUnavailable
                              : '${ReminderUiText.timelineRuleNextLabel}：${ReminderFormatters.milestoneSummary(item.nextMilestone!)}',
                        ),
                        trailing: Text(
                          ReminderFormatters.timelineMilestoneRuleStatus(
                            item.rule.status,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              error: (error, stack) =>
                  const Text(ReminderUiText.timelineRuleLoadFailedMessage),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            detailAsync.when(
              data: (detail) {
                final firstUpcomingByRule = _firstUpcomingByRule(
                  detail?.upcomingMilestones ?? const [],
                );
                if (firstUpcomingByRule.isEmpty) {
                  return const Text(ReminderUiText.noTimelineUpcomingMilestone);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(ReminderUiText.nextMilestoneLabel),
                    const SizedBox(height: 8),
                    ...firstUpcomingByRule.map(
                      (occurrence) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        key: Key(
                          'timeline-upcoming-${timeline.id}-${occurrence.ruleId}',
                        ),
                        title: Text(occurrence.label),
                        subtitle: Text(
                          ReminderFormatters.date(occurrence.targetDate),
                        ),
                      ),
                    ),
                  ],
                );
              },
              error: (error, stack) =>
                  const Text(ReminderUiText.upcomingMilestoneLoadFailedMessage),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('timeline-history-${timeline.id}'),
                  onPressed: () {
                    context.pushNamed(
                      TimelineMilestoneHistoryPage.routeName,
                      pathParameters: {'id': timeline.id.toString()},
                    );
                  },
                  child: const Text(
                    ReminderUiText.timelineMilestoneHistoryTitle,
                  ),
                ),
                if (timeline.status != TimelineStatus.archived)
                  OutlinedButton(
                    key: Key('timeline-edit-${timeline.id}'),
                    onPressed: () {
                      context.pushNamed(
                        TimelineEditPage.timelineEditRouteName,
                        pathParameters: {'id': timeline.id.toString()},
                      );
                    },
                    child: const Text(ReminderUiText.editAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TimelineMilestoneOccurrence> _firstUpcomingByRule(
    List<TimelineMilestoneOccurrence> items,
  ) {
    final byRule = <int, TimelineMilestoneOccurrence>{};
    for (final item in items) {
      byRule.putIfAbsent(item.ruleId, () => item);
    }
    return byRule.values.toList(growable: false)
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }
}
