import 'dart:math' as math;

enum AttentionPolicySource { systemDefault, userCustomized }

enum ReminderTone { gentle, standard, early, urgent }

enum UsageSpeed { low, medium, high }

class AttentionPolicy {
  const AttentionPolicy({
    this.warningAfterDays,
    this.dangerAfterDays,
    this.warningBeforeDays,
    this.dangerBeforeDays,
    this.source = AttentionPolicySource.systemDefault,
  });

  final int? warningAfterDays;
  final int? dangerAfterDays;
  final int? warningBeforeDays;
  final int? dangerBeforeDays;
  final AttentionPolicySource source;
}

class AttentionPolicyResolver {
  const AttentionPolicyResolver();

  AttentionPolicy resolveFixed({
    required DateTime anchorDate,
    required DateTime dueDate,
    ReminderTone tone = ReminderTone.standard,
  }) {
    final normalizedAnchor = _normalizeDate(anchorDate);
    final normalizedDue = _normalizeDate(dueDate);
    final availableWindowDays = math.max(
      1,
      normalizedDue.difference(normalizedAnchor).inDays + 1,
    );
    final standard = _standardFixedBeforeDays(availableWindowDays);

    final (warningBeforeDays, dangerBeforeDays) = switch (tone) {
      ReminderTone.gentle => (math.min(1, availableWindowDays - 1), 0),
      ReminderTone.standard => standard,
      ReminderTone.early => (
        math.max(standard.$1, availableWindowDays - 1),
        math.max(standard.$2, math.min(1, availableWindowDays - 1)),
      ),
      ReminderTone.urgent => (
        math.max(standard.$1, availableWindowDays - 1),
        math.max(standard.$2, math.min(1, availableWindowDays - 1)),
      ),
    };

    final clamped = _clampBefore(
      warningBeforeDays,
      dangerBeforeDays,
      maximum: availableWindowDays - 1,
    );
    return AttentionPolicy(
      warningBeforeDays: clamped.$1,
      dangerBeforeDays: clamped.$2,
    );
  }

  AttentionPolicy resolveFlexible({
    required int expectedIntervalDays,
    ReminderTone tone = ReminderTone.standard,
  }) {
    final expectedDays = math.max(1, expectedIntervalDays);
    if (expectedDays <= 1) {
      return const AttentionPolicy(warningAfterDays: 0, dangerAfterDays: 1);
    }
    if (expectedDays <= 3) {
      return AttentionPolicy(
        warningAfterDays: math.max(1, expectedDays - 1),
        dangerAfterDays: expectedDays,
      );
    }

    final warningRatio = switch (tone) {
      ReminderTone.gentle => 0.9,
      ReminderTone.standard => 0.8,
      ReminderTone.early => 0.65,
      ReminderTone.urgent => 0.6,
    };
    final dangerAfterDays = tone == ReminderTone.urgent
        ? math.max(1, (expectedDays * 0.9).round())
        : expectedDays;
    final warningAfterDays = math.max(0, (expectedDays * warningRatio).round());
    final clampedWarning = warningAfterDays.clamp(0, dangerAfterDays);

    return AttentionPolicy(
      warningAfterDays: clampedWarning,
      dangerAfterDays: dangerAfterDays,
    );
  }

  AttentionPolicy resolveStock({
    required int estimatedDurationDays,
    UsageSpeed usageSpeed = UsageSpeed.medium,
    ReminderTone tone = ReminderTone.standard,
  }) {
    final durationDays = math.max(1, estimatedDurationDays);
    final standard = switch (usageSpeed) {
      UsageSpeed.low => (2, 1),
      UsageSpeed.medium => (3, 1),
      UsageSpeed.high => (5, 2),
    };
    final (warningBeforeDays, dangerBeforeDays) = switch (tone) {
      ReminderTone.gentle => (
        math.min(standard.$1, 2),
        math.min(standard.$2, 1),
      ),
      ReminderTone.standard => standard,
      ReminderTone.early => (
        math.max(standard.$1, 5),
        math.max(standard.$2, 2),
      ),
      ReminderTone.urgent => (
        math.max(standard.$1, 7),
        math.max(standard.$2, 3),
      ),
    };

    final clamped = _clampBefore(
      warningBeforeDays,
      dangerBeforeDays,
      maximum: durationDays,
    );
    return AttentionPolicy(
      warningBeforeDays: clamped.$1,
      dangerBeforeDays: clamped.$2,
    );
  }

  (int, int) _standardFixedBeforeDays(int availableWindowDays) {
    if (availableWindowDays <= 1) {
      return (0, 0);
    }
    if (availableWindowDays <= 3) {
      return (availableWindowDays - 1, 0);
    }
    if (availableWindowDays <= 7) {
      return (math.min(3, availableWindowDays - 1), 1);
    }
    return (
      (availableWindowDays * 0.5).ceil(),
      math.max(1, (availableWindowDays * 0.2).ceil()),
    );
  }

  (int, int) _clampBefore(int warning, int danger, {required int maximum}) {
    final clampedMaximum = math.max(0, maximum);
    final clampedWarning = warning.clamp(0, clampedMaximum);
    final clampedDanger = danger.clamp(0, clampedWarning);
    return (clampedWarning, clampedDanger);
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
