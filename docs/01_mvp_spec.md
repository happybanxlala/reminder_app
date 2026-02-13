# Reminder App MVP 規格說明文件

## 1. 文檔目的

本文件定義 Reminder App MVP 的功能需求、技術規格與驗收條件，作為後續開發、測試與重構的共同依據。

------------------------------------------------------------------------

## 2. 項目概述

### 2.1 產品名稱

**Reminder App**

### 2.2 產品定位

一款運行於 iOS 與 Android 的本機提醒應用，聚焦於提醒事項管理（CRUD）、重複規則與可維護架構。

### 2.3 主要目標

- 明確資料存取抽象（Repository / DAO 分層）
- 統一狀態管理（Riverpod）
- 清楚路由與畫面分層（go_router）
- 可平滑擴充通知與 Widget 模組

------------------------------------------------------------------------

## 3. 範圍與邊界

### 3.1 功能範圍（MVP）

- 提醒事項建立、編輯、刪除、完成、跳過、取消、恢復
- 本機 SQLite / Drift 儲存
- 到期時間與重複規則
- 完成或跳過後可依重複規則產生下一筆提醒
- 列表頁與編輯頁
- 不含通知與 Widget 實作（僅保留擴充空間）

### 3.2 非功能需求

- 模組化、可測試、可維護
- Flutter null-safety
- 暫不處理跨時區需求（以裝置本地時間為準）

------------------------------------------------------------------------

## 4. 功能需求

### 4.1 Reminder Data Model

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | 主鍵，自動遞增 |
| startId | int | 提醒串首筆 id；首筆建立後需回填為自身 id |
| status | int | 狀態：0 pending、1 done、2 skipped、3 canceled |
| title | String | 主題，必填 |
| note | String? | 備註，選填 |
| remindDays | int | 提前提醒天數，允許 0（當天/即時） |
| dueAt | DateTime? | 到期時間，可為 null |
| repeatRule | String? | 重複規則，例：D25、W3、N1、Y1 |
| extendAt | DateTime? | 延期時間，可為 null |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.2 Repeat Rule 定義

- `null`：不重複
- 格式：`<type><interval>`，`interval >= 1`
- type 定義：
  - `D`：每 N 天
  - `W`：每 N 週
  - `N`：每 N 月（曆月）
  - `Y`：每 N 年（曆年）

------------------------------------------------------------------------

## 5. 技術架構規範

### 5.1 資料存取層

#### 5.1.1 DAO / Drift Table

- 必須有 `reminders` table
- DAO 需提供：
  - `watchAll()`
  - `watchActivePending()`
  - `watchTodayPending()`
  - `watchCompletedOrSkipped(limit)`
  - `watchNextReminder()`
  - `insertReminder()` / `updateReminder()` / `deleteReminder()`
  - `complete()` / `skip()` / `cancel()` / `restore()`
  - `createRepeatReminder()`

#### 5.1.2 Repository

- 封裝 DAO，不暴露 SQL
- 對 UI 統一回傳 domain model

#### 5.1.3 Providers（Riverpod）

- `remindersListProvider`
- `activePendingProvider`
- `todayPendingProvider`
- `completedOrSkippedProvider`
- `nextReminderProvider`
- `reminderDetailProvider`

------------------------------------------------------------------------

## 6. 路由設計

| Route | Params | 描述 |
|---|---|---|
| `/` | - | Reminders 列表 |
| `/reminder/new` | - | 新增提醒 |
| `/reminder/:id` | id | 編輯提醒 |

------------------------------------------------------------------------

## 7. UI 需求

### 7.1 Reminders 列表頁（Top Tab）

分為兩個分頁：

1. `進行中`
- 僅載入「未完成且進入提醒期」的提醒（status=0）
- 顯示：標題、剩餘天數（由 dueAt 計算）
- checkbox 可標記完成
- 左右滑操作：`skip`、`cancel`
- `cancel` 需彈出確認對話框
- 長按 2 秒可進入編輯

2. `完成/跳過`
- 顯示 status=1 或 status=2
- 依 `updatedAt` 由新到舊排序
- 僅顯示前 30 筆
- 列表上方需顯示提示文案：`僅顯示近期 30 筆資料`
- 每筆需顯示：狀態、更新時間、到期時間
- 完成與跳過需有不同顏色標記
- 不可直接編輯

### 7.2 「進行中」分頁的暫時完成區（可後悔機制）

- 使用者在 `進行中` 分頁將提醒標記完成後：
  - 該項目先從未完成區移除
  - 暫時顯示於同頁下方灰色區塊（文案：已完成可恢復）
- 點擊灰色項目時：
  - 需彈出確認對話框
  - 確認後恢復為未完成（status=0）
- 此灰色暫存區僅在「當前進行中會話」有效：
  - 若切換到其他分頁或離開頁面 / App 再回來，暫存區清空
  - 回到進行中分頁時僅顯示最新未完成項目

### 7.3 Reminder 編輯頁

- 欄位：
  - `title`（必填）
  - `note`（選填）
  - `dueAt`（日期時間）
  - `remindDays`（整數，>= 0）
  - `repeatRule`（type 下拉 + interval 輸入，interval >= 1）
- 操作按鈕：
  - `儲存`
  - `取消`
  - `[demo] 隨機生成欄位資料`

------------------------------------------------------------------------

## 8. 非功能需求

### 8.1 效能

- Android / iOS 主流裝置上，啟動與列表操作應保持流暢

### 8.2 可維護性

- 清晰命名與單一責任
- 核心邏輯需有測試覆蓋
- 規格與實作保持同步

### 8.3 相容性

- iOS 13+
- Android 8+

------------------------------------------------------------------------

## 9. 可擴充需求（未來階段）

- Local notification 排程
- Widget 顯示 next reminder 或今日清單
- 雲端同步（選配）

------------------------------------------------------------------------

## 10. 代碼結構與分層規範

```text
lib/
  app/
  features/reminders/
    data/
      local/
        app_database.dart
        tables.dart
        daos.dart
      reminder_repository.dart
    domain/
      reminder.dart
      repeat_rule.dart
      demo_reminder_draft.dart
    ui/
      pages/
        reminders_list_page.dart
        reminder_edit_page.dart
      widgets/
```

------------------------------------------------------------------------

## 11. 規格遵循原則

- 規格描述必須可直接轉為實作與測試
- 每個狀態轉換必須有明確觸發條件
- 每個 UI 互動需有可驗收結果

------------------------------------------------------------------------

## 12. 驗收標準（Acceptance Criteria）

| 項目 | 驗收條件 |
|---|---|
| CRUD | 可建立、查詢、編輯、刪除提醒 |
| 狀態流轉 | pending 可轉 done / skipped / canceled；done 可恢復 pending |
| 重複規則 | done / skipped 後可依 repeatRule 產生新提醒 |
| 進行中列表 | 僅顯示未完成且進入提醒期的提醒 |
| 暫時完成區 | 在進行中分頁完成後，項目暫時移到下方灰色區並可確認恢復 |
| 會話清空 | 切換分頁或離開 App 後返回，灰色暫存區不再顯示 |
| 完成/跳過列表 | 僅顯示前 30 筆，顯示狀態、updatedAt、dueAt |
| 編輯頁 | 支援 demo 隨機填值並可正常儲存 |
| 路由 | `/`、`/reminder/new`、`/reminder/:id` 跳轉正常 |
