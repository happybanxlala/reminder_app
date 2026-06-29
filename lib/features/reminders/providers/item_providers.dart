import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_models.dart';
import '../domain/item_action_record.dart';
import '../data/item_repository.dart';
import '../data/local/reminder_dao.dart';
import '../data/remote_backed_item_action_service.dart';
import '../domain/item_pack.dart';
import '../domain/shared_pack.dart';
import '../presentation/text/reminder_ui_text.dart';
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
    this.items = const <UnifiedActivityFeedEntry>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
  });

  final String query;
  final List<UnifiedActivityFeedEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  bool get isSearching => query.trim().isNotEmpty;

  bool get canLoadMoreAttempt => hasMore && !isLoading && !isLoadingMore;

  ItemActivityFeedState copyWith({
    String? query,
    List<UnifiedActivityFeedEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
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
    );
  }
}

enum UnifiedActivityEntityKind { item, resource, stage, member, pack }

class UnifiedActivityFeedEntry {
  const UnifiedActivityFeedEntry({
    required this.source,
    required this.entityKind,
    required this.message,
    required this.entityTitle,
    required this.actorDisplayName,
    required this.packTitle,
    required this.actionLabel,
    required this.stableKey,
    this.bundle,
  });

  final UnifiedActivityEntry source;
  final UnifiedActivityEntityKind entityKind;
  final String message;
  final String entityTitle;
  final String actorDisplayName;
  final String packTitle;
  final String actionLabel;
  final String stableKey;
  final ItemBundle? bundle;

  DateTime get occurredAt => source.occurredAt;
}

final itemActivityFeedControllerProvider =
    StateNotifierProvider.autoDispose<
      ItemActivityFeedController,
      ItemActivityFeedState
    >((ref) {
      final dao = ref.watch(appDatabaseProvider).reminderDao;
      final previewDate = ref.watch(effectivePreviewDateProvider);
      return ItemActivityFeedController(dao: dao, previewDate: previewDate);
    });

class ItemActivityFeedController extends StateNotifier<ItemActivityFeedState> {
  ItemActivityFeedController({
    required ReminderDao dao,
    required DateTime previewDate,
  }) : _dao = dao,
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

  final ReminderDao _dao;
  final DateTime _previewDate;

  DateTime get _recentWindowStart =>
      _previewDate.subtract(const Duration(days: recentDays - 1));

  Future<void> refresh() => _loadInitial();

