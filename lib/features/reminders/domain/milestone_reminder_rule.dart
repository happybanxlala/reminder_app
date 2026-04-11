enum MilestoneReminderRuleType { advance, onDay }

class MilestoneReminderRule {
  const MilestoneReminderRule._({required this.type, this.offsetDays});

  const MilestoneReminderRule.advance(int offsetDays)
    : this._(type: MilestoneReminderRuleType.advance, offsetDays: offsetDays);

  const MilestoneReminderRule.onDay()
    : this._(type: MilestoneReminderRuleType.onDay);

  final MilestoneReminderRuleType type;
  final int? offsetDays;

  String encode() {
    return switch (type) {
      MilestoneReminderRuleType.advance => 'advance:${offsetDays ?? 0}',
      MilestoneReminderRuleType.onDay => 'onDay',
    };
  }

  static MilestoneReminderRule decode(String value) {
    if (value == 'onDay') {
      return const MilestoneReminderRule.onDay();
    }
    if (value.startsWith('advance:')) {
      final offset = int.tryParse(value.split(':').last) ?? 0;
      return MilestoneReminderRule.advance(offset);
    }
    return const MilestoneReminderRule.onDay();
  }
}
