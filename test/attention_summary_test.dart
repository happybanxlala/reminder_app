import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/attention_summary_repository.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';

void main() {
  test(
    'attention summary counts item and stage attention separately',
    () async {
      final repository = AttentionSummaryRepository(
        homeRepository: _FakeHomeAttentionSource(
          stages: [
            StageOccurrence(
              stageTrackerId: 1,
              sourceType: StageRecordSourceType.generated,
              occurrenceDate: DateTime(2026, 5, 1),
              label: '滿 1 個月',
              reminderOffsetDays: 0,
            ),
          ],
        ),
      );

      final summary = await repository.getSummary(now: DateTime(2026, 5, 1));

      expect(summary.dangerCount, 0);
      expect(summary.warningCount, 0);
      expect(summary.stageUpcomingCount, 1);
      expect(summary.totalCount, 1);
    },
  );
}

class _FakeHomeAttentionSource implements HomeAttentionSource {
  const _FakeHomeAttentionSource({this.stages = const []});

  final List<StageOccurrence> stages;

  @override
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now}) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now}) {
    return Stream.value(const []);
  }

  @override
  Stream<List<StageOccurrence>> watchUpcomingStages({DateTime? now}) {
    return Stream.value(stages);
  }
}
