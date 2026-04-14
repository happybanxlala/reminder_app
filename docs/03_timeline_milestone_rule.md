# Timeline Milestone Rule

本文件描述目前 repo 已落地的 Timeline milestone 模型。

## Core Model

- `Timeline` 只保存經過時間的主體資料，例如 `title / startDate / displayUnit / status`
- `Timeline Milestone Rule` 是第一級資料，定義 milestone 的 interval 與 reminder offset，支援 `days / weeks / months / years`
- `Timeline Milestone Occurrence` 是衍生結果，來自 `timeline.startDate + rule`
- `Timeline Milestone Record` 只在 occurrence 被通知或被使用者互動後持久化
- `labelTemplate` 支援三個 placeholders：
  - `{n}` = occurrence 次數
  - `{value}` = 累積時間值
  - `{unit}` = 單位字串（`天 / 週 / 個月 / 年`）

## Why Not Pre-Generate

- `Timeline` 不會完成，也不會 overdue
- `Milestone` 不會 overdue，也不會因 noticed / skipped 產生下一筆
- milestone 的本質是「時間命中某個規則」；因此儲存 rule 比預先生成大量 future rows 更符合產品模型
- 預生成會讓 Home、History、Timeline detail 都依賴過期資料，且容易把 record 誤當 primary source

## Data Flow

1. 使用者建立 `Timeline`
2. 使用者建立一條或多條 `Timeline Milestone Rule`
3. `TimelineMilestoneService` 依 `Timeline + Rule` 動態計算 today / upcoming occurrence
4. Home 與 Timeline detail 直接顯示動態 occurrence
5. 當 occurrence 被 `noticed / skipped / notified` 時，repository 才 upsert `timeline_milestone_records`
6. History 僅顯示 `timeline_milestone_records`

## Persistence Boundary

- `timeline_milestone_rules`
  - primary source
  - 保存 interval、label template、reminder offset、rule status

- `timeline_milestone_records`
  - secondary source
  - 保存已被追蹤的 occurrence，例如 `noticed / skipped / notified`
  - 不保存所有未來 milestone

## Naming Rules

- 不再使用 `custom milestone`
- 不再使用 `rule-based milestone` 指涉預生成 rows
- 不再在 `Timeline` 上保存單一 `milestoneReminderRule`
- 新的預設 template 使用 `第 {value}{unit}`；既有已存 template 不做 migration，因此可能保留舊字樣
- 主流程命名應清楚區分：
  - `Milestone Rule`
  - `Milestone Occurrence`
  - `Milestone Record`
- `Milestone Rule` 目前支援 `active / paused / archived`
- 編輯頁 delete 代表 archive，不是 hard delete；archived rule 不再出現在編輯頁，但既有 history records 仍保留
