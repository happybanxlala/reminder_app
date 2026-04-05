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

- `RecurringReminder` 用來描述具週期性提醒的模板資料與後續產生規則。
- `Reminder` 用來描述實際存在於列表中的提醒實例，可為臨時提醒或由 `RecurringReminder` 產生。
- 臨時提醒不需建立 `RecurringReminder`，其 `recurringReminderId` 為 `null`。
- 具週期性提醒需先建立一筆 `RecurringReminder`，再建立首筆 `Reminder`。
- `Reminder` 建立時需保留標題、備註、分類、提醒設定的快照；後續修改 `RecurringReminder` 僅影響未來新產生的提醒，不回寫既有 `Reminder`。
- `RecurringReminder.status = stopped` 表示暫停中，可再次編輯與重新啟用。
- `RecurringReminder.status = canceled` 表示永久終止，僅保留歷史資料，不可重新啟用。

### 4.2 Recurring Reminder Data Model
| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| status | int | 狀態：0 pending、1 stopped、2 canceled |
| title | String | 主題，必填 |
| note | String? | 備註，選填 |
| trackingMode | int | 提醒類型：1 倒數式、2 起計式 |
| triggerMode | int | 提醒策略：1 進入範圍提醒、2 建立後立即提醒、3 到期才提醒 |
| triggerOffsetDays | int? | 提醒天數設定；倒數式表示提前 N 天，起計式表示累積滿 N 天開始提醒 |
| repeatRule | String? | 重複規則；`null` 表示不重複，例：D25、W3、M1、Y1 |
| topicCategoryId | int? | FK，主題分類 |
| actionCategoryId | int? | FK，行動分類 |
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
- `RecurringReminder.status = stopped` 時不得再自動產生新提醒。
- `RecurringReminder.status = canceled` 時視為已終止，既有提醒保留歷史資料。
- `RecurringReminder` 由 `stopped` 重新啟用為 `pending` 時，需建立一筆新的 `Reminder` 作為目前生效實例，不得恢復既有已取消的 reminder。

### 4.4 Reminder Data Model

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| recurringReminderId | int? | FK，來源 `RecurringReminder.id`；`null` 表示臨時提醒 |
| previousOccurrenceId | int? | FK，上一筆提醒實例 id，便於追蹤週期鏈 |
| trackingMode | int | 提醒類型：1 倒數式、2 起計式 |
| triggerMode | int | 提醒策略：1 進入範圍提醒、2 建立後立即提醒、3 到期才提醒 |
| status | int | 狀態：0 pending、1 done、2 skipped、3 canceled |
| title | String | 主題，必填 |
| note | String? | 備註，選填 |
| triggerOffsetDays | int? | 快照欄位；倒數式表示提前 N 天，起計式表示累積滿 N 天開始提醒 |
| statusNote | String? | 操作補充，例如跳過或取消原因 |
| dueAt | DateTime? | 倒數式目標時間；起計式固定為 `null` |
| startAt | DateTime | 起計基準時間；倒數式通常等於建立時間，起計式為累積計算起點 |
| deferredDueAt | DateTime? | 延期後的目標時間，可為 null |
| topicCategoryId | int? | FK，主題分類快照 |
| actionCategoryId | int? | FK，行動分類快照 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.5 Reminder 類型與提醒規則

- 倒數式提醒：
  - 必須有 `dueAt`
  - 時間精度以「日」為準，暫不處理時分秒
  - 若 `deferredDueAt != null`，則提醒期與剩餘天數計算皆優先使用 `deferredDueAt`
  - `triggerMode = 1` 時，當 `today >= effectiveDueAt - triggerOffsetDays` 進入提醒期
  - `triggerMode = 2` 時，建立後就需提醒
  - `triggerMode = 3` 時，僅在到期點或逾期後視為需提醒
  - 超出到期日子才算過期；例如到期日為 4 月 4 日，至 4 月 5 日才視為逾期
- 起計式提醒：
  - `dueAt = null`
  - 以 `startAt` 為起點，累積天數達到 `triggerOffsetDays` 後進入提醒期
  - 若為週期性提醒，下一筆提醒的 `startAt` 以新提醒建立時間為準
