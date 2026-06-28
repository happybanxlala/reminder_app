part of 'feature_page.dart';

class ItemActivityPage extends ConsumerStatefulWidget {
  const ItemActivityPage({super.key});

  static const routeName = 'item-activity';
  static const routePath = '/activity';
  static const legacyRoutePath = '/feature/item-activity';

  @override
  ConsumerState<ItemActivityPage> createState() => _ItemActivityPageState();
}

class _ItemActivityPageState extends ConsumerState<ItemActivityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.itemActivityFeatureTitle),
      ),
      body: const ItemActivityContent(),
    );
  }
}

class ItemActivityContent extends ConsumerStatefulWidget {
  const ItemActivityContent({super.key});

  @override
  ConsumerState<ItemActivityContent> createState() =>
      _ItemActivityContentState();
}

class _ItemActivityContentState extends ConsumerState<ItemActivityContent> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final state = ref.watch(itemActivityFeedControllerProvider);

    if (_searchController.text != state.query) {
      _searchController.value = _searchController.value.copyWith(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
        composing: TextRange.empty,
      );
    }

    return ReminderRefreshable(
      onRefresh: () =>
          ref.read(itemActivityFeedControllerProvider.notifier).refresh(),
      child: ListView(
        key: const Key('item-activity-page'),
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(ReminderSpacing.page),
        children: [
          TextField(
            key: const Key('item-activity-search-field'),
            controller: _searchController,
            onChanged: (value) {
              ref
                  .read(itemActivityFeedControllerProvider.notifier)
                  .setQuery(value);
            },
            decoration: InputDecoration(
              hintText: ReminderUiText.itemActivitySearchHint,
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: state.query.trim().isEmpty
                  ? null
                  : IconButton(
                      key: const Key('item-activity-search-clear'),
                      onPressed: () {
                        ref
                            .read(itemActivityFeedControllerProvider.notifier)
                            .setQuery('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: ReminderSpacing.listGap),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null && state.items.isEmpty)
            Text(state.errorMessage!)
          else if (state.items.isEmpty)
            Text(
              state.isSearching
                  ? ReminderUiText.noActivitySearchResults
                  : ReminderUiText.noRecentActivity,
            )
          else ...[
            ...state.items.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: ReminderSpacing.listGap),
                child: _ActivityEntryCard(
                  entry: entry,
                  previewDate: previewDate,
                ),
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(state.errorMessage!),
            ],
            if (state.canLoadMoreAttempt) ...[
              const SizedBox(height: 4),
              Center(
                child: state.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )
                    : OutlinedButton(
                        key: const Key('item-activity-load-more'),
                        onPressed: () {
                          ref
                              .read(itemActivityFeedControllerProvider.notifier)
                              .loadMore();
                        },
                        child: const Text(ReminderUiText.loadMoreAction),
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActivityEntryCard extends StatelessWidget {
  const _ActivityEntryCard({required this.entry, required this.previewDate});

  final ItemActivityFeedEntry entry;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final bundle = entry.bundle;
    final packTitle = bundle.pack.isSystemDefault
        ? ReminderUiText.unassignedPackTitle
        : bundle.pack.title;
    final sharedEntry = entry is SharedRemoteItemActivityFeedEntry
        ? entry as SharedRemoteItemActivityFeedEntry
        : null;
    final localEntry = entry is LocalItemActivityFeedEntry
        ? entry as LocalItemActivityFeedEntry
        : null;
    final title = sharedEntry?.message ?? entry.itemTitle;
    final actionLabel = localEntry == null
        ? entry.itemTitle
        : ReminderFormatters.itemActionType(localEntry.entry.record.actionType);
    final actionIcon = localEntry == null
        ? itemActivityActionIcon(_remoteActivityActionType(sharedEntry!.entry))
        : itemActivityActionIcon(localEntry.entry.record.actionType);

    return Card(
      child: ListTile(
        key: Key('item-activity-entry-${entry.stableKey}'),
        onTap: () =>
            showItemSummaryDialog(context, bundle, previewDate: previewDate),
        leading: Icon(actionIcon),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(actionLabel),
            Text(
              '${ReminderUiText.itemActivityTimeLabel}：${ReminderFormatters.dateTime(entry.occurredAt)}',
            ),
            Text('${ReminderUiText.itemActivityPackLabel}：$packTitle'),
          ],
        ),
      ),
    );
  }

  ItemActionType? _remoteActivityActionType(SharedItemActivityEntry entry) {
    return switch (entry.event.action) {
      'item_created' => ItemActionType.created,
      'item_completed' => ItemActionType.done,
      'item_undone' => ItemActionType.reverted,
      _ => null,
    };
  }
}
