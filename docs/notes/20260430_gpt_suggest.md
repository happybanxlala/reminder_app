# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---
第一輪：產品觀感修整，不碰 schema

交給 Codex 的目標可以是：

1. 改 ReminderUiText 使用者文案

內部模型→使用者可見語言
Item→要照顧的事
Item Pack→責任包
Fixed→固定節奏
State Based→距離上次處理
Resource Based→庫存
Danger→需要處理
Warning→要留意
Timeline→時間線
Milestone→里程碑

2. Home 改成一頁式 sections，不再需要切tab

首頁
- 需要處理
- 要留意
- 即將到來

3. Resource completion dialog 修改文案

標題：補充了多少天份？
label：新增可用天數
helper：例如買了一包可用 30 天，就輸入 30
error：請輸入 1 天或以上

4. 隱藏開發期 placeholder 文案→「這裡之後會顯示事項動態」

5. 不改 domain model / database schema

===

第二輪：domain service 清理

1. 抽 item action service
2. 抽 snapshot update service
3. 抽 resource refill calculator
4. 補 repository tests:

- markDone(resourceBased, addedDays)
- markDone(stateBased) 更新 stateAnchorDate
- skip(resourceBased) 必須失敗
- archivePack 會封存 pack 內 items
- preview date 操作 actionDate 正確，但 updatedAt 用真實時間

5. 保持 UI 不動

===
第三輪：schema / migration 清理

只有在你確認沒有正式資料需要保留時才做。