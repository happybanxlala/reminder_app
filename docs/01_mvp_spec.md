# Reminder App MVP 規格說明文件（更新版）

## 1. 文檔目的

本文件定義 Reminder App MVP 的功能需求、技術規格、UI/UX 約束與驗收條件，作為後續開發、測試與重構的共同依據。

本版規格已依目前產品方向更新，重點如下：
- 使用者可見語言以「任務 / 習慣 / 固定時間 / 從某天開始」為主
- 新增流程採 step-based wizard
- 首頁資訊架構以「今天 / 接下來 / 已完成 / 習慣」為主
- presentation 已拆為 `text / formatters / view_models / wizard`
- 新增流程 page 僅負責 orchestration，step UI 與 wizard state 已拆開
- `RecurringReminder` 與 `Reminder` 的雙模型維持不變
- 本階段仍以日期精度提醒為核心，暫不支援精準時分通知

---

## 2. 項目概述

### 2.1 產品名稱
Reminder App

### 2.2 產品定位
一款運行於 iOS 與 Android 的本機提醒應用，聚焦於日常生活中容易忽略的事項，例如家務、照護、寵物、運動、固定習慣與從特定日期開始累積的事件。

### 2.3 主要目標
- 明確資料存取抽象（Repository / DAO 分層）
- 統一狀態管理（Riverpod）
- 清楚路由與畫面分層（go_router）
- 建立可維護的產品語言與 UI/UX 流程
- 可平滑擴充通知、Widget 與統計模組

### 2.4 UI 用語對照

本表只約束使用者看得到的 UI 文案與頁面標題，不代表 DB schema、domain model 或 enum 名稱必須同步修改。

| 內部/舊用語 | 使用者可見文案 | 備註 |
|---|---|---|
| 週期提醒 | 習慣 | 一般畫面使用 |
| 起計式提醒 | 從某天開始 | 用於重複方式選項 |
| 倒數式提醒 | 固定時間 | 用於重複方式選項 |
| Reminder | 任務 | 頁面標題、列表、表單使用 |
| RecurringReminder | 習慣模板 | 僅內部管理語境可使用 |
| trackingMode | 不直接顯示 | UI 需映射成「固定時間 / 從某天開始」 |
| triggerMode | 不直接顯示 | UI 需轉譯成可理解的提醒邏輯 |

補充約束：
- `countdown / accumulation` 仍保留為內部 enum case / 常數
- domain layer 不直接輸出 UI label
- UI label 一律經由 presentation mapper / formatter 產生

---

## 3. 範圍與邊界

### 3.1 功能範圍（MVP）
- 任務建立、編輯、刪除、完成、跳過、取消、恢復
- 本機 SQLite / Drift 儲存
- 支援單次任務與習慣模板
- 習慣模板支援兩種時間語意：
  - 固定時間
  - 從某天開始
- 完成或跳過後可依重複規則產生下一筆任務
- 首頁、習慣管理頁、建立/編輯頁
- 不含通知與 Widget 實作（僅保留擴充空間）

### 3.2 非功能需求
- 模組化、可測試、可維護
- Flutter null-safety
- 暫不處理跨時區需求（以裝置本地時間為準）
- 本階段以「日期精度」為主，不保證精準到時分秒的通知行為
- 不做 migration
- 不改 Drift schema
- 不重寫 repository lifecycle

---

## 4. 核心資料模型

### 4.1 設計原則
- `RecurringReminder` 用來描述具週期性規則的習慣模板
- `Reminder` 用來描述實際存在於列表中的任務實例
- 單次任務不需建立 `RecurringReminder`
- 習慣型任務需先建立 `RecurringReminder`，再建立首筆 `Reminder`
- `Reminder` 建立時需保留標題、備註、分類、時間設定的快照
- 後續修改 `RecurringReminder` 僅影響未來新產生的任務，不回寫既有任務
- `RecurringReminder.status = stopped` 表示暫停，可再次編輯與重新啟用
- `RecurringReminder.status = canceled` 表示永久終止，僅保留歷史資料，不可重新啟用
- `RecurringReminder.trackingMode` 在建立後視為不可變；若需切換類型，應建立新模板

