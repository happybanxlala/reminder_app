part of 'feature_page.dart';

class ItemPacksManagementPage extends StatelessWidget {
  const ItemPacksManagementPage({super.key});

  static const routeName = 'item-packs-management';
  static const routePath = '/feature/item-packs-management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.itemPacksManagementFeatureTitle),
      ),
      body: const PackManagementContent(),
    );
  }
}

class PackManagementContent extends ConsumerWidget {
  const PackManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(activeItemPacksProvider);
    return ReminderRefreshable(
      onRefresh: () async {
        ref.invalidate(activeItemPacksProvider);
        await Future<void>.delayed(Duration.zero);
      },
      child: ListView(
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(ReminderSpacing.page),
        children: [
          _PackTemplateEntryCard(
            onTap: () => _showPackTemplatePicker(context, ref),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('pack-management-add'),
                onPressed: () => _showPackDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text(ReminderUiText.addItemPack),
              ),
              OutlinedButton.icon(
                key: const Key('pack-management-join'),
                onPressed: () => _showJoinPackDialog(context, ref),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text(ReminderUiText.packCareJoinAction),
              ),
            ],
          ),
          const SizedBox(height: ReminderSpacing.section),
          packsAsync.when(
            data: (packs) {
              if (packs.isEmpty) {
                return const Text(ReminderUiText.noItemPacks);
              }
              final customPacks = packs
                  .where((pack) => !pack.isSystemDefault)
                  .toList(growable: false);
              return Column(
                children: [
                  for (final pack in packs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PackManagementTile(
                        pack: pack,
                        customPacks: customPacks,
                      ),
                    ),
                ],
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Future<void> _showPackDialog(
    BuildContext context,
    WidgetRef ref, {
    ItemPack? pack,
  }) async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => PackFormDialog(
        pack: pack,
        showTemplateEntry: pack == null,
        onCreateFromTemplate: pack == null
            ? () {
                Future<void>.microtask(() {
                  if (context.mounted) {
                    _showPackTemplatePicker(context, ref);
                  }
                });
              }
            : null,
      ),
    );
    if (input == null || !context.mounted) {
      return;
    }
    final repository = ref.read(itemRepositoryProvider);
    if (pack == null) {
      await repository.createPack(input);
    } else {
      await repository.updatePack(pack.id, input);
    }
  }

  Future<void> _showJoinPackDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var isJoining = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> join() async {
            if (isJoining) {
              return;
            }
            setState(() => isJoining = true);
            final result = await ref
                .read(sharedPackCareControllerProvider)
                .joinWithInviteCode(controller.text);
            if (!context.mounted) {
              return;
            }
            setState(() => isJoining = false);
            if (!result.succeeded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.errorMessage ??
                        ReminderUiText.packCareRemoteUnavailable,
                  ),
                ),
              );
              return;
            }
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ReminderUiText.packCareJoinSuccess(result.packTitle!),
                ),
              ),
            );
          }

          return AlertDialog(
            title: const Text(ReminderUiText.packCareJoinTitle),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('輸入對方提供的邀請碼。'),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('pack-care-join-code-input'),
                    controller: controller,
                    enabled: !isJoining,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: ReminderUiText.packCareJoinInputLabel,
                    ),
                    onSubmitted: (_) => join(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isJoining
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                key: const Key('pack-care-join-submit'),
                onPressed: isJoining ? null : join,
                child: isJoining
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(ReminderUiText.packCareJoinButton),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }
}

class _PackManagementTile extends ConsumerWidget {
  const _PackManagementTile({required this.pack, required this.customPacks});

