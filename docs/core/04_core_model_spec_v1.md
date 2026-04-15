---
This is the single source of truth for core data model and behavior.
---

# 1. 核心理念（必讀）

本系統不再以「任務分類」為核心，而是：

> **以「責任本質」＋「狀態變化」作為設計基礎**

---

## 核心轉變

| 舊模型                        | 新模型                               |
| -------------------------- | --------------------------------- |
| Task 分類（type1/type2/type3） | Item 本質（fixed / state / resource） |
| due date 驅動                | 狀態（normal / warning / danger）驅動   |
| 今天要做什麼                     | 有沒有事情正在變糟                         |

---

# 2. 核心結構

---

## 2.1 ResponsibilityPack（責任場景）

```ts
ResponsibilityPack {
  id: string
  title: string
  description?: string
  createdAt: DateTime
}
```

用途：

* 組織責任（例如：養貓、家務）
* UI grouping 單位

---

## 2.2 ResponsibilityItem（責任項目）

```ts
ResponsibilityItem {
  id: string
  packId: string

  title: string
  description?: string

  type: ItemType

  config: ItemConfig

  lastDoneAt?: DateTime

  createdAt: DateTime
}
```

---

## 2.3 ItemType（本質分類）

```ts
enum ItemType {
  FIXED_TIME
  STATE_BASED
  RESOURCE_BASED
}
```

---

# 3. ItemConfig 定義

---

## 3.1 FIXED_TIME（固定時間型）

```ts
config = {
  schedule: {
    type: "daily" | "weekly" | "custom"
    time?: "HH:mm"
  }
}
```

用途：

* 每日餵罐
* 每日清理

👉 保留現有 task 行為

---

## 3.2 STATE_BASED（狀態型）🔥 核心

```ts
config = {
  expectedInterval: Duration

  warningAfter: Duration
  dangerAfter: Duration
}
```

---

## 3.3 RESOURCE_BASED（補給型）

```ts
config = {
  estimatedDuration: Duration

  warningBeforeDepletion: Duration
}
```

👉 MVP 可先 fallback 成 STATE_BASED

---

# 4. 狀態模型（核心）

---

## 4.1 狀態定義

```ts
enum ItemStatus {
  NORMAL
  WARNING
  DANGER
  UNKNOWN
}
```

---

## 4.2 計算規則（STATE_BASED）

```ts
elapsed = now - lastDoneAt
```

---

```ts
if lastDoneAt == null:
    status = UNKNOWN

elif elapsed < expectedInterval:
    status = NORMAL

elif elapsed < dangerAfter:
    status = WARNING

else:
    status = DANGER
```

---

## 4.3 FIXED_TIME 狀態

```ts
todayScheduled = isScheduledToday(item)

if todayScheduled and not done:
    status = WARNING

if missed:
    status = DANGER
```

---

# 5. 使用者感受對應（重要）

⚠️ 不作為資料欄位，只作為 UI 呈現

| Status  | UI 感受 |
| ------- | ----- |
| NORMAL  | 想做就做  |
| WARNING | 差不多該做 |
| DANGER  | 已經拖太久 |

---

# 6. UI 顯示規則

---

## 6.1 Home（唯一核心畫面）

Home 顯示：

> **需要注意的責任狀態（跨 Task + Timeline）**

---

### 顯示優先級

1. DANGER
2. WARNING
3. NORMAL（可隱藏）

---

### 顯示內容

```text
🐱 彩月

🚨 貓砂尿片已 7 天未更換
⚠️ 飲水機已 3 天未加水
```

---

## 6.2 Item 顯示

每個 item 必須包含：

* title
* elapsed time（已多久未做）
* status
* 可選：後果描述

---

# 7. 使用者操作

---

## 7.1 完成行為

```ts
onComplete(item):
    item.lastDoneAt = now
```

---

## 7.2 不產生 instance（STATE_BASED）

STATE_BASED 不需要：

* task instance
* completion history（MVP 可省略）

---

# 8. 提醒策略（Notification）

---

## 8.1 觸發方式

```ts
on status change:
    NORMAL → WARNING
    WARNING → DANGER
```

---

## 8.2 頻率控制

```ts
max 1 reminder / day / item
```

---

## 8.3 文案原則

提醒必須解釋：

> 為什麼現在出現

例如：

* ❌ 「請清理貓砂」
* ✅ 「貓砂已 7 天未更換」

---

# 9. Timeline 關係

---

## 9.1 Timeline 定位

```ts
Timeline {
  id
  title
  startDate
}
```

---

## 9.2 Milestone

```ts
Milestone {
  timelineId
  date
  title
}
```

---

## 9.3 與 Responsibility 的關係

* Responsibility = 行動與責任
* Timeline = 時間與意義

👉 不混合

---

# 10. MVP 範圍（強限制）

---

## 必做

* ResponsibilityPack
* ResponsibilityItem
* STATE_BASED
* 狀態計算
* Home 顯示（warning / danger）
* 完成操作

---

## 可延後

* RESOURCE 精細計算
* group 協作
* template marketplace
* timeline 深整合

---

# 11. 禁止事項（防止走歪）

---

❌ 不再實作：

* Task type1/type2/type3 分類
* 單純依 due date 的 reminder 系統
* 巨型通用 Reminder model
* UI 以資料分類為主

---

# 12. 最終產品北極星

---

> **讓重要的事，不會在無意識中變糟**

---

# 🧾 超精簡開發版（貼在螢幕旁）

```text
1. Item 有本質（fixed / state / resource）
2. Item 有狀態（normal / warning / danger）
3. 系統關注「變糟」，不是「到時間」
4. Home 只顯示：需要注意的東西
```