import '../domain/item.dart';
import '../domain/pack_template.dart';
import '../domain/repeat_rule.dart';
import '../domain/repeat_rule_v2.dart';

final defaultPackTemplates = <PackTemplate>[
  PackTemplate(
    id: 'default-housework',
    source: PackTemplateSource.defaultTemplate,
    templateName: '家務',
    iconEmoji: '🏠',
    description: '定期清潔、整理與日常家務',
    items: [
      PackTemplateItem(
        title: '倒垃圾',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXDays,
          scheduleInterval: 2,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.day, interval: 2),
          warningBefore: Duration(days: 1),
        ),
      ),
      PackTemplateItem(
        title: '洗衣服',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 1),
          warningBefore: Duration(days: 1),
        ),
      ),
      PackTemplateItem(
        title: '拖地',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 1),
          warningBefore: Duration(days: 1),
        ),
      ),
      PackTemplateItem(
        title: '清潔浴室',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXWeeks,
          scheduleInterval: 2,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 2),
          warningBefore: Duration(days: 2),
        ),
      ),
      PackTemplateItem(
        title: '整理冰箱',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.monthly,
          scheduleInterval: 1,
          repeatRuleV2: RepeatRuleV2.simple(
            unit: RepeatUnit.month,
            interval: 1,
          ),
          warningBefore: Duration(days: 3),
        ),
      ),
    ],
  ),
  PackTemplate(
    id: 'default-personal-care',
    source: PackTemplateSource.defaultTemplate,
    templateName: '個人護理',
    iconEmoji: '🧴',
    description: '定期照顧身體、衛生與個人物品',
    items: [
      PackTemplateItem(
        title: '剪指甲',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXWeeks,
          scheduleInterval: 2,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 2),
          warningBefore: Duration(days: 2),
        ),
      ),
      PackTemplateItem(
        title: '換牙刷',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.monthly,
          scheduleInterval: 3,
          repeatRuleV2: RepeatRuleV2.simple(
            unit: RepeatUnit.month,
            interval: 3,
          ),
          warningBefore: Duration(days: 7),
        ),
      ),
      PackTemplateItem(
        title: '洗床單',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXWeeks,
          scheduleInterval: 2,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 2),
          warningBefore: Duration(days: 2),
        ),
      ),
      PackTemplateItem(
        title: '整理藥箱',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.monthly,
          scheduleInterval: 1,
          repeatRuleV2: RepeatRuleV2.simple(
            unit: RepeatUnit.month,
            interval: 1,
          ),
          warningBefore: Duration(days: 3),
        ),
      ),
      PackTemplateItem(
        title: '檢查護膚品',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 30),
          dangerAfter: Duration(days: 45),
        ),
      ),
    ],
  ),
  PackTemplate(
    id: 'default-cat-care',
    source: PackTemplateSource.defaultTemplate,
    templateName: '養貓',
    iconEmoji: '🐱',
    description: '貓砂、餵食、飲水與定期護理',
    items: [
      PackTemplateItem(
        title: '清貓砂',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.daily,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.day, interval: 1),
        ),
      ),
      PackTemplateItem(
        title: '補貓糧',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
      PackTemplateItem(
        title: '洗水碗',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXDays,
          scheduleInterval: 2,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.day, interval: 2),
          warningBefore: Duration(days: 1),
        ),
      ),
      PackTemplateItem(
        title: '清潔貓窩',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXWeeks,
          scheduleInterval: 2,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 2),
          warningBefore: Duration(days: 2),
        ),
      ),
      PackTemplateItem(
        title: '剪指甲',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXWeeks,
          scheduleInterval: 3,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 3),
          warningBefore: Duration(days: 3),
        ),
      ),
      PackTemplateItem(
        title: '驅蟲',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.monthly,
          scheduleInterval: 3,
          repeatRuleV2: RepeatRuleV2.simple(
            unit: RepeatUnit.month,
            interval: 3,
          ),
          warningBefore: Duration(days: 7),
        ),
      ),
    ],
  ),
];