### 4.2 RecurringReminder（習慣模板）
| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| status | int | 狀態：0 pending、1 stopped、2 canceled |
| title | String | 主題，必填 |
| note | String? | 備註，選填 |
| trackingMode | int | 內部欄位：countdown / accumulation；UI 不直接顯示 |
| triggerMode | int | 內部提醒策略；UI 不直接顯示 |
| triggerOffsetDays | int? | 固定時間表示提前 N 天；從某天開始表示累積滿 N 天後進入提醒期 |
| repeatRule | String? | 重複規則；`null` 表示不重複 |
| topicCategoryId | int? | 主題分類 |
| actionCategoryId | int? | 行動分類 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.3 Reminder（任務實例）
| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | PK，自動遞增 |
| recurringReminderId | int? | 來源模板；`null` 表示單次任務 |
| previousOccurrenceId | int? | 上一筆實例 id |
| trackingMode | int | 內部欄位；與模板建立當下快照一致 |
| triggerMode | int | 內部欄位；與模板建立當下快照一致 |
| status | int | 0 pending、1 done、2 skipped、3 canceled |
| title | String | 主題 |
| note | String? | 備註 |
| triggerOffsetDays | int? | 提醒偏移快照 |
| statusNote | String? | 操作補充 |
| dueAt | DateTime? | 固定時間目標日期；從某天開始通常為 `null` |
| startAt | DateTime | 起算日期 |
| deferredDueAt | DateTime? | 延後後的生效日期 |
| topicCategoryId | int? | 主題分類快照 |
| actionCategoryId | int? | 行動分類快照 |
| createdAt | DateTime | 建立時間 |
| updatedAt | DateTime | 更新時間 |

### 4.4 Repeat Rule 定義
- `null`：不重複
- 格式：`<type><interval>`，`interval >= 1`
- type 定義：
  - `D`：N 天後
  - `W`：N 週後
  - `M`：N 月後（曆月）
  - `Y`：N 年後（曆年）
- `RecurringReminder.status = stopped` 時不得再自動產生新任務
- `RecurringReminder.status = canceled` 時視為已終止，既有任務保留歷史資料
- `RecurringReminder` 由 `stopped` 重新啟用為 `pending` 時，需建立新的 pending 任務，不得恢復舊的已取消任務

---

## 5. 任務類型與時間規則

### 5.1 單次任務
- 使用者可建立只提醒一次的任務
- 單次任務不建立 `RecurringReminder`
- 單次任務至少需有日期
- 本階段 UI 若出現時間欄位，應明確標示目前仍以日期精度為主

### 5.2 習慣：固定時間
使用者語言：
- 每天
- 每週一
- 每月某日
- 每隔幾天

系統行為：
- `trackingMode = countdown`
- 必須有 `dueAt`
- 日期精度以日為準
- 若 `deferredDueAt != null`，則以 `deferredDueAt` 作為目前生效日期
- `triggerMode = 1` 時，當 `today >= effectiveDueAt - triggerOffsetDays` 進入提醒期
- `triggerMode = 2` 時，建立後即視為需提醒
- `triggerMode = 3` 時，僅在到期點或逾期後視為需提醒

### 5.3 習慣：從某天開始
使用者語言：
- 紀念日
- 第幾天
- 養寵物第幾天
- 戒某件事第幾天

系統行為：
- `trackingMode = accumulation`
- `dueAt = null`
- 以 `startAt` 為起點
- 當累積天數達到 `triggerOffsetDays` 後進入提醒期
- `triggerOffsetDays = 0` 表示起始日當天就可提醒
- UI 應可顯示預覽文案，例如：`今天是第 N 天`

### 5.4 完成、跳過、取消與下一筆生成
- 單次任務完成後不再產生下一筆
- 習慣任務完成後，若模板仍為 `pending` 且具 `repeatRule`，需自動產生下一筆
- 習慣任務跳過後，若模板仍為 `pending` 且具 `repeatRule`，需自動產生下一筆
- 取消任務不會產生下一筆
- 若取消的任務屬於習慣流程，系統可依產品規則將其模板轉為 `stopped`
- 重新啟用習慣模板時，系統應建立新的 pending 任務作為當前實例

