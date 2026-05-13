---
This is the single source of truth for reminders core model, MVP scope, naming, and behavior.
---

# Reminder App Unified Core Spec

本文件是 reminders feature 的唯一實作依據。

後續實作若與舊文件、舊註解、舊命名衝突，一律以本文件為準。

## 1. 核心決策

reminders feature 的核心模型定為：

- `ItemPack`
- `Item`
- `ItemConfig`
- `ItemType`
- `ItemLifecycleStatus`
- `ItemStatus`
- `ItemStatusService`
- `ItemActionRecord`
- `ItemActionType`
- `AttentionPolicy`
- `AttentionPolicySource`
- `Resource`
- `ResourceConfig`
- `ResourceType`
- `ResourceLifecycleStatus`
- `ResourceStatus`
- `ResourceStatusService`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `ResourceActionType`
- `ReminderTone`
- `UsageSpeed`
- `RepeatRuleV2`
- `AppSettings`
- `Timeline`
- `TimelineMilestoneRule`
- `TimelineMilestoneOccurrence`
- `TimelineMilestoneRecord`

此系統不再以 `Task / TaskTemplate / Task instance` 為核心。

一句話版本：

> `Item` 是要做的事；`Resource` 是要留意的資源。Item action 可以消耗 Resource，但 Resource 不是 ItemType。

核心邊界：

| 概念 | 責任 |
| --- | --- |
| `Item` | 責任 / 行為 / 需要被完成的事 |
| `Resource` | 可被消耗、可補充、可提醒的資源 |
| `ItemActionRecord` | user actions on responsibilities |
| `ResourceActionRecord` | resource stock / availability changes |
| `ItemStatus` | item 責任狀態推導結果 |
| `ResourceStatus` | resource 可用性狀態推導結果 |

## 2. 產品北極星

> 讓重要的事，不會在無意識中變糟。

系統優先關注：

- 哪些責任正在惡化
- 哪些固定節奏的責任已接近或超過當前週期
- 哪些資源即將不足或已不足
- 哪些 timeline milestone 已進入提醒窗口

Home 可以聚合 `Item` 與 `Resource` 成 presentation model，例如 `AttentionTarget`。Domain 必須保持分離。

## 3. Item Domain

### 3.1 ItemPack

