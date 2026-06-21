---
This is the single source of truth for reminders core model, MVP scope, naming, and behavior.
Last aligned with repository contents on 2026-06-14.
---

# Reminder App Unified Core Spec

本文件是 `reminders` feature 的核心規格。實作、測試、UI 文案與後續修訂若和舊文件或舊命名衝突，一律以本文件為準。

主要語言使用繁體中文；程式模型、enum、table、route、repository API 保留英文技術命名。

## Supabase Remote Model

Supabase remote data model, RLS policy draft, Phase 3A boundary, Phase 3B anonymous identity bridge, Phase 3C Remote Shared Pack Minimal POC, Phase 3D developer smoke-test surface, and Phase 4A remote invite-code membership MVP are documented in:

- `docs/core/06_supabase_remote_model_spec.md`

## 1. 總覽

### 1.1 產品北極星

> 讓重要的事，不會在無意識中變糟。

Reminder App 關注四種使用者容易忽略的狀態：

- 責任是否正在變糟。
- 固定週期的責任是否已接近或超過本輪處理時間。
- 資源是否即將不足或已不足。
- 一段時間中的重要階段是否已進入提醒窗口。

### 1.2 核心模型邊界

一句話版本：

> `Item` 是要做的事；`Resource` 是要留意的資源；`StageTracker` 是從某一天開始追蹤，提醒將到來的重要階段。`Item` action 可以消耗 `Resource`，但 `Resource` 不是 `ItemType`；`StageTracker` 可以引導建立 `Item`，但 `StageTracker` 本身不是 `Item`。

| 概念 | 責任 |
| --- | --- |
| `ItemPack` | 使用者視角的生活場景 |
| `PackTemplate` | 可快速建立生活場景與預設事項的範本 |
| `Item` | 責任、行為、需要被完成的事 |
| `Resource` | 可被消耗、可補充、可提醒的資源 |
| `StageTracker` | 時間推進中的階段追蹤 |
| `ItemActionRecord` | 使用者對責任的操作紀錄 |
| `ResourceActionRecord` | 資源庫存或可用性變化紀錄 |
| `StageRecord` | 手動重要階段，或 generated occurrence 的使用者互動紀錄 |
| `ItemStatus` | `Item` attention status 的推導結果 |
| `ResourceStatus` | `Resource` 可用性 status 的推導結果 |

Domain 必須保持分離。Home 可以在 presentation layer 聚合 `Item`、`Resource` 與 `StageOccurrence`，但不可把三者合併成同一個 domain object。

### 1.3 已實作模型清單

- `ItemPack`
- `PackTemplate`
- `PackTemplateItem`
- `Item`
- `ItemConfig`
- `FixedItemConfig`
- `StateBasedItemConfig`
- `ItemActionRecord`
- `AttentionPolicy`
- `AppSettings`
- `Resource`
- `ResourceConfig`
- `TimeBasedResourceConfig`
- `QuantityBasedResourceConfig`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `StageTracker`
- `StageRule`
- `StageOccurrence`
- `StageRecord`
- `StageRelatedItem`
- `LocalUser`
- `PackMember`
- `ItemCompletion`
- `ResourceEvent`
- `StageAcknowledgement`
- `ActivityEvent`
- `SyncMapping`

### 1.4 已實作 enum 清單

- `ItemType { fixed, stateBased }`
- `ItemStatus { normal, warning, danger, unknown }`
- `ItemLifecycleStatus { active, paused, archived }`
- `FixedScheduleType { daily, weekly, oneTime, everyXDays, everyXWeeks, monthly }`
- `ItemOverduePolicy { autoAdvance, waitForAction }`
- `ItemNextCycleStrategy { keepSchedule, shiftByDelay }`
- `ItemActionType { created, done, skipped, deferred, reverted }`
- `AttentionPolicySource { systemDefault, userCustomized }`
- `ReminderTone { gentle, standard, early, urgent }`
- `UsageSpeed { low, medium, high }`
- `ResourceType { timeBased, quantityBased }`
- `ResourceLifecycleStatus { active, paused, archived }`
- `ResourceStatus { normal, warning, danger, unknown }`
- `ResourceActionType { created, consumed, refilled, adjusted, reverted }`
- `StageTrackerStatus { active, archived }`
- `StageRuleType { everyNDays, everyNWeeks, everyNMonths, everyNYears }`
- `StageIntervalUnit { days, weeks, months, years }`
- `StageRuleStatus { active, paused, archived }`
- `StageRecordSourceType { generated, manual }`
- `StageRecordStatus { normal, acknowledged, ignored, archived }`
- `ItemPackType { personal, shared }`
- `PackMemberRole { host, member }`
- `PackMemberStatus { active, removed }`
- `ResourceEventChangeType { adjust, increment, decrement }`
- `SyncMappingState { linked, pushed, failed }`

## 2. 已實作模型

### 2.1 ItemPack Domain

#### 產品語意

`ItemPack` 是使用者看到的「生活場景」。它不是純資料夾，也不是強制的 domain 關聯圖。

`Item`、`Resource`、`StageTracker` 都歸屬於一個 `ItemPack`。Pack 代表使用者願意放在同一個生活脈絡中理解與管理的內容，例如「養貓」、「家務」、「健康」、「寶寶」。

system default pack 顯示為「一般」，代表使用者尚未指定生活場景時的預設歸屬位置，不代表具體生活場景。

#### 已實作資料模型

