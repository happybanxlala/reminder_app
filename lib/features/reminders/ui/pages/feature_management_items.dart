part of 'feature_management_sections.dart';

class _ManagementDensity {
  const _ManagementDensity._();

  static const pagePadding = 12.0;
  static const groupGap = 8.0;
  static const itemGap = 6.0;
  static const groupPadding = 10.0;
  static const itemPaddingVertical = 7.0;
  static const itemPaddingHorizontal = 10.0;
  static const cardRadius = 16.0;
  static const packChipSize = 26.0;

  static const itemPadding = EdgeInsets.symmetric(
    vertical: itemPaddingVertical,
    horizontal: itemPaddingHorizontal,
  );
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

class _ItemManagementHeader extends StatelessWidget {
  const _ItemManagementHeader({
    required this.onOpenResources,
    required this.onAddItem,
  });

  final VoidCallback onOpenResources;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            ReminderUiText.itemTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          key: const Key('resource-management-button'),
          onPressed: onOpenResources,
          tooltip: '資源管理',
          icon: const Icon(Icons.inventory_2_outlined),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        IconButton.filled(
          key: const Key('add-item-button'),
          onPressed: onAddItem,
          tooltip: ReminderUiText.addItem,
          icon: const Icon(Icons.add),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
      ],
    );
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

    return ReminderPaperCard(
      key: Key('pack-section-${pack.id}'),
      padding: const EdgeInsets.all(_ManagementDensity.groupPadding),
      radius: _ManagementDensity.cardRadius,
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
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _PackEmojiMiniChip(emoji: pack.iconEmoji),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pack.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${items.length} 項',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        context.reminderPalette.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        if (expanded &&
                            !isUnassigned &&
                            (pack.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            pack.description!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.reminderPalette.textSecondary,
                                ),
                          ),
                        ],
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
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
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
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: _ManagementDensity.itemGap),
            if (items.isEmpty)
              const _CompactPackEmptyRow()
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(
                    top: _ManagementDensity.itemGap,
                  ),
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

class _PackEmojiMiniChip extends StatelessWidget {
  const _PackEmojiMiniChip({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: _ManagementDensity.packChipSize,
      height: _ManagementDensity.packChipSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        shape: BoxShape.circle,
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 15)),
    );
  }
}

class _CompactPackEmptyRow extends StatelessWidget {
  const _CompactPackEmptyRow();

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: double.infinity,
      padding: _ManagementDensity.itemPadding,
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        ReminderUiText.emptyPackHint,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
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
    final syncStatus = ref
        .watch(itemSyncStatusesProvider)
        .maybeWhen(
          data: (statuses) => statuses[bundle.item.id],
          orElse: () => null,
        );
    final syncStatusLabel = _managementSyncStatusLabel(syncStatus);

    return ReminderRailCard(
      key: Key('item-card-${bundle.item.id}'),
      railColor: viewModel.status.color,
      padding: _ManagementDensity.itemPadding,
      radius: _ManagementDensity.cardRadius,
      child: InkWell(
        key: Key('item-card-body-${bundle.item.id}'),
        onTap: () =>
            showItemSummaryDialog(context, bundle, previewDate: previewDate),
        borderRadius: BorderRadius.circular(_ManagementDensity.cardRadius),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      key: Key('item-title-${bundle.item.id}'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${viewModel.compactTypeLabel}・${viewModel.compactSummaryLabel}',
                      key: Key('item-compact-summary-${bundle.item.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.reminderPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (syncStatusLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        syncStatusLabel,
                        key: Key('managed-item-sync-status-${bundle.item.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.reminderPalette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: Key('item-overflow-${bundle.item.id}'),
                onPressed: syncStatus?.isAccessLost == true
                    ? null
                    : () => _showManagedItemActionSheet(
                        context,
                        ref,
                        bundle,
                        previewDate,
                        viewModel,
                      ),
                tooltip: ReminderUiText.itemActionMenuTitle,
                icon: const Icon(Icons.more_vert),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _managementSyncStatusLabel(HomeItemSyncStatus? status) {
  if (status == null || !status.isRemoteBacked) {
    return null;
  }
  if (status.isAccessLost) {
    return ReminderUiText.syncAccessLostLabel;
  }
  if (status.hasFailedMutation ||
      (status.lastSyncError?.trim().isNotEmpty ?? false)) {
    return ReminderUiText.syncFailedLabel;
  }
  if (status.pendingMutationStatus == SyncOutboxStatus.syncing) {
    return ReminderUiText.syncSyncingLabel;
  }
  if (status.pendingMutationStatus == SyncOutboxStatus.pending) {
    return ReminderUiText.syncPendingLabel;
  }
  if (status.isStale) {
    return ReminderUiText.syncNeedsRefreshLabel;
  }
  return null;
}

enum _ManagedItemMenuAction {
  edit,
  details,
  history,
  complete,
  skip,
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
                key: Key('item-menu-edit-${bundle.item.id}'),
                label: ReminderUiText.editAction,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ManagedItemMenuAction.edit),
              ),
              _ItemActionSheetTile(
                key: Key('item-menu-details-${bundle.item.id}'),
                label: ReminderUiText.itemDetailAction,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ManagedItemMenuAction.details),
              ),
              _ItemActionSheetTile(
                key: Key('item-menu-history-${bundle.item.id}'),
                label: ReminderUiText.itemHistoryMenuLabel,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ManagedItemMenuAction.history),
              ),
              const Divider(height: 16),
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
    case _ManagedItemMenuAction.edit:
      context.pushNamed(
        ItemEditPage.editRouteName,
        pathParameters: {'id': bundle.item.id.toString()},
      );
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
    case _ManagedItemMenuAction.complete:
      await _handleManagedItemComplete(
        context,
        ref,
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
        final archived = await repository.archiveItem(bundle.item.id);
        if (archived &&
            await repository.isRemoteBackedPack(bundle.item.packId)) {
          unawaited(
            ref
                .read(remoteBackedSyncCoordinatorProvider)
                .syncAfterRemoteBackedMutation(bundle.item.packId),
          );
        }
      }
      return;
  }
}

Future<void> _handleManagedItemComplete(
  BuildContext context,
  WidgetRef ref,
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

  final completed = await repository.markDone(
    bundle.item.id,
    doneAt: previewDate,
  );
  if (completed && await repository.isRemoteBackedPack(bundle.item.packId)) {
    unawaited(
      ref
          .read(remoteBackedSyncCoordinatorProvider)
          .syncAfterRemoteBackedMutation(bundle.item.packId),
    );
  }
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
