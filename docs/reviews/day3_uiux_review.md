# Day 3 UI/UX Review Sync

本文件已依目前程式實作與正式 spec 同步，保留 Day 3 最終採用的 UI/UX 與 decision 結論。

## 已採用決策

### Task / TaskTemplate

- one-time task 不建立 `TaskTemplate`
- one-time task 直接建立於 `tasks`
- `tasks.template_id` 可為 `null`
- recurring task 仍維持 `TaskTemplate + Task` 流程
- `Task` 需保存 `kind / repeatRule / reminderRule` snapshot

### Today / Upcoming / Overdue

- Today
  - task: `effectiveDueDate == today`
  - milestone: `targetDate == today`
- Upcoming
  - task: 未來且已進入提醒期
  - `immediate` 會進 Upcoming
  - `advance` 於進入提醒期後進 Upcoming
  - `onDue` 不進 Upcoming
  - milestone: 未來且已進入提醒期
  - `onDay` milestone 不進 Upcoming
- Overdue
  - 只包含 overdue task
  - milestone 不可進 overdue

### Status / Readonly

- `Timeline.status` 移除 `paused`
- Timeline 僅保留 `active / archived`
- archived `TaskTemplate` 為唯讀
- archived `Timeline` 為唯讀

### Pause / Cancel 規則

- recurring task 被取消時，對應 `TaskTemplate` 同步轉為 `paused`
- pause `TaskTemplate` 時，所有 pending tasks 批次轉為 `canceled`
- 上述批次取消時，`deferredDueDate` 清空

## 已落地的 UI 修整

- 新增 recurring task 與編輯 TaskTemplate 時，只有 `advance` 顯示 offset
- 新增 / 編輯 Timeline 時，只有 `advance` 顯示 offset
- TaskTemplate / Timeline 編輯頁會正確回填既有 reminder rule
- TaskTemplate 管理卡改為明確按鈕，不再整卡點擊進入編輯
- Timeline 管理卡改為明確 `編輯` 按鈕
- Timeline 編輯頁 milestone 超過 3 筆時預設只顯示最近 3 筆，並提供查看全部
- Home 與 Management 已分離；Home 卡片不直接進管理編輯頁
- Overdue task 卡片提供完成 / 跳過 / 延期 / 取消
- History 頁採雙區塊分頁，每區每頁 10 筆，並顯示 `updatedAt`

## 備註

- 正式規格以 `docs/01_mvp_spec.md` 為準
- architecture 細節以 `docs/02_architecture_refactor.md` 為準
