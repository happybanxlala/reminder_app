enum ReminderRuleType { advance, onDue, immediate }

class ReminderRule {
  const ReminderRule._({required this.type, this.offsetDays});

  const ReminderRule.advance(int offsetDays)
    : this._(type: ReminderRuleType.advance, offsetDays: offsetDays);

  const ReminderRule.onDue() : this._(type: ReminderRuleType.onDue);

  const ReminderRule.immediate() : this._(type: ReminderRuleType.immediate);

  final ReminderRuleType type;
  final int? offsetDays;

  String encode() {
    return switch (type) {
      ReminderRuleType.advance => 'advance:${offsetDays ?? 0}',
      ReminderRuleType.onDue => 'onDue',
      ReminderRuleType.immediate => 'immediate',
    };
  }

  static ReminderRule decode(String value) {
    if (value == 'onDue') {
      return const ReminderRule.onDue();
    }
    if (value == 'immediate') {
      return const ReminderRule.immediate();
    }
    if (value.startsWith('advance:')) {
      final offset = int.tryParse(value.split(':').last) ?? 0;
      return ReminderRule.advance(offset);
    }
    return const ReminderRule.onDue();
  }
}
