import '../../reminders/data/home_models.dart';
import '../../reminders/data/home_repository.dart';
import '../../reminders/domain/resource.dart';
import '../../reminders/presentation/formatters/reminder_formatters.dart';
import '../../reminders/presentation/text/reminder_ui_text.dart';
import '../../reminders/presentation/view_models/item_card_view_model.dart';
import '../data/home_widget_entry.dart';
import '../data/home_widget_snapshot.dart';
import '../data/home_widget_tab.dart';

class HomeWidgetSnapshotService {
  const HomeWidgetSnapshotService({
    required HomeAttentionSource homeRepository,
    required DateTime currentDate,
    DateTime Function()? clock,
  }) : _homeRepository = homeRepository,
       _currentDate = currentDate,
       _clock = clock;

  final HomeAttentionSource _homeRepository;
  final DateTime _currentDate;
  final DateTime Function()? _clock;

  Future<HomeWidgetSnapshot> buildSnapshot({
    HomeWidgetTabId selectedTab = HomeWidgetTabId.needsHandling,
  }) async {
    final dangerFuture = _homeRepository
        .watchDangerAttentionEntries(now: _currentDate)
        .first;
    final warningFuture = _homeRepository
        .watchWarningAttentionEntries(now: _currentDate)
        .first;
    final completedFuture = _homeRepository
        .watchTodayCompletedEntries(now: _currentDate)
        .first;

    final dangerEntries = await dangerFuture;
    final warningEntries = await warningFuture;
    final completedEntries = await completedFuture;

    return HomeWidgetSnapshot(
      schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
      updatedAt: _clock?.call() ?? DateTime.now(),
      selectedTab: selectedTab,
      tabs: [
        _attentionTab(
          id: HomeWidgetTabId.needsHandling,
          entries: dangerEntries,
        ),
        _attentionTab(id: HomeWidgetTabId.attention, entries: warningEntries),
        _completedTab(completedEntries),
      ],
    );
  }

  HomeWidgetTab _attentionTab({
    required HomeWidgetTabId id,
    required List<HomeAttentionEntry> entries,
  }) {
    final rows = entries
        .where(_isWidgetEligibleAttentionEntry)
        .map(_attentionEntry)
        .toList(growable: false);
    return HomeWidgetTab(
      id: id,
      label: id.label,
      count: rows.length,
      entries: rows,
    );
  }

  HomeWidgetEntry _attentionEntry(HomeAttentionEntry entry) {
    return switch (entry.type) {
      HomeAttentionEntryType.item => _itemAttentionEntry(entry),
      HomeAttentionEntryType.resource => _resourceAttentionEntry(entry),
    };
  }

  HomeWidgetEntry _itemAttentionEntry(HomeAttentionEntry entry) {
    final itemEntry = entry.itemEntry!;
    final viewModel = ItemCardViewModel.fromEntry(itemEntry, now: _currentDate);
    return HomeWidgetEntry(
      entryId: entry.stableKey,
      type: HomeWidgetEntryType.itemAttention,
      targetId: viewModel.id,
      title: viewModel.title,
      statusText:
          viewModel.trailingLabel ??
          ReminderFormatters.itemStatus(itemEntry.status),
      displayIcon: itemEntry.bundle.pack.iconEmoji,
      buttonText: ReminderUiText.completeAction,
      action: HomeWidgetEntryAction.complete,
      canAct: viewModel.canComplete,
    );
  }

  HomeWidgetEntry _resourceAttentionEntry(HomeAttentionEntry entry) {
    final bundle = entry.resourceBundle!;
    final resource = bundle.resource;
    return HomeWidgetEntry(
      entryId: entry.stableKey,
      type: HomeWidgetEntryType.resourceAttention,
      targetId: resource.id,
      title: resource.title,
      statusText: _resourceStatusText(resource),
      displayIcon: bundle.pack.iconEmoji,
      canAct: false,
    );
  }

  String _resourceStatusText(Resource resource) {
    return ReminderFormatters.resourceCompactRemainingSummary(
      resource,
      now: _currentDate,
    );
  }

  HomeWidgetTab _completedTab(List<TodayCompletedEntry> entries) {
    final rows = entries
        .where(_isWidgetEligibleCompletedEntry)
        .map(_completedEntry)
        .toList(growable: false);
    return HomeWidgetTab(
      id: HomeWidgetTabId.todayCompleted,
      label: HomeWidgetTabId.todayCompleted.label,
      count: rows.length,
      entries: rows,
    );
  }

  HomeWidgetEntry _completedEntry(TodayCompletedEntry entry) {
    return switch (entry.type) {
      TodayCompletedEntryType.itemDone => _completedItemEntry(entry),
      TodayCompletedEntryType.resourceRefilled => _completedResourceEntry(
        entry,
        statusText: '已補充',
      ),
      TodayCompletedEntryType.resourceAdjusted => _completedResourceEntry(
        entry,
        statusText: '已修正',
      ),
      TodayCompletedEntryType.stageAcknowledged => HomeWidgetEntry(
        entryId: entry.stableKey,
        type: HomeWidgetEntryType.completedStage,
        actionRecordId: entry.stageRecord?.id,
        title: entry.title,
        statusText: ReminderUiText.acknowledgedAction,
        canAct: false,
      ),
    };
  }

  HomeWidgetEntry _completedItemEntry(TodayCompletedEntry entry) {
    final record = entry.itemActionRecord;
    final canUndo = entry.canUndo && record != null;
    return HomeWidgetEntry(
      entryId: entry.stableKey,
      type: HomeWidgetEntryType.completedItem,
      targetId: record?.itemId,
      actionRecordId: record?.id,
      title: entry.title,
      statusText: ReminderUiText.completeAction,
      buttonText: canUndo ? '復原' : null,
      action: canUndo ? HomeWidgetEntryAction.undo : null,
      canAct: canUndo,
    );
  }

  HomeWidgetEntry _completedResourceEntry(
    TodayCompletedEntry entry, {
    required String statusText,
  }) {
    final record = entry.resourceActionRecord;
    return HomeWidgetEntry(
      entryId: entry.stableKey,
      type: HomeWidgetEntryType.completedResource,
      targetId: record?.resourceId,
      actionRecordId: record?.id,
      title: entry.title,
      statusText: statusText,
      canAct: false,
    );
  }

  bool _isWidgetEligibleAttentionEntry(HomeAttentionEntry entry) {
    final itemEntry = entry.itemEntry;
    return itemEntry == null || !itemEntry.syncStatus.isRemoteBacked;
  }

  bool _isWidgetEligibleCompletedEntry(TodayCompletedEntry entry) {
    return entry.type != TodayCompletedEntryType.itemDone ||
        !entry.itemSyncStatus.isRemoteBacked;
  }
}
