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
- `StageTracker`
- `StageRule`
- `StageOccurrence`
- `StageRecord`
- `StageRelatedItem`

一句話版本：

> `Item` 是要做的事；`Resource` 是要留意的資源；`StageTracker` 是從某一天開始追蹤，提醒未來將到來的重要階段。Item action 可以消耗 Resource，但 Resource 不是 ItemType；StageTracker 可以引導建立 Item，但 StageTracker 本身不是 Item。

核心邊界：

| 概念 | 責任 |
| --- | --- |
| `Item` | 責任 / 行為 / 需要被完成的事 |
| `Resource` | 可被消耗、可補充、可提醒的資源 |
| `StageTracker` | 時間推進中的階段追蹤與階段提醒 |
| `ItemActionRecord` | user actions on responsibilities |
| `ResourceActionRecord` | resource stock / availability changes |
| `StageRecord` | user interactions with computed or manual stages |
| `ItemStatus` | item 責任狀態推導結果 |
| `ResourceStatus` | resource 可用性狀態推導結果 |

## 2. 產品北極星

> 讓重要的事，不會在無意識中變糟。

系統優先關注：

- 哪些責任正在惡化
- 哪些固定節奏的責任已接近或超過當前週期
- 哪些資源即將不足或已不足
- 哪些階段追蹤中的階段已進入提醒窗口

Home 可以聚合 `Item`、`Resource` 與 `StageTracker` 階段成 presentation model，例如 `AttentionTarget`。Domain 必須保持分離。

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

- item pack 用來組織責任、資源與階段追蹤場景，例如：養貓、家務、健康、寶寶
- system default pack 必須唯一
- system default pack 可見，但不可改名、不可封存
- archived pack 不再接受新 item / resource / stage tracker 歸屬

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
- Item 本身承載責任設定、生命週期與目前 attention status 推導所需資料
- Resource is no longer an ItemType.
- StageTracker 不是 ItemType；StageTracker 階段若需要行動，應建立相關 Item

### 3.3 ItemType

```dart
enum ItemType {
  fixed,
  stateBased,
}
```

語意：

- `fixed`：有明確日曆週期或 due date 的責任，例如繳費、回診、固定清潔、為某個階段做準備
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
- 從 StageTracker 階段建立 Item 時，Item due date 預設等於階段日期，但使用者可以修改

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

StageTracker 不建立 `StageStatus` 作為 action 或 attention status；階段是否進入 Home 是由階段日期、提醒窗口、record status 與 StageTracker lifecycle 推導的 presentation concern。

Home may aggregate Item、Resource 與 StageTracker stage into `AttentionTarget`，但 aggregation 是 presentation layer，不是 domain 合併。

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

### 6.4 Create Item with Resource Binding Draft

新增 item 時，UI 可以先建立「消耗資源」草稿，但確認前不得寫入 DB。

支援草稿：

1. 綁定既有 active quantity-based resource
2. 建立新的 quantity-based resource draft 並綁定

送出時必須在同一個 transaction 完成：

1. create item
2. insert `ItemActionRecord(created)`
3. 若有 new resource draft，create resource
4. 若有 new resource draft，insert `ResourceActionRecord(created)`
5. insert `ResourceConsumptionRule`

規則：

- 新增 item 時 MVP 僅支援 quantity-based resource consumption binding
- time-based resource 仍由 Resource 管理頁手動建立與補充
- existing resource 選單只顯示同 pack 的 active quantity-based resources
- new resource 使用 item resolved pack
- trigger action 固定為 `done`
- 任一步驟失敗時 transaction 不應留下 partial item / resource / rule

### 6.5 Archive Resource

封存 Resource 只更新 lifecycle status：

```dart
Future<bool> archiveResource(int resourceId)
```

規則：

- archived resource 不出現在 active / managed resource 列表
- archived resource 的 rules 與 action history 保留
- archived resource 的 rules 不再由 `markDone` 套用
- 封存不刪除 `ResourceActionRecord`

### 6.6 Create Item from Stage

StageTracker 階段可以引導建立相關 Item，但 StageTracker 不直接管理完成狀態。

支援來源：

1. important stage
2. repeating stage 的某一次 occurrence

當使用者從某個 stage 建立 related item 時，同一個 transaction 應包含：

1. 若來源是 computed occurrence 且尚無 `StageRecord`，建立 `StageRecord(status = normal)`
2. create item
3. insert `ItemActionRecord(created)`
4. insert `StageRelatedItem(stageRecordId, itemId)`

