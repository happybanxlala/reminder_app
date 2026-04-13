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

## 4. Timeline Rules

### Display

- `Timeline.displayUnit = day / week / month / year`
- 顯示值由 `TimelineCalculator` 根據 `startDate` 與今天計算

### Milestone Source

- `ruleBased`
- `custom`

### MilestoneReminderRule

- `advance`
- `onDay`

### User Actions

- `noticed`
- `skipped`

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
- `milestoneReminderRule`
- `createdAt`
- `updatedAt`

### milestones

- `id`
- `timelineId`
- `targetDate`
- `description`
- `source`
- `status`
- `createdAt`
- `updatedAt`

## 9. Domain Constraints

- `Task` 與 `Timeline` 不可混用
- `Milestone` 不可進入 overdue
- `TaskTemplate` 修改不影響既有 `Task`
- `Milestone` 不依使用者操作產生下一筆
- one-time `Task` 不建立 `TaskTemplate`
- archived `Timeline` 為唯讀，不可再編輯

## 10. Migration Policy

- 已移除 `trackingMode`
- 已移除 `triggerMode`
- 已移除 mixed `Reminder / RecurringReminder` 核心模型
- schema version 目前為 `7`
