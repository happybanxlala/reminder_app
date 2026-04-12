# Reminder App MVP Spec（正式版）

> 本文件為 repo 正式規格，取代舊版 spec。所有實作應以本文件為準。

---

## 1. 目標（Goal）

建立一個協助使用者：

* 管理「需要完成的事情」（Task）
* 追蹤「從某天開始的時間」（Timeline）

並在正確的時間點提供清楚、不混亂的提醒。

---

## 2. 範圍（Scope）

### 包含

* Task（單次 / 定期）
* Timeline（從某天開始）
* 首頁 Today / Upcoming / Overdue
* 歷史紀錄
* Wizard 建立流程

### 不包含（MVP）

* 複雜排程（如每月第幾個週幾）
* 跨裝置同步
* 推播系統（先用 UI 提示）

---

## 3. 核心模型

### 3.1 Task（任務）

* 有 dueDate
* 可完成 / 跳過 / 延期 / 取消
* 可逾期
* 可由規則產生下一筆

### 3.2 Timeline（時間軸）

* 有 startDate
* 不可完成
* 不會逾期
* 透過 Milestone 顯示重要日子

### 3.3 Milestone（重要日子）

* 屬於 Timeline
* 有 targetDate
* 可被「查看 / 忽略」
* 不會產生下一筆（非任務）

---

## 4. 狀態定義

### TaskTemplate

* active / paused / archived

### Task

* pending / done / skipped / canceled

### Timeline

* active / archived

### Milestone

* upcoming / noticed / skipped

---

## 5. Task 系統

### 5.1 類型

* oneTime
* recurring

### 5.2 ReminderRule

* advance（提前 N 天）
* onDue（當天）
* immediate（立即）

### 5.3 行為

完成 / 跳過：

* 更新狀態
* 若 recurring → 產生下一筆

延期：

* 更新 deferredDueDate

取消：

* Task → canceled
* 若 recurring 且來自 TaskTemplate → Template → paused

補充規則：

* 暫停 TaskTemplate 時，既有 pending Task 一律批次轉為 canceled
* 上述批次取消時，需清除 deferredDueDate
* archived TaskTemplate 為唯讀，不可再編輯

---

## 6. Timeline 系統

### 6.1 顯示

* 第 N 天 / 週 / 月 / 年

### 6.2 Milestone

來源：

* rule-based
* custom

### 6.3 提示規則

* advance（提前）
* onDay（當天）

### 6.4 使用者行為

* 查看（noticed）
* 忽略（skipped）

---

## 7. 首頁（Home）

### Tabs

1. Today
2. Upcoming
3. Overdue

### 7.1 Today

* Task（effectiveDueDate = today）
* Milestone（targetDate = today）

### 7.2 Upcoming

* 未來 Task
* 條件：
  * immediate：只要尚未到 dueDate，即列入 Upcoming
  * advance：已進入提醒期且 dueDate 仍在未來，列入 Upcoming
  * onDue：不列入 Upcoming
* 未來 Milestone
* 條件：
  * advance：已進入提醒期且 targetDate 仍在未來，列入 Upcoming
  * onDay：不列入 Upcoming

### 7.3 Overdue

* 只顯示 Task

---

## 8. 歷史

分為：

* Task History（done / skipped / canceled）
* Milestone History（noticed / skipped）

---

## 9. Wizard

### 9.1 Task

1. 輸入內容
2. 是否重複
3. 日期設定
4. 提醒設定

### 9.2 Timeline

1. 輸入內容
2. milestone 設定
3. 提醒設定

---

## 10. Data Model（MVP）

### TaskTemplate

* id
* title
* kind
* status
* firstDueDate
* repeatRule
* reminderRule

### Task

* id
* templateId
* kind
* dueDate
* deferredDueDate
* repeatRule
* reminderRule
* status

補充：

* oneTime Task 可直接建立於 `tasks`
* oneTime Task 允許 `templateId = null`
* Task 需保留 snapshot 欄位，避免後續 template 變更回寫歷史 Task

### Timeline

* id
* title
* startDate
* displayUnit
* status

### Milestone

* id
* timelineId
* targetDate
* description
* status

---

## 11. Domain 規則

* Task 與 Timeline 不可混用
* Milestone 不可進入 Overdue
* TaskTemplate 修改不影響既有 Task
* Milestone 不依使用者操作產生下一筆
* oneTime Task 不建立 TaskTemplate
* recurring Task 取消時，對應 TaskTemplate 需同步轉為 paused
* archived Timeline 為唯讀，不可再編輯

---

## 12. Migration 原則

舊系統需移除：

* trackingMode
* triggerMode

並改為：

* TaskTemplate + Task
* Timeline + Milestone

目前 schema 版本：

* `7`

---

## 13. MVP 優先順序

P0：

* Task / Timeline 分離
* Today / Upcoming / Overdue

P1：

* 完整 Task 行為
* Milestone 提示

P2：

* 進階規則
* UI 優化

---

## 14. 結論

本系統核心為：

* Task = 要完成的事
* Timeline = 經過的時間

所有設計需維持此分離原則。