規則：

- Item due date 預設等於 stage occurrence date，但使用者可修改
- StageTracker reminder start date 不應被誤用成 Item due date
- 一個 stage 可以關聯多個 Item
- 一個 Item MVP 只需支援來自一個 StageRecord；未來若需要可擴充多來源
- related item 被完成、跳過、暫停或封存時，不回寫 StageRecord status

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

### 7.5 stage_trackers

```text
id
packId nullable
title
subjectName nullable
trackingStartDate
trackingEndDate nullable
status // active | archived
createdAt
updatedAt
```

規則：

- `packId == null` 代表全局 StageTracker
- UI 不顯示 raw `trackingEndDate`，使用「追蹤範圍」文案
- `trackingEndDate == null` 代表持續追蹤
- 到達 `trackingEndDate` 後不自動 archive，而是 presentation 顯示「已完成追蹤」

### 7.6 stage_rules

```text
id
stageTrackerId
type // every_n_days | every_n_weeks | every_n_months | every_n_years
intervalValue
intervalUnit // days | weeks | months | years
labelTemplate nullable
reminderOffsetDays nullable
status // active | paused | archived
createdAt
updatedAt
```

規則：

- `reminderOffsetDays == null` 時使用 StageTracker default reminder offset（若實作有設定欄位）或 app default
- MVP UI 使用「重複階段」文案，不顯示 raw enum
- 一個 StageTracker 可以有多條 active rules

### 7.7 stage_records

```text
id
stageTrackerId
stageRuleId nullable
sourceType // generated | manual
occurrenceIndex nullable
occurrenceDate
relativeAmount nullable
relativeUnit nullable // days | weeks | months | years
status // normal | acknowledged | ignored | archived
label
note nullable
reminderOffsetDays nullable
createdAt
updatedAt
```

語意：

- manual important stage 一建立就有 `StageRecord(sourceType = manual)`
- generated occurrence 平常是計算結果；只有使用者互動時才建立 `StageRecord(sourceType = generated)`
- generated record 必須能對應回 rule 與 occurrence，可使用 `stageRuleId + occurrenceIndex` 或 `stageRuleId + occurrenceDate`
- `acknowledged` 表示使用者按過「知道了」，Home 不再顯示這次提示
- `ignored` 表示使用者忽略這次 occurrence，Home / StageTracker 主頁 / 歷史頁都不顯示
- `archived` 主要用於已過去的 manual stage；未來 manual stage 可直接刪除
- `note` 可用於 manual stage 或有互動的 generated occurrence

### 7.8 stage_related_items

```text
id
stageRecordId
itemId
createdAt
updatedAt
```

規則：

- 一個 stage record 可以關聯多個 items
- related item 的 lifecycle/status 不應自動改變 stage record status
- ignored stage record 不影響相關 Item

舊資料不重要；schema upgrade 可 drop/recreate 或等價 reset schema。

## 8. UI 心智模型

```text
Item = 要做的事
Resource = 要留意的資源
StageTracker = 階段追蹤 / 時間推進中的階段提醒
```

規則：

- Item 建立 / 編輯頁只提供 `fixed / stateBased`
- Resource 可以 appear attached to Item in UI, but remains separate in domain.
- StageTracker 可以建立 related Item，但 StageTracker 本身不管理完成狀態
- Item 編輯頁可以有「消耗資源」區塊
- 新增 consumption rule 時只選 existing quantity-based resource
- 新增 item 時可以先建立 resource binding draft；確認前不得寫入 resource / rule
- create item + new resource + consumption rule 必須同 transaction
- trigger action MVP 固定為 done
- Resource 管理頁支援建立 / 編輯 / 補充 / quantity 調整 / 封存
- StageTracker 管理頁支援建立 / 編輯 / 封存 / 重複階段 / 重要階段 / 歷史 / 完整時間表
- UI 文案使用生活語言，不顯示 raw enum 或 raw config 欄位名
- time-based resource UI 使用「大約還能用幾天」、「預計剩 N 天」
- quantity-based resource UI 使用「目前 N 個」、「剩 N 個提醒」
- StageTracker UI 使用「階段追蹤」、「重複階段」、「重要階段」、「從哪一天開始追蹤」、「追蹤範圍」、「知道了」、「忽略這次」等文案

### 8.1 Resource 管理頁

Resource 管理頁有兩個主要入口：

