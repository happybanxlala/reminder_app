import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_models.dart';
import '../domain/item_action_record.dart';
import '../data/item_repository.dart';
import '../data/local/reminder_dao.dart';
import '../data/remote_backed_item_action_service.dart';
import '../domain/item_pack.dart';
import 'developer_settings_providers.dart';
import 'database_providers.dart';
import 'identity_providers.dart';

const itemActivityFeedPageSize = 20;

class ItemManagementGroup {
  const ItemManagementGroup({required this.pack, required this.items});

  final ItemPack pack;
  final List<ItemBundle> items;

  bool get isUnassigned => pack.isSystemDefault;
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(
    ref.watch(appDatabaseProvider).reminderDao,
    remoteBackedItemActionService: ref.watch(
      remoteBackedItemActionServiceProvider,
    ),
    currentActorId: () => currentActorId(ref),
  );
});

final remoteBackedItemActionServiceProvider =
    Provider<RemoteBackedItemActionService>((ref) {
      return RemoteBackedItemActionService(
        dao: ref.watch(appDatabaseProvider).reminderDao,
        identityRepository: ref.watch(identityRepositoryProvider),
      );
    });

final itemPacksProvider = StreamProvider<List<ItemPack>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPacks(includeArchived: true);
});

final activeItemPacksProvider = StreamProvider<List<ItemPack>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPacks();
});

final itemsProvider = StreamProvider<List<ItemBundle>>((ref) {
  return ref.watch(itemRepositoryProvider).watchItems();
});

final packManagementItemsProvider = StreamProvider<List<ItemBundle>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPackManagementItems();
});

final itemSyncStatusesProvider = StreamProvider<Map<int, HomeItemSyncStatus>>((
  ref,
) {
  return ref.watch(itemRepositoryProvider).watchHomeItemSyncStatuses();
});

final itemManagementGroupsProvider =
    Provider<AsyncValue<List<ItemManagementGroup>>>((ref) {
      final packsAsync = ref.watch(activeItemPacksProvider);
      final itemsAsync = ref.watch(packManagementItemsProvider);

      if (packsAsync.hasError) {
        return AsyncError(
          packsAsync.error!,
          packsAsync.stackTrace ?? StackTrace.current,
        );
      }
      if (itemsAsync.hasError) {
        return AsyncError(
          itemsAsync.error!,
          itemsAsync.stackTrace ?? StackTrace.current,
        );
      }
      if (packsAsync.isLoading || itemsAsync.isLoading) {
        return const AsyncLoading();
      }

      final itemsByPackId = <int, List<ItemBundle>>{};
      for (final item in itemsAsync.requireValue) {
        itemsByPackId.putIfAbsent(item.pack.id, () => []).add(item);
      }

      return AsyncData(
        packsAsync.requireValue
            .map(
              (pack) => ItemManagementGroup(
                pack: pack,
                items: itemsByPackId[pack.id] ?? const <ItemBundle>[],
              ),
            )
            .toList(growable: false),
      );
    });

final itemProvider = FutureProvider.family<ItemBundle?, int>((ref, id) {
  return ref.watch(itemRepositoryProvider).getItemById(id);
});

final itemActionHistoryProvider =
    StreamProvider.family<List<ItemActionRecord>, int>((ref, id) {
      return ref.watch(itemRepositoryProvider).watchActionHistory(id);
    });

final itemHistoryEntriesProvider =
    StreamProvider.family<List<ItemHistoryEntry>, int>((ref, id) {
      return ref.watch(itemRepositoryProvider).watchHistoryEntries(id);
    });

final itemPackProvider = FutureProvider.family<ItemPack?, int>((ref, id) {
  return ref.watch(itemRepositoryProvider).getPackById(id);
});

class ItemActivityFeedState {
  const ItemActivityFeedState({
    this.query = '',
    this.items = const <ItemActivityFeedEntry>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.localRecentOffset = 0,
    this.sharedRecentOffset = 0,
    this.localOlderOffset = 0,
    this.sharedOlderOffset = 0,
    this.usingOlderWindow = false,
  });

  final String query;
  final List<ItemActivityFeedEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final int localRecentOffset;
  final int sharedRecentOffset;
  final int localOlderOffset;
  final int sharedOlderOffset;
  final bool usingOlderWindow;