  final ItemPack pack;
  final List<ItemPack> customPacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customIndex = customPacks.indexWhere((item) => item.id == pack.id);
    final isSystemDefault = pack.isSystemDefault;
    final careAsync = ref.watch(packCareViewModelProvider(pack));
    final statusLabel = careAsync.maybeWhen(
      data: (viewModel) => viewModel.rowStatusLabel,
      orElse: () => isSystemDefault
          ? ReminderUiText.systemDefaultPackLabel
          : pack.packType == ItemPackType.shared
          ? ReminderUiText.packCareMembersLabel(1)
          : ReminderUiText.packCareLocalOnlyLabel,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('pack-management-pack-${pack.id}'),
        leading: Text(
          pack.iconEmoji,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        title: Text(pack.title),
        subtitle: Text(statusLabel),
        trailing: isSystemDefault
            ? null
            : Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    key: Key('pack-up-${pack.id}'),
                    onPressed: customIndex > 0
                        ? () => ref
                              .read(itemRepositoryProvider)
                              .movePackUp(pack.id)
                        : null,
                    tooltip: '上',
                    icon: const Icon(Icons.keyboard_arrow_up),
                  ),
                  IconButton(
                    key: Key('pack-down-${pack.id}'),
                    onPressed:
                        customIndex >= 0 && customIndex < customPacks.length - 1
                        ? () => ref
                              .read(itemRepositoryProvider)
                              .movePackDown(pack.id)
                        : null,
                    tooltip: '下',
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  PopupMenuButton<_PackManagementMenuAction>(
                    key: Key('pack-overflow-${pack.id}'),
                    tooltip: ReminderUiText.itemActionMenuTitle,
                    onSelected: (action) =>
                        _handleMenuAction(context, ref, action),
                    itemBuilder: (menuContext) => [
                      const PopupMenuItem(
                        value: _PackManagementMenuAction.care,
                        child: Text(ReminderUiText.packCareAction),
                      ),
                      const PopupMenuItem(
                        value: _PackManagementMenuAction.edit,
                        child: Text(ReminderUiText.editAction),
                      ),
                      const PopupMenuItem(
                        value: _PackManagementMenuAction.saveAsTemplate,
                        child: Text(ReminderUiText.packTemplateSaveAsLabel),
                      ),
                      PopupMenuItem(
                        value: _PackManagementMenuAction.archive,
                        child: Text(
                          ReminderUiText.archiveAction,
                          style: TextStyle(
                            color: Theme.of(menuContext).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _PackManagementMenuAction action,
  ) async {
    switch (action) {
      case _PackManagementMenuAction.care:
        await _showPackCareSheet(context, ref);
        return;
      case _PackManagementMenuAction.edit:
        await _showEditDialog(context, ref);
        return;
      case _PackManagementMenuAction.saveAsTemplate:
        await _showSavePackTemplateDialog(context, ref, pack);
        return;
      case _PackManagementMenuAction.archive:
        await _showArchiveDialog(context, ref);
        return;
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => PackFormDialog(pack: pack),
    );
    if (input == null || !context.mounted) {
      return;
    }
    await ref.read(itemRepositoryProvider).updatePack(pack.id, input);
  }

  Future<void> _showArchiveDialog(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(itemRepositoryProvider);
    final contentCount = await repository.countPackManagedContents(pack.id);
    if (!context.mounted) {
      return;
    }
    if (contentCount == 0) {
      await repository.archivePackWithContents(pack.id);
      return;
    }
    final action = await showDialog<_ArchivePackAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ReminderUiText.archivePackConfirmTitle),
        content: const Text(ReminderUiText.archivePackConfirmMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ArchivePackAction.cancel),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ArchivePackAction.move),
            child: const Text('移到「一般」'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ArchivePackAction.archive),
            child: const Text('一起封存內容'),
          ),
        ],
      ),
    );
    if (action == null || action == _ArchivePackAction.cancel) {
      return;
    }
    switch (action) {
      case _ArchivePackAction.archive:
        await repository.archivePackWithContents(pack.id);
        return;
      case _ArchivePackAction.move:
        await repository.archivePackAndMoveContentsToDefault(pack.id);
        return;
      case _ArchivePackAction.cancel:
        return;
    }
  }