1. 功能頁
2. Item 管理頁

Route：

```text
name: resources-management
path: /feature/resources-management
```

頁面必須包含：

- 返回 / 前往 Item 管理頁入口
- 新增資源 action
- active / paused resource 列表
- resource card

Resource card summary 顯示：

- 名稱
- 類型
- derived `ResourceStatus`
- 數量或預計剩餘天數

Resource card 空白處點擊開 detail dialog。Detail 內容：

- 名稱
- 備註
- 資源類型
- time-based：天數估算、預計可用到、提醒準則
- quantity-based：目前數量、單位、提醒準則
- quantity-based 額外顯示綁定 items：item 名稱、consume amount、rule enabled 狀態

Resource card actions：

- add button = 補充
- overflow menu = 調整、編輯、詳細資訊、歷史紀錄、封存

`adjust` 僅適用 quantity-based resource。

### 8.2 Resource History UI

Resource history 是 `ResourceActionRecord` 的 UI。

Route：

```text
name: resource-history
path: /resource/:id/history
```

列表顯示：

- action type：created / consumed / refilled / adjusted
- action date
- amount / added days
- resulting quantity / resulting duration days
- remark
- `sourceItemActionRecordId`（若來自 item done 消耗）

Home 顯示可以是：

```text
快變糟
- 替換濾水網：已到處理日
- 濾水網：剩 2 個
- 洗髮精：預計剩 3 天
```

MVP 可保留 item sections，並新增 Resource section；presentation model 應朝 `AttentionTarget` 聚合收斂。

### 8.3 StageTracker UI

StageTracker 的使用者名稱是「階段追蹤」。它有自己的主入口，也可以在 Pack 頁面中顯示屬於該 Pack 的 StageTracker。

主入口 Route 建議：

```text
name: stage-trackers
path: /feature/stage-trackers
```

詳情 Route 建議：

```text
name: stage-tracker-detail
path: /stage-tracker/:id
```

完整時間表 Route 建議：

```text
name: stage-tracker-schedule
path: /stage-tracker/:id/schedule
```

歷史 Route 建議：

```text
name: stage-tracker-history
path: /stage-tracker/:id/history
```

#### StageTracker list

StageTracker 列表分為：

```text
進行中
已完成追蹤
```

不顯示 archived StageTracker。

卡片顯示：

- title
- pack title 或「全局」
- subjectName-aware progress，例如「小米已經 5 個月 20 天」
- 下一個階段，例如「下一個階段：10 天後滿 6 個月」

#### Create StageTracker

建立流程採用「極簡建立 + 建立後引導補設定」。

建立時填：

- 名稱
- 對象名稱，可留空
- 從哪一天開始追蹤
- 所屬 Pack / 全局

建立後進入 detail dashboard，顯示引導：

- 加入重複階段
- 新增重要階段

MVP 不做生日 / 紀念日快捷模板。

#### StageTracker detail dashboard

詳情頁是進度儀表板，不是日記牆。

顯示：

- 目前進度，由 presentation layer 自動自然語言格式化，不要求使用者選 displayUnit
- 下一個階段
- 接下來 3 個階段
- 「查看更多」入口
- 歷史入口
- 加入重複階段 / 新增重要階段入口

主頁不顯示過去階段。

接下來列表規則：

- 預設顯示 3 個
- 同一條重複階段規則只顯示最近一期
- 日期排序；同一天時重要階段優先，重複階段在後

#### Full schedule

完整時間表只顯示未來階段。

規則：

- 顯示所有 upcoming 重要階段
- 顯示所有 upcoming 重複階段 occurrence
- 同一條重複規則可以出現多期
- 不顯示過去階段

#### History

歷史頁顯示已過去階段，最近在最上面。

歷史項目顯示：

- 標題
- 日期
- 來源：重複階段 / 重要階段
- 備註（若有）
- 相關提醒摘要（若有）

相關提醒摘要計算：

- done 計入完成數
- archived item 忽略
- paused item 另外顯示
- skipped item 另外顯示

例如：

```text
相關提醒：1 / 2 已完成，1 個已暫停，1 個已跳過
```

#### Home attention

StageTracker 階段只有進入提醒窗口時才出現在 Home。

Home card 操作只支援：

```text
知道了
```

語意：

- 收起這次 Home 提示
- 不代表完成
- 不代表略過
- 不代表刪除
- 不支援延後提醒

