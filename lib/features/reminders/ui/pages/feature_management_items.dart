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

    return ReminderPaperCard(
      key: Key('pack-section-${pack.id}'),
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
                            ReminderIconBubble(
                              size: 40,
                              child: Text(pack.iconEmoji),
                            ),
                            Text(
                              isUnassigned ? pack.title : pack.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        if (!isUnassigned &&
                            (pack.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(pack.description!.trim()),
                        ],
                        const SizedBox(height: 4),
                        ReminderBadge(
                          label:
                              '${items.length} ${ReminderUiText.itemCountLabel}',
                          icon: Icons.checklist_outlined,
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
            const SizedBox(height: ReminderSpacing.listGap),
            if (items.isEmpty)
              const ReminderEmptyState(message: ReminderUiText.emptyPackHint)
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

    final palette = context.reminderPalette;
    return ReminderRailCard(
      key: Key('item-card-${bundle.item.id}'),
      railColor: viewModel.status.color,
      padding: const EdgeInsets.all(ReminderSpacing.cardCompact),
      child: InkWell(
        onTap: () =>
            showItemSummaryDialog(context, bundle, previewDate: previewDate),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReminderIconBubble(
                size: 44,
                backgroundColor: palette.primaryWarmContainer,
                child: Icon(viewModel.typeIcon, color: palette.primaryWarm),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      key: Key('item-type-icon-${bundle.item.id}'),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ReminderBadge(
                          label: viewModel.typeLabel,
                          color: palette.primaryWarmDark,
                          backgroundColor: palette.primaryWarmContainer,
                        ),
                        ReminderBadge(
                          label: viewModel.status.label,
                          icon: viewModel.isPaused
                              ? Icons.pause_circle_outline
                              : null,
                          color: viewModel.status.color,
                          backgroundColor: viewModel.status.color.withValues(
                            alpha: 0.12,
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
