
# Visual Direction

本文件定義 Reminder App 的 UI 視覺方向。後續 app 頁面、widget、component、icon、色彩與 layout 設計，應以本文件作為基準。

Reminder App 不是一般 todo list，也不是企業任務管理工具。它是一個幫助使用者看見生活中「會被忽略、會變糟、會耗盡、會到來」的提醒工具。

核心視覺目標：

> 把快被忽略的生活責任，整理成安心可處理的今日清單。

---

## 1. Product Feeling

### 1.1 核心氣質

Reminder App 的整體感覺應是：

- 清爽
- 有效率
- 有生活感
- 溫暖但不幼稚
- 明確但不焦慮
- 像一本整理好的生活手帳，而不是企業 dashboard

它應該讓使用者覺得：

> 「我知道今天有什麼需要處理，而且這些事被整理得很清楚。」

不是：

> 「我又被一個 app 罵了。」

也不是：

> 「這只是另一個普通 todo list。」

---

## 2. Visual Style Keywords

主要關鍵字：

- Warm utility
- Life dashboard
- Soft stationery
- Clear attention
- Calm urgency
- Organized care

中文語感：

- 清爽
- 暖
- 生活化
- 明確
- 不雜亂
- 不責備
- 有一點手帳感

---

## 3. Visual Metaphor

### 3.1 主要隱喻：生活手帳 + 今日儀表板

UI 可以帶有手帳、紙片、分類貼紙、生活索引的感覺，但資訊架構仍然要像一個清楚的 dashboard。

適合的視覺元素：

- 暖米白背景
- 柔和卡片
- 左側狀態條
- 小型 badge
- emoji 作為生活場景標記
- 清楚的 section title
- 克制的狀態色
- 輕量分隔線
- 紙片式區塊

避免：

- 過多裝飾
- 大量插畫
- 過度遊戲化
- 太多顏色同時出現
- 卡片陰影太重
- 資訊密度失控

---

## 4. Color Direction

### 4.1 主色方向

主色建議使用 Warm Orange / Amber 系列。

用途：

- Primary action
- Selected state
- Important highlight
- Floating action button
- Navigation active state
- Summary emphasis

主色不應過度鮮艷，應偏暖、偏生活、偏安心。

建議語感：

```text
Amber / Warm Orange
不是警告橙，而是生活感的暖橙。
```

---

### 4.2 背景色

整體背景應使用暖米白，而不是純白或冷灰。

建議方向：

```text
App background: warm off-white / cream
Card background: white or very light cream
Surface variant: soft beige / warm grey
```

暖米白的作用：

* 降低工具感
* 增加生活手帳感
* 讓 warning / danger 更容易分層
* 減少長時間使用的疲勞感

---

### 4.3 狀態色

Reminder App 有明確的 attention status：

* normal
* warning
* danger
* unknown

狀態色應採用「分層情緒」：

* warning：溫柔提醒，不製造壓力
* danger：明確需要處理，但避免刺眼紅色
* normal：穩定、安心
* unknown：中性、等待補資料

建議：

```text
normal: soft green / calm neutral
warning: soft amber / warm yellow
danger: soft red / coral red
unknown: warm grey
```

狀態色應優先用在：

* 左側狀態條
* small badge
* icon background
* subtle label
* summary number

避免整張卡片大面積高飽和變色。

---

## 5. Shape Language

### 5.1 整體形狀

形狀應偏手帳紙片感：

* 中高圓角
* 柔和邊界
* 清楚分組
* 少量陰影
* 可用淡 border 取代重陰影

建議：

```text
Cards: 16–24 px radius
Small badges: pill shape
Buttons: rounded, not sharp
Bottom navigation: Material 3 base, visual customized lightly
```

---

### 5.2 Card Style

主要卡片不建議整張用強烈狀態背景。

推薦 card pattern：

```text
Card = light surface + left status rail + content + compact actions
```

也就是：

* 卡片本體保持乾淨
* 左側一條狀態色表示 normal / warning / danger
* 內容區維持高可讀性
* badge 補充類型資訊
* action 不要太多，避免雜亂

這比目前「有色 header card」更適合後續統一 Item / Resource / StageTracker，因為它可以讓三種 domain 各自有 icon / badge / metadata，同時保持整體一致。

---

## 6. Information Density

### 6.1 整體密度

資訊密度應是中等。

不要極簡到需要一直點開，也不要完整到一眼太吵。

預設卡片應顯示：

* 標題
* 所屬生活場景 emoji
* 類型 badge
* 目前狀態
* 最重要的一句時間/數量摘要
* 主要 action

次要資訊放入：

* 展開區
* detail page
* overflow menu
* history page

---