- `triggerOffsetDays = 0` 表示當天開始提醒
- 完成或跳過週期性提醒後，系統依 `repeatRule` 與當前提醒的基準時間產生下一筆提醒
- 取消提醒不會產生下一筆提醒
- 若取消的提醒屬於週期性提醒，需同時將其 `RecurringReminder.status` 轉為 `stopped`

### 4.6 Topic Category Data Model

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| name | String | 名稱 |
| description | String? | 補充說明 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.7 Action Category Data Model

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

- 必須有 `recurring_reminders` table
- 必須有 `reminders` table
- 必須有 `topic_categories` table
- 必須有 `action_categories` table
- DAO 需提供：
  - `watchAll()`
  - `watchActivePending()`
  - `watchTodayPending()`
  - `watchCompletedOrSkipped(limit)`
  - `watchNextReminder()`
  - `getRecurringReminderById()`
  - `insertRecurringReminder()` / `updateRecurringReminder()` / `stopRecurringReminder()` / `cancelRecurringReminder()`
  - `insertReminder()` / `updateReminder()` / `deleteReminder()`
  - `complete()` / `commitCompleted(ids)` / `skip()` / `cancel()`
  - `createNextReminderFromRecurringReminder()`
  - `listTopicCategories()` / `listActionCategories()`

#### 5.1.2 Repository

- 封裝 DAO，不暴露 SQL
- 對 UI 統一回傳 domain model
- 負責臨時提醒與週期性提醒的建立流程：
  - 臨時提醒：直接建立 `Reminder`
  - 週期性提醒：先建立 `RecurringReminder`，再建立首筆 `Reminder`
- 負責 `RecurringReminder` 與 `Reminder` 之間的快照映射
- 負責 staged completion 的批次正式提交流程

#### 5.1.3 Providers（Riverpod）

- `remindersListProvider`
- `activePendingProvider`
- `todayPendingProvider`
- `completedOrSkippedProvider`
- `nextReminderProvider`
- `reminderDetailProvider`
- `recurringRemindersProvider`
- `recurringReminderDetailProvider`
- `topicCategoriesProvider`
- `actionCategoriesProvider`

------------------------------------------------------------------------

## 6. 路由設計

| Route | Params | 描述 |
|---|---|---|
| `/` | - | Reminders 列表 |
| `/reminder/new` | - | 新增提醒 |
| `/reminder/:id` | id | 編輯提醒 |
| `/recurring/new` | - | 新增週期提醒 |
| `/recurring/:id` | id | 編輯週期提醒 |

------------------------------------------------------------------------

## 7. UI 需求

### 7.1 Reminders 列表頁（Top Tab）

分為三個分頁：

1. `進行中`
- 僅載入「未完成且進入提醒期」的提醒（status=0）
- 顯示：標題、提醒類型、分類標籤
- 倒數式顯示剩餘天數；若當天即為到期日，改顯示剩餘小時
- 起計式顯示已累積天數（由 `startAt` 計算）
- checkbox 可標記完成
- 倒數式提醒需提供 `延期` 按鈕；點擊後詢問延期多少天，並將新的 `deferredDueAt` 設為目前生效到期日再加上輸入天數
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

3. `週期提醒`
- 顯示所有 `RecurringReminder`
- 每筆需顯示：標題、狀態、提醒類型、重複規則、分類
- `pending` 可執行：`編輯`、`暫停`、`取消`
- `stopped` 可執行：`編輯`、`啟用`
- `canceled` 僅可檢視，不可編輯與不可重新啟用
- `暫停` 或 `取消` 時需彈出確認對話框，並明確提示會一併取消目前這個週期提醒所有未完成 reminders
- `啟用` 時需彈出選項對話框：
  - 倒數式：`今天＋時間間隔的日期`、`重新輸入到期時間`
  - 起計式：`今天開始起計`、`重新輸入起計時間`
- `啟用` 後需將 recurring reminder 狀態改回 `pending`，並建立一筆新的 pending reminder

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
- 若 `cancel` 的提醒屬於週期性提醒，確認對話框需明確提示會同時暫停所屬 `RecurringReminder`

### 7.3 Reminder 編輯頁

