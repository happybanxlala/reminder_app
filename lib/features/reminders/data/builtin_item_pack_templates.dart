import '../domain/item.dart';
import '../domain/item_pack_template.dart';

const builtinItemPackTemplates = <ItemPackTemplate>[
  ItemPackTemplate(
    id: 'builtin-cat-care',
    source: ItemPackTemplateSource.builtin,
    name: '彩月島貓奴指南',
    category: '照料貓咪',
    description: '這個模版包含了照顧貓咪的日常事項，幫助你確保貓咪的健康和幸福。',
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
        title: '替換貓砂盆尿墊',
        description: '三天一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 3),
          dangerAfter: Duration(days: 5),
        ),
      ),
      ItemPackTemplateItem(
        title: '飲水機加水',
        description: '三天一次、不加會彩水會亂喝水',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXDays,
          scheduleInterval: 3,
          warningBefore: Duration(days: 1),
          dangerBefore: Duration.zero,
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
      ItemPackTemplateItem(
        title: '餵食機加食',
        description: '兩週一次',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXDays,
          scheduleInterval: 14,
          warningBefore: Duration(days: 1),
          dangerBefore: Duration.zero,
        ),
      ),
      ItemPackTemplateItem(
        title: '替換餵食機乾燥劑',
        description: '一月一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 30),
          dangerAfter: Duration(days: 40),
        ),
      ),
      ItemPackTemplateItem(
        title: '補充貓用品',
        description: '尿墊、貓砂，hktvmall買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
      ItemPackTemplateItem(
        title: '補充貓乾糧',
        description: 'hktvmall買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
      ItemPackTemplateItem(
        title: '補充貓罐頭',
        description: '去葵芳買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
      ItemPackTemplateItem(
        title: '剪指甲',
        description: '一週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
      ItemPackTemplateItem(
        title: '刷牙',
        description: '一週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
    ],
  ),
  ItemPackTemplate(
    id: 'builtin-housework',
    source: ItemPackTemplateSource.builtin,
    name: '家務清單',
    category: '家務',
    description: '這個模版包含了常見的家務事項，幫助你保持家庭整潔和有序。',
    items: [
      ItemPackTemplateItem(
        title: '打掃地板',
        description: '每週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
      ItemPackTemplateItem(
        title: '打掃浴室',
        description: '每週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
      ItemPackTemplateItem(
        title: '洗衣服',
        description: '每週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
      ItemPackTemplateItem(
        title: '擦窗戶',
        description: '每月一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 30),
          dangerAfter: Duration(days: 40),
        ),
      ),
      ItemPackTemplateItem(
        title: '清理冰箱',
        description: '每月一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 30),
          dangerAfter: Duration(days: 40),
        ),
      ),
      ItemPackTemplateItem(
        title: '倒垃圾',
        description: '每週一次',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 10),
        ),
      ),
      ItemPackTemplateItem(
        title: '購買清潔用品',
        description: 'hktvmall買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
      ItemPackTemplateItem(
        title: '購買洗衣用品',
        description: 'hktvmall買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
      ItemPackTemplateItem(
        title: '購買垃圾袋',
        description: 'hktvmall買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
      ItemPackTemplateItem(
        title: '購買清潔工具',
        description: 'hktvmall買',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          durationDays: 0,
          warningBefore: 5,
          dangerBefore: 3,
        ),
      ),
    ],
  ),
];