### 6.2 Progressive Disclosure

Reminder App 應大量使用漸進式揭露。

卡片預設只顯示「我現在需要知道什麼」。

展開後才顯示：

* 開始日期
* 到期日期
* 提醒策略
* 逾期策略
* 來源 Stage
* 歷史入口
* 更多操作

原則：

> 預設畫面讓人安心；展開畫面才讓人深入管理。

---

## 7. Home Direction

### 7.1 Home 是今日儀表板

Home 頁應偏向「提醒儀表板」，而不是單純列表。

Home 的主要任務：

1. 告訴使用者今天有多少事需要注意。
2. 明確區分需要處理、要留意、即將到來。
3. 讓使用者能快速完成、知道了、補充或進入管理。
4. 透過生活場景 filter 降低資訊量。

Home 首屏應優先呈現：

* Attention summary
* Pack filter
* Critical attention cards

---

### 7.2 Attention Summary

Attention summary card 應是 Home 的視覺重心。

它應該清楚回答：

```text
今天有幾件事需要處理？
有幾件快變糟？
有幾件資源不足？
有幾個階段快到了？
```

語氣應明確，但不責備。

推薦文案風格：

```text
今天有 3 件事需要處理
2 件需要處理・1 件要留意・1 個階段快到了
```

避免：

```text
你又忘記了
嚴重逾期
警告！
```

---

## 8. Domain Visual Differentiation

Item、Resource、StageTracker 在 domain 上是不同概念，視覺上也應明顯不同。

但它們不應變成三套完全不同的 design system。

原則：

```text
Same layout system, different semantic identity.
```

---

### 8.1 Item：要照顧的事

Item 是「要做、要處理、要完成」的責任。

視覺語言：

* checkbox / check action
* task-like card
* status rail
* due / elapsed time summary
* fixed / state-based badge

建議 icon 語感：

* checklist
* check circle
* calendar check
* recurring rhythm

Item card 主要回答：

```text
這件事現在要不要做？
離期限還有多久？
上次處理是多久前？
```

---

### 8.2 Resource：要留意的資源

Resource 是「會耗盡、要補充、要留意存量」的東西，不是要完成的事。

視覺語言：

* inventory / container / battery metaphor
* quantity / remaining days
* refill action
* stock badge
* resource-specific icon

Resource card 主要回答：

```text
還剩多少？
是否快不足？
要不要補充？
```

Resource 不應看起來像 checkbox task。

---

### 8.3 StageTracker：階段追蹤

StageTracker 是「時間推進中的成長與重要階段」。

它應該比 Item / Resource 更有生命感、時間感、紀錄感。

視覺語言：

* timeline
* milestone
* growth
* next stage
* soft progress
* gentle badge

StageTracker card 主要回答：

```text
現在走到哪裡？
下一個階段是什麼？
距離下一個重要時間還有多久？
```

StageTracker 不應使用 done / skipped 的主要語言。

---

## 9. Pack Visual Role

Pack 是「生活場景」，例如：

* 養貓
* 家務
* 健康
* 寶寶
* 一般

Pack 的視覺角色是中等核心：

* 用於 Home filter
* 用於 card leading emoji
* 用於 tooltip / accessibility label
* 用於建立流程的分類
* 用於管理頁分組或篩選

Pack 不應在 MVP 階段變成主要導航架構，也不需要 Pack detail page。

---

### 9.1 Emoji Usage

Emoji 可以作為生活場景的主要視覺標記。

使用原則：

* Pack filter 可主要顯示 emoji
* Card leading 可顯示 Pack emoji
* Emoji 不應到處濫用
* Emoji 不應取代狀態 icon
* Emoji 不應承擔 warning / danger 語意

適合：

```text
🐱 養貓
🏠 家務
💊 健康
👶 寶寶
📌 一般
```

避免：

```text
每個 button 都放 emoji
每個提示都像聊天貼圖
狀態全靠 emoji 表示
```

---

## 10. Navigation Direction

目前主導航可維持三個核心入口：

* 今天
* 管理
* 階段追蹤

底部導航應保持清楚，不增加過多入口。

功能頁可以作為功能中樞，包含：

* 要照顧的事管理
* 資源管理
* 生活場景管理
* 階段追蹤
* 設定

管理頁可以比 Home 更有效率、更工具化；Home 則保持溫暖、清楚、低負擔。

---

## 11. Component Principles

### 11.1 Cards

所有主要內容都應優先使用 card 或 card-like surface。

Card variants：

1. Attention summary card
2. Item attention card
3. Resource card
4. Stage card
5. Management list card
6. Empty state card
7. Form section card

共同原則：

