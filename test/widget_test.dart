import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule.dart';

void main() {
  test('RepeatRule parser supports D/W/M/Y patterns', () {
    expect(RepeatRule.parse(null), isNull);
    expect(RepeatRule.parse(''), isNull);

    final day = RepeatRule.parse('D25');
    final week = RepeatRule.parse('W3');
    final month = RepeatRule.parse('M2');
    final year = RepeatRule.parse('Y1');

    expect(day, isNotNull);
    expect(week, isNotNull);
    expect(month, isNotNull);
    expect(year, isNotNull);
  });
}