按「知道了」後，若是 generated occurrence 且尚無 record，建立 `StageRecord(status = acknowledged)`。

#### Ignore occurrence

使用者可以對 generated occurrence 執行「忽略這次」。

效果：

- Home 不顯示
- StageTracker 主頁不顯示
- 歷史頁不顯示
- 下一期 occurrence 仍照常產生

若該 occurrence 已有 note 或 related items，必須先提示確認。

忽略後資料保留：

- note 保留
- related item 關聯保留
- related items 不受影響

MVP 只提供 snackbar undo，不做已隱藏管理頁。

## 9. Templates / Demo

Built-in template 若需要 resource 行為，必須建立：

1. `Resource`
2. 需要時建立 `Item`
3. 需要時建立 `ResourceConsumptionRule`

Built-in template 若需要階段追蹤行為，必須建立：

1. `StageTracker`
2. 需要時建立 `StageRule`
3. 需要時建立 manual `StageRecord`
4. 需要時建立 related `Item`
5. 需要時建立 `StageRelatedItem`

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

```text
Pack: 寶寶

StageTracker:
  title: 寶寶成長
  subjectName: 小米
  trackingStartDate: birth date
  trackingEndDate: null
  status: active

StageRule:
  type: every_n_months
  intervalValue: 1
  intervalUnit: months
  labelTemplate: 小米滿 {n} 個月
  reminderOffsetDays: 7

Manual StageRecord:
  label: 副食品階段
  occurrenceDate: birth date + 6 months
  relativeAmount: 6
  relativeUnit: months
  note: 可以先和醫生確認，準備餐具與高腳椅
  reminderOffsetDays: 14
```

## 10. StageTracker Domain

StageTracker 維持 rule-driven occurrence 模型，但擴充 manual important stages、Home acknowledge / ignore、notes、related Item 關聯與追蹤範圍。

### 10.1 StageTracker

`StageTracker` 代表一條從某天開始追蹤的階段線。

```ts
StageTracker {
  id: number
  packId?: number
  title: string
  subjectName?: string
  trackingStartDate: DateTime
  trackingEndDate?: DateTime
  status: "active" | "archived"
  createdAt: DateTime
  updatedAt: DateTime
}
```

語意：

- UI 名稱是「階段追蹤」
- `packId == null` 代表全局 StageTracker
- `subjectName` 用於讓 UI 顯示更自然，例如「小米已經 5 個月 20 天」
- `trackingStartDate` 在 UI 顯示為「從哪一天開始追蹤」
- `trackingEndDate` 在 UI 顯示為「追蹤範圍」中的「追蹤到指定日期」
- 不要求使用者設定 display unit；目前進度由 presentation layer 自動格式化
- 到達 `trackingEndDate` 後不自動 archived，而是在列表顯示「已完成追蹤」
- archived StageTracker 不出現在 Home、主列表、Pack 頁面或一般搜尋
- MVP 不支援刪除整條 StageTracker，只支援 archived
- MVP 暫不提供 archived StageTracker 管理 UI

### 10.2 StageRule

`StageRule` 是重複階段規則。