* 統一圓角
* 統一 padding
* 統一 status rail
* 統一 badge 樣式
* 統一 action 區域
* 減少不同頁面各自發明 card 樣式

---

### 11.2 Badges

Badge 用於表達：

* 固定節奏
* 彈性處理
* 資源
* 階段
* 進行中
* 已暫停
* 已封存
* 需要處理
* 要留意

Badge 應小而清楚，不應搶走 title。

建議樣式：

```text
Pill shape
Soft background
Small label text
Optional tiny icon
```

---

### 11.3 Buttons

Button 語氣分級：

* Primary action：新增、儲存、完成、補充
* Secondary action：查看全部、知道了、編輯
* Destructive action：封存、忽略這次、刪除

不要在同一張 card 上放太多同權重 action。

Home card 中最多顯示 1–2 個直接 action，其餘放 overflow 或 detail。

---

### 11.4 Empty States

Empty state 應保持溫柔、短句、生活化。

推薦：

```text
目前沒有需要處理的事。
目前沒有要留意的資源。
這個生活場景暫時很穩定。
```

避免過度可愛或過度鼓勵：

```text
太棒啦！你是生活管理大師！
```

---

## 12. Typography Direction

Typography 應清楚、溫和、資訊層級明確。

建議層級：

* Page title：清楚但不巨大
* Section title：明確分區
* Card title：最重要
* Metadata：低對比
* Badge：短而穩
* Status text：比 metadata 更明顯

中文 UI 文案應避免太技術化。

使用者文案應優先使用：

* 生活場景
* 要照顧的事
* 資源
* 庫存
* 可用天數
* 階段追蹤
* 重複階段
* 重要階段
* 知道了
* 忽略這次

避免直接顯示：

* Item
* Resource
* StageTracker
* StageRule
* generated occurrence
* lifecycle status
* warningAfter
* dangerBefore

---

## 13. Motion Direction

動畫應輕量、實用，不做表演型動畫。

適合：

* card expand / collapse
* section appear
* filter chip transition
* snackbar undo
* button feedback
* timeline item reveal

不適合：

* 大量彈跳
* 過度遊戲化
* 長動畫阻礙操作
* 每次完成都有大型慶祝動畫

動畫語感：

```text
快速、柔和、讓狀態變化被看見。
```

---

## 14. Layout Direction

### 14.1 Spacing

Spacing 應比一般資料管理 app 稍微寬鬆。

建議：

* Page horizontal padding: 16
* Section gap: 16–24
* Card padding: 16
* Card internal gap: 8–12
* List card gap: 12

避免卡片之間太擠，因為此 app 處理的是容易產生壓力的生活責任。

---

### 14.2 Section Structure

Home section 建議順序：

1. Attention summary
2. Pack filter
3. 需要處理
4. 要留意
5. 資源
6. 即將到來的階段

如果未來 Resource 納入 summary，可依 attention severity 重新排序。

---

## 15. Do / Don’t

### Do

* 使用暖米白背景
* 使用 warm amber 作為主色
* 使用左側狀態條表示 urgency
* 讓 Item / Resource / StageTracker 有明確視覺差異
* 保持 Home 像儀表板
* 保持卡片資訊中等密度
* 使用 emoji 表示生活場景
* 使用 badge 表示類型和狀態
* 保持 warning / danger 明確但不焦慮
* 優先使用生活語言

### Don’t

* 不要讓畫面太雜亂
* 不要每個元素都上色
* 不要把 app 做得像企業 SaaS
* 不要把 app 做成遊戲或寵物養成
* 不要讓 Resource 看起來像 Item
* 不要讓 StageTracker 看起來像一般 task
* 不要用 raw domain class name 當 UI 文案
* 不要在 Home 塞入過多操作
* 不要用高飽和紅色大面積警告

---

## 16. Suggested Design Tokens

以下 token 名稱可作為 Flutter theme / component style 的設計基準。

### 16.1 Color Tokens

```text
appBackground
surfaceCard
surfaceCardMuted
primaryWarm
primaryWarmContainer
statusNormal
statusNormalContainer
statusWarning
statusWarningContainer
statusDanger
statusDangerContainer
statusUnknown
statusUnknownContainer
domainItem
domainResource
domainStage
domainPack
borderSubtle
textPrimary
textSecondary
textMuted
```

---

### 16.2 Shape Tokens

```text
radiusCard
radiusSection
radiusBadge
radiusButton
radiusInput
```

---

### 16.3 Spacing Tokens

```text
spacePage
spaceSection
spaceCard
spaceCardCompact
spaceInline
spaceListGap
```

---

### 16.4 Component Tokens

```text
attentionSummaryCard
itemCard
resourceCard
stageCard
managementCard
packChip
statusBadge
domainBadge
statusRail
```

