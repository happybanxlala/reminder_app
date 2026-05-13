import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/item_repository.dart';
import '../../data/local/item_timeline_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/item_pack_template.dart';
import '../../domain/resource.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/management_item_card_view_model.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/resource_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/timeline_providers.dart';
import 'item_edit_page.dart';
import 'item_history_page.dart';
import 'resource_history_page.dart';
import 'timeline_edit_page.dart';
import 'timeline_milestone_history_page.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/item_config_form_section.dart';
import '../widgets/resource_binding_draft_section.dart';
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
                  OutlinedButton.icon(
                    key: const Key('resource-management-button'),
                    onPressed: () =>
                        context.pushNamed(ResourceManagementPage.routeName),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('資源管理'),
                  ),
                  OutlinedButton(
                    key: const Key('apply-template-button'),
                    onPressed: () => _showTemplatePickerDialog(context, ref),
                    child: const Text(ReminderUiText.applyTemplateAction),
                  ),
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
                OutlinedButton.icon(
                  key: const Key('resource-management-button'),
                  onPressed: () =>
                      context.pushNamed(ResourceManagementPage.routeName),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('資源管理'),
                ),
                OutlinedButton(
                  key: const Key('apply-template-button'),
                  onPressed: () => _showTemplatePickerDialog(context, ref),
                  child: const Text(ReminderUiText.applyTemplateAction),
                ),
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
          loading: () => const Text('正在讀取資源...'),
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

Future<void> _showTemplatePickerDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => const _TemplatePickerDialog(),
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
    final pack = group.pack;
    final items = group.items;
    final isUnassigned = group.isUnassigned;

    return Card(
      key: Key('pack-section-${pack.id}'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    key: Key('pack-header-${pack.id}'),
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
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
                          Text(
                            '${items.length} ${ReminderUiText.itemCountLabel}',
                          ),
                        ],
                      ),
                    ),
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
                        key: Key('pack-overflow-${pack.id}'),
                        onPressed: () =>
                            _showPackActionSheet(context, ref, pack),
                        tooltip: ReminderUiText.itemActionMenuTitle,
                        icon: const Icon(Icons.more_vert),
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

enum _PackMenuAction { edit, saveAsTemplate, archive }

Future<void> _showPackActionSheet(
  BuildContext context,
  WidgetRef ref,
  ItemPack pack,
) async {
  final selected = await showModalBottomSheet<_PackMenuAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ItemActionSheetTile(
              key: Key('pack-menu-edit-${pack.id}'),
              label: ReminderUiText.editAction,
              onTap: () => Navigator.of(sheetContext).pop(_PackMenuAction.edit),
            ),
            const Divider(height: 16),
            _ItemActionSheetTile(
              key: Key('pack-menu-save-template-${pack.id}'),
              label: ReminderUiText.saveAsTemplateAction,
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(_PackMenuAction.saveAsTemplate),
            ),
            const Divider(height: 16),
            _ItemActionSheetTile(
              key: Key('pack-menu-archive-${pack.id}'),
              label: ReminderUiText.archiveAction,
              isDestructive: true,
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PackMenuAction.archive),
            ),
          ],
        ),
      ),
    ),
  );
  if (selected == null || !context.mounted) {
    return;
  }

  final repository = ref.read(itemRepositoryProvider);
  switch (selected) {
    case _PackMenuAction.edit:
      await _showPackDialog(context, ref, pack: pack);
      return;
    case _PackMenuAction.saveAsTemplate:
      final input = await showDialog<ItemPackTemplateInput>(
        context: context,
        builder: (dialogContext) => _SaveTemplateDialog(pack: pack),
      );
      if (input == null || !context.mounted) {
        return;
      }
      final savedId = await repository.savePackAsTemplate(pack.id, input);
      if (savedId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ReminderUiText.templateSavedMessage)),
        );
      }
      return;
    case _PackMenuAction.archive:
      final canArchive = await repository.canArchivePack(pack.id);
      if (!context.mounted || !canArchive) {
        return;
      }
      final managedItemCount = await repository.countPackManagedItems(pack.id);
      if (!context.mounted) {
        return;
      }
      if (managedItemCount > 0) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(ReminderUiText.archivePackConfirmTitle),
            content: const Text(ReminderUiText.archivePackConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(ReminderUiText.archiveAction),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) {
          return;
        }
      }
      await repository.archivePack(pack.id);
      return;
  }
}