```ts
StageRule {
  id: number
  stageTrackerId: number
  type: "every_n_days" | "every_n_weeks" | "every_n_months" | "every_n_years"
  intervalValue: number
  intervalUnit: "days" | "weeks" | "months" | "years"
  labelTemplate?: string
  reminderOffsetDays?: number
  status: "active" | "paused" | "archived"
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- UI 名稱是「重複階段」
- occurrence 是計算結果，不是預生成資料
- 一條 StageTracker 可以有多條 StageRule
- `intervalValue` 必須大於 `0`
- `labelTemplate` 可選；預設使用系統文案，例如「滿 1 個月」、「第 1 週」
- `reminderOffsetDays` 可覆蓋 StageTracker default reminder；若為 null，使用 StageTracker / app default
- paused rule 不產生 Home attention，但保留設定
- archived rule 不出現在 active rule list
- 同一天多個 rule occurrence 不自動合併；使用者可忽略不需要的單次 occurrence

### 10.3 StageOccurrence

`StageOccurrence` 是由 StageTracker + StageRule + StageRecord 計算出的 presentation/domain read model，不是資料表。

```ts
StageOccurrence {
  stageTrackerId: number
  stageRuleId?: number
  stageRecordId?: number
  sourceType: "generated" | "manual"
  occurrenceIndex?: number
  occurrenceDate: DateTime
  label: string
  note?: string
  reminderOffsetDays: number
  recordStatus?: "normal" | "acknowledged" | "ignored" | "archived"
  relatedItemSummary?: StageRelatedItemSummary
}
```

規則：

- generated occurrence 由 active StageRule 計算
- manual occurrence 由 manual StageRecord 取得
- generated occurrence 若沒有互動，不需要 StageRecord
- generated occurrence 若被 acknowledged / ignored / note edited / related item created，必須建立 StageRecord
- ignored occurrence 不進 Home、主頁、完整時間表或歷史頁
- archived manual stage 不出現在一般歷史頁
- Home attention 條件：active StageTracker、未 ignored、未 acknowledged、進入 reminder window、未過期或在合理顯示窗口內

### 10.4 StageRecord

`StageRecord` 記錄 manual important stage，或 generated occurrence 的使用者互動。

```ts
StageRecord {
  id: number
  stageTrackerId: number
  stageRuleId?: number
  sourceType: "generated" | "manual"
  occurrenceIndex?: number
  occurrenceDate: DateTime
  relativeAmount?: number
  relativeUnit?: "days" | "weeks" | "months" | "years"
  status: "normal" | "acknowledged" | "ignored" | "archived"
  label: string
  note?: string
  reminderOffsetDays?: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

語意：

- UI 上 manual StageRecord 叫「重要階段」
- manual stage 一建立就寫入 StageRecord
- generated occurrence 只有互動時才建立 StageRecord
- `status = normal`：有 record，但沒有 acknowledged / ignored / archived
- `status = acknowledged`：使用者按過「知道了」，Home 不再顯示這次提示
- `status = ignored`：使用者忽略這次 stage，Home / StageTracker 主頁 / 完整時間表 / 歷史頁都不顯示
- `status = archived`：已過去 manual stage 被封存；未來 manual stage 可直接刪除
- note 與 related item 不作為 status
- 若已有 note 或 related items，忽略前必須提示使用者確認

### 10.5 StageRelatedItem

`StageRelatedItem` 連接 StageRecord 與 Item。

```ts
StageRelatedItem {
  id: number
  stageRecordId: number
  itemId: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- 一個 StageRecord 可以有多個 related items
- Item 詳情可顯示「來自：{StageTracker.title} · {StageRecord.label}」
- Stage detail / history 可顯示 related item summary
- related item 狀態不回寫 StageRecord status
- ignored StageRecord 不影響 related item
- archived Item 不納入 related item summary
- skipped Item 不計入完成數，但另外顯示
- paused Item 不計入分母，但另外顯示

```ts
StageRelatedItemSummary {
  doneCount: number
  activeCount: number
  pausedCount: number
  skippedCount: number
}
```

顯示範例：

```text
相關提醒：1 / 2 已完成，1 個已暫停，1 個已跳過
```

### 10.6 StageTracker 與 Home Attention

StageTracker stage 可以進入 Home attention，但仍是獨立 domain。

Home card 文案範例：

```text
寶寶成長：3 天後滿 6 個月
```

或 manual important stage：

```text
寶寶成長：副食品階段快到了
```

Home action：

```text
知道了
```

規則：

- 「知道了」只收起本次 Home 提示
- 「知道了」不代表完成、不代表 skip、不代表 snooze
- MVP 不支援 snooze
- 按「知道了」後，若無 StageRecord，建立 `StageRecord(status = acknowledged)`；若已有 StageRecord，更新 status 為 acknowledged，除非 status 是 ignored / archived

## 11. 命名規則

必須使用：

- `ItemPack`
- `Item`
- `ItemActionRecord`
- `Resource`
- `ResourceConfig`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `StageTracker`
- `StageRule`
- `StageOccurrence`
- `StageRecord`
- `StageRelatedItem`

禁止重新引入：

- `ItemType.resourceBased`
- `ResourceBasedItemConfig`
- `ResourceBaseItem`

命名原則：

- 程式碼命名維持英文、清楚、domain-driven
- UI 文案使用繁體中文與生活語意
- Resource domain 一律優先使用 `Resource`，不要使用 `ResourceBaseItem`
- StageTracker domain 在 UI 上使用「階段追蹤」
- StageRule 在 UI 上使用「重複階段」
- Manual StageRecord 在 UI 上使用「重要階段」
- 不在 UI 顯示 raw `StageTracker / StageRule / StageOccurrence / StageRecord` 命名