---

## 6. 技術架構規範

### 6.1 資料存取層
#### 6.1.1 DAO / Drift Table
必須有：
- `recurring_reminders`
- `reminders`
- `topic_categories`
- `action_categories`

DAO 需提供的能力至少包含：
- `watchAll()`
- `watchActivePending()`
- `watchTodayPending()`
- `watchCompletedOrSkipped(limit)`
- `watchNextReminder()`
- `getRecurringReminderById()`
- `insertRecurringReminder()`
- `updateRecurringReminder()`
- `stopRecurringReminder()`
- `cancelRecurringReminder()`
- `insertReminder()`
- `updateReminder()`
- `deleteReminder()`
- `complete()`
- `commitCompleted(ids)`
- `skip()`
- `cancel()`
- `createNextReminderFromRecurringReminder()`
- `listTopicCategories()`
- `listActionCategories()`

#### 6.1.2 Repository
- 封裝 DAO，不暴露 SQL
- 對 UI 統一回傳 domain model
- 負責單次任務與習慣模板的建立流程：
  - 單次任務：直接建立 `Reminder`
  - 習慣：先建立 `RecurringReminder`，再建立首筆 `Reminder`
- 負責 `RecurringReminder` 與 `Reminder` 之間的快照映射
- 負責 staged completion 的批次正式提交流程
- 編輯 `RecurringReminder` 時，不允許修改既有模板的 `trackingMode`

#### 6.1.3 Providers（Riverpod）
至少包含：
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

### 6.2 Presentation / UI 映射層
- UI 不得直接顯示 `trackingMode`、`triggerMode` 等工程字眼
- 應透過 mapper / view model / formatter 統一轉譯成使用者語言
- `countdown` 對外顯示為 `固定時間`
- `accumulation` 對外顯示為 `從某天開始`
- widget 不應自行拼接首頁卡片、習慣模板卡片與狀態摘要字串
- 所有 UI 文案應集中於文字層，不可散落在 widget

#### 6.2.1 目前 presentation 結構
`lib/features/reminders/presentation/`
- `text/reminder_ui_text.dart`
- `formatters/reminder_formatters.dart`
- `view_models/reminder_card_view_model.dart`
- `view_models/recurring_template_view_model.dart`
- `wizard/reminder_wizard_draft.dart`
- `wizard/reminder_wizard_provider.dart`

原則：
- `ReminderUiText` 集中管理 UI 文案
- formatter 負責 consumer-facing 字串組裝
- view model 不直接內嵌散落的 widget 文案
- wizard draft 與 step widget 分離
- 單一 presentation 檔案不應再演變為大型 god file

---

## 7. 路由設計

| Route | Params | 描述 |
|---|---|---|
| `/` | - | 任務首頁 |
| `/reminder/new` | - | 新增任務 |
| `/reminder/:id` | id | 編輯任務 |
| `/recurring/new` | - | 新增習慣 |
| `/recurring/:id` | id | 編輯習慣 |

---

## 8. UI / UX 需求

### 8.1 首頁資訊架構
首頁採 Top Tab，分為四個分頁：
1. 今天
2. 接下來
3. 已完成
4. 習慣

### 8.2 今天
- 顯示今天需要優先處理的 pending 任務
- 固定時間任務主資訊顯示：`今天 / 明天 / 剩 X 天 / 逾期 X 天`
- 固定時間任務次資訊顯示：簡短規則摘要，如 `每天 / 每週`
- 從某天開始任務主資訊顯示：`第 N 天`
- 從某天開始任務次資訊顯示：起始日
- 可執行：完成、延後、跳過、取消
- 為主要日常入口

### 8.3 接下來
- 顯示近期將到來的 pending 任務
- 作為預告與安排用途
- 與「今天」分開，避免資訊過載
- 卡片規則與「今天」一致，仍以主資訊/次資訊/補充資訊呈現

