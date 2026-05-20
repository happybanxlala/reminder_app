import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stage_tracker_models.dart';
import '../data/stage_tracker_repository.dart';
import '../domain/item_pack.dart';
import '../domain/stage_occurrence.dart';
import '../domain/stage_record.dart';
import '../domain/stage_rule.dart';
import '../domain/stage_tracker.dart';
import 'database_providers.dart';
import 'developer_settings_providers.dart';
import 'item_providers.dart';

final stageTrackerRepositoryProvider = Provider<StageTrackerRepository>((ref) {
  return StageTrackerRepository(
    ref.watch(appDatabaseProvider).reminderDao,
    itemRepository: ref.watch(itemRepositoryProvider),
  );
});

final stageTrackersProvider = StreamProvider<List<StageTracker>>((ref) {
  return ref.watch(stageTrackerRepositoryProvider).watchStageTrackers();
});

final stageRulesProvider = StreamProvider<List<StageRule>>((ref) {
  return ref.watch(stageTrackerRepositoryProvider).watchStageRules();
});

final stageRecordsProvider = StreamProvider<List<StageRecord>>((ref) {
  return ref.watch(stageTrackerRepositoryProvider).watchStageRecords();
});

final stageTrackerAttentionOccurrencesProvider =
    Provider<AsyncValue<List<StageOccurrence>>>((ref) {
      final trackersAsync = ref.watch(stageTrackersProvider);
      final rulesAsync = ref.watch(stageRulesProvider);
      final recordsAsync = ref.watch(stageRecordsProvider);

      final error = _firstAsyncError([trackersAsync, rulesAsync, recordsAsync]);
      if (error != null) {
        return AsyncError(error.error, error.stackTrace);
      }
      if (trackersAsync.isLoading ||
          rulesAsync.isLoading ||
          recordsAsync.isLoading) {
        return const AsyncLoading();
      }

      final previewDate = ref.watch(effectivePreviewDateProvider);
      return AsyncData(
        ref
            .watch(stageTrackerRepositoryProvider)
            .computeHomeAttentionOccurrences(
              trackers: trackersAsync.requireValue,
              rules: rulesAsync.requireValue,
              records: recordsAsync.requireValue,
              now: previewDate,
            ),
      );
    });

final stageTrackerOverviewSummaryProvider =
    Provider<AsyncValue<StageTrackerOverviewSummary>>((ref) {
      final trackersAsync = ref.watch(stageTrackersProvider);
      final rulesAsync = ref.watch(stageRulesProvider);
      final recordsAsync = ref.watch(stageRecordsProvider);
      final packsAsync = ref.watch(itemPacksProvider);

      final error = _firstAsyncError([
        trackersAsync,
        rulesAsync,
        recordsAsync,
        packsAsync,
      ]);
      if (error != null) {
        return AsyncError(error.error, error.stackTrace);
      }
      if (trackersAsync.isLoading ||
          rulesAsync.isLoading ||
          recordsAsync.isLoading ||
          packsAsync.isLoading) {
        return const AsyncLoading();
      }

      final previewDate = ref.watch(effectivePreviewDateProvider);
      final repository = ref.watch(stageTrackerRepositoryProvider);
      final trackers = trackersAsync.requireValue;
      final rules = rulesAsync.requireValue;
      final records = recordsAsync.requireValue;
      final packs = {for (final pack in packsAsync.requireValue) pack.id: pack};
      final upcoming = repository.computeHomeAttentionOccurrences(
        trackers: trackers,
        rules: rules,
        records: records,
        now: previewDate,
      );
      final entries = <StageTrackerSummaryEntry>[];
      if (upcoming.isNotEmpty) {
        entries.add(
          StageTrackerSummaryEntry(
            kind: StageTrackerSummaryEntryKind.upcoming,
            text: '今日有 ${upcoming.length} 個階段快到了',
          ),
        );
      } else {
        entries.add(
          const StageTrackerSummaryEntry(
            kind: StageTrackerSummaryEntryKind.neutral,
            text: '目前沒有快到的階段。',
          ),
        );
      }

      final longest = _longestAccumulatedTracker(trackers, previewDate);
      if (longest != null) {
        entries.add(
          StageTrackerSummaryEntry(
            kind: StageTrackerSummaryEntryKind.longest,
            text:
                '最久累積：${_summaryTrackerLabel(longest.tracker, packs)} '
                '${longest.days} 天',
          ),
        );
      }

      if (upcoming.isNotEmpty) {
        final next = upcoming.first;
        final tracker = _trackerById(trackers, next.stageTrackerId);
        final trackerLabel = tracker == null
            ? next.stageTrackerTitle ?? '階段追蹤'
            : _summaryTrackerLabel(tracker, packs);
        entries.add(
          StageTrackerSummaryEntry(
            kind: StageTrackerSummaryEntryKind.next,
            text:
                '最近更新：$trackerLabel '
                '${_summaryCountdown(next.occurrenceDate, previewDate)}進入下一階段',
          ),
        );
      }

      if (entries.length == 1 &&
          entries.single.kind == StageTrackerSummaryEntryKind.neutral) {
        entries.add(
          const StageTrackerSummaryEntry(
            kind: StageTrackerSummaryEntryKind.neutral,
            text: '持續記錄中。',
          ),
        );
      }

      return AsyncData(
        StageTrackerOverviewSummary(
          entries: entries.take(3).toList(growable: false),
        ),
      );
    });

