import '../domain/item.dart';
import '../domain/item_pack_template.dart';
import '../domain/resource.dart';

const builtinItemPackTemplates = <ItemPackTemplate>[
  ItemPackTemplate(
    id: 'builtin-housework-water-filter',
    source: ItemPackTemplateSource.builtin,
    name: '家務 / 濾水',
    category: '家務',
    description: '包含替換濾水網責任，以及濾水網庫存資源。',
    items: [
      ItemPackTemplateItem(
        logicalId: 'replace-water-filter',
        title: '替換濾水網',
        description: '每兩週需要處理一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 12),
          dangerAfter: Duration(days: 14),
        ),
      ),
    ],
    resources: [
      ResourceTemplateItem(
        logicalId: 'water-filter-stock',
        title: '濾水網',
        description: '替換濾水網時會消耗 1 個',
        type: ResourceType.quantityBased,
        config: QuantityBasedResourceConfig(
          currentQuantity: 5,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
    ],
    consumptionRules: [
      ResourceConsumptionRuleTemplate(
        itemLogicalId: 'replace-water-filter',
        resourceLogicalId: 'water-filter-stock',
        consumeAmount: 1,
      ),
    ],
  ),
  ItemPackTemplate(
    id: 'builtin-personal-care',
    source: ItemPackTemplateSource.builtin,
    name: '個人護理',
    category: '個人護理',
    description: '包含常見個人護理用品的資源提醒。',
    items: [
      ItemPackTemplateItem(
        title: '剪指甲',
        description: '一週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
    ],
    resources: [
      ResourceTemplateItem(
        logicalId: 'shampoo',
        title: '洗髮精',
        description: '以可用天數估算大約何時需要留意',
        type: ResourceType.timeBased,
        config: TimeBasedResourceConfig(
          durationDays: 20,
          warningBeforeDays: 3,
          dangerBeforeDays: 1,
        ),
      ),
    ],
  ),
  ItemPackTemplate(
    id: 'builtin-cat-care',
    source: ItemPackTemplateSource.builtin,
    name: '彩月島貓奴指南',
    category: '照料貓咪',
    description: '照顧貓咪的日常事項，保留為 item-focused 模版。',
    items: [
      ItemPackTemplateItem(
        title: '19:00 餵飯',
        description: '餵罐',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.daily,
          warningBefore: Duration.zero,
          dangerBefore: Duration.zero,
        ),
      ),
      ItemPackTemplateItem(
        title: '清理貓砂盆',
        description: '兩週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 10),
          dangerAfter: Duration(days: 15),
        ),
      ),
      ItemPackTemplateItem(
        title: '飲水機換濾芯',
        description: '兩週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 10),
          dangerAfter: Duration(days: 15),
        ),
      ),
    ],
    resources: [
      ResourceTemplateItem(
        logicalId: 'cat-food',
        title: '貓乾糧',
        description: '獨立資源提醒，不再是 Item 類型',
        type: ResourceType.timeBased,
        config: TimeBasedResourceConfig(
          durationDays: 30,
          warningBeforeDays: 5,
          dangerBeforeDays: 2,
        ),
      ),
    ],
  ),
];
