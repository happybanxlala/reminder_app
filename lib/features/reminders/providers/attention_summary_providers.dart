import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attention_summary_repository.dart';
import '../domain/attention_summary.dart';
import 'developer_settings_providers.dart';
import 'home_providers.dart';

final attentionSummaryRepositoryProvider = Provider<AttentionSummaryRepository>(
  (ref) {
    return AttentionSummaryRepository(
      homeRepository: ref.watch(homeRepositoryProvider),
    );
  },
);

final realTodayProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  Timer? timer;

  void emitCurrentDate() {
    final now = DateTime.now();
    final today = normalizePreviewDate(now);
    controller.add(today);

    final nextMidnight = today.add(const Duration(days: 1));
    final delay = nextMidnight.difference(DateTime.now());
    timer?.cancel();
    timer = Timer(delay.isNegative ? Duration.zero : delay, emitCurrentDate);
  }

  emitCurrentDate();
  ref.onDispose(() async {
    timer?.cancel();
    await controller.close();
  });

  return controller.stream;
});

final attentionSummaryProvider = StreamProvider<AttentionSummary>((ref) {
  final previewDate = ref.watch(effectivePreviewDateProvider);
  return ref
      .watch(attentionSummaryRepositoryProvider)
      .watchSummary(now: previewDate);
});

final liveAttentionSummaryProvider = StreamProvider<AttentionSummary>((ref) {
  final today = ref
      .watch(realTodayProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => normalizePreviewDate(DateTime.now()),
      );
  return ref.watch(attentionSummaryRepositoryProvider).watchSummary(now: today);
});