  Future<void> _showPackCareSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, child) {
          final careAsync = ref.watch(packCareViewModelProvider(pack));
          return careAsync.when(
            data: (viewModel) => _PackCareSheet(
              viewModel: viewModel,
              onEnsureInvite: () => ref
                  .read(sharedPackCareControllerProvider)
                  .ensureActiveInviteForPack(viewModel.pack),
              onRefreshInvite: () => ref
                  .read(sharedPackCareControllerProvider)
                  .refreshInviteForPack(viewModel.pack),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(ReminderSpacing.page),
              child: Text('讀取失敗: $error'),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(ReminderSpacing.page),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        },
      ),
    );
  }
}

enum _ArchivePackAction { archive, move, cancel }

enum _PackManagementMenuAction { care, edit, saveAsTemplate, archive }

class _PackCareSheet extends StatefulWidget {
  const _PackCareSheet({
    required this.viewModel,
    required this.onEnsureInvite,
    required this.onRefreshInvite,
  });

  final PackCareViewModel viewModel;
  final Future<PackCareInviteResult> Function() onEnsureInvite;
  final Future<PackCareInviteResult> Function() onRefreshInvite;

  @override
  State<_PackCareSheet> createState() => _PackCareSheetState();
}

class _PackCareSheetState extends State<_PackCareSheet> {
  bool _isUpdatingInvite = false;

  PackCareViewModel get viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final pack = viewModel.pack;
    final isAccessLost = viewModel.isAccessLost;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          ReminderSpacing.page,
          0,
          ReminderSpacing.page,
          ReminderSpacing.page,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccessLost
                  ? ReminderUiText.packCareAccessLostTitle(pack.title)
                  : ReminderUiText.packCareSheetTitle(pack.title),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (viewModel.bannerText != null) ...[
              _PackCareStatusBanner(message: viewModel.bannerText!),
              const SizedBox(height: 12),
            ],
            if (isAccessLost) ...[
              const Text(ReminderUiText.packCareAccessLostReason),
              const SizedBox(height: 8),
              const Text(ReminderUiText.packCareAccessLostGuard),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('知道了'),
                ),
              ),
            ] else if (!viewModel.isShared) ...[
              const Text(ReminderUiText.packCareOnlyHostBody),
              const SizedBox(height: 8),
              if (viewModel.hasActiveInvite) ...[
                Text(
                  ReminderUiText.packCareInviteExpiresAt(
                    ReminderFormatters.dateTime(
                      viewModel.activeInvite!.expiresAt,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PackCareInviteCard(
                  invite: viewModel.activeInvite!,
                  isUpdating: _isUpdatingInvite,
                  onRefresh: _confirmRefreshInvite,
                ),
              ] else if (viewModel.inviteState.latestInviteExpired) ...[
                const Text(ReminderUiText.packCareInviteExpiredBody),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: Key('pack-care-recreate-invite-${pack.id}'),
                  onPressed: _isUpdatingInvite ? null : _ensureInvite,
                  icon: _isUpdatingInvite
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text(ReminderUiText.packCareRecreateInviteCode),
                ),
              ] else ...[
                const Text(ReminderUiText.packCareInviteIntroBody),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: Key('pack-care-invite-${pack.id}'),
                  onPressed: _isUpdatingInvite ? null : _ensureInvite,
                  icon: _isUpdatingInvite
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text(ReminderUiText.packCareInviteAction),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                ReminderUiText.packCareDataProtectionNote,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
              ),
            ] else ...[
              Text(_sharedBodyText(viewModel)),
              if (viewModel.members.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final member in viewModel.members)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(member.displayName),
                    subtitle: Text(member.roleLabel),
                  ),
              ],
              const SizedBox(height: 12),
              if (viewModel.hasActiveInvite)
                _PackCareInviteCard(
                  invite: viewModel.activeInvite!,
                  isUpdating: _isUpdatingInvite,
                  onRefresh: _confirmRefreshInvite,
                )
              else if (viewModel.inviteState.latestInviteExpired) ...[
                const Text(ReminderUiText.packCareInviteExpiredBody),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: Key('pack-care-recreate-invite-${pack.id}'),
                  onPressed: _isUpdatingInvite ? null : _ensureInvite,
                  icon: const Icon(Icons.refresh),
                  label: const Text(ReminderUiText.packCareRecreateInviteCode),
                ),
              ] else
                FilledButton.icon(
                  key: Key('pack-care-invite-more-${pack.id}'),
                  onPressed: _isUpdatingInvite ? null : _ensureInvite,
                  icon: _isUpdatingInvite
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text(ReminderUiText.packCareInviteMoreAction),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _sharedBodyText(PackCareViewModel viewModel) {
    if (viewModel.activeMemberCount <= 1) {
      return ReminderUiText.packCareOnlyHostBody;
    }
    return ReminderUiText.packCareSharedActiveBody(viewModel.activeMemberCount);
  }

  Future<void> _ensureInvite() async {
    await _runInviteAction(widget.onEnsureInvite);
  }

  Future<void> _confirmRefreshInvite() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ReminderUiText.packCareInviteRefreshTitle),
        content: const Text(ReminderUiText.packCareInviteRefreshBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            key: const Key('pack-care-refresh-invite-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('刷新'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runInviteAction(widget.onRefreshInvite);
    }
  }

  Future<void> _runInviteAction(
    Future<PackCareInviteResult> Function() action,
  ) async {
    if (_isUpdatingInvite) {
      return;
    }
    setState(() => _isUpdatingInvite = true);
    final result = await action();
    if (!mounted) {
      return;
    }
    setState(() => _isUpdatingInvite = false);
    if (!result.succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? ReminderUiText.packCareRemoteUnavailable,
          ),
        ),
      );
      return;
    }
    if (result.warningMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.warningMessage!)));
    }
  }
}

