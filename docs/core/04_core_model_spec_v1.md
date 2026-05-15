---
This is the single source of truth for reminders core model, MVP scope, naming, and behavior.
Last aligned with repository contents on 2026-05-15.
---

# Reminder App Unified Core Spec

本文件是 `reminders` feature 的核心規格。實作、測試、UI 文案與後續修訂若和舊文件或舊命名衝突，一律以本文件為準。

主要語言使用繁體中文；程式模型、enum、table、route、repository API 保留英文技術命名。

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

### 1.4 已實作 enum 清單

- `ItemType { fixed, stateBased }`
- `ItemStatus { normal, warning, danger, unknown }`
- `ItemLifecycleStatus { active, paused, archived }`
- `FixedScheduleType { daily, weekly, oneTime, everyXDays, everyXWeeks, monthly }`
- `ItemOverduePolicy { autoAdvance, waitForAction }`
- `ItemNextCycleStrategy { keepSchedule, shiftByDelay }`
- `ItemActionType { created, done, skipped, deferred }`
- `AttentionPolicySource { systemDefault, userCustomized }`
- `ReminderTone { gentle, standard, early, urgent }`
- `UsageSpeed { low, medium, high }`
- `ResourceType { timeBased, quantityBased }`
- `ResourceLifecycleStatus { active, paused, archived }`
- `ResourceStatus { normal, warning, danger, unknown }`
- `ResourceActionType { created, consumed, refilled, adjusted }`
- `StageTrackerStatus { active, archived }`
- `StageRuleType { everyNDays, everyNWeeks, everyNMonths, everyNYears }`
- `StageIntervalUnit { days, weeks, months, years }`
- `StageRuleStatus { active, paused, archived }`
- `StageRecordSourceType { generated, manual }`
- `StageRecordStatus { normal, acknowledged, ignored, archived }`

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

- Pack 管理頁目前只顯示 active packs；archived packs 的管理入口未完成。
- Item / Resource / StageTracker 建立後的跨 Pack 搬移入口未提供。

### 2.2 Item Domain

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
- `markDone` 透過 `ItemActionService` 和 `ItemSnapshotUpdateService` 產生 action 並更新 snapshot。
- `skip` 會寫入 skipped action，並依 `ItemNextCycleStrategy` 處理 fixed cycle。
- `defer` API 存在，但目前固定回傳 `false`，不寫入歷史。
- `stateBased` 使用 `config.anchorDate` 作為主要狀態基準；完成時更新 `stateAnchorDate`，`lastDoneAt` 不作為 state-based 主要基準。
- `fixed` 使用 `anchorDate / dueDate / repeatRuleV2 / overduePolicy` 推導本輪週期。
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
- `deferred` action type 只保留相容性，不建立新的 deferred record。

### 2.3 ItemActionRecord Domain

#### 產品語意

`ItemActionRecord` 是使用者對責任的歷史紀錄，不是 attention status 的唯一來源。

#### 已實作資料模型

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

#### 已實作行為

- `payload` 使用 JSON encode / decode，空 payload 存為 `null`。
- 建立、完成、略過都會形成 history。
- item 操作寫入 record 後，仍需要同步更新 item snapshot 欄位。
- `ItemActivityPage` 以 `ItemActionRecord` 顯示近期活動，支援搜尋與載入更多。

#### 範例

```text
done: 使用者在 2026-05-15 完成「清貓砂」。
skipped: 使用者本輪不處理「整理冰箱」。
```

#### MVP 待完成

- `deferred` 不在目前 MVP 建立流程中使用。

### 2.4 Resource Domain

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
- `ResourceStatusService` 對異常或不足資料回傳 `unknown`。
- `watchResources` 只回傳 active resources；`watchManagedResources` 回傳 active / paused resources。
- Home 目前有「資源」section，顯示 active resources，並可套用 Pack filter。
- Resource 管理頁支援新增、編輯、補充、quantity 調整、詳細資訊、歷史紀錄、封存。
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

#### MVP 待完成

- Resource 已在 Home 顯示，但尚未納入 `AttentionSummaryRepository` 與 `HomeAttentionSource` 的統一 attention summary 計數。
- Resource Home section 尚未收斂到單一 Home presentation model。

### 2.5 ResourceConsumptionRule Domain

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

#### MVP 待完成

- UI 尚未提供完整的既有 rule 編輯、停用、重新啟用管理流程。

### 2.6 ResourceActionRecord Domain

#### 產品語意

`ResourceActionRecord` 記錄資源庫存或可用性變化。

#### 已實作資料模型

