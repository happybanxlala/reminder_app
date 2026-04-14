# Reminder App MVP Spec

本文件是 repo 的正式規格。若文件、實作、命名有衝突，應以本文件、`docs/02_architecture_refactor.md` 與目前 Drift schema 一致的版本為準。

## 1. Product Model

### Task

- `Task` 是要完成的事。
- `Task` 有 `dueDate`，可 `done / skipped / canceled`，也可 defer。
- `Task` 可以 overdue。
- recurring `Task` 在 `done / skipped` 後會依 `repeatRule` 產生下一筆。

### Timeline

- `Timeline` 是從某天開始經過的時間。
- `Timeline` 有 `startDate`，不可完成，也不會 overdue。
- `Timeline` 透過 `Milestone` 顯示重要日子。

### Milestone

- `Milestone` 屬於 `Timeline`。
- `Milestone` 有 `targetDate`。
- `Milestone` 只可 `noticed / skipped`。
- `Milestone` 不會產生下一筆，也不可進入 overdue。

## 2. Status Sets

- `TaskTemplateStatus = active / paused / archived`
- `TaskStatus = pending / done / skipped / canceled`
- `TimelineStatus = active / archived`
- `MilestoneStatus = upcoming / noticed / skipped`

## 3. Task Rules

### Kinds

- `oneTime`
- `recurring`

### ReminderRule

- `advance`
- `onDue`
- `immediate`

### Lifecycle

- `done / skipped`: 更新狀態；若 recurring 且 template 仍為 `active`，產生下一筆 `Task`
- `defer`: 更新 `deferredDueDate`
- `cancel`: `Task.status -> canceled`
- recurring `Task` 被取消且來自 `TaskTemplate` 時，對應 `TaskTemplate.status -> paused`
- `pause TaskTemplate`: 所有既有 pending `Task` 批次轉為 `canceled`，並清空 `deferredDueDate`
- archived `TaskTemplate` 為唯讀

## Timeline & Milestone

### 1. 概念調整（重要）

**Milestones for a Timeline are rule-driven and computed on demand, rather than pre-generated in bulk when the Timeline is created.**

Timeline 的 milestone 不再於建立時批量生成。
改為由使用者設定的「Milestone Rule」動態計算，在需要顯示、提醒或記錄時產生對應的 milestone occurrence。

---

### 2. 核心概念

#### Timeline

一段持續中的時間，具有：

* `startDate`
* 持續累積（例如第 N 天 / 週 / 月 / 年）
* 不可完成、不會 overdue

---

#### Milestone Rule（新增）

Milestone Rule 是定義「什麼時候應該出現 milestone」的規則。

使用者可以在 Timeline 詳情頁中新增與管理規則。

##### 支援類型（MVP）

* `every_n_days`（每 N 天）
* `every_n_weeks`（每 N 週）
* `every_n_months`（每 N 個月）
* `every_n_years`（每 N 年）

##### 範例

* 每 100 天（交往紀念）
* 每 1 年（週年紀念）
* 每 30 天（定期檢視）

##### 屬性（建議）

* `intervalValue`（例如 100）
* `intervalUnit`（days / weeks / months / years）
* `labelTemplate`（例如「第 {value}{unit}」，其中 `{n}` = 次數、`{value}` = 累積值、`{unit}` = 單位）
* `reminderOffsetDays`（提前幾天提醒）
* `status`

---

#### Milestone Occurrence（概念）

Milestone Occurrence 是某條規則在某個時間點對應的一次具體 milestone。

例如：

* 第 100 天 → 2026-04-10
* 第 200 天 → 2026-07-19

Occurrence **不會在 Timeline 建立時全部預先生成**，而是：

* 在 UI 顯示時動態計算
* 在提醒流程中動態取得
* 在需要記錄狀態時才持久化

---

#### Milestone Record（持久化資料）

當 milestone 被實際使用或需要追蹤時，會建立對應記錄。

##### 建立時機

* 已發送提醒（notification）
* 使用者標記為：

  * `noticed`
  * `skipped`

##### 狀態

* `upcoming`
* `noticed`
* `skipped`

##### 特性

* 不會產生下一筆 milestone（不同於 recurring task）
* 不會 overdue
* 僅用於記錄歷史與使用者互動

---

### 3. 行為規則

#### 規則 1：Milestone 來源

Milestone 由以下組成：

* Timeline 的 `startDate`
* Milestone Rule

系統根據規則動態計算 occurrence。

---

#### 規則 2：不預生成

系統**不應在 Timeline 建立時批量產生 milestone 資料**。

原因：

* 避免大量未使用資料
* 保持規則驅動的模型
* 提高彈性（規則可隨時新增/修改）

