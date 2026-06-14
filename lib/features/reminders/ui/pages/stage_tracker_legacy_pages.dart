part of 'stage_tracker_pages.dart';

class StageTrackerSchedulePage extends ConsumerWidget {
  const StageTrackerSchedulePage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-schedule';
  static const routePath = '/stage-tracker/:id/schedule';

  final int stageTrackerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stageTrackerDetailProvider(stageTrackerId));
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('完整時間表')),
      body: detailAsync.when(
        data: (detail) {
          final stages = detail?.scheduleStages ?? const <StageOccurrence>[];
          if (stages.isEmpty) {
            return ReminderRefreshablePlaceholder(
              onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
              child: const Text(ReminderUiText.noStageUpcoming),
            );
          }
          return ReminderRefreshable(
            onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
            child: ListView(
              physics: reminderRefreshPhysics,
              padding: const EdgeInsets.all(ReminderSpacing.page),
              children: [
                for (final occurrence in stages)
                  _StageOccurrenceTile(
                    occurrence: occurrence,
                    now: previewDate,
                  ),
              ],
            ),
          );
        },
        error: (error, stack) => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: Text('讀取失敗: $error'),
        ),
        loading: () => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class StageTrackerHistoryPage extends ConsumerWidget {
  const StageTrackerHistoryPage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-history';
  static const routePath = '/stage-tracker/:id/history';

  final int stageTrackerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stageTrackerDetailProvider(stageTrackerId));
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.stageTrackerHistoryTitle),
      ),
      body: detailAsync.when(
        data: (detail) {
          final stages = detail?.historyStages ?? const <StageOccurrence>[];
          if (stages.isEmpty) {
            return ReminderRefreshablePlaceholder(
              onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
              child: const Text(ReminderUiText.noStageTrackerHistory),
            );
          }
          return ReminderRefreshable(
            onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
            child: ListView(
              physics: reminderRefreshPhysics,
              padding: const EdgeInsets.all(ReminderSpacing.page),
              children: [
                for (final occurrence in stages)
                  _StageOccurrenceTile(
                    occurrence: occurrence,
                    now: previewDate,
                    showSource: true,
                  ),
              ],
            ),
          );
        },
        error: (error, stack) => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: Text('讀取失敗: $error'),
        ),
        loading: () => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
