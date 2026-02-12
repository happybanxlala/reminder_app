# Reminder App MVP 規格說明文件

## 1. 文檔目的

本文件旨在詳細描述 Reminder App 的需求、功能特性與技術規格，以便 Codex
或開發者依此重構現有代碼、補齊遺漏、並實作下一階段功能。本文件作為開發藍圖與溝通依據。

------------------------------------------------------------------------

## 2. 項目概述

### 2.1 產品名稱

**Reminder App**

### 2.2 產品定位

一款運行於 iOS 和 Android 的本機 Reminder
應用，支援基礎提醒管理（CRUD）、桌面 Widget
展示、以及推播通知提醒功能。本階段重構重點先確保本機功能完整、代碼結構清晰、可維護性高。

### 2.3 主要目標

-   明確的資料存取抽象（Repository/DAO 分層）
-   統一狀態管理架構（Riverpod）
-   良好導航與畫面分層（go_router）
-   代碼可擴充、易於加入通知與 widget 模組

------------------------------------------------------------------------

## 3. 範圍與邊界

### 3.1 功能範圍（MVP）

-   提醒事項建立、編輯、刪除、完成標記
-   本機 SQLite/Drift 儲存
-   提醒時間與重複規則（none/daily/weekly）
-   單一資料 model 與清晰 repository/DAO 層
-   UI 展現列表與編輯表單
-   （已完成 Step 2，不含通知與 Widget）

### 3.2 非功能需求

-   UI/UX 平台風格一致，遵循 Material Design 與 iOS 基本指引
-   程式碼維護性高、單一責任原則
-   模組化、可測試性強
-   支援 Flutter null-safety

------------------------------------------------------------------------

## 4. 功能需求

### 4.1 Reminder Data Model

  |欄位         |型別        |說明|
  |------------ |----------- |--------------------------------|
  |id           |int         |主鍵，自動遞增|
  |title        |String      |主題，必填|
  |note         |String      |備註，選填|
  |dueAt        |DateTime?   |提醒時間，可為 null|
  |repeatRule   |int         |重複規則：0 無、1 每日、2 每週|
  |isDone       |bool        |是否完成|
  |createdAt    |DateTime    |建立時間|
  |updatedAt    |DateTime    |更新時間|

------------------------------------------------------------------------

## 5. 技術架構規範

### 5.1 資料存取層

#### 5.1.1 DAO / Drift Table

-   必須建立 Reminders table 定義
-   DAO 提供：
    -   watchAll(): 所有提醒
    -   watchTodayPending(): 今天未完成
    -   watchNextReminder(): 下一個未完成最早提醒
    -   insertReminder(), updateReminder(), deleteReminder()

#### 5.1.2 Repository

-   封裝 DAO，提供給上層使用
-   不暴露 SQL，統一回傳 domain model

#### 5.1.3 Providers

-   使用 Riverpod 提供以下 providers：
    -   remindersListProvider（stream）
    -   todayPendingProvider（stream）
    -   nextReminderProvider（單一值）
    -   reminderDetailProvider（未完成編輯）

------------------------------------------------------------------------

## 6. 路由設計

使用 go_router：

  Route           Params   描述
  --------------- -------- ---------------
  /               ―        Reminder 列表
  /reminder/new   ―        新增表單
  /reminder/:id   id       編輯表單

------------------------------------------------------------------------

## 7. UI 需求

### 7.1 Reminder 列表

-   顯示 title、dueAt（格式化）
-   swipe 可標記完成與刪除
-   點擊進入編輯頁
-   分隔已完成與未完成（可選）

### 7.2 Reminder 編輯

-   表單欄位：title、note、dueAt（日期時間）、repeatRule（下拉）
-   儲存／取消按鈕

------------------------------------------------------------------------

## 8. 非功能需求

### 8.1 效能

App 在 Android 與 iOS 主流裝置上，App 啟動與列表操作需 \< 200 ms。

### 8.2 可維護性

-   使用 descriptive 命名
-   單元測試與資料層測試覆蓋核心 logic
-   文件注釋明確

### 8.3 相容性

-   支援 iOS 13+、Android 8+

------------------------------------------------------------------------

## 9. 可擴充需求（未來階段）

-   通知排程：使用 local notification（安卓與 iOS 權限）
-   Widget 支援：顯示 nextReminder 或今日清單
-   雲端同步（可選）

------------------------------------------------------------------------

## 10. 代碼結構與分層規範

    lib/
      main.dart
      router.dart
      features/reminders/
        data/
          db/
            app_database.dart
            tables.dart
            daos.dart
          reminder_repository.dart
        domain/
          models.dart
          repeat_rule.dart
        services/
        ui/
          reminders_list_page.dart
          reminder_edit_page.dart
          widgets/
      shared/
        utils/

------------------------------------------------------------------------

## 11. 規格遵循原則

-   避免模糊敘述：使用具體欄位與行為定義（例如 dueAt 格式、repeatRule 數值）
-   所有需求應該可直接轉為 test 或 implementation
-   每個界面、每個路由與每個 provider 都有明確描述

------------------------------------------------------------------------

## 12. 驗收標準（Acceptance Criteria）

  |項目         |驗收條件|
  |------------ |-----------------------------------|
  |CRUD         |所有提醒能增、查、改、刪|
  |列表呈現     |未完成／今日提醒能正確顯示|
  |目標欄位     |重複規則可選（none/daily/weekly）|
  |路由         |路由跳轉無錯誤|
  |資料一致性   |list 與 detail 同步更新|
