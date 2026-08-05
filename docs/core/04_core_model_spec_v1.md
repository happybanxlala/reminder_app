---
This is the single source of truth for reminders core model, MVP scope, naming, and behavior.
Last aligned with repository contents on 2026-08-04.
---

# Reminder App Unified Core Spec

本文件是 `reminders` feature 的核心規格。實作、測試、UI 文案與後續修訂若和舊文件或舊命名衝突，一律以本文件為準。

主要語言使用繁體中文；程式模型、enum、table、route、repository API 保留英文技術命名。

## 1. 總覽

### 1.1 產品北極星

> 讓重要的事，不會在無意識中變糟。

Reminder App 關注四種使用者容易忽略的狀態：

- 責任是否正在變糟。
- 固定週期的責任是否已接近或超過本輪處理時間。
- 資源是否即將不足或已不足。
- 一段時間中的重要階段是否已進入提醒窗口。

### 1.2 核心模型邊界

一句話版本：

> `Item` 是要做的事；`Resource` 是要留意的資源；`StageTracker` 是從某一天開始追蹤，提醒將到來的重要階段。`Item` action 可以消耗 `Resource`，但 `Resource` 不是 `ItemType`；`StageTracker` 可以引導建立 `Item`，但 `StageTracker` 本身不是 `Item`。

| 概念 | 責任 |
| --- | --- |
| `ItemPack` | 使用者視角的生活場景 |
| `PackTemplate` | 可快速建立生活場景與預設事項的範本 |
| `Item` | 責任、行為、需要被完成的事 |
| `Resource` | 可被消耗、可補充、可提醒的資源 |
| `StageTracker` | 時間推進中的階段追蹤 |
| `ItemActionRecord` | 使用者對責任的操作紀錄 |
| `ResourceActionRecord` | 資源庫存或可用性變化紀錄 |
| `StageRecord` | 手動重要階段，或 generated occurrence 的使用者互動紀錄 |
| `ItemStatus` | `Item` attention status 的推導結果 |
| `ResourceStatus` | `Resource` 可用性 status 的推導結果 |

Domain 必須保持分離。Home 可以在 presentation layer 聚合 `Item`、`Resource` 與 `StageOccurrence`，但不可把三者合併成同一個 domain object。

### 1.3 Pack 使用範圍語意

`PackAccessScope` 是後續 Shared Pack 開發前先定義的產品語意，不是目前 production model。

```dart
enum PackAccessScope {
  personal,
  shared,
}
```

狀態：

- planned semantic only。
- 現有 production model 尚未實作 `PackAccessScope` enum、欄位或 Drift column。
- Phase 0 只定義語意，不新增 migration，也不提升 `driftSchemaVersion`。

語意邊界：

- `personal` / `shared` 表示 Pack 的使用範圍與存取關係。
- `local` / `remote` 表示技術儲存方式。
- 使用者與 UI 應理解「個人 Pack / 共享 Pack」，不應被迫理解「本機 Pack / 遠端 Pack」。
- 現有已實作 `ItemPack` 全部都是 Personal/local-first Pack；Shared Pack 尚未在 production code 中實作。

### 1.4 Shared Pack v1 cross-reference

Shared Pack 產品方向以 `docs/core/06_shared_pack_direction_spec_v1.md` 為準；planned remote request / contract catalog 以 `docs/core/07_shared_pack_remote_contract_v1.md` 為準；planned client runtime consistency、response ordering、cache trust 與 failure semantics 以 `docs/core/08_shared_pack_runtime_consistency_spec_v1.md` 為準。

在本 core spec 中只鎖定與現有 local model 的交界：

- Shared Pack v1 第一個 vertical slice 是 `ItemType.stateBased` Shared Item-only。
- Shared Item v1 lifecycle 只支援 `active` / `archived`；不支援 `paused`、restore 或 unarchive。
- Shared Item v1 建立時必須提供 `initialStateAnchorDate`；remote DTO 保存為 `stateAnchorDate`。
- `updateSharedItem` 只可修改 definition，不可修改 `stateAnchorDate`、completion attribution 或 lifecycle。
- `completeSharedItem` 是 v1 唯一可更新一般 Shared Item state anchor 的操作；authoritative `completedAt` 由 server 產生，且 `stateAnchorDate = completedAt`。
- Shared Pack v1 不支援 `ItemType.fixed`、recurring fixed schedule、`ItemOverduePolicy`、fixed cycle advance 或 fixed schedule timezone calculation；這些屬於 v1.x 或後續明確規格階段。
- Shared Pack v1 不代表現有整個 `ItemPack` graph 都會 remote-backed。
- `Resource`、`ResourceConsumptionRule`、`ResourceActionRecord`、`StageTracker`、`StageRule`、`StageRecord`、`StageRelatedItem`、`PackTemplate` 與 custom template sync 在 v1 保持 Personal/local-only。
- Personal Pack conversion 不屬於 v1；v1 只支援建立新的 Shared Pack。
- Shared Pack v1 使用獨立 Shared Drift cache tables，不重用現有 `item_packs`、`items` 或 `item_action_records`。
- Shared Item 即使 planned 投影到 local Drift readable cache，也不代表自動進入所有既有 repository query、Home、Widget、通知或 backup。
- Shared Item 不可被現有 `ItemRepository` 當作 Personal Item mutation；Shared Pack action 必須走 `SharedPackApplicationService`，再由 Shared Pack data layer 處理 remote request 與 cache projection。
- Shared Pack remote protocol versions are planned contract values: `remoteApiContractVersion = 1` and `remoteSnapshotSchemaVersion = 1`。
- 所有改變 Shared Pack active current-state snapshot 的 mutation 必須回傳 full active snapshot；Invite state 不屬於 active snapshot，也不改變 `packVersion`。
- Shared Pack v1 timestamps 使用 UTC instant；UI 顯示時才轉成 device local timezone。
- `remotePackVersion` must be monotonic at runtime；較舊 response 或 projection failure 不可讓 Shared cache 倒退或宣稱已套用較新的 authoritative state。

### 1.5 Planned local cache projection

以下 cache shape 只是 Phase 1 technical design 前鎖定的 planned semantic direction。

```text
shared_pack_cache
- localId
- remotePackId
- title
- description
- iconEmoji
- currentUserRole
- remotePackVersion
- lastRefreshedAt
- accessState
- createdAt
- updatedAt

shared_membership_cache
- localId
- remoteMemberId
- remotePackId
- displayName
- role
- joinedAt
- createdAt
- updatedAt

shared_item_cache
- localId
- remoteItemId
- remotePackId
- title
- description
- type
- lifecycleStatus
- stateAnchorDate
- infoAfterMinutes
- warningAfterMinutes
- dangerAfterMinutes
- completedAt
- completedByMemberId
- remoteItemVersion
- createdAt
- updatedAt
```

要求：

- 現有 `item_packs`、`items` 與 `item_action_records` 繼續只代表 Personal / local-first domain。
- Shared cache 不自動進入 Personal repositories、Home、global Item management、notification、Home Widget 或 legacy backup。
- `shared_pack_cache.localId + remotePackId` 可承擔 Pack identity mapping；`shared_item_cache.localId + remoteItemId` 可承擔 Item identity mapping。
- 額外 mapping table 不是預設要求；只有 Phase 1 technical design 證明有必要時才新增。
- 不可在 Shared cache 和額外 mapping table 重複保存相同 identity 而沒有明確理由。
- remote ID mapping 必須集中於 Shared Pack data layer，不可散落在 Personal domain models。
- `remotePackVersion` 只代表目前本機完整 Shared cache 所對應的完整 Pack snapshot version，不代表最後一次收到的 mutation fragment version。
- 會改變 Shared Pack active current-state snapshot 的 mutation，不可只 patch 單一 row 後更新 `remotePackVersion`；remote success 必須回傳完整 snapshot，並透過與 `getSharedPackSnapshot` 相同的 `SharedPackCacheProjector` 在單一 transaction 投影。
- mutation full snapshot projection 失敗時必須 rollback，不更新 `remotePackVersion` 或 `lastRefreshedAt`，UI 不可把 cache 當成最新狀態。
- remote mutation success followed by local projection failure 表示 remote authoritative state 已改變，但 local cache 尚未成功同步；在重新取得並成功投影 authoritative snapshot 前，該 Pack 不可使用 known-untrusted cache 繼續 mutation。
- `lastRefreshedAt` 表示最近一次成功從 remote 取得或驗證 Shared Pack current state 的 UTC 時間；包含 full snapshot projection 成功、mutation full snapshot projection 成功，以及 manual refresh 回傳 `notModified`。
- `notModified` 只更新 `shared_pack_cache.lastRefreshedAt`，不重寫 `shared_membership_cache`、`shared_item_cache`，也不改 `remotePackVersion`。
- 正式 table 名稱、欄位型別、index、migration 與 projection transaction 必須在 Phase 1 technical design 中確認。

