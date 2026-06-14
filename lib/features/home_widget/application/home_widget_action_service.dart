import '../../reminders/data/item_repository.dart';
import '../data/home_widget_entry.dart';
import '../data/home_widget_native_bridge.dart';
import '../data/home_widget_snapshot.dart';
import '../data/home_widget_snapshot_store.dart';
import '../data/home_widget_tab.dart';
import 'home_widget_snapshot_service.dart';

abstract class HomeWidgetActionExecutor {
  Future<HomeWidgetSnapshot> refreshSnapshot({HomeWidgetTabId? selectedTab});

  Future<bool> completeEntry(String entryId);

  Future<bool> undoCompletedEntry(String entryId);
}

class HomeWidgetActionService implements HomeWidgetActionExecutor {
  const HomeWidgetActionService({
    required HomeWidgetSnapshotService snapshotService,
    required HomeWidgetSnapshotStore snapshotStore,
    required ItemRepository itemRepository,
    required DateTime currentDate,
    HomeWidgetNativeBridge? nativeBridge,
  }) : _snapshotService = snapshotService,
       _snapshotStore = snapshotStore,
       _itemRepository = itemRepository,
       _currentDate = currentDate,
       _nativeBridge = nativeBridge;

  final HomeWidgetSnapshotService _snapshotService;
  final HomeWidgetSnapshotStore _snapshotStore;
  final ItemRepository _itemRepository;
  final DateTime _currentDate;
  final HomeWidgetNativeBridge? _nativeBridge;

  @override
  Future<HomeWidgetSnapshot> refreshSnapshot({
    HomeWidgetTabId? selectedTab,
  }) async {
    final snapshot = await _snapshotService.buildSnapshot(
      selectedTab: selectedTab ?? HomeWidgetTabId.needsHandling,
    );
    await _snapshotStore.writeSnapshot(snapshot);
    await _reloadNativeWidgets();
    return snapshot;
  }

  Future<HomeWidgetSnapshot> switchTab(HomeWidgetTabId tab) async {
    final existing = await _snapshotStore.readSnapshot();
    if (existing == null) {
      return refreshSnapshot(selectedTab: tab);
    }
    final updated = existing.copyWith(selectedTab: tab);
    await _snapshotStore.writeSnapshot(updated);
    await _reloadNativeWidgets();
    return updated;
  }

  @override
  Future<bool> completeEntry(String entryId) async {
    final snapshot = await _snapshotStore.readSnapshot();
    final entry = snapshot?.findEntry(entryId);
    if (entry == null ||
        !entry.canAct ||
        entry.action != HomeWidgetEntryAction.complete ||
        entry.type != HomeWidgetEntryType.itemAttention ||
        entry.targetId == null) {
      return false;
    }

    final completed = await _itemRepository.markDone(
      entry.targetId!,
      doneAt: _currentDate,
    );
    if (!completed) {
      return false;
    }
    await refreshSnapshot(selectedTab: snapshot!.selectedTab);
    return true;
  }

  @override
  Future<bool> undoCompletedEntry(String entryId) async {
    final snapshot = await _snapshotStore.readSnapshot();
    final entry = snapshot?.findEntry(entryId);
    if (entry == null ||
        !entry.canAct ||
        entry.action != HomeWidgetEntryAction.undo ||
        entry.type != HomeWidgetEntryType.completedItem ||
        entry.actionRecordId == null) {
      return false;
    }

    final undone = await _itemRepository.undoDone(
      entry.actionRecordId!,
      revertedAt: _currentDate,
    );
    if (!undone) {
      return false;
    }
    await refreshSnapshot(selectedTab: snapshot!.selectedTab);
    return true;
  }

  Future<void> _reloadNativeWidgets() async {
    try {
      await _nativeBridge?.reloadHomeWidgets();
    } catch (_) {
      // Native widget refresh is best-effort; app data mutations already happened.
    }
  }
}
