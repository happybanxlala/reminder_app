import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/router.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/domain/attention_summary.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/attention_summary_providers.dart';
import 'package:reminder_app/features/reminders/providers/home_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';

void main() {
  testWidgets('app shell lands on today and switches primary tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attentionSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const AttentionSummary(
                dangerCount: 0,
                warningCount: 0,
                timelineUpcomingCount: 0,
              ),
            ),
          ),
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(const <ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(const <ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
          ),
          itemManagementGroupsProvider.overrideWithValue(
            const AsyncData(<ItemManagementGroup>[]),
          ),
          timelinesProvider.overrideWith(
            (ref) => Stream.value(const <Timeline>[]),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp.router(
              routerConfig: ref.watch(appRouterProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.bottomNavToday), findsAtLeastNWidgets(1));
    expect(find.text(ReminderUiText.bottomNavManage), findsAtLeastNWidgets(1));
    expect(
      find.text(ReminderUiText.bottomNavTimeline),
      findsAtLeastNWidgets(1),
    );
    expect(find.text(ReminderUiText.homeAttentionStable), findsOneWidget);
    expect(find.byKey(const Key('home-add-item-fab')), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.bottomNavManage).last);
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.itemsManagementFeatureTitle),
      findsOneWidget,
    );
    expect(find.byKey(const Key('manage-add-item-fab')), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.bottomNavTimeline).last);
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.timelineManagementFeatureTitle),
      findsOneWidget,
    );
    expect(find.byKey(const Key('timeline-add-fab')), findsOneWidget);
  });
}