final stageTrackerByIdProvider = FutureProvider.autoDispose
    .family<StageTracker?, int>((ref, id) {
      return ref.watch(stageTrackerRepositoryProvider).getStageTrackerById(id);
    });

final stageTrackerDetailProvider = FutureProvider.autoDispose
    .family<StageTrackerDetail?, int>((ref, id) {
      final previewDate = ref.watch(effectivePreviewDateProvider);
      return ref
          .watch(stageTrackerRepositoryProvider)
          .getStageTrackerDetailById(id, now: previewDate);
    });

({Object error, StackTrace stackTrace})? _firstAsyncError(
  List<AsyncValue<dynamic>> values,
) {
  for (final value in values) {
    if (value.hasError) {
      return (
        error: value.error!,
        stackTrace: value.stackTrace ?? StackTrace.current,
      );
    }
  }
  return null;
}

StageTracker? _trackerById(List<StageTracker> trackers, int id) {
  for (final tracker in trackers) {
    if (tracker.id == id) {
      return tracker;
    }
  }
  return null;
}

({StageTracker tracker, int days})? _longestAccumulatedTracker(
  List<StageTracker> trackers,
  DateTime previewDate,
) {
  final current = normalizePreviewDate(previewDate);
  ({StageTracker tracker, int days})? longest;
  for (final tracker in trackers.where(
    (item) => item.status == StageTrackerStatus.active,
  )) {
    final start = normalizePreviewDate(tracker.trackingStartDate);
    if (current.isBefore(start)) {
      continue;
    }
    final days = current.difference(start).inDays;
    if (longest == null || days > longest.days) {
      longest = (tracker: tracker, days: days);
    }
  }
  return longest;
}

String _summaryTrackerLabel(StageTracker tracker, Map<int, ItemPack> packs) {
  final trackerTitle = tracker.title.trim();
  if (trackerTitle.isNotEmpty) {
    return trackerTitle;
  }
  final packTitle = packs[tracker.packId]?.title.trim();
  if (packTitle != null && packTitle.isNotEmpty) {
    return packTitle;
  }
  return '階段追蹤';
}

String _summaryCountdown(DateTime targetDate, DateTime previewDate) {
  final days = normalizePreviewDate(
    targetDate,
  ).difference(normalizePreviewDate(previewDate)).inDays;
  if (days <= 0) {
    return '今天';
  }
  if (days == 1) {
    return '明天';
  }
  return '$days 天後';
}
