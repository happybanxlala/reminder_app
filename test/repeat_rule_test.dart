import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule_v2.dart';
import 'package:reminder_app/features/reminders/presentation/formatters/reminder_formatters.dart';

void main() {
  group('repeat rule formatters', () {
    test('formats legacy summaries', () {
      expect(ReminderFormatters.formatRepeatRuleSummary(null), '永不');
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.day, interval: 1),
        ),
        '每天',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.day, interval: 3),
        ),
        '每 3 天',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.week, interval: 1),
        ),
        '每週',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.week, interval: 2),
        ),
        '每 2 週',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.month, interval: 1),
        ),
        '每月',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.month, interval: 3),
        ),
        '每 3 個月',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.year, interval: 1),
        ),
        '每年',
      );
      expect(
        ReminderFormatters.formatRepeatRuleSummary(
          const RepeatRule(unit: RepeatUnit.year, interval: 2),
        ),
        '每 2 年',
      );
    });

    test('formats advanced summaries', () {
      expect(
        ReminderFormatters.repeatRuleV2Summary(
          RepeatRuleV2.weeklyWeekdays(
            interval: 1,
            weekdays: const [
              DateTime.monday,
              DateTime.wednesday,
              DateTime.friday,
            ],
          ),
        ),
        '每週一、三、五',
      );
      expect(
        ReminderFormatters.repeatRuleV2Summary(
          RepeatRuleV2.weeklyWeekdays(
            interval: 2,
            weekdays: const [DateTime.wednesday],
          ),
        ),
        '每 2 週的星期三',
      );
      expect(
        ReminderFormatters.repeatRuleV2Summary(
          RepeatRuleV2.monthlyDates(interval: 1, monthDays: const [12, 18]),
        ),
        '每月 12 日和 18 日',
      );
      expect(
        ReminderFormatters.repeatRuleV2Summary(
          RepeatRuleV2.monthlyNthWeekday(
            interval: 1,
            ordinal: MonthlyWeekOrdinal.third,
            weekday: DateTime.wednesday,
          ),
        ),
        '每月第三個星期三',
      );
      expect(
        ReminderFormatters.repeatRuleV2Summary(
          RepeatRuleV2.monthlyNthWeekday(
            interval: 2,
            ordinal: MonthlyWeekOrdinal.last,
            weekday: DateTime.friday,
          ),
        ),
        '每 2 個月的最後一個星期五',
      );
      expect(
        ReminderFormatters.repeatRuleV2Summary(
          RepeatRuleV2.simple(
            unit: RepeatUnit.day,
            interval: 3,
            end: RepeatEndCondition.onDate(DateTime(2026, 6, 30)),
          ),
        ),
        '每 3 天，直到 2026/06/30',
      );
    });
  });

  group('repeat rule parser', () {
    test('parses legacy formats', () {
      expect(RepeatRuleV2.parse('D3')!.unit, RepeatUnit.day);
      expect(RepeatRuleV2.parse('D3')!.interval, 3);
      expect(RepeatRuleV2.parse('W2')!.unit, RepeatUnit.week);
      expect(RepeatRuleV2.parse('M1')!.unit, RepeatUnit.month);
      expect(RepeatRuleV2.parse('Y1')!.unit, RepeatUnit.year);
    });

    test('parses new encoded format and rejects invalid input', () {
      final rule = RepeatRuleV2.weeklyWeekdays(
        interval: 2,
        weekdays: const [DateTime.wednesday],
        end: const RepeatEndCondition.afterCount(10),
      );
      final parsed = RepeatRuleV2.parse(rule.encode());

      expect(parsed, isNotNull);
      expect(parsed!.kind, RepeatRuleV2Kind.weeklyWeekdays);
      expect(parsed.interval, 2);
      expect(parsed.weekdays, [DateTime.wednesday]);
      expect(parsed.end.type, RepeatEndType.afterCount);
      expect(parsed.end.occurrenceCount, 10);
      expect(RepeatRuleV2.parse('not valid'), isNull);
    });
  });

  group('repeat next occurrence', () {
    const calculator = RepeatRuleOccurrenceCalculator();

    test('calculates weekly selected weekdays', () {
      final rule = RepeatRuleV2.weeklyWeekdays(
        interval: 1,
        weekdays: const [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );

      expect(
        calculator.nextOccurrence(
          rule: rule,
          fromDate: DateTime(2026, 4, 1),
          anchorDate: DateTime(2026, 4, 1),
        ),
        DateTime(2026, 4, 3),
      );
    });

    test('calculates every 2 weeks selected weekday', () {
      final rule = RepeatRuleV2.weeklyWeekdays(
        interval: 2,
        weekdays: const [DateTime.wednesday],
      );

      expect(
        calculator.nextOccurrence(
          rule: rule,
          fromDate: DateTime(2026, 4, 1),
          anchorDate: DateTime(2026, 4, 1),
        ),
        DateTime(2026, 4, 15),
      );
    });

    test('calculates monthly dates with last-day fallback', () {
      final rule = RepeatRuleV2.monthlyDates(
        interval: 1,
        monthDays: const [31],
      );

      expect(
        calculator.nextOccurrence(
          rule: rule,
          fromDate: DateTime(2026, 1, 31),
          anchorDate: DateTime(2026, 1, 31),
        ),
        DateTime(2026, 2, 28),
      );
    });

    test('calculates monthly nth weekday and skips missing fifth weekday', () {
      final rule = RepeatRuleV2.monthlyNthWeekday(
        interval: 1,
        ordinal: MonthlyWeekOrdinal.fifth,
        weekday: DateTime.monday,
      );

      expect(
        calculator.nextOccurrence(
          rule: rule,
          fromDate: DateTime(2026, 2, 1),
          anchorDate: DateTime(2026, 2, 1),
        ),
        DateTime(2026, 3, 30),
      );
    });

    test('honors end date and end after count', () {
      expect(
        calculator.nextOccurrence(
          rule: RepeatRuleV2.simple(
            unit: RepeatUnit.day,
            interval: 3,
            end: RepeatEndCondition.onDate(DateTime(2026, 4, 3)),
          ),
          fromDate: DateTime(2026, 4, 1),
        ),
        isNull,
      );
      expect(
        calculator.nextOccurrence(
          rule: RepeatRuleV2.simple(
            unit: RepeatUnit.day,
            interval: 3,
            end: const RepeatEndCondition.afterCount(2),
            completedCount: 2,
          ),
          fromDate: DateTime(2026, 4, 1),
        ),
        isNull,
      );
    });
  });
}
