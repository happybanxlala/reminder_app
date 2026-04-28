---
This is the single source of truth for reminders core model, MVP scope, naming, and behavior.
---

# Reminder App Unified Core Spec

本文件是 reminders feature 的唯一實作依據。

後續實作若與舊文件、舊註解、舊命名衝突，一律以本文件為準。

---

## 1. 核心決策

唯一核心模型定為：

- `ItemPack`
- `Item`
- `ItemActionRecord`
- `ItemType`
- `ItemStatus`
- `Timeline`
- `TimelineMilestoneRule`
- `TimelineMilestoneOccurrence`
- `TimelineMilestoneRecord`

此系統不再以 `Task / TaskTemplate / Task instance` 為核心。

一句話版本：

> reminders feature 的核心，是 `Item` 的狀態變化與其 action history，加上 `Timeline` 的 rule-driven milestone records。

核心轉變：

| 舊模型 | 新模型 |
| --- | --- |
| Task 分類 | Item 本質（fixed / state / resource） |
| due-date task queue | 狀態（normal / warning / danger / unknown）驅動 |
| instance history | item snapshot + item action records |
| timeline data pre-generation | rule -> occurrence -> record |

---

## 2. 產品北極星

> 讓重要的事，不會在無意識中變糟。

系統優先關注：

- 哪些責任正在惡化
- 哪些固定節奏的責任已接近或超過當前週期
- 哪些 timeline milestone 已進入提醒窗口

系統不再以「今天有哪些到期 task」作為主要心智模型。

---

## 3. 核心實體

### 3.1 ItemPack

