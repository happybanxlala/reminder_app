---
This is the single source of truth for reminders core model, MVP scope, naming, and behavior.
---

# Reminder App Unified Core Spec

本文件已整合原本的：

- `01_mvp_spec.md`
- `04_core_model_spec_v1.md`
- `05_core_model_convergence_decision.md`

後續 reminders feature 一律只以本文件作為唯一實作依據。

---

## 1. 核心決策

唯一核心模型定為：

- `ItemPack`
- `ItemPack`
- `Item`
- `ItemType`
- `ItemStatus`
- `Timeline`
- `TimelineMilestoneRule`
- `TimelineMilestoneOccurrence`
- `TimelineMilestoneRecord`

此系統不再以 `Task / TaskTemplate / Task instance` 為核心。

核心轉變：

| 舊模型 | 新模型 |
| --- | --- |
| Task 分類 | Item 本質（fixed / state / resource） |
| due date 驅動 | 狀態（normal / warning / danger）驅動 |
| 今天要做什麼 | 有沒有事情正在變糟 |

一句話版本：

> reminders feature 的核心，是 `Item` 的狀態變化，加上 `Timeline` 的 rule-driven milestone records。

---

## 2. 產品北極星

> 讓重要的事，不會在無意識中變糟。

系統優先關注：

- 哪些責任正在惡化
- 哪些 timeline milestone 已進入提醒窗口

系統不再以「到期任務清單」作為主要心智模型。

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

用途：

- 組織責任場景，例如：養貓、家務、健康
- 作為 UI grouping 單位

規則：

- system default pack 必須唯一
- system default pack 可見，但不可改名、不可封存
- archived pack 不再接受新 item 歸屬

不是：

- template
- schedule container
- instance generator

### 3.2 Item

```ts
Item {
  id: string
  packId: string
  title: string
  description?: string
  type: ItemType
  config: ItemConfig
  lastDoneAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

用途：

- 表示一個需要持續維持、不應無意識變糟的責任

規則：

- item 屬於一個 pack
- item 以 `type + config + lastDoneAt` 推導狀態
- item side 不再建立 `TaskTemplate + Task instance`

不是：

- one-time queue item
- recurring task instance
- 歷史快照容器

### 3.3 Timeline

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

用途：

- 表示一段持續中的時間與其意義

規則：

- timeline 不可完成
- timeline 不會 overdue
- archived timeline 為唯讀

### 3.4 TimelineMilestoneRule

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
- 可以新增、編輯、封存
- `paused` 不產生可用 milestone 提醒

### 3.5 TimelineMilestoneOccurrence

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
- 提醒流程中動態取得
- 需要記錄互動時才對應到 record

### 3.6 TimelineMilestoneRecord

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
  FIXED_TIME
  STATE_BASED
  RESOURCE_BASED
}
```

### 4.1 FIXED_TIME

```ts
config = {
  schedule: {
    type: "daily" | "weekly" | "custom"
    time?: "HH:mm"
  }
}
```

用途：

- 每日餵罐
- 每日清理

### 4.2 STATE_BASED

```ts
config = {
  expectedInterval: Duration
  warningAfter: Duration
  dangerAfter: Duration
}
```

這是 MVP 的核心責任模型。

### 4.3 RESOURCE_BASED

```ts
config = {
  estimatedDuration: Duration
  warningBeforeDepletion: Duration
}
```

MVP 可先以保守方式沿用 state-based 邏輯收斂，不要求完整 depletion engine。

---

## 5. Item 狀態模型

### 5.1 唯一狀態集合

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

### 5.2 STATE_BASED 計算規則

```ts
elapsed = now - lastDoneAt

if lastDoneAt == null:
    status = UNKNOWN
elif elapsed < expectedInterval:
    status = NORMAL
elif elapsed < dangerAfter:
    status = WARNING
else:
    status = DANGER
```

### 5.3 FIXED_TIME 計算規則

```ts
todayScheduled = isScheduledToday(item)

if todayScheduled and not done:
    status = WARNING

if missed:
    status = DANGER
```

### 5.4 UI 感受對應

只作為 UI 呈現，不作為資料欄位：

| Status | UI 感受 |
| --- | --- |
| NORMAL | 想做就做 |
| WARNING | 差不多該做 |
| DANGER | 已經拖太久 |
| UNKNOWN | 尚未建立基準 |

---

## 6. Item 行為規則

### 6.1 完成行為

```ts
onComplete(item):
    item.lastDoneAt = now
```

### 6.2 不產生 instance

`STATE_BASED` 不需要：

- legacy task instance
- recurring task generation
- defer / cancel / pause-template lifecycle
- item completion history（MVP 可省略）

### 6.3 核心原則

- 系統關注「有沒有事情正在變糟」
- 不再以 `dueDate` 作為 item 核心欄位
- 不再以 `Today / Upcoming / Overdue task queue` 作為 item 主畫面語意

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

每個 item 必須可顯示：

