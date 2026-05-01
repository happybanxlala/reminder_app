import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/item_action_record.dart';
import '../data/item_repository.dart';
import '../data/local/item_timeline_dao.dart';
import '../domain/item_pack.dart';
import '../domain/item_pack_template.dart';
import 'developer_settings_providers.dart';
import 'database_providers.dart';

const itemActivityFeedPageSize = 20;

class ItemManagementGroup {
  const ItemManagementGroup({required this.pack, required this.items});

  final ItemPack pack;
  final List<ItemBundle> items;

  bool get isUnassigned => pack.isSystemDefault;
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(appDatabaseProvider).itemTimelineDao);
});

final itemPacksProvider = StreamProvider<List<ItemPack>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPacks(includeArchived: true);
});

final itemPackTemplatesProvider = StreamProvider<List<ItemPackTemplate>>((ref) {
  return ref.watch(itemRepositoryProvider).watchTemplates();
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

final itemPackProvider = FutureProvider.family<ItemPack?, int>((ref, id) {
  return ref.watch(itemRepositoryProvider).getPackById(id);
});

class ItemActivityFeedState {
  const ItemActivityFeedState({
    this.query = '',
    this.items = const <ItemActivityEntry>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.recentOffset = 0,
    this.olderOffset = 0,
    this.usingOlderWindow = false,
  });

  final String query;
  final List<ItemActivityEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final int recentOffset;
  final int olderOffset;
  final bool usingOlderWindow;

  bool get isSearching => query.trim().isNotEmpty;

  bool get canLoadMoreAttempt =>
      hasMore ||
      (!isSearching &&
          !usingOlderWindow &&
          items.length >= itemActivityFeedPageSize);

  ItemActivityFeedState copyWith({
    String? query,
    List<ItemActivityEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? recentOffset,
    int? olderOffset,
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
      recentOffset: recentOffset ?? this.recentOffset,
      olderOffset: olderOffset ?? this.olderOffset,
      usingOlderWindow: usingOlderWindow ?? this.usingOlderWindow,
    );
  }
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
      items: const <ItemActivityEntry>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: false,
      clearErrorMessage: true,
      recentOffset: 0,
      olderOffset: 0,
      usingOlderWindow: false,
    );
    try {
      final trimmedQuery = state.query.trim();
      if (trimmedQuery.isNotEmpty) {
        final items = await _loadRecentPage(query: trimmedQuery, offset: 0);
        final hasMore =
            items.length == pageSize ||
            await _hasMoreRecent(query: trimmedQuery, offset: items.length);
        if (!mounted) {
          return;
        }
        state = state.copyWith(
          items: items,
          isLoading: false,
          hasMore: hasMore,
          recentOffset: items.length,
          olderOffset: 0,
          usingOlderWindow: false,
          clearErrorMessage: true,
        );
        return;
      }

      final recentItems = await _loadRecentPage(offset: 0);
      final hasMoreRecent =
          recentItems.length == pageSize ||
          await _hasMoreRecent(offset: recentItems.length);
      final hasOlder = hasMoreRecent
          ? false
          : await _hasOlderResults(offset: 0);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        items: recentItems,
        isLoading: false,
        hasMore: hasMoreRecent || hasOlder,
        recentOffset: recentItems.length,
        olderOffset: 0,
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
    final nextItems = await _loadRecentPage(
      query: trimmedQuery,
      offset: state.recentOffset,
    );
    final combined = [...state.items, ...nextItems];
    final hasMore =
        nextItems.length == pageSize ||
        await _hasMoreRecent(query: trimmedQuery, offset: combined.length);
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      items: combined,
      isLoadingMore: false,
      hasMore: hasMore,
      recentOffset: combined.length,
      clearErrorMessage: true,
    );
  }

  Future<void> _loadMoreDefaultResults() async {
    if (!state.usingOlderWindow) {
      final nextRecent = await _loadRecentPage(offset: state.recentOffset);
      if (nextRecent.isNotEmpty) {
        final combined = [...state.items, ...nextRecent];
        final hasMoreRecent =
            nextRecent.length == pageSize ||
            await _hasMoreRecent(offset: combined.length);
        final hasOlder = hasMoreRecent
            ? false
            : await _hasOlderResults(offset: 0);
        if (!mounted) {
          return;
        }
        state = state.copyWith(
          items: combined,
          isLoadingMore: false,
          hasMore: hasMoreRecent || hasOlder,
          recentOffset: combined.length,
          usingOlderWindow: !hasMoreRecent && hasOlder,
          clearErrorMessage: true,
        );
        return;
      }
    }

    final nextOlder = await _loadOlderPage(offset: state.olderOffset);
    final combined = [...state.items, ...nextOlder];
    final nextOlderOffset = state.olderOffset + nextOlder.length;
    final hasMoreOlder =
        nextOlder.length == pageSize ||
        await _hasOlderResults(offset: nextOlderOffset);
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      items: combined,
      isLoadingMore: false,
      hasMore: hasMoreOlder,
      olderOffset: nextOlderOffset,
      usingOlderWindow: true,
      clearErrorMessage: true,
    );
  }

  Future<List<ItemActivityEntry>> _loadRecentPage({
    String? query,
    required int offset,
  }) {
    return _repository.listActivityFeed(
      limit: pageSize,
      offset: offset,
      query: query,
      recentDays: recentDays,
      now: _previewDate,
    );
  }

  Future<List<ItemActivityEntry>> _loadOlderPage({required int offset}) {
    return _repository.listActivityFeed(
      limit: pageSize,
      offset: offset,
      actionDateBefore: _recentWindowStart,
      now: _previewDate,
    );
  }

  Future<bool> _hasMoreRecent({String? query, required int offset}) async {
    final result = await _repository.listActivityFeed(
      limit: 1,
      offset: offset,
      query: query,
      recentDays: recentDays,
      now: _previewDate,
    );
    return result.isNotEmpty;
  }

  Future<bool> _hasOlderResults({required int offset}) async {
    final result = await _repository.listActivityFeed(
      limit: 1,
      offset: offset,
      actionDateBefore: _recentWindowStart,
      now: _previewDate,
    );
    return result.isNotEmpty;
  }
}
