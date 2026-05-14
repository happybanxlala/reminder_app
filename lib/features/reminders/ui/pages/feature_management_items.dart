part of 'feature_management_sections.dart';

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
