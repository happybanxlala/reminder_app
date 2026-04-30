import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/timeline_providers.dart';

class TimelineMilestoneHistoryPage extends ConsumerWidget {
  const TimelineMilestoneHistoryPage({super.key, required this.timelineId});

  static const routeName = 'timeline-milestone-history';
  static const routePath = '/timeline/:id/history';

  final int timelineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(timelineDetailProvider(timelineId));

    return detailAsync.when(
      data: (detail) {
        final title = detail == null
            ? ReminderUiText.timelineMilestoneHistoryTitle
            : '${detail.timeline.title} · ${ReminderUiText.milestoneHistoryTitle}';
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (detail == null)
                const Text(ReminderUiText.timelineMissingMessage)
              else if (detail.milestoneHistory.isEmpty)
                const Text(ReminderUiText.noTimelineMilestoneHistory)
              else
                ...detail.milestoneHistory.map(
                  (item) => ListTile(
                    key: Key('timeline-history-${item.record.id}'),
                    title: Text(ReminderFormatters.milestoneHistory(item)),
                    subtitle: Text(
                      ReminderFormatters.milestoneHistoryUpdatedAt(item),
                    ),
                    isThreeLine: false,
                  ),
                ),
            ],
          ),
        );
      },
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text(ReminderUiText.timelineMilestoneHistoryTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('讀取失敗: $error'),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(ReminderUiText.timelineMilestoneHistoryTitle),
        ),
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
