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
- 提醒事項主要分為兩類：倒數式、起計式
- 支援臨時提醒與具週期性提醒
- 到期時間、累積天數與重複規則
- 完成或跳過後可依重複規則產生下一筆提醒
- 列表頁與編輯頁
- 不含通知與 Widget 實作（僅保留擴充空間）

### 3.2 非功能需求

- 模組化、可測試、可維護
- Flutter null-safety
- 暫不處理跨時區需求（以裝置本地時間為準）


------------------------------------------------------------------------

## 4. 功能需求

### 4.1 資料模型設計原則

- `ReminderSeries` 用來描述具週期性提醒的模板資料與後續產生規則。
- `Reminder` 用來描述實際存在於列表中的提醒實例，可為臨時提醒或由 `ReminderSeries` 產生。
- 臨時提醒不需建立 `ReminderSeries`，其 `seriesId` 為 `null`。
- 具週期性提醒需先建立一筆 `ReminderSeries`，再建立首筆 `Reminder`。
- `Reminder` 建立時需保留標題、備註、分類、提醒設定的快照；後續修改 `ReminderSeries` 僅影響未來新產生的提醒，不回寫既有 `Reminder`。

### 4.2 Reminder Series Data Model
| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| status | int | 狀態：0 pending、1 stopped、2 canceled |
| title | String | 主題，必填 |
| note | String? | 備註，選填 |
| timeBasis | int | 時間基準：1 倒數式、2 起計式 |
| notifyStrategy | int | 提醒策略：1 進入範圍提醒、2 建立後立即提醒、3 到期才提醒 |
| remindDays | int? | 提醒天數設定；倒數式表示提前 N 天，起計式表示累積滿 N 天開始提醒 |
| repeatRule | String? | 重複規則；`null` 表示不重複，例：D25、W3、M1、Y1 |
| issueTypeId | int? | FK，內容分類 |
| handleTypeId | int? | FK，操作分類 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.3 Repeat Rule 定義

- `null`：不重複
- 格式：`<type><interval>`，`interval >= 1`
- type 定義：
  - `D`：N 天後
  - `W`：N 週後
  - `M`：N 月後（曆月）
  - `Y`：N 年後（曆年）
- `ReminderSeries.status = stopped` 時不得再自動產生新提醒。
- `ReminderSeries.status = canceled` 時視為已終止，既有提醒保留歷史資料。

### 4.4 Reminder Data Model

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| seriesId | int? | FK，來源 `ReminderSeries.id`；`null` 表示臨時提醒 |
| previousReminderId | int? | FK，上一筆提醒實例 id，便於追蹤週期鏈 |
| timeBasis | int | 時間基準：1 倒數式、2 起計式 |
| notifyStrategy | int | 提醒策略：1 進入範圍提醒、2 建立後立即提醒、3 到期才提醒 |
| status | int | 狀態：0 pending、1 done、2 skipped、3 canceled |
| title | String | 主題，必填 |
| note | String? | 備註，選填 |
| remindDays | int? | 快照欄位；倒數式表示提前 N 天，起計式表示累積滿 N 天開始提醒 |
| remark | String? | 操作補充，例如跳過或取消原因 |
| dueAt | DateTime? | 倒數式目標時間；起計式固定為 `null` |
| startAt | DateTime | 起計基準時間；倒數式通常等於建立時間，起計式為累積計算起點 |
| extendAt | DateTime? | 延期時間，可為 null |
| issueTypeId | int? | FK，內容分類快照 |
| handleTypeId | int? | FK，操作分類快照 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.5 Reminder 類型與提醒規則

- 倒數式提醒：
  - 必須有 `dueAt`
  - 時間精度以「日」為準，暫不處理時分秒
  - `notifyStrategy = 1` 時，當 `today >= dueAt - remindDays` 進入提醒期
  - `notifyStrategy = 2` 時，建立後就需提醒
  - `notifyStrategy = 3` 時，僅在到期點或逾期後視為需提醒
  - 超出到期日子才算過期；例如到期日為 4 月 4 日，至 4 月 5 日才視為逾期
- 起計式提醒：
  - `dueAt = null`
  - 以 `startAt` 為起點，累積天數達到 `remindDays` 後進入提醒期
  - 若為週期性提醒，下一筆提醒的 `startAt` 以新提醒建立時間為準
- `remindDays = 0` 表示當天開始提醒
- 完成或跳過週期性提醒後，系統依 `repeatRule` 與當前提醒的基準時間產生下一筆提醒
- 取消提醒不會產生下一筆提醒

### 4.6 Issue Type Data Model

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| name | String | 名稱 |
| description | String? | 補充說明 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.7 Handle Type Data Model

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| name | String | 名稱 |
| description | String? | 補充說明 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

------------------------------------------------------------------------

## 5. 技術架構規範

### 5.1 資料存取層

#### 5.1.1 DAO / Drift Table

- 必須有 `reminder_series` table
- 必須有 `reminders` table
- 必須有 `issue_types` table
- 必須有 `handle_types` table
- DAO 需提供：
  - `watchAll()`
  - `watchActivePending()`
  - `watchTodayPending()`
  - `watchCompletedOrSkipped(limit)`
  - `watchNextReminder()`
  - `getSeriesById()`
  - `insertSeries()` / `updateSeries()` / `stopSeries()` / `cancelSeries()`
  - `insertReminder()` / `updateReminder()` / `deleteReminder()`
  - `complete()` / `commitCompleted(ids)` / `skip()` / `cancel()`
  - `createNextReminderFromSeries()`
  - `listIssueTypes()` / `listHandleTypes()`