class _PackCareInviteCard extends StatelessWidget {
  const _PackCareInviteCard({
    required this.invite,
    required this.isUpdating,
    required this.onRefresh,
  });

  final RemotePackInvite invite;
  final bool isUpdating;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final displayCode = groupedInviteCode(invite.inviteCode);
    return Container(
      key: const Key('pack-care-active-invite-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReminderUiText.packCareInviteExpiresAt(
              ReminderFormatters.dateTime(invite.expiresAt),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            displayCode,
            key: const Key('pack-care-invite-code'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('pack-care-share-invite-code'),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(text: normalizeInviteCode(invite.inviteCode)),
                  );
                },
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text(ReminderUiText.packCareShareInviteCode),
              ),
              OutlinedButton.icon(
                key: const Key('pack-care-copy-invite-code'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: normalizeInviteCode(invite.inviteCode)),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(ReminderUiText.packCareCopiedInviteCode),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text(ReminderUiText.packCareCopyInviteCode),
              ),
              TextButton.icon(
                key: const Key('pack-care-refresh-invite-code'),
                onPressed: isUpdating ? null : onRefresh,
                icon: isUpdating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text(ReminderUiText.packCareRefreshInviteCode),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackCareStatusBanner extends StatelessWidget {
  const _PackCareStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.statusWarningContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PackTemplateEntryCard extends StatelessWidget {
  const _PackTemplateEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      key: const Key('pack-template-entry-card'),
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(14),
      child: InkWell(
        key: const Key('pack-template-entry-action'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ReminderIconBubble(
              backgroundColor: palette.primaryWarmContainer,
              child: Icon(
                Icons.auto_awesome_outlined,
                color: palette.primaryWarm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ReminderUiText.packTemplatesEntryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ReminderUiText.packTemplatesEntrySubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PackTemplatePickerResult {
  const _PackTemplatePickerResult.template(this.template)
    : createFromExisting = false;

  const _PackTemplatePickerResult.createFromExisting()
    : template = null,
      createFromExisting = true;

  final PackTemplate? template;
  final bool createFromExisting;
}

Future<void> _showPackTemplatePicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await showDialog<_PackTemplatePickerResult>(
    context: context,
    builder: (dialogContext) => const _PackTemplatePickerDialog(),
  );
  if (result == null || !context.mounted) {
    return;
  }
  final template = result.template;
  if (template != null) {
    await _showPackTemplatePreview(context, ref, template);
    return;
  }
  await _showCreateCustomTemplateFromPack(context, ref);
}

Future<void> _showPackTemplatePreview(
  BuildContext context,
  WidgetRef ref,
  PackTemplate template,
) async {
  final repository = ref.read(itemRepositoryProvider);
  final duplicate = await repository.activePackTitleExists(template.packName);
  if (!context.mounted) {
    return;
  }
  final useTemplate = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _PackTemplatePreviewDialog(
      template: template,
      duplicatePackName: duplicate,
    ),
  );
  if (useTemplate != true || !context.mounted) {
    return;
  }
  if (duplicate) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ReminderUiText.packTemplateDuplicateConfirmTitle),
        content: const Text(ReminderUiText.packTemplateDuplicateConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ReminderUiText.packTemplateContinueCreateAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
  }
  final created = await repository.createPackFromTemplate(template);
  if (!context.mounted) {
    return;
  }
  ref.invalidate(activeItemPacksProvider);
  ref.invalidate(itemManagementGroupsProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ReminderUiText.packTemplateCreatedMessage(created.packName),
      ),
      action: SnackBarAction(
        label: ReminderUiText.packTemplateViewAction,
        onPressed: () => context.goNamed(ItemsManagementPage.routeName),
      ),
    ),
  );
}

Future<void> _showCreateCustomTemplateFromPack(
  BuildContext context,
  WidgetRef ref,
) async {
  final packs =
      ref.read(activeItemPacksProvider).valueOrNull ?? const <ItemPack>[];
  final customPacks = packs.where((pack) => !pack.isSystemDefault).toList();
  final selected = await showDialog<ItemPack>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(ReminderUiText.packTemplateCreateFromExistingLabel),
      content: SizedBox(
        width: 420,
        child: customPacks.isEmpty
            ? const Text(ReminderUiText.noItemPacks)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final pack in customPacks)
                      _TemplatePackSelectionRow(pack: pack),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            MaterialLocalizations.of(dialogContext).cancelButtonLabel,
          ),
        ),
      ],
    ),
  );
  if (selected == null || !context.mounted) {
    return;
  }
  await _showSavePackTemplateDialog(context, ref, selected);
}