  bool get isSearching => query.trim().isNotEmpty;

  bool get canLoadMoreAttempt =>
      hasMore ||
      (!isSearching &&
          !usingOlderWindow &&
          items.length >= itemActivityFeedPageSize);

  ItemActivityFeedState copyWith({
    String? query,
    List<ItemActivityFeedEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? localRecentOffset,
    int? sharedRecentOffset,
    int? localOlderOffset,
    int? sharedOlderOffset,
    bool? usingOlderWindow,
  }) {
    return ItemActivityFeedState(
      query: query ?? this.query,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      localRecentOffset: localRecentOffset ?? this.localRecentOffset,
      sharedRecentOffset: sharedRecentOffset ?? this.sharedRecentOffset,
      localOlderOffset: localOlderOffset ?? this.localOlderOffset,
      sharedOlderOffset: sharedOlderOffset ?? this.sharedOlderOffset,
      usingOlderWindow: usingOlderWindow ?? this.usingOlderWindow,
    );
  }
}

sealed class ItemActivityFeedEntry {
  const ItemActivityFeedEntry();

  DateTime get occurredAt;
  String get itemTitle;
  String get packTitle;
  ItemBundle get bundle;
  String get stableKey;
}

class LocalItemActivityFeedEntry extends ItemActivityFeedEntry {
  const LocalItemActivityFeedEntry(this.entry);

  final ItemActivityEntry entry;

  @override
  DateTime get occurredAt => entry.record.actionDate;

  @override
  String get itemTitle => entry.itemTitle;

  @override
  String get packTitle => entry.packTitle;

  @override
  ItemBundle get bundle => entry.bundle;

  @override
  String get stableKey => 'local-${entry.record.id}';
}

class SharedRemoteItemActivityFeedEntry extends ItemActivityFeedEntry {
  const SharedRemoteItemActivityFeedEntry(this.entry);

  final SharedItemActivityEntry entry;

  @override
  DateTime get occurredAt => entry.occurredAt;

  @override
  String get itemTitle => entry.itemTitle;

  @override
  String get packTitle => entry.packTitle;

  @override
  ItemBundle get bundle => ItemBundle(item: entry.item, pack: entry.pack);

  @override
  String get stableKey => 'shared-${entry.event.id}';

  String get message {
    final name = entry.actorDisplayName.trim().isEmpty
        ? '照顧成員'
        : entry.actorDisplayName.trim();
    final title = entry.itemTitle;
    return switch (entry.event.action) {
      'item_created' => '$name 新增了「$title」',
      'item_updated' => '$name 更新了「$title」',
      'item_archived' => '$name 封存了「$title」',
      'item_completed' => '$name 完成了「$title」',
      'item_undone' => '$name 復原了「$title」',
      _ => '$name 更新了「$title」',
    };
  }
}

class _ItemActivityPageResult {
  const _ItemActivityPageResult({
    required this.items,
    required this.localCount,
    required this.sharedCount,
  });

  final List<ItemActivityFeedEntry> items;
  final int localCount;
  final int sharedCount;
}

final itemActivityFeedControllerProvider =
    StateNotifierProvider.autoDispose<
      ItemActivityFeedController,
      ItemActivityFeedState
    >((ref) {
      final repository = ref.watch(itemRepositoryProvider);
      final previewDate = ref.watch(effectivePreviewDateProvider);
      return ItemActivityFeedController(
        repository: repository,
        previewDate: previewDate,
      );
    });

class ItemActivityFeedController extends StateNotifier<ItemActivityFeedState> {
  ItemActivityFeedController({
    required ItemRepository repository,
    required DateTime previewDate,
  }) : _repository = repository,
       _previewDate = DateTime(
         previewDate.year,
         previewDate.month,
         previewDate.day,
       ),
       super(const ItemActivityFeedState()) {
    _loadInitial();
  }

  static const pageSize = itemActivityFeedPageSize;
  static const recentDays = 30;

  final ItemRepository _repository;
  final DateTime _previewDate;

  DateTime get _recentWindowStart =>
      _previewDate.subtract(const Duration(days: recentDays - 1));

  Future<void> refresh() => _loadInitial();

