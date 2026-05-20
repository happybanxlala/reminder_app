請協助重構 Reminder App 的 Item 管理頁 UI，使它和 Home compact card 的視覺語言一致，但保留管理頁的 Pack 分組與管理用途。

請先閱讀並遵守以下文件與現有實作：

- docs/core/04_core_model_spec_v1.md
- docs/ui/visual_direction.md
- lib/app/theme/reminder_theme.dart
- lib/features/reminders/ui/widgets/reminder_components.dart
- lib/features/reminders/ui/pages/feature_management_sections.dart
- lib/features/reminders/ui/pages/feature_management_items.dart
- lib/features/reminders/presentation/view_models/management_item_card_view_model.dart
- lib/features/reminders/presentation/formatters/reminder_formatters.dart
- lib/features/reminders/presentation/text/reminder_ui_text.dart
- lib/features/reminders/providers/item_providers.dart
- lib/features/reminders/data/item_repository.dart
- lib/features/reminders/data/local/reminder_dao.dart

---

## 1. 目標

Item 管理頁目前仍偏向 comfortable card layout，card 高度較大，單頁可見 item 數量偏少。

請將 Item 管理頁改成 compact-management layout，使它和 Home compact UI 更一致。

核心目標：

- 保留 Pack 分組
- Pack groups 預設全部展開
- 單頁能看到更多 items
- Item row 未展開時顯示：
  - status rail
  - item title
  - 小字 type：固定 / 彈性
  - 一句最重要狀態 / 設定摘要
  - overflow menu
- 移除未展開 row 內的大 icon bubble
- 移除 type badge
- 移除 status badge
- 移除 row 上的 edit icon
- 編輯功能移入 overflow menu
- Item row 點擊仍可打開 summary dialog
- 不做 item inline expand

---

## 2. Compact management density

請只調整 Item 管理頁，不要全 app 縮小。

可在 `feature_management_items.dart` 或適合位置新增私有 density constants，例如：

```dart
class _ManagementDensity {
  const _ManagementDensity._();

  static const pagePadding = 12.0;
  static const groupGap = 8.0;
  static const itemGap = 6.0;
  static const groupPadding = 10.0;
  static const itemPaddingVertical = 7.0;
  static const itemPaddingHorizontal = 10.0;
  static const cardRadius = 16.0;
  static const packChipSize = 26.0;

  static const itemPadding = EdgeInsets.symmetric(
    vertical: itemPaddingVertical,
    horizontal: itemPaddingHorizontal,
  );
}
```

或用你認為更符合現有架構的方式。

不要直接修改全域 `ReminderSpacing.card` / `ReminderRadius.card`，避免影響 Home、Resource、Stage、Editor 等頁面。

---

## 3. Pack group layout

Item 管理頁仍然按 Pack 分組。

Pack groups 預設全部展開，方便使用者快速掃全部 items。

目前 `_ItemsManagementContentState` 使用 `_expandedPackIds`，請調整成：

* groups 載入後，預設所有 pack id 都視為 expanded
* 使用者仍可手動收合 / 展開某個 pack
* 如果後續 groups 更新新增 pack，新增 pack 預設 expanded
* 不要因 rebuild 把使用者手動收合狀態一直重設

Pack header 請改成 compact row。

建議未展開/展開 header：

```text
🐱 養貓                         6 項    ＋  ˄
```

保留：

* 小型 pack emoji chip
* pack title
* item count
* add item icon
* expand/collapse icon

移除或隱藏：

* 大型 `ReminderIconBubble(size: 40)`
* item count `ReminderBadge`
* 大面積 header padding
* 未展開狀態下的 pack description

Pack description 如要保留，只在 expanded 狀態下用小字顯示，並且不要佔太多高度。

---

## 4. Managed item compact row

請將 `_ManagedItemCard` 從目前的「大卡片 + icon bubble + badges」改成 compact rail row。

未展開 row 基本結構：

```text
status rail | title | type + summary | overflow
```

例子：

```text
| 清貓砂              彈性・2 天未處理        ⋮
| 繳電費              固定・每月 15 日        ⋮
| 飲水器濾芯          彈性・已暫停            ⋮
```

保留：

* `ReminderRailCard`
* status rail color
* item title
* 小字 type：固定 / 彈性
* 一句最重要狀態 / 設定摘要
* overflow icon

移除未展開 row 內：

* `ReminderIconBubble(size: 44)`
* type badge
* status badge
* edit icon
* 大量 vertical spacing

注意：

* status rail 仍然保留，讓 normal/warning/danger/paused 可視覺辨識
* status 不再用 badge 表示
* type 不再用 badge 表示，只用小字 inline text
* item row 不做 inline expand
* 點擊 item row body 繼續打開 `showItemSummaryDialog`
* overflow menu 保留所有管理操作

---

## 5. Overflow menu 調整

目前 row 上有 edit icon 與 overflow icon。

請移除 row 上獨立 edit icon。