  Future<void> setQuery(String value) async {
    if (value.trim() == state.query.trim()) {
      return;
    }
    state = state.copyWith(query: value);
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (!state.canLoadMoreAttempt) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearErrorMessage: true);
    try {
      final all = await _loadProjectedEntries();
      final next = all
          .skip(state.items.length)
          .take(pageSize)
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      final combined = [...state.items, ...next];
      state = state.copyWith(
        items: combined,
        isLoadingMore: false,
        hasMore: combined.length < all.length,
        clearErrorMessage: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: ReminderUiText.activityLoadFailed,
      );
    }
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      items: const <UnifiedActivityFeedEntry>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: false,
      clearErrorMessage: true,
    );
    try {
      final all = await _loadProjectedEntries();
      final page = all.take(pageSize).toList(growable: false);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        items: page,
        isLoading: false,
        hasMore: page.length < all.length,
        clearErrorMessage: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: ReminderUiText.activityLoadFailed,
      );
    }
  }

  Future<List<UnifiedActivityFeedEntry>> _loadProjectedEntries() async {
    final query = state.query.trim();
    final rows = await _dao.listUnifiedActivityEntries();
    final entries = <UnifiedActivityFeedEntry>[];
    for (final row in rows) {
      if (query.isEmpty && row.occurredAt.isBefore(_recentWindowStart)) {
        continue;
      }
      final projected = _projectActivity(row);
      if (projected == null) {
        continue;
      }
      if (query.isNotEmpty && !_matchesQuery(projected, query)) {
        continue;
      }
      entries.add(projected);
    }
    return _dedupe(entries);
  }

  UnifiedActivityFeedEntry? _projectActivity(UnifiedActivityEntry entry) {
    final actorName = _actorName(entry.actorDisplayName);
    final packTitle = entry.pack?.isSystemDefault == true
        ? '一般'
        : (entry.packTitle.trim().isEmpty ? '生活場景' : entry.packTitle.trim());
    final action = entry.event.action;
    switch (entry.event.entityType) {
      case 'item':
        final itemTitle = _entityTitle(entry.item?.title, '一個事項');
        final message = switch (action) {
          'item_created' => '$actorName 新增了「$itemTitle」',
          'item_updated' => '$actorName 更新了「$itemTitle」',
          'item_archived' => '$actorName 封存了「$itemTitle」',
          'item_completed' => '$actorName 完成了「$itemTitle」',
          'item_undone' => '$actorName 復原了「$itemTitle」',
          _ => null,
        };
        if (message == null) {
          return null;
        }
        return UnifiedActivityFeedEntry(
          source: entry,
          entityKind: UnifiedActivityEntityKind.item,
          message: message,
          entityTitle: itemTitle,
          actorDisplayName: actorName,
          packTitle: packTitle,
          actionLabel: '事項',
          stableKey: _stableKey(entry),
          bundle: entry.item == null || entry.pack == null
              ? null
              : ItemBundle(item: entry.item!, pack: entry.pack!),
        );
      case 'resource':
        final resourceTitle = _entityTitle(entry.resource?.title, '一個資源');
        final message = switch (action) {
          'resource_created' => '$actorName 新增了「$resourceTitle」',
          'resource_updated' => '$actorName 更新了「$resourceTitle」',
          'resource_incremented' => _resourceIncrementMessage(
            entry,
            actorName,
            resourceTitle,
          ),
          'resource_adjusted' => '$actorName 調整了「$resourceTitle」',
          'resource_decremented' => '$actorName 扣除了「$resourceTitle」',
          'resource_archived' => '$actorName 封存了「$resourceTitle」',
          _ => null,
        };
        if (message == null) {
          return null;
        }
        return UnifiedActivityFeedEntry(
          source: entry,
          entityKind: UnifiedActivityEntityKind.resource,
          message: message,
          entityTitle: resourceTitle,
          actorDisplayName: actorName,
          packTitle: packTitle,
          actionLabel: '資源',
          stableKey: _stableKey(entry),
        );
      case 'stage_tracker':
      case 'stage_rule':
      case 'stage_record':
      case 'stage':
        final title = _entityTitle(
          entry.stageRecord?.label ?? entry.stageTracker?.title,
          '一個階段',
        );
        final message = switch (action) {
          'stage_tracker_created' ||
          'stage_created' => '$actorName 新增了「$title」',
          'stage_tracker_updated' ||
          'stage_rule_updated' ||
          'stage_record_updated' ||
          'stage_updated' => '$actorName 更新了「$title」',
          'stage_acknowledged' ||
          'stage_record_acknowledged' => '$actorName 確認了「$title」',
          'stage_progress_updated' => '$actorName 更新了「$title」的進度',
          'stage_tracker_archived' ||
          'stage_rule_archived' ||
          'stage_record_archived' ||
          'stage_archived' => '$actorName 封存了「$title」',
          _ => null,
        };
        if (message == null) {
          return null;
        }
        return UnifiedActivityFeedEntry(
          source: entry,
          entityKind: UnifiedActivityEntityKind.stage,
          message: message,
          entityTitle: title,
          actorDisplayName: actorName,
          packTitle: packTitle,
          actionLabel: '階段',
          stableKey: _stableKey(entry),
        );
      case 'pack_member':
        final message = switch (action) {
          'member_joined' => '$actorName 加入了這個生活場景',
          'member_removed' => '$actorName 已不在這個生活場景中',
          _ => null,
        };
        if (message == null) {
          return null;
        }
        return UnifiedActivityFeedEntry(
          source: entry,
          entityKind: UnifiedActivityEntityKind.member,
          message: message,
          entityTitle: '成員',
          actorDisplayName: actorName,
          packTitle: packTitle,
          actionLabel: '成員',
          stableKey: _stableKey(entry),
        );
      case 'pack':
        if (action != 'pack_updated') {
          return null;
        }
        return UnifiedActivityFeedEntry(
          source: entry,
          entityKind: UnifiedActivityEntityKind.pack,
          message: '$actorName 更新了生活場景資料',
          entityTitle: packTitle,
          actorDisplayName: actorName,
          packTitle: packTitle,
          actionLabel: '生活場景',
          stableKey: _stableKey(entry),
        );
    }
    return null;
  }

  List<UnifiedActivityFeedEntry> _dedupe(
    List<UnifiedActivityFeedEntry> entries,
  ) {
    final seenRemoteIds = <String>{};
    final seenMutationIds = <String>{};
    final accepted = <UnifiedActivityFeedEntry>[];
    for (final entry in entries) {
      final metadata = _metadata(entry.source.event);
      final remoteActivityId = _stringValue(metadata, 'remoteActivityId');
      if (remoteActivityId != null && !seenRemoteIds.add(remoteActivityId)) {
        continue;
      }
      final mutationId = _clientMutationId(metadata);
      if (mutationId != null && !seenMutationIds.add(mutationId)) {
        continue;
      }
      final duplicate = accepted.any(
        (existing) => _isConservativeDuplicate(existing, entry),
      );
      if (!duplicate) {
        accepted.add(entry);
      }
    }
    return accepted;
  }

  bool _isConservativeDuplicate(
    UnifiedActivityFeedEntry existing,
    UnifiedActivityFeedEntry candidate,
  ) {
    if (existing.source.event.id == candidate.source.event.id) {
      return true;
    }
    if (existing.source.event.entityType != candidate.source.event.entityType ||
        existing.source.event.entityId != candidate.source.event.entityId ||
        existing.source.event.action != candidate.source.event.action ||
        existing.source.event.actorUserId !=
            candidate.source.event.actorUserId) {
      return false;
    }
    final delta = existing.occurredAt
        .difference(candidate.occurredAt)
        .inMilliseconds
        .abs();
    return delta <= const Duration(minutes: 2).inMilliseconds;
  }

  bool _matchesQuery(UnifiedActivityFeedEntry entry, String query) {
    return entry.message.contains(query) ||
        entry.entityTitle.contains(query) ||
        entry.actorDisplayName.contains(query) ||
        entry.packTitle.contains(query) ||
        entry.actionLabel.contains(query);
  }

  String _resourceIncrementMessage(
    UnifiedActivityEntry entry,
    String actorName,
    String resourceTitle,
  ) {
    final metadata = _metadata(entry.event);
    final remoteMetadata = metadata['remoteMetadata'];
    final action = remoteMetadata is Map
        ? remoteMetadata['resource_action']
        : null;
    if (action == 'refilled') {
      return '$actorName 補充了「$resourceTitle」';
    }
    return '$actorName 補充了「$resourceTitle」';
  }

  String _stableKey(UnifiedActivityEntry entry) {
    final remoteActivityId = _stringValue(
      _metadata(entry.event),
      'remoteActivityId',
    );
    return remoteActivityId == null
        ? 'local-${entry.event.id}'
        : 'remote-$remoteActivityId';
  }

  String _actorName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '有成員' : trimmed;
  }

  String _entityTitle(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Map<String, Object?> _metadata(ActivityEvent event) {
    final raw = event.metadataJson;
    if (raw == null || raw.trim().isEmpty) {
      return const <String, Object?>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
    } catch (_) {
      return const <String, Object?>{};
    }
    return const <String, Object?>{};
  }

  String? _clientMutationId(Map<String, Object?> metadata) {
    final direct =
        _stringValue(metadata, 'clientMutationId') ??
        _stringValue(metadata, 'client_mutation_id');
    if (direct != null) {
      return direct;
    }
    final remoteMetadata = metadata['remoteMetadata'];
    if (remoteMetadata is Map) {
      return _stringValue(
            remoteMetadata.cast<String, Object?>(),
            'clientMutationId',
          ) ??
          _stringValue(
            remoteMetadata.cast<String, Object?>(),
            'client_mutation_id',
          );
    }
    return null;
  }

  String? _stringValue(Map<String, Object?> metadata, String key) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