---

## 17. MVP UI Refactor Priority

建議 UI 重整時優先順序：

1. 建立 app theme tokens
2. 統一 card shape、padding、radius、border
3. 將 Item card 從 colored header 改為 left status rail pattern
4. 建立 Item / Resource / Stage 三種 domain card variant
5. 統一 badge 樣式
6. 統一 Pack emoji chip 樣式
7. 重整 Home attention summary
8. 統一管理頁 card/list 樣式
9. 為 StageTracker 建立 timeline / growth-style visual pattern
10. 整理 empty state 和 error state

---

## 18. One-line Direction

> Reminder App 是一個帶有生活手帳感的提醒儀表板，用暖色、紙片式卡片與清楚狀態條，把快被忽略的生活責任整理成安心可處理的今日清單。

---

## 19. Implementation Convergence 2026-05-17

本節記錄目前 Flutter UI refactor 的實作收斂狀態，後續 UI 調整應優先沿用這些落點。

### 19.1 實作邊界

- 本次只調整 UI layer：`app/theme`、`features/reminders/ui`、history/settings/editor 的 presentation widgets。
- 不修改 domain model、core rule、repository、provider contract、Drift schema 或 generated database code。
- 附件圖片只作為 visual reference，不納入 app assets；現階段以 Material icons、emoji、paper card、狀態條和暖色 token 表達手帳感。

### 19.2 已落地 Tokens

Flutter token 入口：

```text
lib/app/theme/reminder_theme.dart
```

已落地：

- `ReminderPalette`：warm cream background、paper card surface、warm orange primary、soft green / amber / coral / warm grey status colors、domain item/resource/stage colors。
- `ReminderSpacing`：page、section、card、cardCompact、inline、listGap。
- `ReminderRadius`：card、section、badge、button、input。
- `ReminderTheme.light()`：Material 3 theme、AppBar、Card、FilledButton、OutlinedButton、TextButton、Chip、Input、FAB、NavigationBar、ListTile。

### 19.3 已落地 Components

Flutter component 入口：

```text
lib/features/reminders/ui/widgets/reminder_components.dart
```

已落地：

- `ReminderPaperCard`：主要 paper-card surface。
- `ReminderRailCard`：左側 status rail card，用於 Item / Resource / Stage attention cards。
- `ReminderBadge`：domain / status / metadata pill。
- `ReminderIconBubble`：emoji 或 icon 的圓形生活脈絡標記。
- `ReminderSectionHeader`：section title + icon。
- `ReminderEmptyState`：溫和空狀態。
- `ReminderFooterMark`：頁面底部生活語氣標記。
- `ReminderTimelineDots`：輕量 stage timeline/progress visual。

### 19.4 已套用頁面

- Today：attention summary hero、pack filter、needs action、watch soon、resources、upcoming stages、footer。
- Manage / Feature hub：care system hub entry cards 與底部提示。
- Care items：pack group cards、managed item rail cards、status/type badges、empty state。
- Resources：resource rail cards、stock/refill visual、resource badges。
- Stage tracking：management cards、detail hero、timeline dots、next/upcoming stages、rules、schedule/history occurrence cards。
- Editor / dialogs / histories / settings：套用全域 theme、spacing、paper card、empty state；原本表單欄位與流程保持不變。

### 19.5 Verification Baseline

本次收斂後需維持：

```text
flutter analyze
flutter test
```

兩者皆應通過。UI 後續改動若新增 component variant，應同步更新本文件。

### 19.6 Runtime Bugfix Notes

- `ReminderRailCard` 不可使用 `Row(crossAxisAlignment: stretch)` 依賴父層高度；在 `ListView` 等無界高度環境中會造成 `BoxConstraints forces an infinite height`，並連帶導致 hover hit-test 無尺寸。Rail 應以 `Stack + Positioned.fill + Align` 疊在 paper card 左側，card 高度由內容自然撐開。
- `ReminderPaperCard` 必須提供 `Material` ancestor，即使本身沒有 `onTap`。管理頁 group card 內可能有 `InkWell` / `IconButton`，缺少 Material 會在互動時丟 runtime exception。
- Bottom navigation branch routes 不應用 `pushNamed` 疊到 navigator 上。從 Feature hub 或 summary hero 前往 `/manage`、`/feature/stage-trackers` 這類 shell branch route 時使用 `goNamed`。
- Stage tracking branch 的 branch-level FAB 不應 push 自己的 shell route；新增階段追蹤保留在頁面內的「新增階段追蹤」按鈕。
- Stage tracking branch 沒有資料時必須顯示 `ReminderEmptyState(ReminderUiText.noStageTrackers)`，不可呈現空白頁。