```ts
ItemPack {
  id: string
  title: string
  description?: string
  status: "active" | "archived"
  isSystemDefault: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- item pack 用來組織責任場景，例如：養貓、家務、健康
- system default pack 必須唯一
- system default pack 可見，但不可改名、不可封存
- archived pack 不再接受新 item 歸屬

### 3.2 Item

```ts
Item {
  id: string
  packId: string
  title: string
  description?: string
  type: ItemType
  config: ItemConfig
  status: "active" | "paused" | "archived"
  lastDoneAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- item 屬於一個 pack
- item 的 lifecycle 與 attention status 分離
- item 以 `type + config` 為主推導 attention status；部分類型會輔以 `lastDoneAt`
- `lastDoneAt` 是快照欄位與查詢優化欄位，不等於完整歷史
- `STATE_BASED` 不再以 `lastDoneAt` 作為主要基準，改以 `config.anchorDate`
- item side 不建立 `TaskTemplate + Task instance`

### 3.3 ItemActionRecord

```ts
ItemActionRecord {
  id: string
  itemId: string
  actionType: "done" | "skipped" | "deferred"
  actionDate: DateTime
  remark?: string
  payload?: Json
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- `ItemActionRecord` 是 history layer，不是 item attention status 的唯一來源
- `payload` 用來保存操作附加資訊，例如：`addedDays`、`nextCycleStrategy`
- `未處理` 不持久化成 record status；以缺少該輪 action 表示
- item 操作寫入 record 後，仍需同步更新 item snapshot 欄位
- `deferred` action type 保留給既有資料相容與未來功能恢復；目前 MVP 不會建立新的 deferred record

### 3.4 Timeline

```ts
Timeline {
  id: string
  title: string
  startDate: DateTime
  displayUnit: "day" | "week" | "month" | "year"
  status: "active" | "archived"
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- timeline 表示一段持續中的時間與其意義
- timeline 不可完成
- timeline 不會 overdue
- archived timeline 為唯讀

### 3.5 TimelineMilestoneRule

```ts
TimelineMilestoneRule {
  id: string
  timelineId: string
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

- rule 是 timeline milestone 的 primary source
- `paused` 不產生可用 milestone 提醒

### 3.6 TimelineMilestoneOccurrence

```ts
TimelineMilestoneOccurrence {
  timelineId: string
  ruleId: string
  occurrenceIndex: number
  targetDate: DateTime
  label: string
  status: "upcoming" | "noticed" | "skipped"
  reminderOffsetDays: number
}
```

規則：

- occurrence 是計算結果，不是預生成資料
- UI 顯示時動態計算
- 需要記錄互動時才對應到 record

### 3.7 TimelineMilestoneRecord

```ts
TimelineMilestoneRecord {
  id: string
  timelineId: string
  ruleId: string
  occurrenceIndex: number
  targetDate: DateTime
  status: "upcoming" | "noticed" | "skipped"
  notifiedAt?: DateTime
  actedAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

規則：

- record 只記錄已通知或已互動的 milestone
- record 不產生下一筆 milestone
- record 不進入 overdue

---

## 4. ItemType

```ts
enum ItemType {
  FIXED
  STATE_BASED
  RESOURCE_BASED
}
```

### 4.1 FIXED

```ts
config = {
  scheduleType: "daily" | "weekly" | "oneTime"
  anchorDate?: DateTime
  dueDate?: DateTime
  timeOfDay?: "HH:mm"
  overduePolicy: "autoAdvance" | "waitForAction"
  expectedBefore: Duration
  warningBefore: Duration
  dangerBefore: Duration
}
```

用途：

- 每日餵罐
- 每週清理
- 跑步提醒
- 需要固定節奏的例行責任

規則：

- `FIXED` 吸收原本產品討論中的「一般通知」與「例行事務」
- 差異不在 top-level type，而在 `overduePolicy`
- `anchorDate` 是固定排程的基準日
- `dueDate` 是當前週期的到期點
- `oneTime` 類型顯示文案使用 `ONETIME`
- `timeOfDay` 目前只作為摘要顯示欄位，不參與狀態判斷
- `autoAdvance` item 在 preview date 或實際 today 超過 `dueDate` 時，status 與摘要都必須反映 resolved next cycle

### 4.2 STATE_BASED

```ts
config = {
  anchorDate?: DateTime
  expectedAfter: Duration
  warningAfter: Duration
  dangerAfter: Duration
}
```

用途：

- 需要依「距離上次處理多久」來判斷是否變糟的責任

規則：

- `anchorDate` 是 `STATE_BASED` 的主要 baseline
- `anchorDate` 當天視為第 `1` 天
- 建立 item 時，system 以 `anchorDate` 作為初始 baseline 推導狀態
- 使用者完成 item 時，system 直接更新 `anchorDate`
- `lastDoneAt` 在 `STATE_BASED` 上視為棄用欄位，不再參與狀態判斷
- `warningAfter` 與 `dangerAfter` 都是「第 N 天當天生效」的 inclusive 門檻
- `expectedAfter` 保留作為資訊層設定，不單獨形成 attention status 邊界

### 4.3 RESOURCE_BASED

```ts
config = {
  anchorDate?: DateTime
  durationDays: number
  expectedBefore: number
  warningBefore: number
  dangerBefore: number
}
```

用途：

- 貓罐頭補貨
- 濾芯存量
- 任何可用「剩餘天數」估算的資源型責任

規則：

- `anchorDate` 表示目前這批資源開始被消耗的日期
- `durationDays` 表示依目前估算可持續多久，且包含 `anchorDate` 當天
- `expectedBefore / warningBefore / dangerBefore` 以剩餘天數做判斷
- depletion day 本身視為已進入 danger boundary
- 完成時必須要求使用者輸入 `addedDays`
- 補貨 / 完成行為透過 action record 的 `addedDays` 表示，並同步更新 item snapshot
- 完成後新的 `anchorDate` 一律重設為完成當天
- 若完成日尚未超過 depletion date，需保留「完成當天起仍可沿用」的剩餘天數，再加上 `addedDays`
- snapshot 更新公式為：
  - `depletionDate = anchorDate + durationDays - 1`
  - `remainingCarryDays = max(0, depletionDate - actionDate + 1)`
  - `newDurationDays = remainingCarryDays + addedDays`
- 若完成日已晚於 depletion date，則 `remainingCarryDays = 0`，等價於 `newDurationDays = addedDays`
- `RESOURCE_BASED` 不允許 `skip`

---

## 5. Item 狀態模型

### 5.1 Lifecycle 狀態集合

```ts
enum ItemLifecycleStatus {
  ACTIVE
  PAUSED
  ARCHIVED
}
```

規則：

- `ACTIVE` 參與一般 item 列表與 derived status 計算
- `PAUSED` 不參與 Home 的 danger / warning 列表
- `ARCHIVED` 不參與一般 item 列表，僅作為保留資料
- pack 被封存時，其底下 items 會一併轉為 `ARCHIVED`

### 5.2 Attention 狀態集合

```ts
enum ItemStatus {
  NORMAL
  WARNING
  DANGER
  UNKNOWN
}
```

規則：

- 這是 derived status
- 不是持久化 instance history

### 5.3 STATE_BASED 計算規則

```ts
dayIndex = (now - anchorDate) + 1

if anchorDate == null:
    status = UNKNOWN
elif dayIndex >= dangerAfter:
    status = DANGER
elif dayIndex >= warningAfter:
    status = WARNING
else:
    status = NORMAL
```

補充：

- `unknown` 代表尚未建立 baseline
- `StateBased` 的 baseline 由 `anchorDate` 單一承擔
- `anchorDate` 當天是第 `1` 天，不是第 `0` 天
- `warningAfter = 4` 代表第 4 天當天起進入 `WARNING`
- `dangerAfter = 10` 代表第 10 天當天起進入 `DANGER`
- 若 `dangerAfter < warningAfter`，仍以 `DANGER` 優先
- `expectedAfter` 不參與 attention status 邊界，只保留為資訊層設定

### 5.4 FIXED 計算規則

```ts
if anchorDate == null or dueDate == null:
    status = UNKNOWN

cycle = resolveCurrentCycle(anchorDate, dueDate, scheduleType, overduePolicy, now)

if now < cycle.anchorDate:
    status = NORMAL
elif completedWithin(cycle):
    status = NORMAL
elif now > cycle.dueDate and overduePolicy == "waitForAction":
    status = DANGER
elif remainingDays(cycle.dueDate, now) <= dangerBefore:
    status = DANGER
elif remainingDays(cycle.dueDate, now) <= warningBefore:
    status = WARNING
else:
    status = NORMAL
```

補充：

- `autoAdvance` 逾期後，系統會虛擬推進到目前應在的 cycle，再用新週期做狀態判斷
- `waitForAction` 逾期後，不自動推進；維持待處理，直到使用者 `done / skipped`
- `custom` 目前不自動展開下一輪

### 5.5 RESOURCE_BASED 計算規則

```ts
if anchorDate == null or durationDays <= 0:
    status = UNKNOWN

depletionDate = anchorDate + durationDays - 1
remainingDays = depletionDate - now

if remainingDays <= dangerBefore:
    status = DANGER
elif remainingDays <= warningBefore:
    status = WARNING
else:
    status = NORMAL
```

補充：

- `RESOURCE_BASED` 以剩餘天數心智運作，不以 `lastDoneAt` 作為主要狀態基準
- `lastDoneAt` 仍保留為最近一次完成/補貨快照
- `remainingDays` 表示「今天之後還剩幾天」；因此 depletion day 會顯示 `0`

### 5.6 UI 感受對應

只作為 UI 呈現，不作為資料欄位：

| Status | UI 感受 |
| --- | --- |
| NORMAL | 穩定 |
| WARNING | 需留意 |
| DANGER | 快變糟 |
| UNKNOWN | 未建立基準 |

---

## 6. Item 行為規則

### 6.1 完成行為

```ts
onComplete(item):
    create ItemActionRecord(actionType="done", actionDate=completionDate)
    sync item snapshot
```

規則：

- 一般情況下 `completionDate = 真實今天`
- 若 UI 正在使用 Developer Preview Date Override，且操作來自 Home / Items 管理頁，`completionDate = 生效中的 preview date`
- `updatedAt` 保留真實寫入時間，不跟隨 preview date 覆蓋

### 6.2 跳過與延期

```ts
onSkip(item):
    create ItemActionRecord(actionType="skipped")
    sync item snapshot

onDefer(item, deferDays):
    return disabled
```

規則：

- `skip` 是 item 的正式操作
- `skip` 不等於刪除或封存 item
- `defer` 目前為停用狀態
- UI 不提供 defer 入口
- repository / data layer 也必須拒絕 defer 呼叫，不更新 snapshot，也不建立 `ItemActionRecord`

### 6.3 History 與 snapshot 邊界

- item history 由 `ItemActionRecord` 提供
- `lastDoneAt` 保留為快照欄位與查詢優化欄位，但 `STATE_BASED` 不再依賴它
- 首頁與列表查詢不要求回放完整 history 才能顯示狀態

### 6.4 不產生 instance

item side 不需要：

- legacy task instance
- recurring task generation
- cancel / pause-template lifecycle

### 6.5 核心原則

- 系統關注「有沒有事情正在變糟」
- 不再以 `Today / Upcoming / Overdue task queue` 作為 item 主畫面語意
- `FIXED` 可包含 `dueDate`，但仍不回退成 task-instance 模型

---

## 7. Timeline 規則

### 7.1 Rule over Data

timeline milestone 採 rule-driven 模型：

- 優先儲存 rule
- occurrence 按需計算
- 僅保存有互動或已通知的 records

系統不得在 timeline 建立時批量預生成所有 milestone。

### 7.2 支援的 rule 類型

- `every_n_days`
- `every_n_weeks`
- `every_n_months`
- `every_n_years`

### 7.3 Reminder 規則

對每個 occurrence：

- 以 `reminderOffsetDays` 計算提醒時間
- 進入提醒窗口後列入 timeline upcoming
- timeline milestone 不會進入 overdue

### 7.4 History 規則

history 僅包含：

- `noticed`
- `skipped`

未互動的 future milestones 不進入 history。

---

## 8. Home 語意

Home 是唯一核心畫面。

### 8.1 Item 區塊

只關注：

- `danger`
- `warning`

`normal` 可隱藏。

首頁 item card 使用三段式中的兩段：

- 標題列
- 可展開的內容列

首頁不再顯示獨立提示列。

標題列必須可顯示：

- 完成 checkbox
- title
- 緊貼 title 的 item type badge
- 與 title / badge 拉開的尾欄狀態文字
- 展開 / 收合按鈕

內容列展開後必須可顯示：

- pack title
- note（item description；若空則隱藏）
- 開始日期
- 到期日期（如有）
- overdue policy（僅 `FIXED`）

尾欄狀態文字規則：

- `FIXED`：`剩餘N日` / `今天到期` / `過期`
- `STATE_BASED`：`已持續N日`
- `RESOURCE_BASED`：`剩餘N日`

補充：

- `RESOURCE_BASED` 的尾欄剩餘天數最小顯示為 `0`
- `skip` 只在展開後提供給 `FIXED` 與 `STATE_BASED`
- `RESOURCE_BASED` 在首頁不提供 `skip`
- `notStarted / overdue` 為首頁 item card 的 presentation state，不是 core `ItemStatus` 欄位

### 8.2 Timeline 區塊

顯示：

- 已進入提醒窗口的 upcoming milestone occurrences

### 8.3 顯示優先級

1. item `danger`
2. item `warning`
3. timeline upcoming

### 8.4 Home 入口

Home 的 AppBar 保留主要日常操作入口，並提供一個 `功能` 入口導向功能頁。

---

## 9. 編輯與管理流程

### 9.1 Item 編輯流程

建立 item：

1. 輸入內容
2. 選擇 pack
3. 選擇 item type
4. 設定對應 config

編輯既有 item：

1. 輸入內容
2. 選擇 pack
3. 檢視既有 item type（唯讀，不可修改）
4. 調整對應 config

規則：

- item type 只可在建立時選擇；既有 item 不允許變更 type
- UI 必須在 edit mode 鎖住 type
- repository / data layer 也必須拒絕任何跨 type 的更新請求
- 編輯 `FIXED` item 時，日期欄位必須反映目前生效中的 cycle snapshot
- 若 `FIXED` item 為 `autoAdvance` 且 preview date 已推進到下一輪，edit 頁必須顯示 resolved cycle 的 `anchorDate / dueDate`
- 若無法解析 resolved cycle，才退回實際儲存的 `anchorDate / dueDate`
- `STATE_BASED` 與 `RESOURCE_BASED` 的 edit 頁日期欄位仍直接反映目前儲存的 snapshot
- preview date 不可污染存檔 payload；它只影響 `FIXED` edit 頁的預填顯示與狀態/操作計算

### 9.2 Timeline 編輯流程

1. 輸入內容
2. milestone rule 設定
3. reminder offset 設定

### 9.3 Management

#### 9.3.1 Items 管理

- 只管理 system default pack 內的 items
- 可顯示：
  - default pack 標示
  - item title
  - item summary
  - derived status
- 可操作：
  - 新增 item
  - 編輯 item
  - 完成 item
  - 跳過 item
  - 查看 item history

#### 9.3.2 Item Packs 管理

- pack 是正式可見實體
- item packs 頁以 pack card 內嵌顯示該 pack 的 item 清單
- 可操作：
  - 新增 pack
  - 編輯非 system default pack
  - 新增 item 到指定 pack
  - 編輯 pack 內 item
  - 暫停 / 恢復 / 封存 pack 內 item
  - 封存非 system default pack；若 pack 內仍有 active / paused items，需二次確認

#### 9.3.3 Timeline 管理

- timeline 管理獨立為單頁
- 可操作：
  - 新增 timeline
  - 編輯 active timeline
  - 查看 milestone history

#### 9.3.4 History

- 不保留首頁層級的聚合 history page
- milestone history 只保留在單一 timeline 的明細層級
- item history 以單一 item 明細頁提供

### 9.4 Developer Preview Date Override

規則：

- 覆蓋值為 `DateTime?`
- `null` 代表使用真實今天
- 生效日期一律正規化為本地時區的年月日 `00:00`
- 此設定影響狀態計算與部分 item 操作的 actionDate / snapshot
- 此設定只存在記憶體，本次 app 啟動有效

影響範圍：

- Home 的 `danger / warning / upcoming timeline` 計算
- `Items 管理` 中 item derived status 的顯示
- Home / `Items 管理` 的 item `完成 / 跳過` 操作
- `Timeline 管理` 中 next / upcoming milestone 的顯示

不影響：

- `createdAt / updatedAt / actedAt / notifiedAt`
- timeline 編輯頁的預設日期欄位
- item 建立頁的預設日期欄位

例外：

- `FIXED` item 編輯頁的日期欄位必須依 preview date 反映目前生效 cycle 的 snapshot

---

## 10. Persistence Model

### 10.1 item_packs

- `id`
- `title`
- `description`
- `status`
- `isSystemDefault`
- `createdAt`
- `updatedAt`

### 10.2 items

- `id`
- `packId`
- `title`
- `description`
- `status`
- `type`
- `fixedScheduleType`
- `fixedAnchorDate`
- `fixedDueDate`
- `fixedTimeOfDay`
- `fixedOverduePolicy`
- `fixedExpectedBeforeMinutes`
- `fixedWarningBeforeMinutes`
- `fixedDangerBeforeMinutes`
- `stateExpectedAfterMinutes`
- `stateWarningAfterMinutes`
- `stateDangerAfterMinutes`
- `resourceAnchorDate`
- `resourceDurationDays`
- `resourceExpectedBeforeDays`
- `resourceWarningBeforeDays`
- `resourceDangerBeforeDays`
- `lastDoneAt`
- `createdAt`
- `updatedAt`

### 10.3 item_action_records

- `id`
- `itemId`
- `actionType`
- `actionDate`
- `remark`
- `payload`
- `createdAt`
- `updatedAt`

### 10.4 timelines

- `id`
- `title`
- `startDate`
- `displayUnit`
- `status`
- `createdAt`
- `updatedAt`

### 10.5 timeline_milestone_rules

- `id`
- `timelineId`
- `type`
- `intervalValue`
- `intervalUnit`
- `labelTemplate`
- `reminderOffsetDays`
- `status`
- `createdAt`
- `updatedAt`

### 10.6 timeline_milestone_records

- `id`
- `timelineId`
- `ruleId`
- `occurrenceIndex`
- `targetDate`
- `status`
- `notifiedAt`
- `actedAt`
- `createdAt`
- `updatedAt`

---

## 11. Domain Constraints

- `Item` 與 `Timeline` 不混用
- item side 不再拆成 `TaskTemplate + Task`
- `ItemStatus` 來自規則計算，不作為核心歷史模型
- `ItemActionRecord` 是 history layer，不是 item attention status 的唯一來源
- `TimelineMilestoneRule` 是 primary source，occurrence 為動態計算結果
- `TimelineMilestoneRecord` 不依使用者操作產生下一筆
- archived `Timeline` 為唯讀
- system default `ItemPack` 必須唯一、可見、不可封存

---

## 12. MVP 必做 / 可延後 / 禁止事項

### 必做

- `ItemPack`
- `Item`
- `ItemActionRecord`
- `STATE_BASED`
- `FIXED` 的 overdue policy
- item 狀態計算
- Home 顯示（warning / danger）
- item `完成 / 跳過`
- timeline milestone rule / record 基本流

### 可延後

- group 協作
- pack preset marketplace
- timeline 深整合

### 禁止事項

不再實作：

- `TaskTemplate`
- `Task`
- `TaskStatus`
- `TaskTemplateStatus`
- recurring task instance generation
- 巨型通用 Reminder model

---

## 13. 實作指令

後續所有 reminders feature 實作必須遵守：

1. 不再新增 `task`、`template`、`instance` 型命名到核心 domain/data/UI
2. item 相關實作一律以 `ItemPack / Item / ItemActionRecord` 收斂
3. timeline 相關實作一律維持 `rule -> occurrence -> record` 邊界
4. 若舊註解、舊文件、舊欄位名稱仍使用舊 task 語言，以本文件覆寫