```ts
ResourceActionRecord {
  id: number
  resourceId: number
  actionType: "created" | "consumed" | "refilled" | "adjusted"
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

#### 已實作行為

- quantity consumption / refill / adjustment 記錄 `amount` 或 `resultingQuantity`。
- time-based refill 記錄 `addedDays` 與 `resultingDurationDays`。
- 由 item done 觸發的 consumed record 會設定 `sourceItemActionRecordId`。
- `refillResource`：
  - time-based resource 要求 `addedDays > 0`。
  - quantity-based resource 要求 `addedQuantity > 0`。
  - time-based refill 會 carry over 尚未耗盡的剩餘天數。
- `adjustResourceQuantity`：
  - 只支援 quantity-based resource。
  - `newQuantity` 經 `ResourceRefillService.adjustQuantity` 處理，負數 clamp 到 `0`。

#### 範例

```text
refilled: 補充洗髮精 20 天，resultingDurationDays = 20
consumed: 完成「替換濾水網」後扣除 1 個濾水網，resultingQuantity = 4
adjusted: 使用者手動把濾水網庫存修正為 3 個
```

#### MVP 待完成

- Resource history 已有頁面，但 `sourceItemActionRecordId` 目前主要透過格式化文字呈現，尚未提供跳回來源 Item action 的互動入口。

### 2.7 StageTracker Domain

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
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- `StageTracker` 必須歸屬於一個 Pack。
- 建立時未指定 `packId` 會寫入 system default pack。
- `trackingStartDate` 在 UI 顯示為「從哪一天開始追蹤」。
- `trackingEndDate == null` 代表持續追蹤。
- 到達 `trackingEndDate` 後不自動 archive，而是由 presentation 分到「已完成追蹤」。
- active trackers 出現在 StageTracker 管理頁；archived trackers 不出現在一般 watch query。
- StageTracker 管理 route 已實作：`/feature/stage-trackers`，route name 是 `stage-trackers`。
- StageTracker detail route 已實作：`/stage-tracker/:id`，route name 是 `stage-tracker-detail`。
- StageTracker full schedule route 已實作：`/stage-tracker/:id/schedule`，route name 是 `stage-tracker-schedule`。
- StageTracker history route 已實作：`/stage-tracker/:id/history`，route name 是 `stage-tracker-history`。
- 建立 StageTracker 後進入 detail dashboard。
- detail dashboard 顯示目前進度、下一個階段、接下來階段、重複階段列表、加入重複階段、新增重要階段、完整時間表、歷史入口。

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
小米已經 5 個月 20 天
下一個階段：10 天後滿 6 個月
```

#### MVP 待完成

- StageTracker 編輯 UI 未完成。
- StageTracker 封存 UI 未完成；repository 已有 `archiveStageTracker`。
- archived StageTracker 管理 UI 未完成。

### 2.8 StageRule Domain

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
- `intervalValue <= 0` 會丟出 `ArgumentError`。
- active rule 會產生 generated occurrences。
- paused rule 不產生 occurrence。
- archived rule 不出現在 detail 的 visible rule list。
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

#### MVP 待完成

- StageRule 編輯 UI 未完成。
- StageRule 暫停、封存 UI 未完成。

### 2.9 StageOccurrence Domain

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

### 2.10 StageRecord Domain

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
- generated occurrence 只有被 acknowledged、ignored、建立 related item 等互動時才建立 `StageRecord`。
- generated record 以 `stageRuleId + occurrenceIndex` 作 unique key。
- `acknowledgeOccurrence` 會 upsert generated record 並設為 `acknowledged`。
- `ignoreOccurrence` 會 upsert generated record 並設為 `ignored`。
- `deleteOrArchiveImportantStage`：
  - 未來 manual stage 會刪除。
  - 已過去 manual stage 會改為 archived。
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

#### MVP 待完成

- important stage 編輯 UI 未完成。
- important stage 刪除 / 封存 UI 未完成；repository 已有 `deleteOrArchiveImportantStage`。

### 2.11 StageRelatedItem Domain

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

#### MVP 待完成

- Item 詳情頁顯示「來自：{StageTracker.title} · {StageRecord.label}」的完整 UI 尚未收斂。

### 2.12 AttentionPolicy 與 AppSettings

#### 產品語意