Future<void> _showSavePackTemplateDialog(
  BuildContext context,
  WidgetRef ref,
  ItemPack pack,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _SavePackTemplateDialog(pack: pack),
  );
}

class _PackTemplatePickerDialog extends ConsumerWidget {
  const _PackTemplatePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(packTemplatesProvider);
    return AlertDialog(
      title: const Text(ReminderUiText.packTemplatePickerTitle),
      content: SizedBox(
        width: 460,
        child: templatesAsync.when(
          data: (templates) {
            final defaults = templates
                .where(
                  (template) =>
                      template.source == PackTemplateSource.defaultTemplate,
                )
                .toList(growable: false);
            final custom = templates
                .where(
                  (template) => template.source == PackTemplateSource.custom,
                )
                .toList(growable: false);
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TemplateSectionTitle(
                    ReminderUiText.packTemplateDefaultSectionTitle,
                  ),
                  for (final template in defaults)
                    _TemplatePickerRow(template: template),
                  const SizedBox(height: 12),
                  _TemplateSectionTitle(
                    ReminderUiText.packTemplateCustomSectionTitle,
                  ),
                  if (custom.isEmpty)
                    const _TemplateEmptyCustomState()
                  else
                    for (final template in custom)
                      _TemplatePickerRow(template: template),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('pack-template-create-from-existing'),
                      onPressed: () => Navigator.of(context).pop(
                        const _PackTemplatePickerResult.createFromExisting(),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        ReminderUiText.packTemplateCreateFromExistingLabel,
                      ),
                    ),
                  ),
                ],
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

class _TemplateSectionTitle extends StatelessWidget {
  const _TemplateSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.reminderPalette.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TemplatePickerRow extends StatelessWidget {
  const _TemplatePickerRow({required this.template});

  final PackTemplate template;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('pack-template-row-${template.id}'),
          onTap: () => Navigator.of(
            context,
          ).pop(_PackTemplatePickerResult.template(template)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: palette.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              children: [
                Text(template.iconEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.templateName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ReminderUiText.packTemplateItemsCount(
                          template.items.length,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: palette.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateEmptyCustomState extends StatelessWidget {
  const _TemplateEmptyCustomState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pack-template-custom-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.reminderPalette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.reminderPalette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReminderUiText.packTemplateNoCustomTitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            ReminderUiText.packTemplateNoCustomSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.reminderPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackTemplatePreviewDialog extends StatelessWidget {
  const _PackTemplatePreviewDialog({
    required this.template,
    required this.duplicatePackName,
  });

  final PackTemplate template;
  final bool duplicatePackName;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return AlertDialog(
      title: Text(template.templateName),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReminderUiText.packTemplateWillCreateLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ReminderPaperCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: palette.surfaceWarm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ReminderUiText.packTemplatePackNameLabel}：${template.packName}',
                      key: const Key('pack-template-preview-pack-name'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReminderUiText.packTemplateItemsCount(
                        template.items.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (duplicatePackName) ...[
                const SizedBox(height: 8),
                Text(
                  ReminderUiText.packTemplateDuplicatePackWarning,
                  key: const Key('pack-template-duplicate-warning'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              for (final item in template.items)
                _TemplatePreviewItemRow(item: item),
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
          key: const Key('pack-template-use-button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(ReminderUiText.packTemplatePreviewCreateLabel),
        ),
      ],
    );
  }
}

class _TemplatePreviewItemRow extends StatelessWidget {
  const _TemplatePreviewItemRow({required this.item});

  final PackTemplateItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•'),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  key: Key('pack-template-preview-item-${item.title}'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _templateScheduleSummary(item.config),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.reminderPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _templateScheduleSummary(ItemConfig config) {
  return switch (config) {
    FixedItemConfig fixed => ReminderFormatters.fixedScheduleSummary(fixed),
    StateBasedItemConfig state => ReminderFormatters.attentionPolicySummary(
      state,
    ),
    _ => '',
  };
}

class _TemplatePackSelectionRow extends StatelessWidget {
  const _TemplatePackSelectionRow({required this.pack});

  final ItemPack pack;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('pack-template-source-pack-${pack.id}'),
      leading: Text(pack.iconEmoji),
      title: Text(pack.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(pack),
    );
  }
}

class _SavePackTemplateDialog extends ConsumerStatefulWidget {
  const _SavePackTemplateDialog({required this.pack});

  final ItemPack pack;

  @override
  ConsumerState<_SavePackTemplateDialog> createState() =>
      _SavePackTemplateDialogState();
}

class _SavePackTemplateDialogState
    extends ConsumerState<_SavePackTemplateDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pack.title);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(packManagementItemsProvider);
    final items =
        itemsAsync.valueOrNull
            ?.where((bundle) => bundle.item.packId == widget.pack.id)
            .where((bundle) => bundle.item.status == ItemLifecycleStatus.active)
            .toList(growable: false) ??
        const <ItemBundle>[];
    return AlertDialog(
      title: const Text(ReminderUiText.packTemplateSaveAsTitle),
      content: SizedBox(
        width: 440,
        child: itemsAsync.isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        key: const Key('pack-template-name-field'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: ReminderUiText.packTemplateNameLabel,
                        ),
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ? '請輸入模版名稱' : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ReminderUiText.packTemplateItemsCount(items.length),
                        key: const Key('pack-template-save-item-count'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (items.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ReminderUiText.packTemplateEmptyPackMessage,
                          key: const Key('pack-template-empty-pack-message'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        for (final bundle in items.take(7))
                          Text(
                            '• ${bundle.item.title}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('pack-template-save-button'),
          onPressed: _isSaving || items.isEmpty ? null : _save,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await ref
          .read(packTemplateRepositoryProvider)
          .savePackAsTemplate(
            packId: widget.pack.id,
            templateName: _nameController.text,
          );
      ref.invalidate(packTemplatesProvider);
      ref.invalidate(customPackTemplatesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
