part of 'stage_tracker_pages.dart';

class StageTrackerManagementPage extends StatelessWidget {
  const StageTrackerManagementPage({super.key});

  static const routeName = 'stage-trackers';
  static const routePath = '/feature/stage-trackers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.stageTrackerManagementFeatureTitle),
      ),
      body: const StageTrackerManagementContent(),
    );
  }
}

class StageTrackerManagementContent extends ConsumerWidget {
  const StageTrackerManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(stageTrackersProvider);
    final packsAsync = ref.watch(itemPacksProvider);
    final rulesAsync = ref.watch(stageRulesProvider);
    final recordsAsync = ref.watch(stageRecordsProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final summaryAsync = ref.watch(stageTrackerOverviewSummaryProvider);
    final attentionOccurrences =
        ref.watch(stageTrackerAttentionOccurrencesProvider).valueOrNull ??
        const <StageOccurrence>[];

    return ReminderRefreshable(
      onRefresh: () async {
        ref.invalidate(stageTrackersProvider);
        ref.invalidate(stageRulesProvider);
        ref.invalidate(stageRecordsProvider);
        ref.invalidate(itemPacksProvider);
        ref.invalidate(stageTrackerOverviewSummaryProvider);
        ref.invalidate(stageTrackerAttentionOccurrencesProvider);
        await Future<void>.delayed(Duration.zero);
      },
      child: ListView(
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(
          _StageTrackerManagementDensity.pagePadding,
        ),
        children: [
          _StageTrackerManagementHeader(
            onAddTracker: () => _showCreateStageTrackerDialog(context, ref),
          ),
          const SizedBox(height: _StageTrackerManagementDensity.sectionGap),
          _StageTrackerSummaryCard(summaryAsync: summaryAsync),
          const SizedBox(height: _StageTrackerManagementDensity.sectionGap),
          trackersAsync.when(
            data: (trackers) {
              final showAddCard = trackers
                  .where((tracker) => !tracker.isSystemDefault)
                  .isEmpty;
              final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
              final rules = rulesAsync.valueOrNull ?? const <StageRule>[];
              final records = recordsAsync.valueOrNull ?? const <StageRecord>[];
              return GridView.builder(
                key: const Key('stage-tracker-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trackers.length + (showAddCard ? 1 : 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: _StageTrackerManagementDensity.gridGap,
                  mainAxisSpacing: _StageTrackerManagementDensity.gridGap,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  if (showAddCard && index == trackers.length) {
                    return _StageTrackerDashedAddCard(
                      onTap: () => _showCreateStageTrackerDialog(context, ref),
                    );
                  }
                  final tracker = trackers[index];
                  return _StageTrackerAchievementCard(
                    tracker: tracker,
                    pack: _packFor(tracker.packId, packs),
                    now: previewDate,
                    nearestOccurrence: _nearestOccurrenceFor(
                      tracker,
                      attentionOccurrences,
                      rules,
                      records,
                      previewDate,
                    ),
                  );
                },
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  ItemPack? _packFor(int packId, List<ItemPack> packs) {
    for (final pack in packs) {
      if (pack.id == packId) {
        return pack;
      }
    }
    return null;
  }

  StageOccurrence? _nearestOccurrenceFor(
    StageTracker tracker,
    List<StageOccurrence> occurrences,
    List<StageRule> rules,
    List<StageRecord> records,
    DateTime previewDate,
  ) {
    for (final occurrence in occurrences) {
      if (occurrence.stageTrackerId == tracker.id) {
        return occurrence;
      }
    }
    if (tracker.status != StageTrackerStatus.active) {
      return null;
    }
    final service = const StageOccurrenceService();
    final trackerRules = rules.where(
      (rule) => rule.stageTrackerId == tracker.id,
    );
    final trackerRecords = records
        .where((record) => record.stageTrackerId == tracker.id)
        .toList(growable: false);
    final ruleOccurrences = [
      for (final rule in trackerRules)
        service.getNextOccurrence(
          rule,
          tracker,
          after: previewDate,
          records: trackerRecords,
        ),
    ].whereType<StageOccurrence>().toList()..sort(service.compareFuture);
    if (ruleOccurrences.isNotEmpty) {
      return ruleOccurrences.first;
    }
    return null;
  }
}

class _StageTrackerManagementDensity {
  const _StageTrackerManagementDensity._();

  static const pagePadding = 12.0;
  static const sectionGap = 10.0;
  static const gridGap = 8.0;
  static const cardPadding = 9.0;
  static const cardRadius = 16.0;
  static const iconSize = 34.0;
}

class _StageTrackerManagementHeader extends StatelessWidget {
  const _StageTrackerManagementHeader({required this.onAddTracker});

  final VoidCallback onAddTracker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            ReminderUiText.stageTrackerManagementFeatureTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TextButton.icon(
          key: const Key('stage-tracker-content-add-button'),
          onPressed: onAddTracker,
          icon: const Icon(Icons.add, size: 18),
          label: const Text(ReminderUiText.addStageTracker),
        ),
      ],
    );
  }
}

class _StageTrackerSummaryCard extends StatelessWidget {
  const _StageTrackerSummaryCard({required this.summaryAsync});

  final AsyncValue<StageTrackerOverviewSummary> summaryAsync;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      key: const Key('stage-tracker-summary-card'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      radius: _StageTrackerManagementDensity.cardRadius,
      backgroundColor: palette.surfaceWarm,
      child: summaryAsync.when(
        data: (summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in summary.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(
                      _summaryIcon(entry.kind),
                      size: 15,
                      color: entry.kind == StageTrackerSummaryEntryKind.neutral
                          ? palette.textSecondary
                          : palette.domainStage,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.text,
                        key: Key('stage-tracker-summary-${entry.kind.name}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        error: (error, stack) => Text(
          '讀取失敗: $error',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
        loading: () => Text(
          '持續記錄中。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
      ),
    );
  }

  IconData _summaryIcon(StageTrackerSummaryEntryKind kind) {
    return switch (kind) {
      StageTrackerSummaryEntryKind.upcoming => Icons.flag_outlined,
      StageTrackerSummaryEntryKind.longest => Icons.auto_graph_outlined,
      StageTrackerSummaryEntryKind.next => Icons.event_available_outlined,
      StageTrackerSummaryEntryKind.neutral => Icons.check_circle_outline,
    };
  }
}

class _StageTrackerDashedAddCard extends StatelessWidget {
  const _StageTrackerDashedAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Semantics(
      button: true,
      label: ReminderUiText.addStageTrackerCardTitle,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          _StageTrackerManagementDensity.cardRadius,
        ),
        child: InkWell(
          key: const Key('stage-tracker-dashed-add-card'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            _StageTrackerManagementDensity.cardRadius,
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: palette.domainStage.withValues(alpha: 0.45),
              radius: _StageTrackerManagementDensity.cardRadius,
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(
                _StageTrackerManagementDensity.cardPadding,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceWarm.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(
                  _StageTrackerManagementDensity.cardRadius,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.domainStage,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ReminderUiText.addStageTrackerCardTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ReminderUiText.addStageTrackerCardSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}

class _StageTrackerAchievementCard extends StatelessWidget {
  const _StageTrackerAchievementCard({
    required this.tracker,
    required this.pack,
    required this.now,
    required this.nearestOccurrence,
  });

  final StageTracker tracker;
  final ItemPack? pack;
  final DateTime now;
  final StageOccurrence? nearestOccurrence;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final statusLabel = _statusLabel(nearestOccurrence, now);
    return Tooltip(
      message: '查看 ${tracker.title} 階段追蹤',
      child: Semantics(
        label: '查看 ${tracker.title} 階段追蹤',
        button: true,
        child: ReminderPaperCard(
          key: Key('stage-tracker-card-${tracker.id}'),
          onTap: () => context.pushNamed(
            StageTrackerDetailPage.routeName,
            pathParameters: {'id': tracker.id.toString()},
          ),
          padding: const EdgeInsets.all(
            _StageTrackerManagementDensity.cardPadding,
          ),
          radius: _StageTrackerManagementDensity.cardRadius,
          borderColor: palette.domainStage.withValues(alpha: 0.28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageTrackerEmojiBubble(pack: pack, trackerId: tracker.id),
              const SizedBox(height: 7),
              Text(
                ReminderFormatters.stageTrackerDayLabel(tracker, now: now),
                key: Key('stage-tracker-days-${tracker.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _trackerTitle(tracker),
                key: Key('stage-tracker-short-title-${tracker.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (statusLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  key: Key('stage-tracker-status-${tracker.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _statusLabel(StageOccurrence? attentionOccurrence, DateTime now) {
    if (attentionOccurrence != null) {
      final current = _normalizeDate(now);
      final occurrenceDate = _normalizeDate(attentionOccurrence.occurrenceDate);
      return _countdownLabel(occurrenceDate.difference(current).inDays);
    }
    return null;
  }

  String _countdownLabel(int days) {
    if (days <= 0) {
      return '今天';
    }
    if (days == 1) {
      return '明天';
    }
    return '$days天後';
  }

  String _trackerTitle(StageTracker tracker) {
    final trackerTitle = tracker.title.trim();
    return trackerTitle.isEmpty
        ? ReminderUiText.stageTrackerLabel
        : trackerTitle;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _StageTrackerEmojiBubble extends StatelessWidget {
  const _StageTrackerEmojiBubble({required this.pack, required this.trackerId});

  final ItemPack? pack;
  final int trackerId;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: Key('stage-tracker-emoji-$trackerId'),
      width: _StageTrackerManagementDensity.iconSize,
      height: _StageTrackerManagementDensity.iconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.statusNormalContainer,
        shape: BoxShape.circle,
        border: Border.all(color: palette.borderSubtle),
      ),
      child: pack == null
          ? Icon(Icons.timeline_outlined, size: 18, color: palette.domainStage)
          : Text(pack!.iconEmoji, style: const TextStyle(fontSize: 18)),
    );
  }
}