`AttentionPolicy` 代表系統或使用者設定的提醒門檻。`AppSettings` 保存目前使用者設定。

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
  updatedAt: DateTime
}
```

Drift table `app_settings` 另有固定 `id = 1`、`createdAt`、`updatedAt`。

#### 已實作行為

- `AttentionPolicyResolver` 可根據 `ReminderTone` 推導 fixed、flexible、stock 類型的提醒門檻。
- `AppDatabase.beforeOpen` 會確保 `app_settings` 有 `id = 1` 的 row。
- 設定頁 route 已實作：`/feature/settings`，route name 是 `settings`。
- 設定頁目前只暴露 `reminderTone`。

#### 範例

```text
ReminderTone.standard: 使用較平衡的 warning / danger 門檻。
ReminderTone.early: 較早提醒使用者。
```

#### MVP 待完成

- 使用者自訂單一 Item / Resource attention policy 的完整 UI 尚未收斂。

## 3. 跨 Domain 行為

### 3.1 完成 Item 並消耗 Resource

`ItemRepository.markDone` 套用 resource consumption rules 時，同一個 transaction 內包含：

1. 計算 item done action。
2. 更新 item snapshot。
3. 插入 `ItemActionRecord(done)`。
4. 查詢 matching enabled `ResourceConsumptionRule`。
5. 僅對 active quantity-based resource 扣量。
6. quantity clamp 到 `0`。
7. 插入 `ResourceActionRecord(consumed)`，並寫入 `sourceItemActionRecordId`。

Matching rule 條件：

- `rule.itemId == item.id`
- `rule.isEnabled == true`
- `rule.triggerActionType == done`
- resource active
- resource config 是 `QuantityBasedResourceConfig`

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
- Pack filter。
- Resource section。
- danger item section。
- warning item section。
- upcoming stage section。
- Stage Home card 的「知道了」 action。

Pack filter：

- 顯示「全部」與所有 active Pack。
- 包含 system default pack「一般」。
- chip label 主要顯示 emoji。
- Pack title 保留於 tooltip / accessibility label。
- 點擊 Pack icon 只篩選 Home 內容，不進入 Pack detail page。

### 4.3 Item 管理與編輯

Item 管理 route：`/manage`，route name：`items-management`。

Item edit routes：

- create：`/item/new`，route name：`item-new`
- edit：`/item/:id`，route name：`item-edit`

已實作 UI：

- Item 建立 / 編輯只提供 `fixed` 與 `stateBased`。
- 建立時可選生活場景；選「之後再說」時寫入 system default pack。
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

Resource history route：`/resource/:id/history`，route name：`resource-history`。

### 4.5 StageTracker UI

StageTracker 管理 route：`/feature/stage-trackers`，route name：`stage-trackers`。

已實作 UI：

- bottom navigation 有階段追蹤主入口。
- 列表分為「進行中」與「已完成追蹤」。
- 建立流程填入名稱、對象名稱、開始日期、生活場景。
- 建立後進入 detail dashboard。
- detail dashboard 顯示目前進度、下一個階段、接下來階段、重複階段列表。
- detail dashboard 提供加入重複階段、新增重要階段、查看完整時間表、查看歷史。
- schedule 頁顯示未來 stages。
- history 頁顯示過去 stages。
- stage tile 可建立 related item。

### 4.6 Pack 管理

Pack 管理 route：`/feature/item-packs-management`，route name：`item-packs-management`。

已實作 UI：

- 新增自訂 Pack。
- 編輯自訂 Pack 名稱、description、emoji。
- 系統依 Pack 名稱推薦 emoji，使用者可手動選擇。
- 對自訂 Pack 使用「上」「下」調整排序。
- 封存自訂 Pack。
- system default pack 顯示但不可編輯、不可封存。

## 5. Drift Schema

目前 schema version：`2`。

### 5.1 item_packs

```text
id
title
description
iconEmoji
orderIndex
status
isSystemDefault
createdAt
updatedAt
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
createdAt
updatedAt
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
createdAt
updatedAt
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

### 5.11 app_settings

```text
id
reminderTone
createdAt
updatedAt
```

## 6. MVP 待完成

本章只列產品已明確要收斂，但目前 repo 尚未完整實作的 MVP 項目。這些項目不可寫入「已實作行為」。

- Resource attention summary：把 Resource 納入 `AttentionSummaryRepository` 與 `HomeAttentionSource`，使 badge / summary 計數包含需要注意的資源。
- Home presentation model 收斂：將 Item、Resource、StageOccurrence 的 Home 顯示整合到單一 presentation model；Domain 仍保持分離。
- Stage ignore UI：提供 generated occurrence 的「忽略這次」入口、確認流程與 snackbar undo。
- StageTracker 編輯與封存 UI：接上既有 repository 能力。
- StageRule 編輯、暫停、封存 UI：接上既有 status model。
- important stage 編輯、刪除 / 封存 UI：接上 `deleteOrArchiveImportantStage`。
- ResourceConsumptionRule 管理 UI：編輯 consume amount、停用、重新啟用。
- Item related stage source 顯示：在 Item 詳情或摘要中清楚呈現來源 StageTracker / StageRecord。
- archived Pack / StageTracker 的管理入口。

## 7. 非 MVP / 長線方向

本章列暫不納入 MVP 的方向。實作前必須另行更新 core spec。

- Pack detail page。
- 建立後跨 Pack 搬移 Item / Resource / StageTracker。
- snooze。
- deferred action 恢復。
- time-based resource 由 Item action 自動消耗。
- 生日、紀念日、生活場景模板。
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