enum _ManagedItemMenuAction {
  complete,
  skip,
  details,
  history,
  move,
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
              _ItemActionSheetTile(
                key: Key('item-menu-move-${bundle.item.id}'),
                label: ReminderUiText.moveAction,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ManagedItemMenuAction.move),
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
    case _ManagedItemMenuAction.move:
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _MoveItemDialog(bundle: bundle),
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

  await repository.markDone(bundle.item.id, doneAt: previewDate);
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

class ResourceManagementPage extends StatelessWidget {
  const ResourceManagementPage({super.key});

  static const routeName = 'resources-management';
  static const routePath = '/feature/resources-management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('資源管理'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/manage'),
            icon: const Icon(Icons.checklist_outlined),
            label: const Text(ReminderUiText.itemsManagementFeatureTitle),
          ),
        ],
      ),
      body: const ResourceManagementContent(),
    );
  }
}

class ResourceManagementContent extends StatelessWidget {
  const ResourceManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 12),
        resourcesAsync.when(
          data: (resources) {
            if (resources.isEmpty) {
              return const Text('目前沒有要留意的資源。');
            }
            return Column(
              children: resources
                  .map(
                    (bundle) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
    return Card(
      key: Key('resource-card-${resource.id}'),
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => _showResourceDetailDialog(
          context,
          resource: resource,
          status: status,
          previewDate: previewDate,
        ),
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(resource.title),
        subtitle: Text(
          '${ReminderFormatters.resourceType(resource.type)}｜${ReminderFormatters.resourceStatus(status)}｜${ReminderFormatters.resourceSummary(resource, now: previewDate)}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              key: Key('resource-refill-${resource.id}'),
              onPressed: () =>
                  _showResourceRefillDialog(context, ref, resource),
              tooltip: '補充',
              icon: const Icon(Icons.add_circle_outline),
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

class _ResourceFormDialog extends StatefulWidget {
  const _ResourceFormDialog({this.resource});

  final Resource? resource;

  @override
  State<_ResourceFormDialog> createState() => _ResourceFormDialogState();
}

class _ResourceFormDialogState extends State<_ResourceFormDialog> {
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
        packId: widget.resource?.packId,
      ),
    );
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

class _MoveItemDialog extends ConsumerStatefulWidget {
  const _MoveItemDialog({required this.bundle});

  final ItemBundle bundle;

  @override
  ConsumerState<_MoveItemDialog> createState() => _MoveItemDialogState();
}

class _MoveItemDialogState extends ConsumerState<_MoveItemDialog> {
  static const _unassignedPackValue = 'unassigned';
  static const _newPackValue = 'new-pack';

  late String _selectedPackValue;
  ItemPackInput? _pendingPack;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPackValue = widget.bundle.pack.isSystemDefault
        ? _unassignedPackValue
        : _packValue(widget.bundle.pack.id);
  }

  @override
  Widget build(BuildContext context) {
    final activePacksAsync = ref.watch(activeItemPacksProvider);
    return AlertDialog(
      title: const Text(ReminderUiText.moveItemTitle),
      content: SizedBox(
        width: 480,
        child: activePacksAsync.when(
          data: (packs) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bundle.item.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('move-pack-field'),
                initialValue: _selectedPackValue,
                decoration: const InputDecoration(
                  labelText: ReminderUiText.moveDestinationFieldLabel,
                ),
                items: _packOptions(packs),
                onChanged: _isSaving
                    ? null
                    : (value) {
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
                  key: const Key('move-item-add-pack-button'),
                  onPressed: _isSaving
                      ? null
                      : () async {
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
            ],
          ),
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('move-item-confirm-button'),
          onPressed: _isSaving ? null : _submit,
          child: const Text(ReminderUiText.confirmAction),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _packOptions(List<ItemPack> packs) {
    return [
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
  }

  Future<void> _submit() async {
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
      await repository.moveItemToPack(
        widget.bundle.item.id,
        packId: packId,
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
          config: _configController.buildConfigForCreate(),
          packId: packId,
        ),
        newPack: newPack,
        resourceBindings: _resourceBindingDrafts
            .map((draft) => draft.toInput())
            .toList(growable: false),
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

  int? _resolvedPackId(List<ItemPack> packs) {
    if (_selectedPackValue == _newPackValue) {
      return null;
    }
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
