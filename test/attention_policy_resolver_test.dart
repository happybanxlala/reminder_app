import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';

void main() {
  group('AttentionPolicyResolver fixed rhythm', () {
    const resolver = AttentionPolicyResolver();

    test('3 day window warns at window start and dangers on due day', () {
      final policy = resolver.resolveFixed(
        anchorDate: DateTime(2024, 5, 1),
        dueDate: DateTime(2024, 5, 3),
      );

      expect(policy.warningBeforeDays, 2);
      expect(policy.dangerBeforeDays, 0);
      expect(policy.source, AttentionPolicySource.systemDefault);
    });

    test('1 day window never produces negative thresholds', () {
      final policy = resolver.resolveFixed(
        anchorDate: DateTime(2024, 5, 1),
        dueDate: DateTime(2024, 5, 1),
      );

      expect(policy.warningBeforeDays, 0);
      expect(policy.dangerBeforeDays, 0);
    });

    test('7 day window is clamped to valid warning and danger ordering', () {
      final policy = resolver.resolveFixed(
        anchorDate: DateTime(2024, 5, 1),
        dueDate: DateTime(2024, 5, 7),
      );

      expect(policy.warningBeforeDays, 3);
      expect(policy.dangerBeforeDays, 1);
      expect(
        policy.warningBeforeDays,
        greaterThanOrEqualTo(policy.dangerBeforeDays!),
      );
    });
  });

  group('AttentionPolicyResolver flexible rhythm', () {
    const resolver = AttentionPolicyResolver();

    test('21 day standard interval warns around 80 percent', () {
      final policy = resolver.resolveFlexible(expectedIntervalDays: 21);

      expect(policy.warningAfterDays, 17);
      expect(policy.dangerAfterDays, 21);
    });

    test('1 day interval keeps thresholds valid', () {
      final policy = resolver.resolveFlexible(expectedIntervalDays: 1);

      expect(policy.warningAfterDays, 0);
      expect(policy.dangerAfterDays, 1);
    });

    test('urgent tone warns and dangers earlier than standard', () {
      final standard = resolver.resolveFlexible(expectedIntervalDays: 21);
      final urgent = resolver.resolveFlexible(
        expectedIntervalDays: 21,
        tone: ReminderTone.urgent,
      );

      expect(urgent.warningAfterDays, lessThan(standard.warningAfterDays!));
      expect(urgent.dangerAfterDays, lessThan(standard.dangerAfterDays!));
      expect(
        urgent.warningAfterDays,
        lessThanOrEqualTo(urgent.dangerAfterDays!),
      );
    });
  });

  group('AttentionPolicyResolver stock', () {
    const resolver = AttentionPolicyResolver();

    test('10 day medium stock uses standard medium thresholds', () {
      final policy = resolver.resolveStock(
        estimatedDurationDays: 10,
        usageSpeed: UsageSpeed.medium,
      );

      expect(policy.warningBeforeDays, 3);
      expect(policy.dangerBeforeDays, 1);
    });

    test('3 day high stock clamps thresholds to duration and ordering', () {
      final policy = resolver.resolveStock(
        estimatedDurationDays: 3,
        usageSpeed: UsageSpeed.high,
      );

      expect(policy.warningBeforeDays, lessThanOrEqualTo(3));
      expect(
        policy.dangerBeforeDays,
        lessThanOrEqualTo(policy.warningBeforeDays!),
      );
    });

    test('low, medium, and high usage speeds produce different results', () {
      final low = resolver.resolveStock(
        estimatedDurationDays: 10,
        usageSpeed: UsageSpeed.low,
      );
      final medium = resolver.resolveStock(
        estimatedDurationDays: 10,
        usageSpeed: UsageSpeed.medium,
      );
      final high = resolver.resolveStock(
        estimatedDurationDays: 10,
        usageSpeed: UsageSpeed.high,
      );

      expect(low.warningBeforeDays, lessThan(medium.warningBeforeDays!));
      expect(medium.warningBeforeDays, lessThan(high.warningBeforeDays!));
      expect(low.dangerBeforeDays, lessThanOrEqualTo(medium.dangerBeforeDays!));
      expect(medium.dangerBeforeDays, lessThan(high.dangerBeforeDays!));
    });
  });
}