編輯功能要移入 overflow menu。

`_ManagedItemMenuAction` 請加入或保留 edit/details 的清楚分工：

建議 overflow menu 包含：

* 編輯
* 完成，如可用
* 略過，如可用
* 詳情
* 歷史紀錄
* 暫停 / 恢復
* 封存

如果現有 `details` 是 summary dialog，請保留。
新增 `edit` action 需導航到 `ItemEditPage.editRouteName`。

排序建議：

```text
編輯
詳情
歷史紀錄
---
完成
略過
---
暫停 / 恢復
封存
```

或如果你認為「完成 / 略過」更常用，也可放前面，但請保持 destructive action 在最後。

---

## 6. Item row summary

請使用 `ManagementItemCardViewModel` 或 formatter 建立 compact summary。

未展開 row 建議顯示：

```text
{typeLabel}・{statusOrScheduleSummary}
```

例子：

```text
固定・每週
固定・每月 15 日
彈性・2 天未處理
彈性・已暫停
固定・今天到期
彈性・危險
```

如果現有 view model 沒有足夠欄位，請小幅擴充 `ManagementItemCardViewModel`，不要在 widget 內塞太多 domain 判斷。

請避免顯示 raw enum / technical terms，例如：

* `fixed`
* `stateBased`
* `warningAfter`
* `dangerBefore`
* `lifecycle status`

UI 文案應使用現有 `ReminderUiText` / `ReminderFormatters` 風格。

---

## 7. Header actions compact

Item 管理頁頂部目前可能顯示：

* 資源管理 button
* 新增 item button

請縮小成更 compact 的 header actions。

建議：

```text
要照顧的事                         [資源 icon] [＋]
```

要求：

* 保留「資源管理」入口
* 保留「新增 item」入口
* 可以改為 icon button + tooltip
* 不要讓兩個大 button 佔掉太多垂直空間
* accessibility label / tooltip 要清楚

---

## 8. Empty state

Empty state 也請 compact。

如果某個 pack expanded 但沒有 items：

* 使用 compact empty row
* 不要使用太高的 `ReminderEmptyState` 大卡片
* 文案可沿用 `ReminderUiText.emptyPackHint`

整頁沒有 groups 時仍可保留較完整 empty state，但 spacing 應配合 compact management density。

---

## 9. 不要做的事

請不要在本 prompt 中做：

* 不要改變 Item / Resource / StageTracker domain model
* 不要改 Drift schema
* 不要重做 Home UI
* 不要重做 Resource 管理頁
* 不要重做 StageTracker 管理頁
* 不要新增 undo / reverted 行為
* 不要改變 Item status 推導
* 不要移除 Pack 分組
* 不要做 item inline expand
* 不要把 edit action 完全移除，只是移進 overflow
* 不要把所有 app spacing 全域縮小

---

## 10. 測試要求

請新增或更新 widget tests，至少覆蓋：

1. Item 管理頁仍按 Pack 分組顯示
2. Pack groups 預設全部展開
3. 使用者可以收合 / 展開 pack group
4. 新增 pack group 或資料更新後，新 pack 預設 expanded，如測試架構方便
5. Managed item row 不顯示大型 type icon bubble
6. Managed item row 不顯示 type badge
7. Managed item row 不顯示 status badge
8. Managed item row 顯示 title
9. Managed item row 顯示固定 / 彈性小字 type
10. Managed item row 顯示 compact summary
11. Managed item row 不顯示獨立 edit icon
12. Overflow menu 中可以找到「編輯」
13. 點擊 overflow 的「編輯」會導航到 edit route
14. 點擊 item row body 仍會打開 summary dialog
15. Header 的資源管理與新增 item 入口仍存在，且為 compact icon action 或等效 compact UI
16. 畫面 smoke test 無 overflow

如既有測試依賴 edit icon key，請更新測試為 overflow menu edit action。

---

## 11. 文件更新

請更新：

* docs/ui/visual_direction.md

加入 Implementation note，說明：

* Item 管理頁採用 compact-management density
* Item 管理頁保留 Pack 分組
* Pack groups 預設全部展開
* Managed item row 改為 compact rail row
* 未展開 row 不再顯示大 icon bubble、type badge、status badge
* 編輯操作移入 overflow menu
* Home 與管理頁共享 compact visual language，但管理頁仍保留 Pack organization 與 management actions

如果 core 行為沒有改變，不需要更新 core spec。

---

## 12. 驗證

完成後請執行：

```bash
dart format lib test docs
flutter analyze
flutter test
```

最後請回報：

1. 修改了哪些主要檔案
2. Pack group 預設展開如何實作
3. Managed item row 新版 layout
4. Overflow menu 如何保留 edit
5. 測試結果
6. 有沒有任何 TODO 或限制

```

這個 prompt 可以作為下一個 UI 收斂切片。它不碰資料模型，風險相對低，但會明顯改善「管理頁太胖」的問題。
```