---

#### 規則 3：提醒機制

對於每個 milestone occurrence：

* 系統可根據 `reminderOffsetDays` 計算提醒時間
* 當進入提醒範圍時：

  * 顯示於 Home（Today / Upcoming）
  * 可觸發通知

---

#### 規則 4：Home 顯示

Milestone 在 Home 中的行為：

* Today：targetDate 為今天
* Upcoming：已進入提醒窗口，但日期尚未到
* 不會出現在 Overdue

---

#### 規則 5：History

History 僅包含：

* 已被 `noticed` 或 `skipped` 的 milestone records

未互動的 future milestones 不進入 History。

---

#### 規則 6：Timeline 詳情頁

Timeline 詳情頁應提供：

* Milestone Rule 列表
* 新增 / 編輯 / 刪除規則
* Upcoming milestones 預覽（動態計算）
* 過去 milestone 紀錄（records）

---

### 4. 與 Task 的差異（強化語意）

| 項目          | Task         | Milestone |
| ----------- | ------------ | --------- |
| 是否需要完成      | ✅ 是          | ❌ 否       |
| 是否會 overdue | ✅ 會          | ❌ 不會      |
| 是否會產生下一筆    | ✅（recurring） | ❌         |
| 來源          | Template     | Rule      |
| 產生方式        | 預先產生         | 動態計算      |

---

### 5. 設計原則（重要）

1. **Rule over Data**
   優先儲存規則，而非大量預生成資料

2. **On-demand computation**
   milestone occurrence 在需要時才計算

3. **Lightweight persistence**
   僅保存有互動或已通知的 milestone records

4. **User mental model first**
   使用者理解的是「每 100 天」，不是「第 17 筆 milestone」

---

### 6. 範例（實際使用）

Timeline：
「與 xxx 交往」
startDate：2026-01-01

Milestone Rule：

* every 100 days
* reminderOffsetDays = 3

系統行為：

* 第 100 天 → 2026-04-10
* 第 200 天 → 2026-07-19
* 於 2026-07-16 開始提醒
* 若使用者標記 noticed → 建立 record
* 未互動 → 不產生資料

## 5. Home Semantics

### Today

- today `Task`: `effectiveDueDate == today`
- today `Milestone`: `targetDate == today`

### Upcoming

- future `Task`
- `immediate`: 只要尚未到 due date 就列入 Upcoming
- `advance`: 已進入提醒期且 due date 仍在未來時列入 Upcoming
- `onDue`: 不列入 Upcoming
- future `Milestone`
- `advance`: 已進入提醒期且 target date 仍在未來時列入 Upcoming
- `onDay`: 不列入 Upcoming

### Overdue

- 只顯示 `Task`

## 6. History

- `Task History`: `done / skipped / canceled`
- `Milestone History`: `noticed / skipped`

## 7. Wizard Flows

### Task

1. 輸入內容
2. 是否重複
3. 日期設定
4. 提醒設定

### Timeline

1. 輸入內容
2. milestone 設定
3. 提醒設定

## 8. Data Model

### task_templates

- `id`
- `title`
- `categoryId`
- `note`
- `kind`
- `status`
- `firstDueDate`
- `repeatRule`
- `reminderRule`
- `createdAt`
- `updatedAt`

### tasks

- `id`
- `templateId`
- `kind`
- `titleSnapshot`
- `noteSnapshot`
- `categoryId`
- `dueDate`
- `repeatRule`
- `reminderRule`
- `deferredDueDate`
- `status`
- `createdAt`
- `updatedAt`
- `resolvedAt`

補充：

- one-time `Task` 直接建立於 `tasks`
- one-time `Task` 允許 `templateId = null`
- `Task` 保留 snapshot 欄位，避免後續 template 變更回寫歷史 task

### timelines

- `id`
- `title`
- `startDate`
- `displayUnit`
- `status`
- `createdAt`
- `updatedAt`

### timeline_milestone_rules

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

### timeline_milestone_records

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

## 9. Domain Constraints

- `Task` 與 `Timeline` 不可混用
- `Milestone` 不可進入 overdue
- `Milestone Rule` 是 primary source，occurrence 為動態計算結果
- 建立 `Timeline` 時不得預先批量生成 milestone occurrence
- `TaskTemplate` 修改不影響既有 `Task`
- `Milestone` 不依使用者操作產生下一筆
- one-time `Task` 不建立 `TaskTemplate`
- archived `Timeline` 為唯讀，不可再編輯

## 10. Migration Policy

- 已移除 `trackingMode`
- 已移除 `triggerMode`
- 已移除 mixed `Reminder / RecurringReminder` 核心模型
- schema version 目前為 `7`
