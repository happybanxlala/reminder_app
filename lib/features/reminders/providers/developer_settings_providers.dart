import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final developerDateOverrideProvider = StateProvider<DateTime?>((ref) => null);

final systemPreviewDateProvider = StreamProvider<DateTime>((ref) {
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

final effectivePreviewDateProvider = Provider<DateTime>((ref) {
  final overrideDate = ref.watch(developerDateOverrideProvider);
  if (overrideDate != null) {
    return normalizePreviewDate(overrideDate);
  }

  return ref
      .watch(systemPreviewDateProvider)
      .maybeWhen(
        data: normalizePreviewDate,
        orElse: () => normalizePreviewDate(DateTime.now()),
      );
});

DateTime normalizePreviewDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