- title
- elapsed time
- status
- 可選：後果描述
- pack title

### 8.2 Timeline 區塊

顯示：

- 已進入提醒窗口的 upcoming milestone occurrences

### 8.3 顯示優先級

1. item `danger`
2. item `warning`
3. timeline upcoming

### 8.4 Home 入口

Home 的 AppBar 保留主要日常操作入口，並提供一個 `功能` 入口導向功能頁。

功能頁作為 reminders feature 的導覽層，至少包含：

- `動態（for item）`
- `Items 管理 (= Default Item Packs)`
- `Item Packs 管理`
- `Timeline 管理`
- `設定頁(for user）`
- `開發者設定`

---

## 9. 編輯與管理流程

### 9.1 Item 編輯流程

1. 輸入內容
2. 選擇 pack
3. 選擇 item type
4. 設定對應 config

### 9.2 Timeline 編輯流程

1. 輸入內容
2. milestone rule 設定
3. reminder offset 設定

### 9.3 Management

管理不再以單一「總管理頁」承載全部內容，而是透過功能頁分流到獨立頁面。

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

#### 9.3.2 Item Packs 管理

- pack 是正式可見實體
- item packs 頁只負責 pack 管理，不內嵌 item 清單
- 可操作：
  - 新增 pack
  - 編輯非 system default pack
  - 封存非 system default 且為空的 pack
- archived pack 預設不作為 active selector 候選

#### 9.3.3 Timeline 管理

- timeline 管理獨立為單頁
- 可顯示：
  - timeline summary
  - milestone rules
  - next upcoming milestone by rule
- 可操作：
  - 新增 timeline
  - 編輯 active timeline
  - 查看 milestone history

#### 9.3.4 History

- 不再保留首頁層級的聚合 history page
- milestone history 只保留在單一 timeline 的明細層級
- item completion history 仍非 MVP 必做項目

#### 9.3.5 Settings / Developer Settings

- `設定頁(for user）` 可先保留為 UI shell，不強制在 MVP 實作資料設定
- `開發者設定` 可承載只用於預覽與測試的 UI control

### 9.4 Developer Preview Date Override

MVP 允許在 `開發者設定` 中覆蓋 app 內的預覽日期，用於快速檢查不同日期下的 UI/UX 結果。

規則：

- 覆蓋值為 `DateTime?`
- `null` 代表使用真實今天
- 生效日期一律正規化為本地時區的年月日 `00:00`
- 此設定只影響預覽計算，不影響 persistence timestamp
- 此設定只存在記憶體，本次 app 啟動有效

影響範圍：

- Home 的 `danger / warning / upcoming timeline` 計算
- `Items 管理` 中 item derived status 的顯示
- `Timeline 管理` 中 next / upcoming milestone 的顯示

不影響：

- `createdAt / updatedAt / actedAt / notifiedAt`
- item / timeline 編輯頁的預設日期欄位
- DAO、schema、record 結構

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
- `type`
- `fixedScheduleType`
- `fixedAnchorDate`
- `fixedTimeOfDay`
- `stateExpectedIntervalMinutes`
- `stateWarningAfterMinutes`
- `stateDangerAfterMinutes`
- `resourceEstimatedDurationMinutes`
- `resourceWarningBeforeDepletionMinutes`
- `lastDoneAt`
- `createdAt`
- `updatedAt`

### 10.3 timelines

- `id`
- `title`
- `startDate`
- `displayUnit`
- `status`
- `createdAt`
- `updatedAt`

### 10.4 timeline_milestone_rules

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

### 10.5 timeline_milestone_records

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
- `TimelineMilestoneRule` 是 primary source，occurrence 為動態計算結果
- `TimelineMilestoneRecord` 不依使用者操作產生下一筆
- archived `Timeline` 為唯讀
- system default `ItemPack` 必須唯一、可見、不可封存

---

## 12. MVP 必做 / 可延後 / 禁止事項

### 必做

- `ItemPack`
- `Item`
- `STATE_BASED`
- 狀態計算
- Home 顯示（warning / danger）
- 完成操作
- timeline milestone rule / record 基本流

### 可延後

- `RESOURCE_BASED` 精細計算
- group 協作
- pack preset marketplace
- timeline 深整合

### 禁止事項

不再實作：

- `TaskTemplate`
- `Task`
- `TaskStatus`
- `TaskTemplateStatus`
- 單純依 due date 的 item reminder 系統
- 巨型通用 Reminder model
- recurring task instance generation
- defer / cancel / pause-template 作為責任主流轉

---

## 13. 實作指令

後續所有 reminders feature 實作必須遵守：

1. 不再新增 `task`、`template`、`instance` 型命名到核心 domain/data/UI
2. item 相關實作一律以 `ItemPack / Item` 收斂
3. timeline 相關實作一律維持 `rule -> occurrence -> record` 邊界
4. 若舊註解、舊文件、舊欄位名稱仍使用 task 語言，以本文件覆寫