```ts
ItemPack {
  id: number
  title: string
  description?: string
  status: "active" | "archived"
  isSystemDefault: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- item pack 用來組織責任與資源場景，例如：養貓、家務、健康
- system default pack 必須唯一
- system default pack 可見，但不可改名、不可封存
- archived pack 不再接受新 item / resource 歸屬

### 3.2 Item

```ts
Item {
  id: number
  packId: number
  title: string
  description?: string
  type: ItemType
  config: ItemConfig
  attentionPolicySource: "systemDefault" | "userCustomized"
  status: "active" | "paused" | "archived" // lifecycle status
  lastDoneAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- item 屬於一個 pack
- item 的 lifecycle 與 attention status 分離
- item 以 `type + config` 為主推導 attention status；部分類型會輔以 `lastDoneAt`
- `attentionPolicySource` 記錄提醒策略是系統推導或使用者自訂
- `lastDoneAt` 是快照欄位與查詢優化欄位，不等於完整歷史
- `STATE_BASED` 不再以 `lastDoneAt` 作為主要基準，改以 `config.anchorDate`
- item side 不建立 `TaskTemplate + Task instance`
- Resource is no longer an ItemType.

### 3.3 ItemType

```dart
enum ItemType {
  fixed,
  stateBased,
}
```

語意：

- `fixed`：有明確日曆週期或 due date 的責任，例如繳費、回診、固定清潔
- `stateBased`：狀態會隨時間變差的責任，例如清貓砂、換濾水網、整理冰箱

明確淘汰：

- `ItemType.resourceBased`
- `ResourceBasedItemConfig`
- Item 上的 resource-based config
- Item table 上的 `resourceAnchorDate / resourceDurationDays / resourceExpectedBeforeDays / resourceWarningBeforeDays / resourceDangerBeforeDays`

The previous `RESOURCE_BASED ItemType` is removed. Its day-based availability behavior is now represented by `ResourceType.timeBased`.

### 3.4 FixedItemConfig

```ts
FixedItemConfig {
  scheduleType: "oneTime" | "daily" | "weekly" | "monthly" | "yearly" | "custom"
  anchorDate?: DateTime
  dueDate?: DateTime
  repeatRule?: RepeatRuleV2
  overduePolicy: "waitForAction" | "autoComplete"
}
```

規則：

- `fixed` 責任的主要問題是「週期是否到點」
- `skip` 可用於跳過本輪 fixed 責任
- `overduePolicy.waitForAction` 會維持待處理直到使用者 action

### 3.5 StateBasedItemConfig

```ts
StateBasedItemConfig {
  anchorDate?: DateTime
  infoAfter: Duration
  warningAfter: Duration
  dangerAfter: Duration
}
```

規則：

- `stateBased` 責任的主要問題是「距離上次重設基準多久」
- 完成時將 `anchorDate` 更新為 action date
- `skip` 可用於表示這次不處理，但不重設狀態基準
- `warningAfter / dangerAfter` 由 domain service 集中計算，不散落在 widget

### 3.6 ItemActionRecord

```ts
ItemActionRecord {
  id: number
  itemId: number
  actionType: "created" | "done" | "skipped" | "deferred"
  actionDate: DateTime
  remark?: string
  payload?: Json
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- `ItemActionRecord` records user actions on responsibilities.
- `ItemActionRecord` 是 history layer，不是 item attention status 的唯一來源
- `payload` 只保存 item action 附加資訊，不保存 resource refill 資訊
- item 操作寫入 record 後，仍需同步更新 item snapshot 欄位
- `deferred` action type 保留給既有資料相容與未來功能恢復；目前 MVP 不會建立新的 deferred record
- `ItemActionService` 不再要求 `addedDays`，也不再對 resource item 做 special case

## 4. Resource Domain

### 4.1 Resource

`Resource` 代表可用資源，而不是要完成的責任。

範例：

- 濾水網：目前 5 個，剩 2 個提醒，剩 1 個危急
- 洗髮精：大約還能用 20 天，剩 3 天提醒，剩 1 天危急

```ts
Resource {
  id: number
  packId: number
  title: string
  description?: string
  type: ResourceType
  config: ResourceConfig
  status: "active" | "paused" | "archived" // lifecycle status
  lastRefilledAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- Resource 屬於 pack，可在管理頁或 Home 與 item 聚合顯示
- Resource lifecycle 使用 `active / paused / archived`
- Home 只聚合 active resources
- UI 可以把 Resource 顯示在 Item 編輯頁的「消耗資源」區塊，但 domain 仍保持分離

### 4.2 ResourceType

```dart
enum ResourceType {
  timeBased,
  quantityBased,
}
```

語意：

- `timeBased`：用天數估算可用性，例如洗髮精、貓砂、清潔劑
- `quantityBased`：用數量估算可用性，例如濾水網、垃圾袋、藥片

### 4.3 ResourceConfig

```dart
abstract class ResourceConfig {
  ResourceType get type;
}
```

Time-based resource：

```ts
TimeBasedResourceConfig {
  anchorDate?: DateTime
  durationDays: number
  infoBeforeDays: number
  warningBeforeDays: number
  dangerBeforeDays: number
}
```

規則：

- `anchorDate` 當天算第 1 天
- `durationDays` 是估算可用天數
- depletion day 顯示 remaining days = `0`
- UI 文案使用「預計」、「大約」，避免太絕對

Quantity-based resource：

```ts
QuantityBasedResourceConfig {
  currentQuantity: number
  unitLabel: string
  infoThreshold?: number
  warningThreshold: number
  dangerThreshold: number
}
```

規則：

- quantity 不允許小於 `0`
- repository 在消耗或調整時將負數結果 clamp 到 `0`
- `unitLabel` 使用生活單位，例如：個、包、瓶、片

### 4.4 ResourceConsumptionRule

```ts
ResourceConsumptionRule {
  id: number
  resourceId: number
  itemId: number
  triggerActionType: ItemActionType
  consumeAmount: number
  isEnabled: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- MVP 只支援 `triggerActionType = done`
- MVP 只支援 item action 消耗 quantity-based resource
- `consumeAmount` 必須大於 `0`
- disabled rule 不會套用，但可保留歷史設定

範例：

```text
Item: 替換濾水網
Resource: 濾水網
Rule: done 時 consume 1 個
```

### 4.5 ResourceActionRecord

```dart
enum ResourceActionType {
  created,
  consumed,
  refilled,
  adjusted,
}
```

```ts
ResourceActionRecord {
  id: number
  resourceId: number
  actionType: ResourceActionType
  actionDate: DateTime
  amount?: number
  resultingQuantity?: number
  addedDays?: number
  resultingDurationDays?: number
  sourceItemActionRecordId?: number
  remark?: string
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- `ResourceActionRecord` records resource stock / availability changes.
- quantity consumption / refill / adjustment 記錄 `amount` 與 `resultingQuantity`
- time refill 記錄 `addedDays` 與 `resultingDurationDays`
- 由 item done 觸發的 consumption 必須設定 `sourceItemActionRecordId`

## 5. Status 邊界

`ItemStatus` and `ResourceStatus` are separate derived statuses.

Home may aggregate both into `AttentionTarget`，但 aggregation 是 presentation layer，不是 domain 合併。

### 5.1 ItemStatus

```dart
enum ItemStatus {
  normal,
  warning,
  danger,
  unknown,
}
```

規則：

- `fixed` 由 due date / repeat cycle / preview date 推導
- `stateBased` 由 `anchorDate + warningAfter / dangerAfter` 推導
- paused / archived item 不應進入 Home attention 聚合

### 5.2 ResourceStatus

```dart
enum ResourceStatus {
  normal,
  warning,
  danger,
  unknown,
}
```

Time-based resource：

```text
if anchorDate == null or durationDays <= 0:
    status = unknown

depletionDate = anchorDate + durationDays - 1
remainingDays = depletionDate - now

if remainingDays <= dangerBeforeDays:
    status = danger
elif remainingDays <= warningBeforeDays:
    status = warning
else:
    status = normal
```

Quantity-based resource：

```text
if currentQuantity < 0:
    status = unknown

if currentQuantity <= dangerThreshold:
    status = danger
elif currentQuantity <= warningThreshold:
    status = warning
else:
    status = normal
```

Repository 不應寫入 negative quantity；若外部資料異常小於 `0`，status service 可回傳 `unknown`。

## 6. Repository / Transaction 行為

### 6.1 完成 Item

When completing an Item, matching `ResourceConsumptionRules` are applied in the same transaction.

同一個 transaction 必須包含：

1. item snapshot update
2. `ItemActionRecord(done)` insert
3. matching enabled resource consumption rules query
4. quantity resource snapshot update
5. `ResourceActionRecord(consumed)` insert

規則：

- rule 必須符合 `rule.itemId == item.id`
- rule 必須 enabled
- rule trigger 必須為 `done`
- MVP 僅扣 quantity-based resource
- resource 必須 active
- 消耗後 quantity clamp 到 `0`
- `ResourceActionRecord.sourceItemActionRecordId` 指向剛建立的 `ItemActionRecord(done)`

### 6.2 Refill Resource

建議 repository API：

```dart
Future<bool> refillResource(
  int resourceId, {
  DateTime? actionAt,
  int? addedDays,
  int? addedQuantity,
  String? remark,
})
```

Time-based resource refill：

- 必須輸入 `addedDays > 0`
- 若尚未耗盡，要 carry over 剩餘天數
- 新 `anchorDate = actionDate`
- 新 `durationDays = remainingCarryDays + addedDays`
- 寫入 `ResourceActionRecord(refilled)`

Quantity-based resource refill：

- 必須輸入 `addedQuantity > 0`
- `currentQuantity += addedQuantity`
- 寫入 `ResourceActionRecord(refilled)`
- `resultingQuantity = 更新後數量`

### 6.3 Adjust Resource

MVP 支援 manual adjustment：

```dart
Future<bool> adjustResourceQuantity(
  int resourceId, {
  required int newQuantity,
  DateTime? actionAt,
  String? remark,
})
```

規則：

- `newQuantity` 若小於 `0`，repository clamp 到 `0`
- adjustment 用於使用者修正庫存錯誤
- 寫入 `ResourceActionRecord(adjusted)`

## 7. Drift Schema

### 7.1 items

`items` 不再保存 resource-based 欄位。

移除：

- `resourceAnchorDate`
- `resourceDurationDays`
- `resourceExpectedBeforeDays`
- `resourceWarningBeforeDays`
- `resourceDangerBeforeDays`

### 7.2 resources

```text
id
packId
title
description
status
type
timeAnchorDate
timeDurationDays
timeExpectedBeforeDays
timeWarningBeforeDays
timeDangerBeforeDays
quantityCurrent
quantityUnitLabel
quantityExpectedThreshold
quantityWarningThreshold
quantityDangerThreshold
lastRefilledAt
createdAt
updatedAt
```

### 7.3 resource_consumption_rules

```text
id
resourceId
itemId
triggerActionType
consumeAmount
isEnabled
createdAt
updatedAt
```

### 7.4 resource_action_records

```text
id
resourceId
actionType
actionDate
amount
resultingQuantity
addedDays
resultingDurationDays
sourceItemActionRecordId
remark
createdAt
updatedAt
```

舊資料不重要；schema upgrade 可 drop/recreate 或等價 reset schema。

## 8. UI 心智模型

```text
Item = 要做的事
Resource = 要留意的資源
```

規則：

- Item 建立 / 編輯頁只提供 `fixed / stateBased`
- Resource 可以 appear attached to Item in UI, but remains separate in domain.
- Item 編輯頁可以有「消耗資源」區塊
- 新增 consumption rule 時只選 existing quantity-based resource
- trigger action MVP 固定為 done
- Resource 管理頁支援建立 / 編輯 / 補充 / quantity 調整
- UI 文案使用生活語言，不顯示 raw enum 或 raw config 欄位名
- time-based resource UI 使用「大約還能用幾天」、「預計剩 N 天」
- quantity-based resource UI 使用「目前 N 個」、「剩 N 個提醒」

Home 顯示可以是：

```text
快變糟
- 替換濾水網：已到處理日
- 濾水網：剩 2 個
- 洗髮精：預計剩 3 天
```

MVP 可保留 item sections，並新增 Resource section；presentation model 應朝 `AttentionTarget` 聚合收斂。

## 9. Templates / Demo

Built-in template 若需要 resource 行為，必須建立：

1. `Resource`
2. 需要時建立 `Item`
3. 需要時建立 `ResourceConsumptionRule`

示例：

```text
Pack: 家務 / 濾水

Item:
  title: 替換濾水網
  type: stateBased
  anchorDate: today
  warningAfter: 12 days
  dangerAfter: 14 days

Resource:
  title: 濾水網
  type: quantityBased
  currentQuantity: 5
  unitLabel: 個
  warningThreshold: 2
  dangerThreshold: 1

ConsumptionRule:
  item = 替換濾水網
  resource = 濾水網
  trigger = done
  consumeAmount = 1
```

```text
Pack: 個人護理

Resource:
  title: 洗髮精
  type: timeBased
  anchorDate: today
  durationDays: 20
  warningBeforeDays: 3
  dangerBeforeDays: 1
```

## 10. Timeline Domain

Timeline 維持 rule-driven milestone 模型，不與 Resource 合併。

```ts
Timeline {
  id: number
  title: string
  startDate: DateTime
  displayUnit: "day" | "week" | "month" | "year"
  status: "active" | "archived"
  createdAt: DateTime
  updatedAt: DateTime
}
```

```ts
TimelineMilestoneRule {
  id: number
  timelineId: number
  type: "every_n_days" | "every_n_weeks" | "every_n_months" | "every_n_years"
  intervalValue: number
  intervalUnit: "days" | "weeks" | "months" | "years"
  labelTemplate?: string
  reminderOffsetDays: number
  status: "active" | "paused" | "archived"
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- occurrence 是計算結果，不是預生成資料
- 需要記錄互動時才建立 `TimelineMilestoneRecord`
- timeline milestone 可以進入 Home attention，但仍是獨立 domain

## 11. 命名規則

必須使用：

- `ItemPack`
- `Item`
- `ItemActionRecord`
- `Resource`
- `ResourceConfig`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `Timeline`
- `TimelineMilestoneRule`

禁止重新引入：

- `Task`
- `TaskTemplate`
- `TaskInstance`
- `ItemType.resourceBased`
- `ResourceBasedItemConfig`
- `ResourceBaseItem`

命名原則：

- 程式碼命名維持英文、清楚、domain-driven
- UI 文案使用繁體中文與生活語意
- Resource domain 一律優先使用 `Resource`，不要使用 `ResourceBaseItem`