```ts
ItemPack {
  id: number
  title: string
  description?: string
  iconEmoji: string
  orderIndex: number
  status: "active" | "archived"
  isSystemDefault: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

`ItemPackInput`：

```ts
ItemPackInput {
  title: string
  description?: string
  iconEmoji: string // default "🏷️"
}
```

system default pack 常數：

- title：`一般`
- iconEmoji：`📌`
- orderIndex：`0`
- description：`System default pack`

#### 已實作行為

- `item_packs` 由 Drift 管理，`AppDatabase.beforeOpen` 會確保 system default pack 存在。
- system default pack 必須維持 active、名稱「一般」、icon `📌`、`orderIndex = 0`。
- system default pack 不可封存。
- `Item`、`Resource`、`StageTracker` 建立時若沒有提供 `packId`，repository 會寫入 system default pack。
- 建立流程的 pack picker 會把未指定 / system default 顯示為「之後決定」，避免同時出現「一般」與未決定選項；編輯 / 唯讀脈絡則把 system default pack 顯示為「一般」。這是 UI display mapping，不改變 `packId` 或 repository 預設歸屬。
- 自訂 Pack 可新增、編輯名稱、編輯 emoji、調整排序、封存。
- Pack 排序由 `orderIndex` 控制；DAO 排序會把 system default pack 固定在前，再依自訂 Pack 的 `orderIndex`、`createdAt` 穩定排序。
- Pack 管理頁使用「生活場景管理」文案，支援「上」「下」排序，不支援 drag and drop。
- 封存自訂 Pack 時，已實作兩種 repository 行為：
  - `archivePackWithContents`：Pack 封存，底下 active / paused `Item` 與 `Resource` 封存，底下 active `StageTracker` 封存。
  - `archivePackAndMoveContentsToDefault`：Pack 封存，底下內容移到 system default pack，內容原 lifecycle status 保持不變。
- 封存 Pack 不刪除 action records、stage records 或 related item links。

#### 範例

```text
Pack: 養貓 🐱
Item: 清貓砂
Resource: 貓砂
StageTracker: 小米成長
```

這三個 object 同屬「養貓」生活場景，但彼此不必存在直接行為關聯。

#### MVP 待完成

- Item / Resource / StageTracker 建立後的跨 Pack 搬移入口未提供。

### 2.2 PackTemplate Domain

#### 產品語意

`PackTemplate` 是可重用的生活場景範本，用來快速建立一個 `ItemPack` 與一組預設 `Item`。

Pack Template 分為兩種來源：

- `defaultTemplate`：app 內建，例如「家務」、「個人護理」、「養貓」。
- `custom`：使用者只能從既有 active Pack 儲存而成。

#### 已實作資料模型

```ts
PackTemplate {
  id: string
  source: "defaultTemplate" | "custom"
  templateName: string
  iconEmoji: string
  description?: string
  items: PackTemplateItem[]
}
```

```ts
PackTemplateItem {
  title: string
  type: ItemType
  config: ItemConfig
  attentionPolicySource: "systemDefault" | "userCustomized"
}
```

自訂 template 由 Drift `pack_templates` 與 `pack_template_items` 儲存。預設 template 由 Dart code 定義，不 seed 進資料庫。

#### 已實作行為

- Pack 管理頁提供「從模版建立生活場景」入口。
- 新增 Pack dialog 提供「從模版建立」入口；Item / Resource / StageTracker inline 新增 Pack 流程仍只做空白建立。
- Template Picker 分為「預設模版」與「自訂模版」，列表顯示 emoji、template name 與 item count。
- 使用 template 前必須進入 preview detail；第一版不支援勾選、修改 item title 或修改 schedule。
- 使用 template 建立 Pack 時，Pack title 固定為 `{templateName}(模版)`，不自動加數字或「副本」。
- 若已存在同名 active Pack，preview 會提示，建立前可再次確認；仍允許建立同名 Pack。
- 使用 template 建立 Pack + Items 會在 repository transaction 中完成。
- template-created Items 不寫入 `ItemActionRecord(created)`，不建立 resource binding、resource action history、stage tracker 或 done records。
- 自訂 template 只能從已有 Pack 儲存，且只保存 active Items。
- 自訂 template 保存 Pack title / icon / description，以及 Item title / type / schedule config。
- 自訂 template 不保存 resource binding、resource consumption、resources、action history、done records、stage trackers 或 archived item history。

#### 範例

```text
Template: 養貓
Created Pack: 養貓(模版)
Created Items: 清貓砂、補貓糧、洗水碗、清潔貓窩、剪指甲、驅蟲
```

#### MVP 待完成

- 建立後「查看」只導向 Item 管理頁；尚未支援自動定位或展開新建立 Pack。

### 2.3 Item Domain

#### 產品語意

`Item` 是要做的事。它承載責任設定、生命週期，以及 attention status 推導所需資料。

`Item` 的 lifecycle status 和 attention status 是兩件事：

- lifecycle status：使用者是否仍管理此責任，使用 `active / paused / archived`。
- attention status：此責任目前是否需要注意，使用 `normal / warning / danger / unknown`，由 `ItemStatusService` 推導。

#### 已實作資料模型

```ts
Item {
  id: number
  packId: number
  title: string
  description?: string
  type: ItemType
  config: ItemConfig
  attentionPolicySource: "systemDefault" | "userCustomized"
  status: "active" | "paused" | "archived"
  lastDoneAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

```dart
enum ItemType {
  fixed,
  stateBased,
}
```

`FixedItemConfig`：

```ts
FixedItemConfig {
  scheduleType: "daily" | "weekly" | "oneTime" | "everyXDays" | "everyXWeeks" | "monthly"
  scheduleInterval: number
  monthlyDay?: number
  repeatRuleV2?: RepeatRuleV2
  anchorDate?: DateTime
  dueDate?: DateTime
  timeOfDay?: string
  overduePolicy: "autoAdvance" | "waitForAction"
  infoBefore: Duration
  warningBefore: Duration
  dangerBefore: Duration
}
```

`StateBasedItemConfig`：

```ts
StateBasedItemConfig {
  anchorDate?: DateTime
  infoAfter: Duration
  warningAfter: Duration
  dangerAfter: Duration
}
```

#### 已實作行為

- `fixed` 代表有明確日曆週期或 due date 的責任，例如繳費、回診、固定清潔、為某個階段做準備。
- `stateBased` 代表狀態會隨時間變差的責任，例如清貓砂、換濾水網、整理冰箱。
- `ItemRepository.createItem` 會建立 `Item`，並寫入 `ItemActionRecord(created)`。
- `createItemWithOptionalNewPack` 支援在建立 Item 時同步建立新 Pack。
- `updateItem` 不允許改變既有 Item 的 `type`。
- `updateItem` 支援 edit form 的 pending resource binding：在同一個 transaction 更新 Item、建立尚未落庫的新 Resource、寫入 consumption rules；pending Resource 預設跟隨 Item 最終 `packId`。
- `moveItemToPack(itemId, targetPackId, moveLinkedResources)` 在 transaction 內更新 Item `packId`，刪除該 Item 的 `stage_related_items` links；若 `moveLinkedResources == true`，enabled consumption rules 指向的 linked Resources 會一起搬到 target Pack，否則保留 Resource Pack 並將該 Item 的 consumption rules 設為 disabled。
- `markDone` 透過 `ItemActionService` 和 `ItemSnapshotUpdateService` 產生 action 並更新 snapshot。
- `skip` 會寫入 skipped action，並依 `ItemNextCycleStrategy` 處理 fixed cycle。
- `defer` API 存在，但目前固定回傳 `false`，不寫入歷史。
- `stateBased` 使用 `config.anchorDate` 作為主要狀態基準；完成時更新 `stateAnchorDate`，`lastDoneAt` 不作為 state-based 主要基準。
- `fixed` 使用 `anchorDate / dueDate / repeatRuleV2 / overduePolicy` 推導本輪週期。
- fixed item 的 create / edit UI 不直接顯示或輸入 `anchorDate`；使用者只選擇「完成方式」。
- fixed 完成方式為「到期當日完成」時，系統儲存 `anchorDate = dueDate`。
- fixed 完成方式為「可提前一段時間完成」時，使用者輸入「到期前 N 天開始」，且 N 必須為正整數；系統儲存 `anchorDate = dueDate - N days`。
- fixed edit 由既有 `anchorDate / dueDate` 還原完成方式：相同日期為「到期當日完成」，`anchorDate < dueDate` 為「可提前一段時間完成」，`anchorDate > dueDate` 必須阻止儲存直到使用者修正。
- fixed item 儲存前必須檢查檔期不重疊；規則為本輪 `currentDueDate < nextAnchorDate`，其中 `nextAnchorDate` 必須由現有重複規則推算出的下一輪 due date 再扣回本輪 lead days，不可用固定日數粗略判斷 monthly / yearly。
- fixed 檔期重疊時阻止 create / update，錯誤文案為「可處理時間太長，會和下一次提醒重疊。請縮短可處理期，或調整重複規則。」
- `ItemOverduePolicy.autoAdvance` 可在 read model 推導時虛擬前進到目前週期。
- `ItemOverduePolicy.waitForAction` 過期後維持待處理，並回傳 danger。
- active items 進入 Home warning / danger 查詢；paused / archived items 不進入 Home attention query。

#### 範例

```text
Item: 替換濾水網
type: stateBased
anchorDate: 2026-05-01
warningAfter: 12 days
dangerAfter: 14 days
```

```text
Item: 繳電費
type: fixed
scheduleType: monthly
monthlyDay: 15
dueDate: 2026-05-15
overduePolicy: waitForAction
warningBefore: 3 days
dangerBefore: 1 day
```

#### MVP 待完成

- `ItemNextCycleStrategy.shiftByDelay` 已存在於 domain API，但 UI 主要流程尚未完整暴露為使用者可選策略。
- `deferred` action type 只保留相容性，不建立新的 deferred record。Status: Compatibility-only.

### 2.4 ItemActionRecord Domain

#### 產品語意

`ItemActionRecord` 是使用者對責任的歷史紀錄，不是 attention status 的唯一來源。

#### 已實作資料模型

```ts
ItemActionRecord {
  id: number
  itemId: number
  actionType: "created" | "done" | "skipped" | "deferred" | "reverted"
  actionDate: DateTime
  remark?: string
  payload?: Json
  isReverted: boolean
  revertedAt?: DateTime
  revertedByActionRecordId?: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- `payload` 使用 JSON encode / decode，空 payload 存為 `null`。
- 建立、完成、略過都會形成 history。
- 新增的 done record 會在 payload 寫入 `undoSnapshot`，保存完成前 item snapshot，供精準 undo 使用。
- undo done 不刪除原 done record；原 done 會標記 `isReverted = true`，並新增 `ItemActionRecord(reverted)` 指向被撤銷的 done record。
- Item history 以 `ItemActionRecord` 為核心資料來源；一般 UI read model 會把 done 與後續 reverted 合併為同一筆使用者可讀紀錄，避免把完成與回復拆成會計分錄。
- Item history 的 resource impact 可從相關 `ResourceActionRecord.sourceItemActionRecordId` 推導；完成造成的 consumed record 顯示為扣除資源，回復造成的 reverted compensation record 顯示為已補回資源。
- Fixed item history 在一般 UI 顯示 action date；不顯示 preview date、cycle preview 或虛擬週期資訊。
- 缺少 `undoSnapshot` 的既有舊 done record 不提供精準 undo。
- item 操作寫入 record 後，仍需要同步更新 item snapshot 欄位。
- `ItemActivityPage` 以 `ItemActionRecord` 顯示近期活動，支援搜尋與載入更多。

#### 範例

```text
done: 使用者在 2026-05-15 完成「清貓砂」。
skipped: 使用者本輪不處理「整理冰箱」。
```

#### MVP 待完成

- `deferred` 不在目前 MVP 建立流程中使用。Status: Compatibility-only.

### 2.5 Resource Domain

#### 產品語意

`Resource` 是要留意的資源，不是要完成的責任。

`Resource` 可以獨立管理，也可以透過 `ResourceConsumptionRule` 被 `ItemActionRecord(done)` 消耗。UI 可以把資源顯示在 Item 編輯頁的「消耗資源」區塊，但 domain 仍保持分離。

#### 已實作資料模型

```ts
Resource {
  id: number
  packId: number
  title: string
  description?: string
  type: ResourceType
  config: ResourceConfig
  status: "active" | "paused" | "archived"
  lastRefilledAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

```dart
enum ResourceType {
  timeBased,
  quantityBased,
}
```

`TimeBasedResourceConfig`：

```ts
TimeBasedResourceConfig {
  anchorDate?: DateTime
  durationDays: number
  infoBeforeDays: number
  warningBeforeDays: number
  dangerBeforeDays: number
}
```

`QuantityBasedResourceConfig`：

```ts
QuantityBasedResourceConfig {
  currentQuantity: number
  unitLabel: string
  infoThreshold?: number
  warningThreshold: number
  dangerThreshold: number
}
```

#### 已實作行為

- `ResourceRepository.createResource` 會建立 `Resource`，並寫入 `ResourceActionRecord(created)`。
- `updateResource` 不允許改變既有 Resource 的 `type`。
- `archiveResource` 只更新 lifecycle status，不刪除 action history 或 consumption rules。
- time-based resource 使用 `anchorDate + durationDays - 1` 推導 depletion date。
- quantity-based resource 使用 `currentQuantity` 與 warning / danger thresholds 推導狀態。
- Resource edit 可調整名稱、備註、Pack、單位與提醒 thresholds，但不應直接修改目前數量或剩餘可用天數；資源數量 / 可用天數變動應透過 `refillResource` 或 `adjustResourceQuantity` 寫入 `ResourceActionRecord`。
- `moveResourceToPack(resourceId, targetPackId)` 在 transaction 內更新 Resource `packId`，並將使用該 Resource 的 Item consumption rules 設為 disabled；不搬移 Item。
- `ResourceStatusService` 對異常或不足資料回傳 `unknown`。
- `watchResources` 只回傳 active resources；`watchManagedResources` 回傳 active / paused resources。
- Home danger / warning attention sections 會依 `ResourceStatus` 混合顯示 active Resource 與 Item，並可套用 Pack filter。
- Resource 已納入 `AttentionSummaryRepository` 與 `HomeAttentionSource` 的統一 attention summary 計數。
- Resource 管理頁支援新增、編輯、補充、quantity 調整、詳細資訊、歷史紀錄、刪除；底層仍是 soft archive，不硬刪資料。
- Resource history route 已實作：`/resource/:id/history`，route name 是 `resource-history`。

#### 範例

```text
Resource: 濾水網
type: quantityBased
currentQuantity: 5
unitLabel: 個
warningThreshold: 2
dangerThreshold: 1
```

```text
Resource: 洗髮精
type: timeBased
anchorDate: 2026-05-01
durationDays: 20
warningBeforeDays: 3
dangerBeforeDays: 1
```

### 2.6 ResourceConsumptionRule Domain

#### 產品語意

`ResourceConsumptionRule` 連接「完成某個 Item」與「扣除某個 Resource」。

#### 已實作資料模型

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

#### 已實作行為

- 目前 trigger 固定使用 `ItemActionType.done`。
- 目前只支援消耗 quantity-based resource。
- `consumeAmount < 1` 時 repository 會存為 `1`。
- disabled rule 不會套用。
- 建立 Item 時可帶入 `ItemResourceBindingInput.existing`，綁定同 Pack 的 active quantity-based resource。
- 建立 Item 時可帶入 `ItemResourceBindingInput.newResource`，同 transaction 建立 quantity-based resource 並插入 consumption rule。
- 若 resource binding 失敗，create item transaction 會 rollback，不留下 partial item / resource / rule。
- `markDone` 會在同一個 transaction 內更新 item snapshot、寫入 item done record、套用 enabled rules、扣除 quantity resource、寫入 `ResourceActionRecord(consumed)`。
- archived resource 不會被 `markDone` 扣量。

#### 範例

```text
Item: 替換濾水網
Resource: 濾水網
Rule: done 時 consume 1 個
```

### 2.7 ResourceActionRecord Domain

#### 產品語意

`ResourceActionRecord` 記錄資源庫存或可用性變化。

#### 已實作資料模型

```ts
ResourceActionRecord {
  id: number
  resourceId: number
  actionType: "created" | "consumed" | "refilled" | "adjusted" | "reverted"
  actionDate: DateTime
  amount?: number
  resultingQuantity?: number
  addedDays?: number
  resultingDurationDays?: number
  sourceItemActionRecordId?: number
  remark?: string
  isReverted: boolean
  revertedAt?: DateTime
  revertedByActionRecordId?: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- quantity consumption / refill / adjustment 記錄 `amount` 或 `resultingQuantity`。
- time-based refill 記錄 `addedDays` 與 `resultingDurationDays`。
- 由 item done 觸發的 consumed record 會設定 `sourceItemActionRecordId`。
- undo item done 若曾消耗 quantity resource，原 consumed record 會標記 `isReverted = true`，並新增 `ResourceActionRecord(reverted)` 作為補回紀錄。
- Resource history 預設排除 `isReverted = true` 與 `actionType = reverted` 的一扣一補噪音；需要除錯時 repository 可要求包含 reverted records。
- `refillResource`：
  - time-based resource 要求 `addedDays > 0`。
  - quantity-based resource 要求 `addedQuantity > 0`。
  - quantity-based refill 代表增加目前數量，並寫入 refilled action record。
  - time-based refill 代表新增可用天數；既有 repository 會 carry over 尚未耗盡的剩餘天數，不直接把剩餘天數修正為輸入值。
- `adjustResourceQuantity`：
  - 只支援 quantity-based resource。
  - quantity-based adjustment 代表直接修正目前數量，並寫入 adjusted action record。
  - `newQuantity` 經 `ResourceRefillService.adjustQuantity` 處理，負數 clamp 到 `0`。

#### 範例

```text
refilled: 補充洗髮精 20 天，resultingDurationDays = 20
consumed: 完成「替換濾水網」後扣除 1 個濾水網，resultingQuantity = 4
adjusted: 使用者手動把濾水網庫存修正為 3 個
```

#### MVP 待完成

- Resource history 已有頁面，但 `sourceItemActionRecordId` 目前主要透過格式化文字呈現，尚未提供跳回來源 Item action 的互動入口。

### 2.8 StageTracker Domain

#### 產品語意

`StageTracker` 是一條從某天開始追蹤的階段線。UI 名稱是「階段追蹤」。

它用來看見時間推進中的重要節點，例如寶寶成長、交往紀念、搬家後保養、復健進度。它不代表一件要完成的事，也不以 done / skipped 作為主要狀態。

#### 已實作資料模型

```ts
StageTracker {
  id: number
  packId: number
  title: string
  subjectName?: string
  trackingStartDate: DateTime
  trackingEndDate?: DateTime
  status: "active" | "archived"
  isSystemDefault: boolean
  systemKey?: string
  isHidden: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- `StageTracker` 必須歸屬於一個 Pack。
- 建立時未指定 `packId` 會寫入 system default pack。
- `trackingStartDate` 在 UI 顯示為「從哪一天開始追蹤」。
- `trackingEndDate == null` 代表持續追蹤。
- 一般 StageTracker 可編輯 title、subjectName、pack、trackingStartDate、trackingEndDate。
- `moveStageTrackerToPack(trackerId, targetPackId, moveRelatedItems, moveRelatedResources)` 在 transaction 內更新 StageTracker `packId`。相關 Item 來自 `stage_related_items`；選擇搬移時會同步更新 Item `packId`，不搬移時會刪除該 tracker 底下的 `stage_related_items` links。相關 Resource 來自 related Items 的 enabled consumption rules；選擇搬移時會同步更新 Resource `packId`，跨 Pack 關聯未一起搬移時會將對應 consumption rules 設為 disabled。
- trackingStartDate / trackingEndDate 屬於進階設定；修改後會影響累積天數與階段推算，但不會重寫既有 StageRecord。
- 到達 `trackingEndDate` 後不自動 archive，而是由 presentation 分到「已完成追蹤」。
- 一般 StageTracker 可封存；封存後不出現在一般管理列表，既有 StageRule、StageRecord 與 related item links 保留。
- App 會建立一個 system default StageTracker：title `Reminder App`、subjectName `系統`、systemKey `reminder_app`。
- system default StageTracker 的 `trackingStartDate` 使用首次建立日期，後續 ensure 不重置。
- system default StageTracker 不可 edit / archive / delete，也不可新增或修改底下階段；唯一使用者操作是 hide / show。
- system default StageTracker hidden 後不出現在 StageTracker overview，但資料不刪除、不封存，可在 Settings 恢復顯示。
- active trackers 出現在 StageTracker 管理頁；archived trackers 不出現在一般 watch query。
- StageTracker 管理 route 已實作：`/feature/stage-trackers`，route name 是 `stage-trackers`。
- StageTracker detail route 已實作：`/stage-tracker/:id`，route name 是 `stage-tracker-detail`。
- StageTracker complete timeline route 已實作：`/stage-tracker/:id/timeline`，route name 是 `stage-tracker-timeline`。
- StageTracker full schedule route 已實作：`/stage-tracker/:id/schedule`，route name 是 `stage-tracker-schedule`。
- StageTracker history route 已實作：`/stage-tracker/:id/history`，route name 是 `stage-tracker-history`。
- 建立 StageTracker 後進入 detail dashboard。
- detail dashboard 顯示第 N 天、最近 / 待確認階段、即將到來、重複階段列表、加入階段、完整時間線入口。
- StageTracker display day count 以 `trackingStartDate` 當天為「第1天」起算，後一天為「第2天」；早於 start date 的 preview date 最小顯示「第1天」，不顯示 `0天`。

#### 範例

```text
StageTracker:
  title: 寶寶成長
  subjectName: 小米
  trackingStartDate: 2026-05-01
  trackingEndDate: null
```

UI 可顯示：

```text
第173天
下一個階段：10 天後滿 6 個月
```

### 2.9 StageRule Domain

#### 產品語意

`StageRule` 是 StageTracker 底下的「重複階段」規則。Rule 是設定，occurrence 是計算結果。

#### 已實作資料模型

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

#### 已實作行為

- `createStageRule` 只允許建立在存在且未 archived 的 StageTracker 底下。
- `createStageRule` 只建立 StageRule；StageRule 是 generated occurrence 的推算規則，不是具體 StageRecord。
- `intervalValue <= 0` 會丟出 `ArgumentError`。
- active rule 會產生 generated occurrences。
- paused rule 不產生 occurrence。
- archived rule 不出現在 detail 的 visible rule list。
- StageRule 可編輯 type、intervalValue、intervalUnit、labelTemplate、reminderOffsetDays。
- StageRule 可暫停、恢復、封存；封存是 status 更新，不硬刪 rule。
- StageRule detail row 可展開查看該 rule 的下一輪 occurrence 與 related reminder count。
- StageRule 只支援針對「下一輪 occurrence」建立 related reminder；不支援每輪自動建立提醒模板，也不把 Item 直接綁到 StageRule。
- `labelTemplate` 支援 `{n}`、`{value}`、`{unit}`。
- `reminderOffsetDays == null` 時 fallback 到 `StageOccurrenceService.defaultReminderOffsetDays`，目前值是 `0`。

#### 範例

```text
StageRule:
  type: every_n_months
  intervalValue: 1
  intervalUnit: months
  labelTemplate: 小米滿 {value}{unit}
  reminderOffsetDays: 7
```

### 2.10 StageOccurrence Domain

#### 產品語意

`StageOccurrence` 是由 `StageTracker + StageRule + StageRecord` 合成的 read model，不是資料表。

generated occurrence 平常由 rule 動態計算；manual occurrence 來自 `StageRecord(sourceType = manual)`。

#### 已實作資料模型

```ts
StageOccurrence {
  stageTrackerTitle?: string
  subjectName?: string
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

#### 已實作行為

- `StageOccurrenceService` 動態計算 upcoming、schedule、history、Home attention occurrences。
- dashboard upcoming 預設取未來 366 天內 manual stages，加上每條 active rule 的下一次 occurrence，排序後由 repository 取前 3 筆。
- StageTracker detail 的 upcoming occurrence row 可展開查看 compact related reminders；complete timeline 不做 inline expansion。
- schedule 只顯示未來 occurrence。
- history 只顯示過去 occurrence，日期由新到舊排序。
- ignored / archived records 不出現在一般 occurrence lists。
- acknowledged occurrence 保留在 schedule，但不進 Home attention。
- Home attention 條件：
  - StageTracker active。
  - occurrence 未 ignored、未 archived、未 acknowledged。
  - current date 已到 `occurrenceDate - reminderOffsetDays`。
- 同一天排序時 manual occurrence 優先於 generated occurrence。

#### 範例

```text
寶寶成長：3 天後滿 6 個月
寶寶成長：副食品階段快到了
```

#### MVP 待完成

- Home attention occurrence 已支援「知道了」；「忽略這次」的 UI 入口、確認流程與 undo 尚未完成。

### 2.11 StageRecord Domain

#### 產品語意

`StageRecord` 記錄 manual important stage，或 generated occurrence 的使用者互動。UI 上 manual StageRecord 稱為「重要階段」。

#### 已實作資料模型

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

#### 已實作行為

- manual important stage 一建立就寫入 `StageRecord(sourceType = manual, status = normal)`。
- manual important stage 可建立在過去日期，用於補記已經歷階段。
- generated occurrence 只有被 acknowledged、ignored、建立 related item 等互動時才建立 `StageRecord`。
- 建立 recurring StageRule 後不立即 materialize future occurrence；只有 related reminder、acknowledged、ignored 或其他需要保存互動狀態時才寫入 generated StageRecord。
- generated record 以 `stageRuleId + occurrenceIndex` 作 unique key。
- `acknowledgeOccurrence` 會 upsert generated record 並設為 `acknowledged`。
- `ignoreOccurrence` 會 upsert generated record 並設為 `ignored`。
- `deleteOrArchiveImportantStage`：
  - 未來 manual stage 會刪除。
  - 已過去 manual stage 會改為 archived。
- manual important stage 可編輯 label、occurrenceDate、note、reminderOffsetDays。
- manual important stage UI 使用「刪除」文案；repository 現行語意仍是未來 stage 可硬刪、過去 stage 改為 archived。
- recurring generated occurrence 不可透過 manual important stage 編輯流程修改。
- note 不作為 status。

#### 範例

```text
Manual StageRecord:
  label: 副食品階段
  occurrenceDate: 2026-11-01
  relativeAmount: 6
  relativeUnit: months
  note: 可以先和醫生確認，準備餐具與高腳椅
  reminderOffsetDays: 14
```

### 2.12 StageRelatedItem Domain

#### 產品語意

`StageRelatedItem` 連接 `StageRecord` 與 `Item`。它表示某個階段引導使用者建立了一件相關提醒。

#### 已實作資料模型

```ts
StageRelatedItem {
  id: number
  stageRecordId: number
  itemId: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

```ts
StageRelatedItemSummary {
  doneCount: number
  activeCount: number
  pausedCount: number
  skippedCount: number
}
```

#### 已實作行為

- 一個 StageRecord 可以關聯多個 Items。
- 從 generated occurrence 建立 related item 時，repository 會先建立 StageRecord，再建立 Item，再建立 StageRelatedItem。
- Recurring rule 建立「下一輪提醒」時，UI 先推導下一輪 StageOccurrence，再走相同的 generated occurrence materialization 流程；舊提醒固定屬於當次 StageRecord，不會隨下一輪推進而轉移。
- 建立 related item 時，Item type 固定為 `fixed`，`scheduleType = oneTime`，`overduePolicy = waitForAction`。
- Item due date 預設等於 stage occurrence date；使用者可在 dialog 輸入其他 due date。
- related item 的完成、略過、暫停、封存不回寫 StageRecord status。
- related item summary：
  - archived item 不納入 summary。
  - done 計入 `doneCount`。
  - paused 計入 `pausedCount`。
  - skipped 計入 `skippedCount`。

#### 範例

```text
StageRecord: 副食品階段
Related Item: 準備副食品餐具
```

顯示摘要：

```text
相關提醒：1 / 2 已完成，1 個已暫停，1 個已跳過
```

### 2.13 AttentionPolicy 與 AppSettings

#### 已實作資料模型

```ts
AttentionPolicy {
  warningAfterDays?: number
  dangerAfterDays?: number
  warningBeforeDays?: number
  dangerBeforeDays?: number
  source: "systemDefault" | "userCustomized"
}
```

```ts
AppSettings {
  reminderTone: "gentle" | "standard" | "early" | "urgent"
  notificationReminderTime: "HH:mm"
  updatedAt: DateTime
}
```

Drift table `app_settings` 另有固定 `id = 1`、`createdAt`、`updatedAt`。

#### 已實作行為

- `AttentionPolicyResolver` 可根據 `ReminderTone` 推導 fixed、flexible、stock 類型的提醒門檻。
- `AppDatabase.beforeOpen` 會確保 `app_settings` 有 `id = 1` 的 row。
- 設定頁 route 已實作：`/feature/settings`，route name 是 `settings`。
- 設定頁一般設定暴露 `reminderTone` 與 notification reminder time；system StageTracker 顯示開關仍保留底層設定 / repository 行為，但不出現在一般 UAT UI。
- 設定頁資料管理提供 JSON backup / import / reset。Backup payload 使用 `app = reminder_app`、`schemaVersion = 4`、`exportedAt` ISO-8601 與 `data` keys：`packs/items/resources/stages/stageTrackers/customTemplates/relations/activityLogs`。
- Backup 包含 user-created Pack、Item、Resource、user-created StageTracker、StageRule、StageRecord、StageRelatedItem、ResourceConsumptionRule、自訂 PackTemplate、ItemActionRecord 與 ResourceActionRecord；不包含 system StageTracker、debug-only setting、temporary UI state 或 app settings。
- Import 採 replace all user data，不做 merge；匯入前檢查 `app` 與 `schemaVersion`，失敗時不改動現有資料。匯入時 system default Pack 會以目前資料庫 seed 重建 / 保留，backup 中指向舊 system default Pack 的 `packId` 會 remap 到目前 system default Pack。
- Reset database 會清空 user data，並保留或重建 system default Pack、`app_settings` 與 system default StageTracker。
- Notification reminder time 預設為 `09:00`，更新後會透過既有 daily attention notification sync 使用新時間。
- `Preview date` 是 developer-only setting，用於測試不同日期下的提醒狀態，不出現在一般設定。

#### 範例

```text
ReminderTone.standard: 使用較平衡的 warning / danger 門檻。
ReminderTone.early: 較早提醒使用者。
```

### 2.14 Shared Pack Phase 1 Domain

#### 產品語意

Shared Pack Phase 1 是本機多人協作語意模擬，不是正式 online sync、登入、邀請或 realtime collaboration。

Shared Pack 的核心原則是：優先讓狀態變更透明、可追溯，而不是用嚴格 task ownership 限制誰可以完成事情。

#### 已實作資料模型

```ts
LocalUser {
  id: string
  displayName: string
  avatarUrl?: string
  identityKind: "local" | "anonymous_remote" | "linked" | "placeholder" | "removed"
  remoteUserId?: string
  remoteProvider?: "supabase_anonymous" | "apple" | "google" | "email"
  isPrimary: boolean
  createdAt: DateTime
  updatedAt: DateTime
  linkedAt?: DateTime
  lastSeenAt?: DateTime
  deletedAt?: DateTime
}
```

```ts
PackMember {
  packId: number
  userId: string
  role: "host" | "member"
  status: "active" | "removed"
  joinedAt: DateTime
}
```

```ts
ItemCompletion {
  id: number
  itemId: number
  packId: number
  itemActionRecordId: number
  completedByUserId: string
  completedAt: DateTime
  undoneByUserId?: string
  undoneAt?: DateTime
  clientMutationId?: string
  createdAt: DateTime
}
```

```ts
ResourceEvent {
  id: number
  resourceId: number
  packId: number
  actorUserId: string
  changeType: "adjust" | "increment" | "decrement"
  previousValue?: number
  newValue?: number
  deltaValue?: number
  unit?: string
  createdAt: DateTime
  metadataJson?: string
}
```

```ts
StageAcknowledgement {
  id: number
  stageRecordId: number
  packId: number
  userId: string
  acknowledgedAt: DateTime
}
```

```ts
ActivityEvent {
  id: number
  packId: number
  actorUserId: string
  entityType: string
  entityId: number
  action: string
  beforeJson?: string
  afterJson?: string
  metadataJson?: string
  createdAt: DateTime
}
```

#### 已實作行為

- App 會保留兩個 local debug users：`user_host / Host` 與 `user_member_1 / Member`，供 Shared Pack 本機模擬與舊資料相容。
- Phase 2 後，App UI repository path 未指定 actor 時會透過 current local identity 取得 actor；未注入 identity resolver 的 repository test/debug path 仍 fallback `user_host`。
- `ItemPack` 透過 `packType` 區分 `personal / shared`。
- Personal Pack 可以轉為 Shared Pack；轉換後會設定 `hostUserId`，建立 active host `PackMember`，並寫入 `ActivityEvent(pack_converted_to_shared)`。
- Shared Pack 不可轉回 Personal Pack。
- Shared Pack 可加入 local/debug member，並寫入 `ActivityEvent(member_added)`。
- Phase 1 不提供完整 member management UI；Host / member 支援先在本機資料模型與 repository 中驗證。
- `assignedToUserId` 只是提示性質，代表預期負責人，不限制完成權限。
- Shared Pack 的狀態變更 action 必須由 active pack member 執行；Personal Pack 維持既有單人模式，repository 未指定 actor 時預設 `user_host`。
- 任一 active pack member 都可以完成 item，也可以 undo 其他 member 的 completion；`assignedToUserId` 不限制誰能完成。
- Item completion 會寫入 `ItemActionRecord(done)`，並同步寫入 `ItemCompletion(completedByUserId, completedAt)`。
- Undo 不刪除原 completion，不覆寫 `completedByUserId`；undo 會寫入 `ItemActionRecord(reverted)`，並在 `ItemCompletion` 記錄 `undoneByUserId / undoneAt`。
- Shared Pack item completion 採 first-write-wins：同一 item 已有未 undone active completion 時，後續 completion attempt 是 no-op，即使 action date 不同也不覆寫 current `completedByUserId`；undo 後才可再次完成並建立新的 factual completion event。
- Resource 不使用 take task / completed_by 語意；quantity resource 的 adjust / increment / decrement 會寫入 `ResourceEvent` 與 `ActivityEvent`。
- `ResourceEventChangeType.increment / decrement` 是可合併的 delta operation；`adjust` 是 absolute adjustment，未來 sync 時需要 base version 檢查。
- Stage 不使用 complete / completed_by 作為核心語意。
- Stage acknowledge 是 member-specific record；同一 member 重複 acknowledge 同一 stage 會更新 `acknowledgedAt`，不影響其他 member。
- Shared Pack 重要事件會寫入 `ActivityEvent`，包含 pack converted、member added、item created、item assigned、item completed、item undone、resource adjusted / incremented / decremented、stage acknowledged。

#### Phase 1.5 驗收規則

- Shared Pack 的 completion / undo / assignment / resource adjust / resource delta / stage acknowledge 若 actor 不是 active pack member，必須 no-op，不應產生 action record、resource event、stage acknowledgement 或 activity event。
- Shared Pack duplicate completion 不以日期為唯一判斷；只要 item 仍有未 undone `ItemCompletion`，later attempt 必須保留第一筆 `completedByUserId`。
- 舊 backup schema v1 若缺少 Shared Pack metadata，import 時應補成 Personal Pack 預設值，不應讓舊個人資料因缺 shared metadata 而失敗。
- Home widget 與既有 Personal Pack flow 不改語意；未帶 actor 的既有 repository call 繼續使用 `user_host`。

#### 範例

```text
Host 將「養貓」轉為 Shared Pack，加入 Member。
Host 指派「補貓砂」給 Member。
Member 完成「補貓砂」，completion 記錄 completedByUserId = user_member_1。
Host 復原該 completion，原 completion 保留，並記錄 undoneByUserId = user_host。
```

### 2.15 Phase 2：Device Identity & Account Binding Foundation

#### 產品語意

Reminder App 使用漸進式身份模型，不在首次使用時強制登入。面向使用者的未登入狀態稱為「此裝置資料」，不使用 Local Mode、Guest Mode 或 Anonymous Mode。

文案語意：

```text
你的資料目前只保存在此裝置。
之後可綁定 Apple / Google / Email，以避免資料遺失。
```

身份階梯：

```text
Level 0：此裝置資料
- 本機 app_user_id / GUID
- 不需要登入
- 可使用 personal pack、本機提醒、widget、backup
- 可保留 Phase 1 local shared pack simulation

Level 1：匿名遠端身份
- 未來使用 Supabase anonymous auth
- 使用者仍不需要輸入 Apple / Google / Email
- server 可識別 user
- 用於正式 shared pack / online pack membership

Level 2：綁定保護
- 未來可綁定 Apple / Google / Email
- 目的為避免換機 / 刪 app / 遺失資料
- 不是一開始的強制登入入口

Level 3：完整帳號
- 多裝置同步
- 找回資料
- 管理帳號 / 刪除帳號
```

Phase 2 只實作 Level 0 的穩定本機身份，以及 Level 1 / 2 / 3 的資料欄位與 interface 預留；不接 Supabase network。

#### 已實作資料模型

```ts
AppInstallation {
  id: number
  installationGuid: string
  createdAt: DateTime
  lastSeenAt: DateTime
}
```

`LocalUser` 直接沿用 `local_users` table，不另建 `app_users`。`remoteUserId` 未來對應 Supabase Auth user id；`remoteProvider` 預留 `supabase_anonymous / apple / google / email`。

Phase 2 暫不建立 `auth_identity_links` table；目前 single remote link 存在 `local_users.remoteUserId / remoteProvider / linkedAt`，未來多 provider link 可拆表。

#### 已實作行為

- `IdentityRepository.ensureLocalIdentity()` 會確保 app installation identity 存在，並回傳目前 primary local user。
- 若沒有 primary local user，會建立一個 GUID local user，`identityKind = local`，`displayName = 此裝置資料`。
- 重複呼叫 `ensureLocalIdentity()` 不會建立第二個 primary user。
- 既有 Phase 1 / 1.5 資料升級時，`user_host` 保留為 legacy primary local user，不重寫歷史 actor / member id。
- 登入 / 綁定採 link model：local app user id 穩定存在，`remoteUserId` nullable，`linkedAt` nullable。
- `linkRemoteIdentity(remoteUserId, provider)` 不改變 local user id；provider 為 `supabase_anonymous` 時 `identityKind = anonymous_remote`，provider 為 `apple / google / email` 時 `identityKind = linked`。
- `FakeAuthRepository` 提供 provider-agnostic fake auth adapter；`signInAnonymously()` 回傳 `fake_supabase_user_<guid>`，Apple / Google / Email fake link 只回傳本機 fake remote identity。
- Phase 2 不加入 `supabase_flutter`，不呼叫 Supabase Auth，不建立 remote database，不儲存 access token、refresh token、OAuth credential 或 Apple / Google credential。
- Shared Pack membership 仍使用 local app user id；remote user id 不會取代 `pack_members.userId`、`completedByUserId`、`actorUserId` 或 stage acknowledgement user id。
- Personal Pack 在「此裝置資料」狀態下可正常使用，不需要 shared membership。
- Settings developer debug 區只顯示 read-only「此裝置資料」資訊，不提供正式登入 UI。

#### Backup / Restore

- Backup 可包含 local app user id、display name、identity kind、nullable remote reference、app installation id、pack member relation 與 activity history。
- Backup 不包含 Supabase token、refresh token、OAuth credential、Apple / Google credential。
- v1 / v2 舊 backup 若缺 identity fields，import 會補 `identityKind = local`、`remoteUserId = null`、`remoteProvider = null`，並確保 default local identity 與 app installation 可用。
- restored shared pack 在正式 online sync 前視為 local restored shared data，不驗證 remote membership。

#### 長線語意預留

- 正式 online Shared Pack 將需要 Supabase-recognized identity，但不一定需要 Apple / Google / Email；可先使用 anonymous remote identity。
- 被移除 member 不應刪除 user row；可使用 `identityKind = removed` 或 `PackMember.status = removed` 保留歷史 actor。
- 未來 remote shared pack 若遇到本機未認識 user，可建立 `identityKind = placeholder`，之後補 display name / avatar / remote user id。
- 刪除帳號後 shared pack history 不應被破壞；activity event 可保留 actor display name snapshot，UI 可顯示「已移除成員」或匿名化名稱。

### 2.16 Phase 3B：Supabase Anonymous Auth Identity POC

Phase 3B adds Supabase anonymous remote identity link. It does not implement remote shared pack sync.

#### 已實作行為

- App 使用 `SUPABASE_URL` 與 `SUPABASE_ANON_KEY` dart-define 讀取 Supabase config，不 hardcode project URL 或 anon key。
- 若 Supabase config 缺少或初始化失敗，app 仍可正常啟動；Personal Pack、本機提醒、widget、backup 不依賴 Supabase。
- `SupabaseAuthRepository` 只使用 Supabase Auth anonymous sign-in，不建立 remote profile、remote pack、remote item，不呼叫 Supabase database CRUD。
- `ensureAnonymousRemoteIdentity()` 會先確保 local identity，再建立 / 取得 Supabase anonymous user，並透過 `IdentityRepository.linkRemoteIdentity` 寫入 `remoteUserId`、`remoteProvider = supabase_anonymous`、`identityKind = anonymous_remote`、`linkedAt`。
- 若 local user 已是 `supabase_anonymous + anonymous_remote`，重複呼叫會回傳 already linked，不重複建立 remote identity。
- Link remote identity 不改 local user id，不改 `pack_members.userId`、`activity_events.actorUserId`、`item_completions.completedByUserId` 或任何 local history actor id。
- Settings developer debug 區提供 Supabase config status、remote provider、remote user id 與「建立匿名遠端身份」測試入口；這不是正式 login / onboarding UI。
- `signOut` 不刪 local user、不刪 personal pack、不清除 local history。Anonymous users 若未綁定 Apple / Google / Email，sign out 後可能無法找回同一 remote identity。

#### Backup / Restore

- Backup 可保留 remote identity reference：`remoteUserId`、`remoteProvider`、`identityKind`、`linkedAt`。
- Backup 不包含 access token、refresh token、OAuth credential、Supabase session JSON、service role key 或 secret key。
- Restore 後 `remoteUserId` 只是 reference，不代表目前裝置已恢復 Supabase authenticated session；online access 需要之後重新驗證 / 綁定。

#### 非目標

- 不建立 remote pack。
- 不 push / pull pack snapshot。
- 不實作 sync、realtime、invite、RLS remote tests。
- 不實作 Apple / Google / Email binding、magic link、OTP 或 email login。
- 不 apply `docs/core/sql/phase3a_supabase_schema_draft.sql`。

### 2.17 Phase 3C：Supabase Remote Shared Pack Minimal POC

Phase 3C adds the first explicit developer-triggered remote Shared Pack loop. It is a minimal POC, not full sync.

#### 已實作資料模型

```ts
SyncMapping {
  id: number
  localEntityType: string
  localEntityId: number
  remoteTable: string
  remoteEntityId: string
  syncState: "linked" | "pushed" | "failed"
  lastPushedAt?: DateTime
  lastPulledAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

`sync_mappings` 是本機 sync layer mapping，不是 Supabase remote table。Phase 3C 只使用：

```text
pack -> packs
item -> items
```

Profile mapping 不使用 `sync_mappings`，因為 `local_users.remoteUserId` 已保存 Supabase Auth user id reference。

#### 已實作行為

- `RemoteSharedPackRepository.ensureRemoteProfile()` 會先確保 anonymous remote identity，再呼叫 remote RPC `upsert_current_profile`；它不建立 pack、不自動上傳資料。
- `createRemoteSharedPackFromLocalPack(localPackId)` 只接受 local Shared Pack，且 current local user 必須是該 pack active member；成功後建立 `sync_mappings(pack -> packs)`。
- 已有 pack mapping 時，重複建立 remote pack 會回傳 already linked，不建立 duplicate remote pack。
- `pushMinimalItems(localPackId)` 只推送指定 mapped shared pack 的 unmapped active / paused items，並建立 `sync_mappings(item -> items)`。
- Phase 3C 不推送 Personal Pack、Resources、Stages 或 local completion history。
- `completeRemoteItemForLocalItem(localItemId)` 只呼叫 remote RPC `complete_pack_item`；remote `already_completed` 不覆寫本機 `completedByUserId`，也不自動 merge 回 local completion history。
- `pullRemotePackSnapshot(remotePackId)` 只解析 remote DTO snapshot，不寫入 local DB，不建立 local items。
- Missing Supabase config 會回傳 typed failure；Personal Pack、本機 Shared Pack、widget 與 backup flow 不依賴 Supabase configured。
- Production remote data source 使用 Supabase RPC / query；tests 使用 fake data source，不依賴真 Supabase project。

#### SQL / RLS

- Phase 3C SQL draft 位於 `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
- SQL draft 只包含 `profiles / packs / pack_members / items / item_completions / activity_events`，並定義 RLS、`is_pack_member`、`is_pack_host` 與 Phase 3C RPC。
- SQL draft 需手動在 Supabase SQL editor 或 local Supabase CLI apply；app 不會自動 apply SQL，不會使用 service role key。

#### Backup / Restore

- Backup schema v4 可包含 `syncMapping` relation，作為 remote reference。
- Restore 後 `sync_mappings` 不代表目前裝置已有 remote access，也不觸發 automatic pull / push。
- Backup 不包含 Supabase access token、refresh token、session JSON、OAuth credential、service role key 或 secret key。

#### 非目標

- 不做 full two-way sync、realtime、invite、resource remote sync、stage remote sync、background sync、conflict resolution engine 或正式同步 UI。
- 不在 app startup 自動建立 remote pack，不自動上傳所有 Personal Pack 或 Shared Pack。
- 不修改 iOS / Android home widget 行為。

### 2.18 Phase 3D：Developer Remote POC Action Surface

Phase 3D adds a developer-only remote POC action surface for manual Supabase smoke testing.

#### 已實作行為

- Settings developer debug 區提供 `Supabase 遠端 POC` 區塊，只在 developer/debug visibility enabled 時顯示。
- POC target 使用第一個 active local Shared Pack；沒有 Shared Pack 時顯示提示，不 crash。
- Debug UI 顯示 Supabase config status、local / remote identity 摘要、selected Shared Pack、remote pack mapping、first mapped remote item、last operation result 與 remote snapshot summary。
- 每個 remote POC operation 都必須由使用者手動按下，不在 app startup 自動執行。
- Manual actions 包含 anonymous remote identity、remote profile、remote shared pack、minimal item push、remote item complete、remote snapshot pull。
- Remote snapshot 只顯示 DTO summary，不 merge 回 local DB。
- Remote item completion 不自動修改 local `ItemCompletion` 或 `completedByUserId`。

#### 非目標

- 不新增正式 sync UI、invite、realtime、resource / stage remote sync、background sync、automatic upload 或 conflict resolution engine。
- 不修改 Drift schema、backup schema、home widget 行為或 visual tokens。

### 2.19 Phase 4A：Remote Invite Code & Membership MVP

Phase 4A adds developer-only remote invite-code membership for the Remote Shared Pack POC.

#### 已實作行為

- Host 可在 Settings developer debug 的 `Supabase 遠端 POC` 區塊手動建立 Invite Code POC。
- Invite code 是 temporary bearer secret，只保存在 volatile UI state；local DB、backup、activity event 不保存完整 invite code。
- 第二個 anonymous remote user 可輸入 invite code，加入 remote shared pack 並成為 `member / active`。
- Join 後可用 joined remote pack id 拉取 remote snapshot，且可完成 snapshot 第一個 remote item。
- Join 不建立 local pack、local item、`sync_mappings`，也不 merge remote snapshot。

#### 非目標

- 不新增 full sync、realtime、正式 invite UI、remote pack list、local merge、automatic upload、resource / stage remote sync 或 widget 行為變更。
- 不修改 Drift schema 或 backup schema。

## 3. 跨 Domain 行為

### 3.1 完成 Item 並消耗 Resource

`ItemRepository.markDone` 套用 resource consumption rules 時，同一個 transaction 內包含：

1. 計算 item done action。
   - Shared Pack 會先檢查 actor 是否為 active pack member。
   - Shared Pack 若已有 active `ItemCompletion`，本次 completion 是 no-op。
2. 更新 item snapshot。
3. 插入 `ItemActionRecord(done)`。
4. 插入 `ItemCompletion(completedByUserId, completedAt)`，保留 factual completion actor。
5. 寫入 `ActivityEvent(item_completed)`。
6. 查詢 matching enabled `ResourceConsumptionRule`。
7. 僅對 active quantity-based resource 扣量。
8. quantity clamp 到 `0`。
9. 插入 `ResourceActionRecord(consumed)`，並寫入 `sourceItemActionRecordId`。
10. 寫入對應 `ResourceEvent(decrement)`，記錄 actor、previous value、new value、delta value、unit、time。
11. 新 done record payload 寫入完成前 `undoSnapshot`，供「恢復成未完成」精準還原。

Matching rule 條件：

- `rule.itemId == item.id`
- `rule.isEnabled == true`
- `rule.triggerActionType == done`
- resource active
- resource config 是 `QuantityBasedResourceConfig`

### 3.1.1 Undo Item Done

`ItemRepository.undoDone` 是「按錯完成」的撤銷 / 抵銷流程，不是刪除歷史。

同一個 transaction 內包含：

1. 驗證輸入 record 存在、類型為 `done`、尚未 reverted，且 payload 有 `undoSnapshot`。
2. Shared Pack 會檢查 actor 是否為 active pack member。
3. 插入 `ItemActionRecord(reverted)`，payload 記錄 `reason = undo_done` 與被撤銷的 done record id。
4. 將原 done record 標記 `isReverted = true`，寫入 `revertedAt` 與 `revertedByActionRecordId`。
5. 更新原 `ItemCompletion` 的 `undoneByUserId / undoneAt`；不得刪除或覆寫 `completedByUserId`。
6. 依 `undoSnapshot` 還原 item fixed / state snapshot 欄位。
7. 查詢原 done 產生的 `ResourceActionRecord(consumed)`，不重新計算 consumption rule。
8. 逐筆將 quantity resource 補回原 consumed amount，標記原 consumed record reverted，新增 `ResourceActionRecord(reverted)`，並寫入對應 `ResourceEvent(increment)`。
9. 寫入 `ActivityEvent(item_undone)`。

disabled consumption rule 不影響 undo；archived resource 仍可被補回，因為這是撤銷歷史錯誤，不是新的消耗行為。

### 3.2 建立 Item 與 Resource Binding Draft

Item 建立頁可以先保留 resource binding draft；使用者儲存前不得寫入 DB。

支援兩種 draft：

- 綁定既有同 Pack active quantity-based resource。
- 建立新的 quantity-based resource 並綁定。

送出時同一個 transaction 完成：

1. resolve pack。
2. create item。
3. insert `ItemActionRecord(created)`。
4. 若有 new resource draft，create resource。
5. 若有 new resource draft，insert `ResourceActionRecord(created)`。
6. insert `ResourceConsumptionRule`。

### 3.3 從 StageOccurrence 建立 Related Item

當使用者從某個 stage 建立 related item 時，同一個 transaction 完成：

1. 若來源是 generated occurrence 且尚無 StageRecord，建立 `StageRecord(status = normal)`。
2. create fixed one-time item。
3. insert `ItemActionRecord(created)`。
4. insert `StageRelatedItem(stageRecordId, itemId)`。

建立出的 Item：

- `type = fixed`
- `scheduleType = oneTime`
- `anchorDate = dueDate`
- `dueDate` 預設為 stage occurrence date
- `overduePolicy = waitForAction`

### 3.4 封存 Pack

system default pack 不可封存。

自訂 Pack 封存時 UI 提供：

- 一起封存內容。
- 移到「一般」。
- 取消。

「一起封存內容」會封存 Pack、active / paused Items、active / paused Resources、active StageTrackers。

「移到一般」會封存 Pack，並把 Items、Resources、StageTrackers 的 `packId` 改成 system default pack id，原 lifecycle status 不變。

## 4. UI 心智模型

### 4.1 使用者語言

```text
Item = 要做的事
Resource = 要留意的資源
StageTracker = 階段追蹤
StageRule = 重複階段
Manual StageRecord = 重要階段
Pack = 生活場景
```

UI 不顯示 raw domain class 名稱，不把 enum name 當使用者文案。

### 4.2 Home

Home route：`/`，route name：`home`。

Home 已實作：

- attention summary card。
- attention summary card 的日期 badge 顯示目前生效日期，格式為 `yyyy/MM/dd`；developer preview date 啟用時跟隨覆蓋日期。
- attention summary 的 `dangerCount` / `warningCount` 包含 Item 與 Resource；主文案使用「今天有 X 項需要留意」。
- Pack filter。
- danger attention section：混合顯示 danger Item 與 danger Resource。
- warning attention section：混合顯示 warning Item 與 warning Resource。
- upcoming stage section。
- StageTracker 本身不進入 danger / warning；StageOccurrence 保留在 upcoming stage section。
- Stage Home card 的「知道了」 action。
- Home 最下方有「今天已完成」section，依 preview date 顯示當天有效 `ItemActionRecord(done)`、`ResourceActionRecord(refilled / adjusted)`，以及當天 acknowledged 的 `StageRecord`。
- 「今天已完成」預設收合；Item done entry 若有 `undoSnapshot` 可用 undo icon 恢復成未完成，undo 後該 entry 從 section 移除。
- Today completed section 跟隨 Pack filter：Item 依 item pack、Resource 依 resource pack、Stage 依 tracker pack。

Pack filter：

- 顯示「全部」與所有 active Pack。
- 包含 system default pack「一般」。
- 「全部」選取時顯示剔號。
- 未選取 Pack chip 只顯示 emoji。
- 選取 Pack chip 顯示 emoji 與 Pack title，不顯示剔號，hover / pressed 時不顯示陰影。
- Pack chip 以固定 label layout 顯示 emoji，避免選取狀態切換時 emoji 位置跳動。
- Pack title 保留於 tooltip / accessibility label。
- 點擊 Pack icon 只篩選 Home 內容，不進入 Pack detail page。

### 4.3 Item 管理與編輯

Item 管理 route：`/manage`，route name：`items-management`。

Item edit routes：

- create：`/item/new`，route name：`item-new`
- edit：`/item/:id`，route name：`item-edit`

已實作 UI：

- Item 建立 / 編輯只提供 `fixed` 與 `stateBased`。
- 建立時可選生活場景；選「之後決定」時寫入 system default pack。編輯 / 唯讀脈絡中的 system default pack 顯示為「一般」。
- 編輯既有 Item 時 Pack 以唯讀顯示。
- locked pack mode 會隱藏 pack field，並把 Item 建在指定 Pack。
- Item 編輯頁有「消耗資源」區塊，可綁定 existing quantity-based resource。
- 建立流程可 inline 新增 Pack。

### 4.4 Resource 管理

Resource 管理 route：`/feature/resources-management`，route name：`resources-management`。

已實作 UI：

- 功能頁與 Item 管理頁都可進入 Resource 管理。
- Resource 管理頁支援新增資源。
- 列表顯示 active / paused resources。
- Resource card 顯示名稱、類型、derived status、數量或預計剩餘天數。
- card 空白處開 detail dialog。
- add icon 執行補充。
- overflow menu 支援調整、編輯、詳細資訊、歷史紀錄、封存。
- `adjust` 只出現在 quantity-based resource。
- Resource edit 不直接修改目前數量 / 可用天數；資源變動需透過補充或調整流程留下 `ResourceActionRecord`。

Resource history route：`/resource/:id/history`，route name：`resource-history`。

Resource history 使用 compact timeline UI：頁首顯示 resource summary，支援 action filter chips 與「顯示已抵銷紀錄」切換。一般狀態預設隱藏 `isReverted = true` 的原紀錄與 `actionType = reverted` 的補償紀錄，但資料仍保留並可在切換後顯示。

Item history route：`/item/:id/history`，route name：`item-history`。

Item history 使用 compact timeline UI：頁首顯示 item summary，支援「全部 / 完成 / 已回復 / 資源影響」filter chips 與日期分組。Item edit AppBar overflow 與 Item management row overflow 都提供「歷史紀錄」入口。

Item history 的 done + reverted 以 read model 合併成「完成，後來已回復」一筆主要 timeline row，並在同一列顯示完成日期、回復日期與 resource impact sub rows。Fixed item history 不顯示 preview date。

### 4.5 StageTracker UI

StageTracker 管理 route：`/feature/stage-trackers`，route name：`stage-trackers`。

已實作 UI：

- bottom navigation 不再有階段追蹤主入口；StageTracker overview 從 More page 的「階段追蹤」入口進入。
- 列表分為「進行中」與「已完成追蹤」。
- 建立流程填入名稱、對象名稱、開始日期、生活場景。
- 建立後進入 detail dashboard。
- detail dashboard 顯示累積時間、最近 / 待確認階段、即將到來階段、重複階段列表。
- detail dashboard 提供 unified `加入階段` dialog，可建立重要階段或重複階段。
- detail AppBar overflow 提供「編輯階段追蹤」、「完整時間線」、「封存追蹤器」。
- destructive action 使用紅字並在執行前顯示 confirmation dialog。
- 重複階段 compact row overflow 提供編輯、暫停 / 恢復、封存。
- complete timeline route 顯示即將到來與已經歷 stages。
- complete timeline 中 manual important stage row overflow 提供新增提醒事項、編輯、封存；generated occurrence 不顯示 manual stage 管理操作。
- schedule / history 舊 route 保留可用，但主要 detail 入口導向 complete timeline。
- StageTracker detail 的 upcoming stage row 可點擊展開 / 收起 related reminders；row 右側仍不顯示 standalone add / eye icon，只保留 manual stage overflow。
- expanded related reminders 使用 compact list，顯示 title 與 due/status，點 row 開啟 Item summary dialog。
- 無 related reminders 時，expanded content 顯示 compact「建立相關提醒」文字 button；已有 related reminders 時仍可建立更多。
- complete timeline 的 stage row 不支援 inline expansion，維持 compact timeline row 與 manual stage overflow。
- overview 在沒有 user-created visible tracker，或只有 system default tracker 時，顯示 dashed add card：`新增追蹤 / 記錄一件正在累積的事`。
- system default tracker 在 detail overflow 顯示「從列表隱藏」，不顯示 edit / archive。

### 4.6 Pack 管理

Pack 管理 route：`/feature/item-packs-management`，route name：`item-packs-management`。

已實作 UI：

- 新增自訂 Pack。
- 從預設 / 自訂模版建立 Pack + Items。
- 從既有 active Pack 儲存自訂模版。
- 編輯自訂 Pack 名稱、description、emoji。
- 系統依 Pack 名稱推薦 emoji，使用者可手動選擇。
- 對自訂 Pack 使用「上」「下」調整排序。
- 封存自訂 Pack。
- system default pack 顯示但不可編輯、不可封存。

## 5. Drift Schema

目前 schema version：`8`。

### 5.0 local_users

```text
id
displayName
avatarUrl
identityKind
remoteUserId
remoteProvider
isPrimary
createdAt
updatedAt
linkedAt
lastSeenAt
deletedAt
```

### 5.0.1 app_installations

```text
id
installationGuid
createdAt
lastSeenAt
```

### 5.1 item_packs

```text
id
title
description
iconEmoji
orderIndex
status
isSystemDefault
packType
hostUserId
createdAt
updatedAt
```

### 5.1.1 pack_members

```text
packId
userId
role
status
joinedAt
```

### 5.2 items

```text
id
packId
title
description
status
type
attentionPolicySource
fixedScheduleType
fixedScheduleInterval
fixedMonthlyDay
fixedRepeatRuleV2
fixedAnchorDate
fixedDueDate
fixedTimeOfDay
fixedOverduePolicy
fixedExpectedBeforeMinutes
fixedWarningBeforeMinutes
fixedDangerBeforeMinutes
stateAnchorDate
stateExpectedAfterMinutes
stateWarningAfterMinutes
stateDangerAfterMinutes
assignedToUserId
lastDoneAt
createdAt
updatedAt
```

### 5.3 item_action_records

```text
id
itemId
actionType
actionDate
remark
payload
isReverted
revertedAt
revertedByActionRecordId
createdAt
updatedAt
```

### 5.3.1 item_completions

```text
id
itemId
packId
itemActionRecordId
completedByUserId
completedAt
undoneByUserId
undoneAt
clientMutationId
createdAt
```

### 5.4 resources

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

### 5.5 resource_consumption_rules

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

### 5.6 resource_action_records

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
isReverted
revertedAt
revertedByActionRecordId
createdAt
updatedAt
```

### 5.6.1 resource_events

```text
id
resourceId
packId
actorUserId
changeType
previousValue
newValue
deltaValue
unit
createdAt
metadataJson
```

### 5.7 stage_trackers

```text
id
packId
title
subjectName
trackingStartDate
trackingEndDate
status
isSystemDefault
systemKey
isHidden
createdAt
updatedAt
```

### 5.8 stage_rules

```text
id
stageTrackerId
type
intervalValue
intervalUnit
labelTemplate
reminderOffsetDays
status
createdAt
updatedAt
```

### 5.9 stage_records

```text
id
stageTrackerId
stageRuleId
sourceType
occurrenceIndex
occurrenceDate
relativeAmount
relativeUnit
status
label
note
reminderOffsetDays
createdAt
updatedAt
```

Unique key：

```text
stageTrackerId + stageRuleId + occurrenceIndex
```

### 5.10 stage_related_items

```text
id
stageRecordId
itemId
createdAt
updatedAt
```

### 5.10.1 stage_acknowledgements

```text
id
stageRecordId
packId
userId
acknowledgedAt
```

Unique key：

```text
stageRecordId + userId
```

### 5.10.2 activity_events

```text
id
packId
actorUserId
entityType
entityId
action
beforeJson
afterJson
metadataJson
createdAt
```

### 5.10.3 sync_mappings

```text
id
localEntityType
localEntityId
remoteTable
remoteEntityId
syncState
lastPushedAt
lastPulledAt
createdAt
updatedAt
```

Unique key：

```text
localEntityType + localEntityId + remoteTable
```

### 5.11 app_settings

```text
id
reminderTone
notificationReminderTime
createdAt
updatedAt
```

### 5.12 pack_templates

```text
id
templateName
iconEmoji
description
createdAt
updatedAt
```

### 5.13 pack_template_items

```text
id
templateId
orderIndex
title
type
attentionPolicySource
fixedScheduleType
fixedScheduleInterval
fixedMonthlyDay
fixedRepeatRuleV2
fixedTimeOfDay
fixedOverduePolicy
fixedExpectedBeforeMinutes
fixedWarningBeforeMinutes
fixedDangerBeforeMinutes
stateExpectedAfterMinutes
stateWarningAfterMinutes
stateDangerAfterMinutes
createdAt
updatedAt
```

## 6. MVP 待完成

本章只列產品已明確要收斂，但目前 repo 尚未完整實作的 MVP 項目。這些項目不可寫入「已實作行為」。

- Stage ignore UI：提供 generated occurrence 的「忽略這次」入口、確認流程與 snackbar undo。
- ResourceConsumptionRule 管理 UI：編輯 consume amount、停用、重新啟用。
- Item related stage source 顯示：在 Item 詳情或摘要中清楚呈現來源 StageTracker / StageRecord。
- archived Pack / StageTracker 的管理入口。

## 7. 非 MVP / 長線方向

本章列暫不納入 MVP 的方向。實作前必須另行更新 core spec。

- Pack detail page。
- 建立後跨 Pack 搬移 Item / Resource / StageTracker。
- 將 Shared Pack 複製成新的 Personal Pack。
- snooze。
- deferred action 恢復。
- time-based resource 由 Item action 自動消耗。
- 生日、紀念日。
- archived StageTracker 的完整瀏覽與還原流程。
- Resource history 跳回來源 Item action。
- 多來源 related item。
- Pack 搜尋與 drag and drop 排序。

## 8. 命名規則

### 8.1 必須使用

- `ItemPack`
- `Item`
- `ItemConfig`
- `FixedItemConfig`
- `StateBasedItemConfig`
- `ItemActionRecord`
- `Resource`
- `ResourceConfig`
- `TimeBasedResourceConfig`
- `QuantityBasedResourceConfig`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `StageTracker`
- `StageRule`
- `StageOccurrence`
- `StageRecord`
- `StageRelatedItem`
- `AttentionPolicy`
- `AppSettings`

### 8.2 禁止重新引入

- 把 Resource 放回 Item type。
- 把 Resource availability config 放回 Item table。
- 把 StageTracker 當成 Item。
- 用完成、略過、延後等 Item action 直接表示 StageTracker 階段狀態。
- 在 UI 顯示 raw domain class name 或 raw enum name。

### 8.3 UI 文案原則

- Pack 使用「生活場景」。
- Item 使用「提醒」、「要做的事」或具體責任名稱。
- Resource 使用「資源」、「庫存」、「可用天數」等生活語言。
- StageTracker 使用「階段追蹤」。
- StageRule 使用「重複階段」。
- manual StageRecord 使用「重要階段」。
- acknowledged 使用「知道了」。
- ignored 使用「忽略這次」。