#### 5.1.2 Repository

- 封裝 DAO，不暴露 SQL
- 對 UI 統一回傳 domain model
- 負責臨時提醒與週期性提醒的建立流程：
  - 臨時提醒：直接建立 `Reminder`
  - 週期性提醒：先建立 `ReminderSeries`，再建立首筆 `Reminder`
- 負責 `ReminderSeries` 與 `Reminder` 之間的快照映射
- 負責 staged completion 的批次正式提交流程

#### 5.1.3 Providers（Riverpod）

- `remindersListProvider`
- `activePendingProvider`
- `todayPendingProvider`
- `completedOrSkippedProvider`
- `nextReminderProvider`
- `reminderDetailProvider`
- `issueTypesProvider`
- `handleTypesProvider`

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
- 顯示：標題、提醒類型、分類標籤
- 倒數式顯示剩餘天數；若當天即為到期日，改顯示剩餘小時
- 起計式顯示已累積天數（由 `startAt` 計算）
- checkbox 可標記完成
- 左右滑操作：`skip`、`cancel`
- `cancel` 需彈出確認對話框
- 長按 2 秒可進入編輯

2. `完成/跳過`
- 顯示 status=1 或 status=2
- 依 `updatedAt` 由新到舊排序
- 僅顯示前 30 筆
- 列表上方需顯示提示文案：`僅顯示近期 30 筆資料`
- 每筆需顯示：狀態、更新時間、提醒類型
- 倒數式顯示 `dueAt`
- 起計式顯示 `startAt`
- 完成與跳過需有不同顏色標記
- 不可直接編輯

### 7.2 「進行中」分頁的暫時完成區（可後悔機制）

- 使用者在 `進行中` 分頁將提醒標記完成後：
  - 該項目先從未完成區移除
  - 暫時顯示於同頁下方灰色區塊（文案：已完成可恢復）
  - 此時僅視為「暫時完成」，不得立即寫入正式 `done`
  - 若該提醒屬於週期性提醒，此時不得立即產生下一筆 reminder
- 點擊灰色項目時：
  - 需彈出確認對話框
  - 確認後回到未完成區
- 此灰色暫存區僅在「當前進行中會話」有效：
  - 使用者可透過手動批次提交按鈕，立即將暫存區內項目正式完成
  - 若切換到其他分頁或離開頁面 / App 再回來，需先將暫存區內項目批次正式完成，再清空暫存區
  - 回到進行中分頁時僅顯示最新未完成項目
- `skip` 與 `cancel` 為立即生效操作，不進入可後悔暫存區

### 7.3 Reminder 編輯頁

- 欄位：
  - `title`（必填）
  - `note`（選填）
  - `timeBasis`（倒數式 / 起計式）
  - `notifyStrategy`（倒數式：進入範圍提醒 / 建立後立即提醒 / 到期才提醒；起計式：累積達標後提醒）
  - `dueAt`（倒數式必填，日期精度）
  - `startAt`（起計式顯示，預設為建立時間，日期精度）
  - `remindDays`（整數，>= 0）
  - `repeatRule`（type 下拉 + interval 輸入，interval >= 1）
  - `issueType`（選填）
  - `handleType`（選填）
- 操作按鈕：
  - `儲存`
  - `取消`
  - `[demo] 隨機生成欄位資料`
- 編輯規則：
  - 臨時提醒可直接編輯提醒內容
  - 週期性提醒編輯時需同步編輯 `ReminderSeries`
  - 已完成、已跳過、已取消的提醒不可直接編輯

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
      reminder_series.dart
      repeat_rule.dart
      issue_type.dart
      handle_type.dart
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
| 狀態流轉 | pending 可轉 done / skipped / canceled；staged completion 可在正式提交前回到 pending 視圖 |
| 提醒類型 | 倒數式與起計式皆可建立並正確顯示提醒狀態 |
| 重複規則 | 僅週期性提醒在 done / skipped 後可依 repeatRule 產生新提醒 |
| 進行中列表 | 僅顯示未完成且進入提醒期的提醒 |
| 起計式規則 | 起計式提醒可依 `startAt + remindDays` 正確進入提醒期 |
| 暫時完成區 | 在進行中分頁完成後，項目暫時移到下方灰色區並可確認恢復，期間不得產生新 reminder |
| 手動批次完成 | 使用者可透過批次完成按鈕，立即正式提交暫時完成區內項目 |
| 會話清空 | 切換分頁或離開 App 後返回，灰色暫存區內項目會先正式完成並清空 |
| 倒數式顯示 | 倒數式提醒於到期當天顯示剩餘小時，超出到期日後才顯示逾期天數 |
| 完成/跳過列表 | 僅顯示前 30 筆，顯示狀態、updatedAt，以及對應的 `dueAt` 或 `startAt` |
| 編輯頁 | 支援 demo 隨機填值並可正常儲存 |
| 分類資料 | 可為提醒指定 `issueType` 與 `handleType`，並於列表或明細顯示 |
| 路由 | `/`、`/reminder/new`、`/reminder/:id` 跳轉正常 |

------------------------------------------------------------------------