  Future<void> setQuery(String value) async {
    final trimmed = value.trim();
    if (trimmed == state.query.trim()) {
      return;
    }
    state = state.copyWith(query: value);
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.canLoadMoreAttempt) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearErrorMessage: true);
    try {
      if (state.isSearching) {
        await _loadMoreSearchResults();
      } else {
        await _loadMoreDefaultResults();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '讀取失敗: $error',
      );
    }
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      items: const <ItemActivityFeedEntry>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: false,
      clearErrorMessage: true,
      localRecentOffset: 0,
      sharedRecentOffset: 0,
      localOlderOffset: 0,
      sharedOlderOffset: 0,
      usingOlderWindow: false,
    );
    try {
      final trimmedQuery = state.query.trim();
      if (trimmedQuery.isNotEmpty) {
        final page = await _loadRecentPage(
          query: trimmedQuery,
          localOffset: 0,
          sharedOffset: 0,
        );
        final hasMore =
            page.items.length == pageSize ||
            await _hasMoreRecent(
              query: trimmedQuery,
              localOffset: page.localCount,
              sharedOffset: page.sharedCount,
            );
        if (!mounted) {
          return;
        }
        state = state.copyWith(
          items: page.items,
          isLoading: false,
          hasMore: hasMore,
          localRecentOffset: page.localCount,
          sharedRecentOffset: page.sharedCount,
          localOlderOffset: 0,
          sharedOlderOffset: 0,
          usingOlderWindow: false,
          clearErrorMessage: true,
        );
        return;
      }

      final recentPage = await _loadRecentPage(localOffset: 0, sharedOffset: 0);
      final hasMoreRecent =
          recentPage.items.length == pageSize ||
          await _hasMoreRecent(
            localOffset: recentPage.localCount,
            sharedOffset: recentPage.sharedCount,
          );
      final hasOlder = hasMoreRecent
          ? false
          : await _hasOlderResults(localOffset: 0, sharedOffset: 0);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        items: recentPage.items,
        isLoading: false,
        hasMore: hasMoreRecent || hasOlder,
        localRecentOffset: recentPage.localCount,
        sharedRecentOffset: recentPage.sharedCount,
        localOlderOffset: 0,
        sharedOlderOffset: 0,
        usingOlderWindow: !hasMoreRecent && hasOlder,
        clearErrorMessage: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, errorMessage: '讀取失敗: $error');
    }
  }

  Future<void> _loadMoreSearchResults() async {
    final trimmedQuery = state.query.trim();
    final page = await _loadRecentPage(
      query: trimmedQuery,
      localOffset: state.localRecentOffset,
      sharedOffset: state.sharedRecentOffset,
    );
    final combined = [...state.items, ...page.items];
    final nextLocalOffset = state.localRecentOffset + page.localCount;
    final nextSharedOffset = state.sharedRecentOffset + page.sharedCount;
    final hasMore =
        page.items.length == pageSize ||
        await _hasMoreRecent(
          query: trimmedQuery,
          localOffset: nextLocalOffset,
          sharedOffset: nextSharedOffset,
        );
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      items: combined,
      isLoadingMore: false,
      hasMore: hasMore,
      localRecentOffset: nextLocalOffset,
      sharedRecentOffset: nextSharedOffset,
      clearErrorMessage: true,
    );
  }

  Future<void> _loadMoreDefaultResults() async {
    if (!state.usingOlderWindow) {
      final recentPage = await _loadRecentPage(
        localOffset: state.localRecentOffset,
        sharedOffset: state.sharedRecentOffset,
      );
      if (recentPage.items.isNotEmpty) {
        final combined = [...state.items, ...recentPage.items];
        final nextLocalOffset = state.localRecentOffset + recentPage.localCount;
        final nextSharedOffset =
            state.sharedRecentOffset + recentPage.sharedCount;
        final hasMoreRecent =
            recentPage.items.length == pageSize ||
            await _hasMoreRecent(
              localOffset: nextLocalOffset,
              sharedOffset: nextSharedOffset,
            );
        final hasOlder = hasMoreRecent
            ? false
            : await _hasOlderResults(localOffset: 0, sharedOffset: 0);
        if (!mounted) {
          return;
        }
        state = state.copyWith(
          items: combined,
          isLoadingMore: false,
          hasMore: hasMoreRecent || hasOlder,
          localRecentOffset: nextLocalOffset,
          sharedRecentOffset: nextSharedOffset,
          usingOlderWindow: !hasMoreRecent && hasOlder,
          clearErrorMessage: true,
        );
        return;
      }
    }

    final olderPage = await _loadOlderPage(
      localOffset: state.localOlderOffset,
      sharedOffset: state.sharedOlderOffset,
    );
    final combined = [...state.items, ...olderPage.items];
    final nextLocalOlderOffset = state.localOlderOffset + olderPage.localCount;
    final nextSharedOlderOffset =
        state.sharedOlderOffset + olderPage.sharedCount;
    final hasMoreOlder =
        olderPage.items.length == pageSize ||
        await _hasOlderResults(
          localOffset: nextLocalOlderOffset,
          sharedOffset: nextSharedOlderOffset,
        );
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      items: combined,
      isLoadingMore: false,
      hasMore: hasMoreOlder,
      localOlderOffset: nextLocalOlderOffset,
      sharedOlderOffset: nextSharedOlderOffset,
      usingOlderWindow: true,
      clearErrorMessage: true,
    );
  }

  Future<_ItemActivityPageResult> _loadRecentPage({
    String? query,
    required int localOffset,
    required int sharedOffset,
  }) async {
    final local = await _repository.listActivityFeed(
      limit: pageSize,
      offset: localOffset,
      query: query,
      recentDays: recentDays,
      now: _previewDate,
    );
    final shared = await _repository.listSharedItemActivityFeed(
      limit: pageSize,
      offset: sharedOffset,
      query: query,
      recentDays: recentDays,
      now: _previewDate,
    );
    return _mergeActivityPage(local: local, shared: shared);
  }

  Future<_ItemActivityPageResult> _loadOlderPage({
    required int localOffset,
    required int sharedOffset,
  }) async {
    final local = await _repository.listActivityFeed(
      limit: pageSize,
      offset: localOffset,
      actionDateBefore: _recentWindowStart,
      now: _previewDate,
    );
    final shared = await _repository.listSharedItemActivityFeed(
      limit: pageSize,
      offset: sharedOffset,
      actionDateBefore: _recentWindowStart,
      now: _previewDate,
    );
    return _mergeActivityPage(local: local, shared: shared);
  }

  Future<bool> _hasMoreRecent({
    String? query,
    required int localOffset,
    required int sharedOffset,
  }) async {
    final local = await _repository.listActivityFeed(
      limit: 1,
      offset: localOffset,
      query: query,
      recentDays: recentDays,
      now: _previewDate,
    );
    if (local.isNotEmpty) {
      return true;
    }
    final shared = await _repository.listSharedItemActivityFeed(
      limit: 1,
      offset: sharedOffset,
      query: query,
      recentDays: recentDays,
      now: _previewDate,
    );
    return shared.isNotEmpty;
  }

  Future<bool> _hasOlderResults({
    required int localOffset,
    required int sharedOffset,
  }) async {
    final local = await _repository.listActivityFeed(
      limit: 1,
      offset: localOffset,
      actionDateBefore: _recentWindowStart,
      now: _previewDate,
    );
    if (local.isNotEmpty) {
      return true;
    }
    final shared = await _repository.listSharedItemActivityFeed(
      limit: 1,
      offset: sharedOffset,
      actionDateBefore: _recentWindowStart,
      now: _previewDate,
    );
    return shared.isNotEmpty;
  }

  _ItemActivityPageResult _mergeActivityPage({
    required List<ItemActivityEntry> local,
    required List<SharedItemActivityEntry> shared,
  }) {
    final merged =
        <ItemActivityFeedEntry>[
          ...local.map(LocalItemActivityFeedEntry.new),
          ...shared.map(SharedRemoteItemActivityFeedEntry.new),
        ]..sort((a, b) {
          final timeCompare = b.occurredAt.compareTo(a.occurredAt);
          if (timeCompare != 0) {
            return timeCompare;
          }
          return b.stableKey.compareTo(a.stableKey);
        });
    final page = merged.take(pageSize).toList(growable: false);
    return _ItemActivityPageResult(
      items: page,
      localCount: page.whereType<LocalItemActivityFeedEntry>().length,
      sharedCount: page.whereType<SharedRemoteItemActivityFeedEntry>().length,
    );
  }
}