### 1.6 Version naming

文件與程式碼應避免單獨使用模糊的 `schemaVersion` 描述不同協定。若需要描述版本，必須指明是哪一種：

| 名稱 | 目前值 | 來源 | 語意 |
| --- | --- | --- | --- |
| `driftSchemaVersion` | `5` | `AppDatabase.schemaVersion` | Drift database schema / migration version |
| `backupFormatVersion` | `1` | `BackupPayload.currentSchemaVersion`，JSON 欄位目前仍名為 `schemaVersion` | legacy local JSON backup format |
| `widgetSnapshotSchemaVersion` | `1` | `HomeWidgetSnapshot.currentSchemaVersion` 與 native supported schema | Home Widget Flutter-to-native snapshot protocol |
| `remoteApiContractVersion` | `1` planned / not implemented | `docs/core/07_shared_pack_remote_contract_v1.md` | Shared Pack remote request / response contract major version |
| `remoteSnapshotSchemaVersion` | `1` planned / not implemented | `docs/core/07_shared_pack_remote_contract_v1.md` | Shared Pack full active snapshot schema |

### 1.7 已實作模型清單

- `ItemPack`
- `PackTemplate`
- `PackTemplateItem`
- `Item`
- `ItemConfig`
- `FixedItemConfig`
- `StateBasedItemConfig`
- `ItemActionRecord`
- `AttentionPolicy`
- `AppSettings`
- `Resource`
- `ResourceConfig`
- `TimeBasedResourceConfig`
- `QuantityBasedResourceConfig`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `StageTracker`
- `StageRule`
- `StageOccurrence`
- `StageRecord`
- `StageRelatedItem`

### 1.8 已實作 enum 清單

- `ItemType { fixed, stateBased }`
- `ItemStatus { normal, warning, danger, unknown }`
- `ItemLifecycleStatus { active, paused, archived }`
- `FixedScheduleType { daily, weekly, oneTime, everyXDays, everyXWeeks, monthly }`
- `ItemOverduePolicy { autoAdvance, waitForAction }`
- `ItemNextCycleStrategy { keepSchedule, shiftByDelay }`
- `ItemActionType { created, done, skipped, deferred, reverted }`
- `AttentionPolicySource { systemDefault, userCustomized }`
- `ReminderTone { gentle, standard, early, urgent }`
- `UsageSpeed { low, medium, high }`
- `ResourceType { timeBased, quantityBased }`
- `ResourceLifecycleStatus { active, paused, archived }`
- `ResourceStatus { normal, warning, danger, unknown }`
- `ResourceActionType { created, consumed, refilled, adjusted, reverted }`
- `StageTrackerStatus { active, archived }`
- `StageRuleType { everyNDays, everyNWeeks, everyNMonths, everyNYears }`
- `StageIntervalUnit { days, weeks, months, years }`
- `StageRuleStatus { active, paused, archived }`
- `StageRecordSourceType { generated, manual }`
- `StageRecordStatus { normal, acknowledged, ignored, archived }`

## 2. 已實作模型

### 2.1 ItemPack Domain

#### 產品語意

`ItemPack` 是使用者看到的「生活場景」。它不是純資料夾，也不是強制的 domain 關聯圖。

`Item`、`Resource`、`StageTracker` 都歸屬於一個 `ItemPack`。Pack 代表使用者願意放在同一個生活脈絡中理解與管理的內容，例如「養貓」、「家務」、「健康」、「寶寶」。

system default pack 顯示為「一般」，代表使用者尚未指定生活場景時的預設歸屬位置，不代表具體生活場景。

#### 已實作資料模型