### 8.4 已完成
- 顯示完成與跳過的任務歷史
- 依 `updatedAt` 由新到舊排序
- 主要用於回顧，不作為編輯入口

### 8.5 習慣
- 作為習慣模板管理頁，而非每日工作頁
- 顯示：
  - 標題
  - 類型標籤（固定時間 / 從某天開始）
  - 簡短規則摘要
  - 狀態
- 操作：
  - `pending`：可編輯 / 暫停 / 取消
  - `stopped`：可編輯 / 啟用
  - `canceled`：唯讀

補充：
- 視覺上應避免表格式堆疊
- 卡片應更接近日常產品，而非 admin panel
- 規則摘要與分類資訊應由 formatter 統一生成

### 8.6 新增任務流程（Wizard）
新增流程應採 step-based wizard，而非一次顯示所有技術欄位。

#### Step 1：輸入內容
- 你想提醒什麼？（必填）
- 分類（選填）
- 備註（選填）

#### Step 2：是否需要重複
選項：
- 不需要：只提醒一次
- 需要：系統會自動幫你安排下一次

#### Step 3：若需要重複，選擇方式
選項：
- 固定時間（例如每天、每週一）
- 從某天開始（例如紀念日、養寵物第幾天）

#### Step 4A：單次任務設定
- 日期（必填）
- 時間欄位若存在，需清楚標示目前仍以日期精度為主

#### Step 4B：固定時間設定
- 頻率
- 日期基準
- 必要時顯示規則摘要

#### Step 4C：從某天開始設定
- 起始日期
- 顯示方式：第幾天 / 第幾週 / 第幾年
- 必須顯示預覽文字，例如：`今天是第 N 天`

#### Wizard 結構約束
- page 只負責 orchestration
- state 集中在 wizard provider
- step widget 應拆分為：
  - `Step1InputWidget`
  - `Step2RepeatToggleWidget`
  - `Step3RepeatTypeWidget`
  - `Step4OnceWidget`
  - `Step4FixedWidget`
  - `Step4SinceStartWidget`

### 8.7 UX 約束
- UI 不應讓使用者先理解工程分類，再開始建立任務
- 類型選擇應延後到「已確認需要重複」之後再出現
- 設定頁不作為類型建立入口
- UI 不得直接出現「起計式」「倒數式」「trackingMode」「triggerMode」

---

## 9. 驗收條件

### 9.1 功能驗收
- 可建立單次任務
- 可建立固定時間的習慣
- 可建立從某天開始的習慣
- 習慣完成後會依規則產生下一筆
- 習慣跳過後會依規則產生下一筆
- 習慣取消後不產生下一筆
- 暫停中的習慣不再自動產生新任務
- 重新啟用習慣會建立新的 pending 任務

### 9.2 UI 驗收
- 首頁分頁為：今天 / 接下來 / 已完成 / 習慣
- 新增流程採 wizard
- 使用者看不到 `countdown / accumulation / trackingMode`
- 使用者可見語言為：
  - 任務
  - 習慣
  - 固定時間
  - 從某天開始

### 9.3 測試驗收
至少需涵蓋：
- tracking mode UI label 映射
- 新增流程 step 切換
- 選單次任務時不顯示重複方式
- 選習慣後才顯示固定時間 / 從某天開始
- 從某天開始時顯示預覽文案
- 完成 / 跳過 / 取消 / 暫停 / 重新啟用的 lifecycle 行為

目前測試落點應包含：
- widget test：wizard flow 與首頁/習慣頁互動
- repository test：recurring lifecycle

Repository lifecycle 至少應有獨立測試覆蓋：
- recurring done -> 產生下一筆
- recurring skip -> 產生下一筆
- cancel -> 不產生下一筆
- stop -> 取消 pending reminders
- reactivate -> 建立新 reminder

---

## 10. 本版刻意不處理的項目
- 精準時分通知
- 推播排程與通知權限流程
- Widget
- 跨時區
- 高階統計（streak、完成率）
- 複雜模板批次操作