- 欄位：
  - `title`（必填）
  - `note`（選填）
  - `trackingMode`（倒數式 / 起計式）
  - `triggerMode`（倒數式：進入範圍提醒 / 建立後立即提醒 / 到期才提醒；起計式：累積達標後提醒）
  - `dueAt`（倒數式必填，日期精度）
  - `startAt`（起計式顯示，預設為建立時間，日期精度）
  - `triggerOffsetDays`（整數，>= 0）
  - `repeatRule`（type 下拉 + interval 輸入，interval >= 1）
  - `topicCategory`（選填）
  - `actionCategory`（選填）
- 操作按鈕：
  - `儲存`
  - `取消`
  - `[demo] 隨機生成欄位資料`
- 編輯規則：
  - 臨時提醒可直接編輯提醒內容
  - 週期性提醒編輯時需同步編輯 `RecurringReminder`
  - 已完成、已跳過、已取消的提醒不可直接編輯
  - 編輯 `RecurringReminder` 時不得修改 `trackingMode`
  - 編輯 `RecurringReminder` 時僅修改模板資料，不回寫既有 reminders 的 snapshot

### 7.4 Recurring Reminder 編輯與狀態流轉

- `RecurringReminder.status` 流轉規則：
  - `pending -> stopped`：需同時取消該 recurring reminder 目前所有 `pending` reminders
  - `pending -> canceled`：需同時取消該 recurring reminder 目前所有 `pending` reminders
  - `stopped -> pending`：需建立一筆新的 pending reminder
  - `canceled` 不可再轉回 `pending` 或 `stopped`
- `RecurringReminder` 重新啟用時：
  - 倒數式若選擇 `今天＋時間間隔的日期`，新 reminder 的 `dueAt` 需以 `today` 為基準，依 `repeatRule` 推算
  - 倒數式若選擇 `重新輸入到期時間`，需由使用者指定新 `dueAt`
  - 起計式若選擇 `今天開始起計`，新 reminder 的 `startAt = today`
  - 起計式若選擇 `重新輸入起計時間`，需由使用者指定新 `startAt`
- 重新啟用時不得復原既有已取消 reminders，必須建立新 reminder 承接後續週期

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
        recurring_reminder.dart
      repeat_rule.dart
      topic_category.dart
      action_category.dart
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
| 狀態流轉 | reminder pending 可轉 done / skipped / canceled；staged completion 可在正式提交前回到 pending 視圖；週期性 reminder canceled 時會同時將所屬 series 轉為 stopped |
| 提醒類型 | 倒數式與起計式皆可建立並正確顯示提醒狀態 |
| 重複規則 | 僅週期性提醒在 done / skipped 後可依 repeatRule 產生新提醒 |
| 進行中列表 | 僅顯示未完成且進入提醒期的提醒 |
| 起計式規則 | 起計式提醒可依 `startAt + triggerOffsetDays` 正確進入提醒期 |
| 暫時完成區 | 在進行中分頁完成後，項目暫時移到下方灰色區並可確認恢復，期間不得產生新 reminder |
| 手動批次完成 | 使用者可透過批次完成按鈕，立即正式提交暫時完成區內項目 |
| 會話清空 | 切換分頁或離開 App 後返回，灰色暫存區內項目會先正式完成並清空 |
| 倒數式顯示 | 倒數式提醒於到期當天顯示剩餘小時，超出到期日後才顯示逾期天數 |
| 完成/跳過列表 | 僅顯示前 30 筆，顯示狀態、updatedAt，以及對應的 `dueAt` 或 `startAt` |
| 編輯頁 | 支援 demo 隨機填值並可正常儲存 |
| 週期提醒 | 具備獨立分頁，可顯示 status、類型、repeatRule、分類，並依狀態提供 edit / stop / cancel / reactivate |
| 週期提醒狀態流轉 | recurring reminder pending 暫停或取消時會一併取消目前 pending reminders；stopped 可重新啟用並建立新 reminder；canceled 不可重新啟用 |
| 週期提醒編輯限制 | recurring reminder 編輯時不得修改 `trackingMode`，且不回寫既有 reminders snapshot |
| 分類資料 | 可為提醒指定 `topicCategory` 與 `actionCategory`，並於列表或明細顯示 |
| 路由 | `/`、`/reminder/new`、`/reminder/:id`、`/recurring/new`、`/recurring/:id` 跳轉正常 |

------------------------------------------------------------------------