```ts
ItemPack {
  id: number
  title: string
  description?: string
  iconEmoji: string
  orderIndex: number
  status: "active" | "archived"
  isSystemDefault: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

`ItemPackInput`：

```ts
ItemPackInput {
  title: string
  description?: string
  iconEmoji: string // default "🏷️"
}
```

system default pack 常數：

- title：`一般`
- iconEmoji：`📌`
- orderIndex：`0`
- description：`System default pack`

#### 已實作行為

- `item_packs` 由 Drift 管理，`AppDatabase.beforeOpen` 會確保 system default pack 存在。
- system default pack 必須維持 active、名稱「一般」、icon `📌`、`orderIndex = 0`。
- system default pack 不可封存。
- `Item`、`Resource`、`StageTracker` 建立時若沒有提供 `packId`，repository 會寫入 system default pack。
- 建立流程的 pack picker 會把未指定 / system default 顯示為「之後決定」，避免同時出現「一般」與未決定選項；編輯 / 唯讀脈絡則把 system default pack 顯示為「一般」。這是 UI display mapping，不改變 `packId` 或 repository 預設歸屬。
- 自訂 Pack 可新增、編輯名稱、編輯 emoji、調整排序、封存。
- Pack 排序由 `orderIndex` 控制；DAO 排序會把 system default pack 固定在前，再依自訂 Pack 的 `orderIndex`、`createdAt` 穩定排序。
- Pack 管理頁使用「生活場景管理」文案，支援「上」「下」排序，不支援 drag and drop。
- 封存自訂 Pack 時，已實作兩種 repository 行為：
  - `archivePackWithContents`：Pack 封存，底下 active / paused `Item` 與 `Resource` 封存，底下 active `StageTracker` 封存。
  - `archivePackAndMoveContentsToDefault`：Pack 封存，底下內容移到 system default pack，內容原 lifecycle status 保持不變。
- 封存 Pack 不刪除 action records、stage records 或 related item links。

#### 範例

```text
Pack: 養貓 🐱
Item: 清貓砂
Resource: 貓砂
StageTracker: 小米成長
```

這三個 object 同屬「養貓」生活場景，但彼此不必存在直接行為關聯。

### 2.2 PackTemplate Domain

#### 產品語意

`PackTemplate` 是可重用的生活場景範本，用來快速建立一個 `ItemPack` 與一組預設 `Item`。

Pack Template 分為兩種來源：

- `defaultTemplate`：app 內建，例如「家務」、「個人護理」、「養貓」。
- `custom`：使用者只能從既有 active Pack 儲存而成。

#### 已實作資料模型

```ts
PackTemplate {
  id: string
  source: "defaultTemplate" | "custom"
  templateName: string
  iconEmoji: string
  description?: string
  items: PackTemplateItem[]
}
```

```ts
PackTemplateItem {
  title: string
  type: ItemType
  config: ItemConfig
  attentionPolicySource: "systemDefault" | "userCustomized"
}
```

自訂 template 由 Drift `pack_templates` 與 `pack_template_items` 儲存。預設 template 由 Dart code 定義，不 seed 進資料庫。

#### 已實作行為

- Pack 管理頁提供「從模版建立生活場景」入口。
- 新增 Pack dialog 提供「從模版建立」入口；Item / Resource / StageTracker inline 新增 Pack 流程仍只做空白建立。
- Template Picker 分為「預設模版」與「自訂模版」，列表顯示 emoji、template name 與 item count。
- 使用 template 前必須進入 preview detail；第一版不支援勾選、修改 item title 或修改 schedule。
- 使用 template 建立 Pack 時，Pack title 固定為 `{templateName}(模版)`，不自動加數字或「副本」。
- 若已存在同名 active Pack，preview 會提示，建立前可再次確認；仍允許建立同名 Pack。
- 使用 template 建立 Pack + Items 會在 repository transaction 中完成。
- template-created Items 不寫入 `ItemActionRecord(created)`，不建立 resource binding、resource action history、stage tracker 或 done records。
- 自訂 template 只能從已有 Pack 儲存，且只保存 active Items。
- 自訂 template 保存 Pack title / icon / description，以及 Item title / type / schedule config。
- 自訂 template 不保存 resource binding、resource consumption、resources、action history、done records、stage trackers 或 archived item history。

#### 範例

```text
Template: 養貓
Created Pack: 養貓(模版)
Created Items: 清貓砂、補貓糧、洗水碗、清潔貓窩、剪指甲、驅蟲
```

#### MVP 待完成

- 建立後「查看」只導向 Item 管理頁；尚未支援自動定位或展開新建立 Pack。

### 2.3 Item Domain

#### 產品語意

`Item` 是要做的事。它承載責任設定、生命週期，以及 attention status 推導所需資料。

`Item` 的 lifecycle status 和 attention status 是兩件事：

- lifecycle status：使用者是否仍管理此責任，使用 `active / paused / archived`。
- attention status：此責任目前是否需要注意，使用 `normal / warning / danger / unknown`，由 `ItemStatusService` 推導。

#### 已實作資料模型

```ts
Item {
  id: number
  packId: number
  title: string
  description?: string
  type: ItemType
  config: ItemConfig
  attentionPolicySource: "systemDefault" | "userCustomized"
  status: "active" | "paused" | "archived"
  lastDoneAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

```dart
enum ItemType {
  fixed,
  stateBased,
}
```

`FixedItemConfig`：

```ts
FixedItemConfig {
  scheduleType: "daily" | "weekly" | "oneTime" | "everyXDays" | "everyXWeeks" | "monthly"
  scheduleInterval: number
  monthlyDay?: number
  repeatRuleV2?: RepeatRuleV2
  anchorDate?: DateTime
  dueDate?: DateTime
  timeOfDay?: string
  overduePolicy: "autoAdvance" | "waitForAction"
  infoBefore: Duration
  warningBefore: Duration
  dangerBefore: Duration
}
```

`StateBasedItemConfig`：

```ts
StateBasedItemConfig {
  anchorDate?: DateTime
  infoAfter: Duration
  warningAfter: Duration
  dangerAfter: Duration
}
```

#### 已實作行為

- `fixed` 代表有明確日曆週期或 due date 的責任，例如繳費、回診、固定清潔、為某個階段做準備。
- `stateBased` 代表狀態會隨時間變差的責任，例如清貓砂、換濾水網、整理冰箱。
- `ItemRepository.createItem` 會建立 `Item`，並寫入 `ItemActionRecord(created)`。
- `createItemWithOptionalNewPack` 支援在建立 Item 時同步建立新 Pack。
- `updateItem` 不允許改變既有 Item 的 `type`。
- `updateItem` 支援 edit form 的 pending resource binding：在同一個 transaction 更新 Item、建立尚未落庫的新 Resource、寫入 consumption rules；pending Resource 預設跟隨 Item 最終 `packId`。
- `moveItemToPack(itemId, targetPackId, moveLinkedResources)` 在 transaction 內更新 Item `packId`，刪除該 Item 的 `stage_related_items` links；若 `moveLinkedResources == true`，enabled consumption rules 指向的 linked Resources 會一起搬到 target Pack，否則保留 Resource Pack 並將該 Item 的 consumption rules 設為 disabled。
- `markDone` 透過 `ItemActionService` 和 `ItemSnapshotUpdateService` 產生 action 並更新 snapshot。
- `skip` 會寫入 skipped action，並依 `ItemNextCycleStrategy` 處理 fixed cycle。
- `defer` API 存在，但目前固定回傳 `false`，不寫入歷史。
- `stateBased` 使用 `config.anchorDate` 作為主要狀態基準；完成時更新 `stateAnchorDate`，`lastDoneAt` 不作為 state-based 主要基準。
- `fixed` 使用 `anchorDate / dueDate / repeatRuleV2 / overduePolicy` 推導本輪週期。
- fixed item 的 create / edit UI 不直接顯示或輸入 `anchorDate`；使用者只選擇「完成方式」。
- fixed 完成方式為「到期當日完成」時，系統儲存 `anchorDate = dueDate`。
- fixed 完成方式為「可提前一段時間完成」時，使用者輸入「到期前 N 天開始」，且 N 必須為正整數；系統儲存 `anchorDate = dueDate - N days`。
- fixed edit 由既有 `anchorDate / dueDate` 還原完成方式：相同日期為「到期當日完成」，`anchorDate < dueDate` 為「可提前一段時間完成」，`anchorDate > dueDate` 必須阻止儲存直到使用者修正。
- fixed item 儲存前必須檢查檔期不重疊；規則為本輪 `currentDueDate < nextAnchorDate`，其中 `nextAnchorDate` 必須由現有重複規則推算出的下一輪 due date 再扣回本輪 lead days，不可用固定日數粗略判斷 monthly / yearly。
- fixed 檔期重疊時阻止 create / update，錯誤文案為「可處理時間太長，會和下一次提醒重疊。請縮短可處理期，或調整重複規則。」
- `ItemOverduePolicy.autoAdvance` 可在 read model 推導時虛擬前進到目前週期。
- `ItemOverduePolicy.waitForAction` 過期後維持待處理，並回傳 danger。
- active items 進入 Home warning / danger 查詢；paused / archived items 不進入 Home attention query。

#### 範例

```text
Item: 替換濾水網
type: stateBased
anchorDate: 2026-05-01
warningAfter: 12 days
dangerAfter: 14 days
```

```text
Item: 繳電費
type: fixed
scheduleType: monthly
monthlyDay: 15
dueDate: 2026-05-15
overduePolicy: waitForAction
warningBefore: 3 days
dangerBefore: 1 day
```

#### MVP 待完成

- `ItemNextCycleStrategy.shiftByDelay` 已存在於 domain API，但 UI 主要流程尚未完整暴露為使用者可選策略。
- `deferred` action type 只保留相容性，不建立新的 deferred record。Status: Compatibility-only.

### 2.4 ItemActionRecord Domain

#### 產品語意

`ItemActionRecord` 是使用者對責任的歷史紀錄，不是 attention status 的唯一來源。

#### 已實作資料模型

```ts
ItemActionRecord {
  id: number
  itemId: number
  actionType: "created" | "done" | "skipped" | "deferred" | "reverted"
  actionDate: DateTime
  remark?: string
  payload?: Json
  isReverted: boolean
  revertedAt?: DateTime
  revertedByActionRecordId?: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- `payload` 使用 JSON encode / decode，空 payload 存為 `null`。
- 建立、完成、略過都會形成 history。
- 新增的 done record 會在 payload 寫入 `undoSnapshot`，保存完成前 item snapshot，供精準 undo 使用。
- undo done 不刪除原 done record；原 done 會標記 `isReverted = true`，並新增 `ItemActionRecord(reverted)` 指向被撤銷的 done record。
- Item history 以 `ItemActionRecord` 為核心資料來源；一般 UI read model 會把 done 與後續 reverted 合併為同一筆使用者可讀紀錄，避免把完成與回復拆成會計分錄。
- Item history 的 resource impact 可從相關 `ResourceActionRecord.sourceItemActionRecordId` 推導；完成造成的 consumed record 顯示為扣除資源，回復造成的 reverted compensation record 顯示為已補回資源。
- Fixed item history 在一般 UI 顯示 action date；不顯示 preview date、cycle preview 或虛擬週期資訊。
- 缺少 `undoSnapshot` 的既有舊 done record 不提供精準 undo。
- item 操作寫入 record 後，仍需要同步更新 item snapshot 欄位。
- `ItemActivityPage` 以 `ItemActionRecord` 顯示近期活動，支援搜尋與載入更多。

#### 範例

```text
done: 使用者在 2026-05-15 完成「清貓砂」。
skipped: 使用者本輪不處理「整理冰箱」。
```

#### MVP 待完成

- `deferred` 不在目前 MVP 建立流程中使用。Status: Compatibility-only.

### 2.5 Resource Domain

#### 產品語意

`Resource` 是要留意的資源，不是要完成的責任。

`Resource` 可以獨立管理，也可以透過 `ResourceConsumptionRule` 被 `ItemActionRecord(done)` 消耗。UI 可以把資源顯示在 Item 編輯頁的「消耗資源」區塊，但 domain 仍保持分離。

#### 已實作資料模型

```ts
Resource {
  id: number
  packId: number
  title: string
  description?: string
  type: ResourceType
  config: ResourceConfig
  status: "active" | "paused" | "archived"
  lastRefilledAt?: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

```dart
enum ResourceType {
  timeBased,
  quantityBased,
}
```

`TimeBasedResourceConfig`：

```ts
TimeBasedResourceConfig {
  anchorDate?: DateTime
  durationDays: number
  infoBeforeDays: number
  warningBeforeDays: number
  dangerBeforeDays: number
}
```

`QuantityBasedResourceConfig`：

```ts
QuantityBasedResourceConfig {
  currentQuantity: number
  unitLabel: string
  infoThreshold?: number
  warningThreshold: number
  dangerThreshold: number
}
```

#### 已實作行為

- `ResourceRepository.createResource` 會建立 `Resource`，並寫入 `ResourceActionRecord(created)`。
- `updateResource` 不允許改變既有 Resource 的 `type`。
- `archiveResource` 只更新 lifecycle status，不刪除 action history 或 consumption rules。
- time-based resource 使用 `anchorDate + durationDays - 1` 推導 depletion date。
- quantity-based resource 使用 `currentQuantity` 與 warning / danger thresholds 推導狀態。
- Resource edit 可調整名稱、備註、Pack、單位與提醒 thresholds，但不應直接修改目前數量或剩餘可用天數；資源數量 / 可用天數變動應透過 `refillResource` 或 `adjustResourceQuantity` 寫入 `ResourceActionRecord`。
- `moveResourceToPack(resourceId, targetPackId)` 在 transaction 內更新 Resource `packId`，並將使用該 Resource 的 Item consumption rules 設為 disabled；不搬移 Item。
- `ResourceStatusService` 對異常或不足資料回傳 `unknown`。
- `watchResources` 只回傳 active resources；`watchManagedResources` 回傳 active / paused resources。
- Home danger / warning attention sections 會依 `ResourceStatus` 混合顯示 active Resource 與 Item，並可套用 Pack filter。
- Resource 已納入 `AttentionSummaryRepository` 與 `HomeAttentionSource` 的統一 attention summary 計數。
- Resource 管理頁支援新增、編輯、補充、quantity 調整、詳細資訊、歷史紀錄、刪除；底層仍是 soft archive，不硬刪資料。
- Resource history route 已實作：`/resource/:id/history`，route name 是 `resource-history`。

#### 範例

```text
Resource: 濾水網
type: quantityBased
currentQuantity: 5
unitLabel: 個
warningThreshold: 2
dangerThreshold: 1
```

```text
Resource: 洗髮精
type: timeBased
anchorDate: 2026-05-01
durationDays: 20
warningBeforeDays: 3
dangerBeforeDays: 1
```

### 2.6 ResourceConsumptionRule Domain

#### 產品語意

`ResourceConsumptionRule` 連接「完成某個 Item」與「扣除某個 Resource」。

#### 已實作資料模型

```ts
ResourceConsumptionRule {
  id: number
  resourceId: number
  itemId: number
  triggerActionType: ItemActionType
  consumeAmount: number
  isEnabled: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- 目前 trigger 固定使用 `ItemActionType.done`。
- 目前只支援消耗 quantity-based resource。
- `consumeAmount < 1` 時 repository 會存為 `1`。
- disabled rule 不會套用。
- 建立 Item 時可帶入 `ItemResourceBindingInput.existing`，綁定同 Pack 的 active quantity-based resource。
- 建立 Item 時可帶入 `ItemResourceBindingInput.newResource`，同 transaction 建立 quantity-based resource 並插入 consumption rule。
- 若 resource binding 失敗，create item transaction 會 rollback，不留下 partial item / resource / rule。
- `markDone` 會在同一個 transaction 內更新 item snapshot、寫入 item done record、套用 enabled rules、扣除 quantity resource、寫入 `ResourceActionRecord(consumed)`。
- archived resource 不會被 `markDone` 扣量。

#### 範例

```text
Item: 替換濾水網
Resource: 濾水網
Rule: done 時 consume 1 個
```

### 2.7 ResourceActionRecord Domain

#### 產品語意

`ResourceActionRecord` 記錄資源庫存或可用性變化。

#### 已實作資料模型

```ts
ResourceActionRecord {
  id: number
  resourceId: number
  actionType: "created" | "consumed" | "refilled" | "adjusted" | "reverted"
  actionDate: DateTime
  amount?: number
  resultingQuantity?: number
  addedDays?: number
  resultingDurationDays?: number
  sourceItemActionRecordId?: number
  remark?: string
  isReverted: boolean
  revertedAt?: DateTime
  revertedByActionRecordId?: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- quantity consumption / refill / adjustment 記錄 `amount` 或 `resultingQuantity`。
- time-based refill 記錄 `addedDays` 與 `resultingDurationDays`。
- 由 item done 觸發的 consumed record 會設定 `sourceItemActionRecordId`。
- undo item done 若曾消耗 quantity resource，原 consumed record 會標記 `isReverted = true`，並新增 `ResourceActionRecord(reverted)` 作為補回紀錄。
- Resource history 預設排除 `isReverted = true` 與 `actionType = reverted` 的一扣一補噪音；需要除錯時 repository 可要求包含 reverted records。
- `refillResource`：
  - time-based resource 要求 `addedDays > 0`。
  - quantity-based resource 要求 `addedQuantity > 0`。
  - quantity-based refill 代表增加目前數量，並寫入 refilled action record。
  - time-based refill 代表新增可用天數；既有 repository 會 carry over 尚未耗盡的剩餘天數，不直接把剩餘天數修正為輸入值。
- `adjustResourceQuantity`：
  - 只支援 quantity-based resource。
  - quantity-based adjustment 代表直接修正目前數量，並寫入 adjusted action record。
  - `newQuantity` 經 `ResourceRefillService.adjustQuantity` 處理，負數 clamp 到 `0`。

#### 範例

```text
refilled: 補充洗髮精 20 天，resultingDurationDays = 20
consumed: 完成「替換濾水網」後扣除 1 個濾水網，resultingQuantity = 4
adjusted: 使用者手動把濾水網庫存修正為 3 個
```

#### MVP 待完成

- Resource history 已有頁面，但 `sourceItemActionRecordId` 目前主要透過格式化文字呈現，尚未提供跳回來源 Item action 的互動入口。

### 2.8 StageTracker Domain

#### 產品語意

`StageTracker` 是一條從某天開始追蹤的階段線。UI 名稱是「階段追蹤」。

它用來看見時間推進中的重要節點，例如寶寶成長、交往紀念、搬家後保養、復健進度。它不代表一件要完成的事，也不以 done / skipped 作為主要狀態。

#### 已實作資料模型

```ts
StageTracker {
  id: number
  packId: number
  title: string
  subjectName?: string
  trackingStartDate: DateTime
  trackingEndDate?: DateTime
  status: "active" | "archived"
  isSystemDefault: boolean
  systemKey?: string
  isHidden: boolean
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- `StageTracker` 必須歸屬於一個 Pack。
- 建立時未指定 `packId` 會寫入 system default pack。
- `trackingStartDate` 在 UI 顯示為「從哪一天開始追蹤」。
- `trackingEndDate == null` 代表持續追蹤。
- 一般 StageTracker 可編輯 title、subjectName、pack、trackingStartDate、trackingEndDate。
- `moveStageTrackerToPack(trackerId, targetPackId, moveRelatedItems, moveRelatedResources)` 在 transaction 內更新 StageTracker `packId`。相關 Item 來自 `stage_related_items`；選擇搬移時會同步更新 Item `packId`，不搬移時會刪除該 tracker 底下的 `stage_related_items` links。相關 Resource 來自 related Items 的 enabled consumption rules；選擇搬移時會同步更新 Resource `packId`，跨 Pack 關聯未一起搬移時會將對應 consumption rules 設為 disabled。
- trackingStartDate / trackingEndDate 屬於進階設定；修改後會影響累積天數與階段推算，但不會重寫既有 StageRecord。
- 到達 `trackingEndDate` 後不自動 archive，而是由 presentation 分到「已完成追蹤」。
- 一般 StageTracker 可封存；封存後不出現在一般管理列表，既有 StageRule、StageRecord 與 related item links 保留。
- App 會建立一個 system default StageTracker：title `Reminder App`、subjectName `系統`、systemKey `reminder_app`。
- system default StageTracker 的 `trackingStartDate` 使用首次建立日期，後續 ensure 不重置。
- system default StageTracker 不可 edit / archive / delete，也不可新增或修改底下階段；唯一使用者操作是 hide / show。
- system default StageTracker hidden 後不出現在 StageTracker overview，但資料不刪除、不封存，可在 Settings 恢復顯示。
- active trackers 出現在 StageTracker 管理頁；archived trackers 不出現在一般 watch query。
- StageTracker 管理 route 已實作：`/feature/stage-trackers`，route name 是 `stage-trackers`。
- StageTracker detail route 已實作：`/stage-tracker/:id`，route name 是 `stage-tracker-detail`。
- StageTracker complete timeline route 已實作：`/stage-tracker/:id/timeline`，route name 是 `stage-tracker-timeline`。
- StageTracker full schedule route 已實作：`/stage-tracker/:id/schedule`，route name 是 `stage-tracker-schedule`。
- StageTracker history route 已實作：`/stage-tracker/:id/history`，route name 是 `stage-tracker-history`。
- 建立 StageTracker 後進入 detail dashboard。
- detail dashboard 顯示第 N 天、最近 / 待確認階段、即將到來、重複階段列表、加入階段、完整時間線入口。
- StageTracker display day count 以 `trackingStartDate` 當天為「第1天」起算，後一天為「第2天」；早於 start date 的 preview date 最小顯示「第1天」，不顯示 `0天`。

#### 範例

```text
StageTracker:
  title: 寶寶成長
  subjectName: 小米
  trackingStartDate: 2026-05-01
  trackingEndDate: null
```

UI 可顯示：

```text
第173天
下一個階段：10 天後滿 6 個月
```

### 2.9 StageRule Domain

#### 產品語意

`StageRule` 是 StageTracker 底下的「重複階段」規則。Rule 是設定，occurrence 是計算結果。

#### 已實作資料模型

```ts
StageRule {
  id: number
  stageTrackerId: number
  type: "every_n_days" | "every_n_weeks" | "every_n_months" | "every_n_years"
  intervalValue: number
  intervalUnit: "days" | "weeks" | "months" | "years"
  labelTemplate?: string
  reminderOffsetDays?: number
  status: "active" | "paused" | "archived"
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- `createStageRule` 只允許建立在存在且未 archived 的 StageTracker 底下。
- `createStageRule` 只建立 StageRule；StageRule 是 generated occurrence 的推算規則，不是具體 StageRecord。
- `intervalValue <= 0` 會丟出 `ArgumentError`。
- active rule 會產生 generated occurrences。
- paused rule 不產生 occurrence。
- archived rule 不出現在 detail 的 visible rule list。
- StageRule 可編輯 type、intervalValue、intervalUnit、labelTemplate、reminderOffsetDays。
- StageRule 可暫停、恢復、封存；封存是 status 更新，不硬刪 rule。
- StageRule detail row 可展開查看該 rule 的下一輪 occurrence 與 related reminder count。
- StageRule 只支援針對「下一輪 occurrence」建立 related reminder；不支援每輪自動建立提醒模板，也不把 Item 直接綁到 StageRule。
- `labelTemplate` 支援 `{n}`、`{value}`、`{unit}`。
- `reminderOffsetDays == null` 時 fallback 到 `StageOccurrenceService.defaultReminderOffsetDays`，目前值是 `0`。

#### 範例

```text
StageRule:
  type: every_n_months
  intervalValue: 1
  intervalUnit: months
  labelTemplate: 小米滿 {value}{unit}
  reminderOffsetDays: 7
```

### 2.10 StageOccurrence Domain

#### 產品語意

`StageOccurrence` 是由 `StageTracker + StageRule + StageRecord` 合成的 read model，不是資料表。

generated occurrence 平常由 rule 動態計算；manual occurrence 來自 `StageRecord(sourceType = manual)`。

#### 已實作資料模型

```ts
StageOccurrence {
  stageTrackerTitle?: string
  subjectName?: string
  stageTrackerId: number
  stageRuleId?: number
  stageRecordId?: number
  sourceType: "generated" | "manual"
  occurrenceIndex?: number
  occurrenceDate: DateTime
  label: string
  note?: string
  reminderOffsetDays: number
  recordStatus?: "normal" | "acknowledged" | "ignored" | "archived"
  relatedItemSummary?: StageRelatedItemSummary
}
```

#### 已實作行為

- `StageOccurrenceService` 動態計算 upcoming、schedule、history、Home attention occurrences。
- dashboard upcoming 預設取未來 366 天內 manual stages，加上每條 active rule 的下一次 occurrence，排序後由 repository 取前 3 筆。
- StageTracker detail 的 upcoming occurrence row 可展開查看 compact related reminders；complete timeline 不做 inline expansion。
- schedule 只顯示未來 occurrence。
- history 只顯示過去 occurrence，日期由新到舊排序。
- ignored / archived records 不出現在一般 occurrence lists。
- acknowledged occurrence 保留在 schedule，但不進 Home attention。
- Home attention 條件：
  - StageTracker active。
  - occurrence 未 ignored、未 archived、未 acknowledged。
  - current date 已到 `occurrenceDate - reminderOffsetDays`。
- 同一天排序時 manual occurrence 優先於 generated occurrence。

#### 範例

```text
寶寶成長：3 天後滿 6 個月
寶寶成長：副食品階段快到了
```

#### MVP 待完成

- Home attention occurrence 已支援「知道了」；「忽略這次」的 UI 入口、確認流程與 undo 尚未完成。

### 2.11 StageRecord Domain

#### 產品語意

`StageRecord` 記錄 manual important stage，或 generated occurrence 的使用者互動。UI 上 manual StageRecord 稱為「重要階段」。

#### 已實作資料模型

```ts
StageRecord {
  id: number
  stageTrackerId: number
  stageRuleId?: number
  sourceType: "generated" | "manual"
  occurrenceIndex?: number
  occurrenceDate: DateTime
  relativeAmount?: number
  relativeUnit?: "days" | "weeks" | "months" | "years"
  status: "normal" | "acknowledged" | "ignored" | "archived"
  label: string
  note?: string
  reminderOffsetDays?: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 已實作行為

- manual important stage 一建立就寫入 `StageRecord(sourceType = manual, status = normal)`。
- manual important stage 可建立在過去日期，用於補記已經歷階段。
- generated occurrence 只有被 acknowledged、ignored、建立 related item 等互動時才建立 `StageRecord`。
- 建立 recurring StageRule 後不立即 materialize future occurrence；只有 related reminder、acknowledged、ignored 或其他需要保存互動狀態時才寫入 generated StageRecord。
- generated record 以 `stageRuleId + occurrenceIndex` 作 unique key。
- `acknowledgeOccurrence` 會 upsert generated record 並設為 `acknowledged`。
- `ignoreOccurrence` 會 upsert generated record 並設為 `ignored`。
- `deleteOrArchiveImportantStage`：
  - 未來 manual stage 會刪除。
  - 已過去 manual stage 會改為 archived。
- manual important stage 可編輯 label、occurrenceDate、note、reminderOffsetDays。
- manual important stage UI 使用「刪除」文案；repository 現行語意仍是未來 stage 可硬刪、過去 stage 改為 archived。
- recurring generated occurrence 不可透過 manual important stage 編輯流程修改。
- note 不作為 status。

#### 範例

```text
Manual StageRecord:
  label: 副食品階段
  occurrenceDate: 2026-11-01
  relativeAmount: 6
  relativeUnit: months
  note: 可以先和醫生確認，準備餐具與高腳椅
  reminderOffsetDays: 14
```

### 2.12 StageRelatedItem Domain

#### 產品語意

`StageRelatedItem` 連接 `StageRecord` 與 `Item`。它表示某個階段引導使用者建立了一件相關提醒。

#### 已實作資料模型

```ts
StageRelatedItem {
  id: number
  stageRecordId: number
  itemId: number
  createdAt: DateTime
  updatedAt: DateTime
}
```

```ts
StageRelatedItemSummary {
  doneCount: number
  activeCount: number
  pausedCount: number
  skippedCount: number
}
```

#### 已實作行為

- 一個 StageRecord 可以關聯多個 Items。
- 從 generated occurrence 建立 related item 時，repository 會先建立 StageRecord，再建立 Item，再建立 StageRelatedItem。
- Recurring rule 建立「下一輪提醒」時，UI 先推導下一輪 StageOccurrence，再走相同的 generated occurrence materialization 流程；舊提醒固定屬於當次 StageRecord，不會隨下一輪推進而轉移。
- 建立 related item 時，Item type 固定為 `fixed`，`scheduleType = oneTime`，`overduePolicy = waitForAction`。
- Item due date 預設等於 stage occurrence date；使用者可在 dialog 輸入其他 due date。
- related item 的完成、略過、暫停、封存不回寫 StageRecord status。
- related item summary：
  - archived item 不納入 summary。
  - done 計入 `doneCount`。
  - paused 計入 `pausedCount`。
  - skipped 計入 `skippedCount`。

#### 範例

```text
StageRecord: 副食品階段
Related Item: 準備副食品餐具
```

顯示摘要：

```text
相關提醒：1 / 2 已完成，1 個已暫停，1 個已跳過
```

### 2.13 AttentionPolicy 與 AppSettings

#### 已實作資料模型

```ts
AttentionPolicy {
  warningAfterDays?: number
  dangerAfterDays?: number
  warningBeforeDays?: number
  dangerBeforeDays?: number
  source: "systemDefault" | "userCustomized"
}
```

```ts
AppSettings {
  reminderTone: "gentle" | "standard" | "early" | "urgent"
  notificationReminderTime: "HH:mm"
  updatedAt: DateTime
}
```

Drift table `app_settings` 另有固定 `id = 1`、`createdAt`、`updatedAt`。

#### 已實作行為

- `AttentionPolicyResolver` 可根據 `ReminderTone` 推導 fixed、flexible、stock 類型的提醒門檻。
- `AppDatabase.beforeOpen` 會確保 `app_settings` 有 `id = 1` 的 row。
- 設定頁 route 已實作：`/feature/settings`，route name 是 `settings`。
- 設定頁一般設定暴露 `reminderTone` 與 notification reminder time；system StageTracker 顯示開關仍保留底層設定 / repository 行為，但不出現在一般 UAT UI。
- 設定頁資料管理提供 JSON backup / import / Reset Personal local data。Backup payload 使用 `app = reminder_app`、`schemaVersion = 1`、`exportedAt` ISO-8601 與 `data` keys：`packs/items/resources/stages/stageTrackers/customTemplates/relations/activityLogs`。
- 上述 backup JSON 的 `schemaVersion = 1` 是 legacy `backupFormatVersion`，不是 `driftSchemaVersion`。
- Backup 包含 user-created Pack、Item、Resource、user-created StageTracker、StageRule、StageRecord、StageRelatedItem、ResourceConsumptionRule、自訂 PackTemplate、ItemActionRecord 與 ResourceActionRecord；不包含 system StageTracker、debug-only setting、temporary UI state 或 app settings。
- Import 採 replace all user data，不做 merge；匯入前檢查 `app` 與 `schemaVersion`，失敗時不改動現有資料。匯入時 system default Pack 會以目前資料庫 seed 重建 / 保留，backup 中指向舊 system default Pack 的 `packId` 會 remap 到目前 system default Pack。
- Reset Personal local data 會清空 Personal user data，並保留或重建 system default Pack、`app_settings` 與 system default StageTracker。
- 現有 JSON backup 是 legacy local export / import；Phase 0 不修改 backup production code。
- Shared Pack remote access 不由 local backup 恢復。Shared Pack cache、membership、invite code、remote identity mapping 與 credential 不應被當成傳統 backup recovery data。
- Reset Personal local data 不可清除 `shared_pack_cache`、`shared_membership_cache`、`shared_item_cache`、anonymous remote identity/session 或 Shared Pack remote access metadata；否則 remote membership 仍存在但 client 沒有 v1 membership discovery API，使用者可能無法重新開啟既有 Shared Pack。
- Shared Pack reset / unlink / sign-out / clear Shared cache 必須是日後獨立流程。若未來需要清除 Shared data，必須先定義 remote membership 是否保留、identity/session 是否保留、cache rebuild 方法，以及 account binding / recovery 路徑。
- v1 不新增 `listMySharedPacks`、`recoverMyMemberships`、`clearSharedData` 或 `signOutSharedIdentity`。
- Supabase access token、refresh token、service role key 或其他 credential 永遠不可進入 backup。
- 未綁定帳號時，local backup 可保護 Personal local data；已綁定帳號後的長期方向是 Personal / Shared active data 由帳號與 remote membership 恢復。
- Notification reminder time 預設為 `09:00`，更新後會透過既有 daily attention notification sync 使用新時間。
- `Preview date` 是 developer-only setting，用於測試不同日期下的提醒狀態，不出現在一般設定。

#### 範例

```text
ReminderTone.standard: 使用較平衡的 warning / danger 門檻。
ReminderTone.early: 較早提醒使用者。
```

## 3. 跨 Domain 行為

### 3.1 完成 Item 並消耗 Resource

`ItemRepository.markDone` 套用 resource consumption rules 時，同一個 transaction 內包含：

1. 計算 item done action。
2. 更新 item snapshot。
3. 插入 `ItemActionRecord(done)`。
4. 查詢 matching enabled `ResourceConsumptionRule`。
5. 僅對 active quantity-based resource 扣量。
6. quantity clamp 到 `0`。
7. 插入 `ResourceActionRecord(consumed)`，並寫入 `sourceItemActionRecordId`。
8. 新 done record payload 寫入完成前 `undoSnapshot`，供「恢復成未完成」精準還原。

Matching rule 條件：

- `rule.itemId == item.id`
- `rule.isEnabled == true`
- `rule.triggerActionType == done`
- resource active
- resource config 是 `QuantityBasedResourceConfig`

### 3.1.1 Undo Item Done

`ItemRepository.undoDone` 是「按錯完成」的撤銷 / 抵銷流程，不是刪除歷史。

同一個 transaction 內包含：

1. 驗證輸入 record 存在、類型為 `done`、尚未 reverted，且 payload 有 `undoSnapshot`。
2. 插入 `ItemActionRecord(reverted)`，payload 記錄 `reason = undo_done` 與被撤銷的 done record id。
3. 將原 done record 標記 `isReverted = true`，寫入 `revertedAt` 與 `revertedByActionRecordId`。
4. 依 `undoSnapshot` 還原 item fixed / state snapshot 欄位。
5. 查詢原 done 產生的 `ResourceActionRecord(consumed)`，不重新計算 consumption rule。
6. 逐筆將 quantity resource 補回原 consumed amount，標記原 consumed record reverted，並新增 `ResourceActionRecord(reverted)`。

disabled consumption rule 不影響 undo；archived resource 仍可被補回，因為這是撤銷歷史錯誤，不是新的消耗行為。

### 3.2 建立 Item 與 Resource Binding Draft

Item 建立頁可以先保留 resource binding draft；使用者儲存前不得寫入 DB。

支援兩種 draft：

- 綁定既有同 Pack active quantity-based resource。
- 建立新的 quantity-based resource 並綁定。

送出時同一個 transaction 完成：

1. resolve pack。
2. create item。
3. insert `ItemActionRecord(created)`。
4. 若有 new resource draft，create resource。
5. 若有 new resource draft，insert `ResourceActionRecord(created)`。
6. insert `ResourceConsumptionRule`。

### 3.3 從 StageOccurrence 建立 Related Item

當使用者從某個 stage 建立 related item 時，同一個 transaction 完成：

1. 若來源是 generated occurrence 且尚無 StageRecord，建立 `StageRecord(status = normal)`。
2. create fixed one-time item。
3. insert `ItemActionRecord(created)`。
4. insert `StageRelatedItem(stageRecordId, itemId)`。

建立出的 Item：

- `type = fixed`
- `scheduleType = oneTime`
- `anchorDate = dueDate`
- `dueDate` 預設為 stage occurrence date
- `overduePolicy = waitForAction`

### 3.4 封存 Pack

system default pack 不可封存。

自訂 Pack 封存時 UI 提供：

- 一起封存內容。
- 移到「一般」。
- 取消。

「一起封存內容」會封存 Pack、active / paused Items、active / paused Resources、active StageTrackers。

「移到一般」會封存 Pack，並把 Items、Resources、StageTrackers 的 `packId` 改成 system default pack id，原 lifecycle status 不變。

這是現有 Personal Pack lifecycle 語意，不可直接套用到 Shared Pack。

Shared Pack lifecycle 必須獨立規格化，至少要分開處理：

- Personal Pack archive
- Shared Pack leave
- Shared Pack member removal
- Shared Pack archive
- Shared Pack deletion

Shared Pack v1 支援最小建立、加入、查看、metadata update、state-based Shared Item management、invite code get-or-create / rotate 與完成流程。leave、owner transfer、last owner、remote archive、remote delete、取消共享後轉回 Personal Pack 等流程屬於 v1.x 或後續版本，不屬於現有 local Pack archive 行為。

## 4. UI 心智模型

### 4.1 使用者語言

```text
Item = 要做的事
Resource = 要留意的資源
StageTracker = 階段追蹤
StageRule = 重複階段
Manual StageRecord = 重要階段
Pack = 生活場景
```

UI 不顯示 raw domain class 名稱，不把 enum name 當使用者文案。

### 4.2 Home

Home route：`/`，route name：`home`。

Home 已實作：

- attention summary card。
- attention summary card 的日期 badge 顯示目前生效日期，格式為 `yyyy/MM/dd`；developer preview date 啟用時跟隨覆蓋日期。
- attention summary 的 `dangerCount` / `warningCount` 包含 Item 與 Resource；主文案使用「今天有 X 項需要留意」。
- Pack filter。
- danger attention section：混合顯示 danger Item 與 danger Resource。
- warning attention section：混合顯示 warning Item 與 warning Resource。
- upcoming stage section。
- StageTracker 本身不進入 danger / warning；StageOccurrence 保留在 upcoming stage section。
- Stage Home card 的「知道了」 action。
- Home 最下方有「今天已完成」section，依 preview date 顯示當天有效 `ItemActionRecord(done)`、`ResourceActionRecord(refilled / adjusted)`，以及當天 acknowledged 的 `StageRecord`。
- 「今天已完成」預設收合；Item done entry 若有 `undoSnapshot` 可用 undo icon 恢復成未完成，undo 後該 entry 從 section 移除。
- Today completed section 跟隨 Pack filter：Item 依 item pack、Resource 依 resource pack、Stage 依 tracker pack。

Pack filter：

- 顯示「全部」與所有 active Pack。
- 包含 system default pack「一般」。
- 「全部」選取時顯示剔號。
- 未選取 Pack chip 只顯示 emoji。
- 選取 Pack chip 顯示 emoji 與 Pack title，不顯示剔號，hover / pressed 時不顯示陰影。
- Pack chip 以固定 label layout 顯示 emoji，避免選取狀態切換時 emoji 位置跳動。
- Pack title 保留於 tooltip / accessibility label。
- 點擊 Pack icon 只篩選 Home 內容，不進入 Pack detail page。

### 4.3 Item 管理與編輯

Item 管理 route：`/manage`，route name：`items-management`。

Item edit routes：

- create：`/item/new`，route name：`item-new`
- edit：`/item/:id`，route name：`item-edit`

已實作 UI：

- Item 建立 / 編輯只提供 `fixed` 與 `stateBased`。
- 建立時可選生活場景；選「之後決定」時寫入 system default pack。編輯 / 唯讀脈絡中的 system default pack 顯示為「一般」。
- 編輯既有 Item 時可變更 Pack；跨 Pack 搬移會顯示確認流程，並依 repository 規則處理 linked Resources 與 Stage related links。
- locked pack mode 會隱藏 pack field，並把 Item 建在指定 Pack。
- Item 編輯頁有「消耗資源」區塊，可綁定 existing quantity-based resource。
- 建立流程可 inline 新增 Pack。

### 4.4 Resource 管理

Resource 管理 route：`/feature/resources-management`，route name：`resources-management`。

已實作 UI：

- 功能頁與 Item 管理頁都可進入 Resource 管理。
- Resource 管理頁支援新增資源。
- 列表顯示 active / paused resources。
- Resource card 顯示名稱、類型、derived status、數量或預計剩餘天數。
- card 空白處開 detail dialog。
- add icon 執行補充。
- overflow menu 支援調整、編輯、詳細資訊、歷史紀錄、封存。
- `adjust` 只出現在 quantity-based resource。
- Resource edit 不直接修改目前數量 / 可用天數；資源變動需透過補充或調整流程留下 `ResourceActionRecord`。

Resource history route：`/resource/:id/history`，route name：`resource-history`。

Resource history 使用 compact timeline UI：頁首顯示 resource summary，支援 action filter chips 與「顯示已抵銷紀錄」切換。一般狀態預設隱藏 `isReverted = true` 的原紀錄與 `actionType = reverted` 的補償紀錄，但資料仍保留並可在切換後顯示。

Item history route：`/item/:id/history`，route name：`item-history`。

Item history 使用 compact timeline UI：頁首顯示 item summary，支援「全部 / 完成 / 已回復 / 資源影響」filter chips 與日期分組。Item edit AppBar overflow 與 Item management row overflow 都提供「歷史紀錄」入口。

Item history 的 done + reverted 以 read model 合併成「完成，後來已回復」一筆主要 timeline row，並在同一列顯示完成日期、回復日期與 resource impact sub rows。Fixed item history 不顯示 preview date。

### 4.5 StageTracker UI

StageTracker 管理 route：`/feature/stage-trackers`，route name：`stage-trackers`。

已實作 UI：

- bottom navigation 不再有階段追蹤主入口；StageTracker overview 從 More page 的「階段追蹤」入口進入。
- 列表分為「進行中」與「已完成追蹤」。
- 建立流程填入名稱、對象名稱、開始日期、生活場景。
- 建立後進入 detail dashboard。
- detail dashboard 顯示累積時間、最近 / 待確認階段、即將到來階段、重複階段列表。
- detail dashboard 提供 unified `加入階段` dialog，可建立重要階段或重複階段。
- detail AppBar overflow 提供「編輯階段追蹤」、「完整時間線」、「封存追蹤器」。
- destructive action 使用紅字並在執行前顯示 confirmation dialog。
- 重複階段 compact row overflow 提供編輯、暫停 / 恢復、封存。
- complete timeline route 顯示即將到來與已經歷 stages。
- complete timeline 中 manual important stage row overflow 提供新增提醒事項、編輯、封存；generated occurrence 不顯示 manual stage 管理操作。
- schedule / history 舊 route 保留可用，但主要 detail 入口導向 complete timeline。
- StageTracker detail 的 upcoming stage row 可點擊展開 / 收起 related reminders；row 右側仍不顯示 standalone add / eye icon，只保留 manual stage overflow。
- expanded related reminders 使用 compact list，顯示 title 與 due/status，點 row 開啟 Item summary dialog。
- 無 related reminders 時，expanded content 顯示 compact「建立相關提醒」文字 button；已有 related reminders 時仍可建立更多。
- complete timeline 的 stage row 不支援 inline expansion，維持 compact timeline row 與 manual stage overflow。
- overview 在沒有 user-created visible tracker，或只有 system default tracker 時，顯示 dashed add card：`新增追蹤 / 記錄一件正在累積的事`。
- system default tracker 在 detail overflow 顯示「從列表隱藏」，不顯示 edit / archive。

### 4.6 Pack 管理

Pack 管理 route：`/feature/item-packs-management`，route name：`item-packs-management`。

已實作 UI：

- 新增自訂 Pack。
- 從預設 / 自訂模版建立 Pack + Items。
- 從既有 active Pack 儲存自訂模版。
- 編輯自訂 Pack 名稱、description、emoji。
- 系統依 Pack 名稱推薦 emoji，使用者可手動選擇。
- 對自訂 Pack 使用「上」「下」調整排序。
- 封存自訂 Pack。
- system default pack 顯示但不可編輯、不可封存。

## 5. Drift Schema

目前 `driftSchemaVersion`：`5`。

注意：`backupFormatVersion`、`widgetSnapshotSchemaVersion`、planned `remoteApiContractVersion` 與 planned `remoteSnapshotSchemaVersion` 目前值都是 `1`，但它們不是 Drift schema version。Shared Pack remote protocol versions 是 planned contract / not implemented，尚未有 production API 或 table。

### 5.1 item_packs

```text
id
title
description
iconEmoji
orderIndex
status
isSystemDefault
createdAt
updatedAt
```

### 5.2 items

```text
id
packId
title
description
status
type
attentionPolicySource
fixedScheduleType
fixedScheduleInterval
fixedMonthlyDay
fixedRepeatRuleV2
fixedAnchorDate
fixedDueDate
fixedTimeOfDay
fixedOverduePolicy
fixedExpectedBeforeMinutes
fixedWarningBeforeMinutes
fixedDangerBeforeMinutes
stateAnchorDate
stateExpectedAfterMinutes
stateWarningAfterMinutes
stateDangerAfterMinutes
lastDoneAt
createdAt
updatedAt
```

### 5.3 item_action_records

```text
id
itemId
actionType
actionDate
remark
payload
isReverted
revertedAt
revertedByActionRecordId
createdAt
updatedAt
```

### 5.4 resources

```text
id
packId
title
description
status
type
timeAnchorDate
timeDurationDays
timeExpectedBeforeDays
timeWarningBeforeDays
timeDangerBeforeDays
quantityCurrent
quantityUnitLabel
quantityExpectedThreshold
quantityWarningThreshold
quantityDangerThreshold
lastRefilledAt
createdAt
updatedAt
```

### 5.5 resource_consumption_rules

```text
id
resourceId
itemId
triggerActionType
consumeAmount
isEnabled
createdAt
updatedAt
```

### 5.6 resource_action_records

```text
id
resourceId
actionType
actionDate
amount
resultingQuantity
addedDays
resultingDurationDays
sourceItemActionRecordId
remark
isReverted
revertedAt
revertedByActionRecordId
createdAt
updatedAt
```

### 5.7 stage_trackers

```text
id
packId
title
subjectName
trackingStartDate
trackingEndDate
status
isSystemDefault
systemKey
isHidden
createdAt
updatedAt
```

### 5.8 stage_rules

```text
id
stageTrackerId
type
intervalValue
intervalUnit
labelTemplate
reminderOffsetDays
status
createdAt
updatedAt
```

### 5.9 stage_records

```text
id
stageTrackerId
stageRuleId
sourceType
occurrenceIndex
occurrenceDate
relativeAmount
relativeUnit
status
label
note
reminderOffsetDays
createdAt
updatedAt
```

Unique key：

```text
stageTrackerId + stageRuleId + occurrenceIndex
```

### 5.10 stage_related_items

```text
id
stageRecordId
itemId
createdAt
updatedAt
```

### 5.11 app_settings

```text
id
reminderTone
notificationReminderTime
createdAt
updatedAt
```

### 5.12 pack_templates

```text
id
templateName
iconEmoji
description
createdAt
updatedAt
```

### 5.13 pack_template_items

```text
id
templateId
orderIndex
title
type
attentionPolicySource
fixedScheduleType
fixedScheduleInterval
fixedMonthlyDay
fixedRepeatRuleV2
fixedTimeOfDay
fixedOverduePolicy
fixedExpectedBeforeMinutes
fixedWarningBeforeMinutes
fixedDangerBeforeMinutes
stateExpectedAfterMinutes
stateWarningAfterMinutes
stateDangerAfterMinutes
createdAt
updatedAt
```

## 6. MVP 待完成

本章只列產品已明確要收斂，但目前 repo 尚未完整實作的 MVP 項目。這些項目不可寫入「已實作行為」。

- Stage ignore UI：提供 generated occurrence 的「忽略這次」入口、確認流程與 snackbar undo。
- ResourceConsumptionRule 管理 UI：編輯 consume amount、停用、重新啟用。
- Item related stage source 顯示：在 Item 詳情或摘要中清楚呈現來源 StageTracker / StageRecord。
- archived Pack / StageTracker 的管理入口。

## 7. 非 MVP / 長線方向

本章列暫不納入 MVP 的方向。實作前必須另行更新 core spec。

- snooze。
- deferred action 恢復。
- time-based resource 由 Item action 自動消耗。
- 生日、紀念日。
- archived StageTracker 的完整瀏覽與還原流程。
- Resource history 跳回來源 Item action。
- 多來源 related item。
- Pack 搜尋與 drag and drop 排序。
- Personal Pack detail page。Shared Pack 可在 v1 擁有 compact Shared Pack detail / settings page，但該頁是 members、invite、manual refresh 與 Shared Items 的 context，不代表 Personal Pack 也需要 detail page。

## 8. 命名規則

### 8.1 必須使用

- `ItemPack`
- `Item`
- `ItemConfig`
- `FixedItemConfig`
- `StateBasedItemConfig`
- `ItemActionRecord`
- `Resource`
- `ResourceConfig`
- `TimeBasedResourceConfig`
- `QuantityBasedResourceConfig`
- `ResourceConsumptionRule`
- `ResourceActionRecord`
- `StageTracker`
- `StageRule`
- `StageOccurrence`
- `StageRecord`
- `StageRelatedItem`
- `AttentionPolicy`
- `AppSettings`

### 8.2 禁止重新引入

- 把 Resource 放回 Item type。
- 把 Resource availability config 放回 Item table。
- 把 StageTracker 當成 Item。
- 用完成、略過、延後等 Item action 直接表示 StageTracker 階段狀態。
- 在 UI 顯示 raw domain class name 或 raw enum name。

### 8.3 UI 文案原則

- Pack 使用「生活場景」。
- Item 使用「提醒」、「要做的事」或具體責任名稱。
- Resource 使用「資源」、「庫存」、「可用天數」等生活語言。
- StageTracker 使用「階段追蹤」。
- StageRule 使用「重複階段」。
- manual StageRecord 使用「重要階段」。
- acknowledged 使用「知道了」。
- ignored 使用「忽略這次」。
