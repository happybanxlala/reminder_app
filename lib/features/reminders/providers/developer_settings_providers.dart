import 'package:flutter_riverpod/flutter_riverpod.dart';

final developerDateOverrideProvider = StateProvider<DateTime?>((ref) => null);

final effectivePreviewDateProvider = Provider<DateTime>((ref) {
  final overrideDate = ref.watch(developerDateOverrideProvider);
  return normalizePreviewDate(overrideDate ?? DateTime.now());
});

DateTime normalizePreviewDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
