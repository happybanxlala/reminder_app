# Reminder App Architecture

本文件描述目前已落地的架構切分，並與 `docs/01_mvp_spec.md` 與 Drift schema 對齊。

## 1. Canonical Sources

唯一真相來源：

- `docs/01_mvp_spec.md`
- `docs/02_architecture_refactor.md`
- `lib/features/reminders/data/local/tables.dart`
- `lib/features/reminders/data/local/app_database.dart`

## 2. Core Split

系統只允許兩條獨立 domain track：

- `TaskTemplate + Task`
- `Timeline + Milestone`

這個切分是強制的：

- `Task` 有 `dueDate`，可 `done / skipped / canceled / defer`，且可能 overdue
- `Timeline` 有 `startDate`，不是 todo item，不會 overdue
- `Milestone` 屬於 `Timeline`，只可 `noticed / skipped`，不會產生下一筆

## 3. Data Layer

Drift tables：

- `task_templates`
- `tasks`
- `timelines`
- `milestones`

已落地決策：

- one-time task 直接存在 `tasks`，可 `templateId = null`
- `tasks` 保存 snapshot 欄位，如 `titleSnapshot / repeatRule / reminderRule`
- `task_templates` 只負責 recurring template lifecycle
- `milestones` 與 `tasks` 分離，設計上排除 overdue query
- `timelines` 只有 `active / archived`，沒有 `paused`
- schema version 是 `7`

## 4. Domain Services

### TaskScheduler

- 計算 task 的 today / upcoming / overdue
- `Today`: `effectiveDueDate == today`
- `Upcoming`: future task 且已進入 reminder window
- recurring task 在 `done / skipped` 後推算下一筆 due date

### TimelineCalculator

- 計算 timeline display counter
- 計算 milestone reminder date
- `Today`: `targetDate == today`
- `Upcoming`: future milestone 且已進入 reminder window
- milestone 永遠不進 overdue

## 5. Repository And Query Boundaries

### TaskRepository

- `TaskTemplate` CRUD
- `Task` CRUD
- task lifecycle transition

### TimelineRepository

- `Timeline` CRUD
- `Milestone` CRUD
- timeline lifecycle

### HomeQueryService

- 組合 Today / Upcoming 首頁資料
- Today = today tasks + today milestones
- Upcoming = upcoming tasks + upcoming milestones
- Overdue 由 task query 單獨提供，因 milestone 不可 overdue

### History Providers

- `Task History`
- `Milestone History`

歷史查詢不再提供 mixed history aggregate。

## 6. UI Shape

- Home：`Today / Upcoming / Overdue`
- History：分開顯示 `Task History / Milestone History`
- Management：分開顯示 `Task Template management / Timeline management`
- Shared editor page 允許 `task / task template / timeline` mode，但 route 與 mode 命名必須明確

## 7. Removed Legacy Concepts

以下概念已從主流程移除：

- `trackingMode`
- `triggerMode`
- mixed `Reminder / RecurringReminder`
- 把 timeline-like entity 當成 task
- `TimelineStatus.paused`
