# Day 3 UI/UX Review Sync

本文件只保留仍與目前 repo 一致的 UI/UX 決策，避免再次引入舊 mixed reminder 心智模型。

## 已採用決策

- one-time task 不建立 `TaskTemplate`
- recurring task 維持 `TaskTemplate + Task`
- `Task` 保留 `kind / repeatRule / reminderRule` snapshot
- Today = today task + today milestone
- Upcoming = 已進入提醒期且仍在未來的 task / milestone
- Overdue = task only
- `Timeline.status` 只有 `active / archived`
- recurring task 被取消時，對應 `TaskTemplate` 轉為 `paused`
- pause `TaskTemplate` 時，既有 pending task 批次轉為 `canceled` 並清空 `deferredDueDate`

## 已落地的 UI 結論

- Home 與 Management 分離
- History 分開顯示 `Task History` 與 `Milestone History`
- TaskTemplate / Timeline 管理卡使用明確動作按鈕
- 共用 editor page 以 task / task template / timeline mode 區分
- `advance` 才顯示 offset 欄位
- Timeline 編輯頁改為編輯 `Milestone Rule`，並預覽動態計算的 upcoming milestone occurrence
