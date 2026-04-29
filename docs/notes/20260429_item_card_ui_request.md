# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---
1. item pack 管理頁 > pack-item_card > item edit 頁: 
    - item 資料沒有snapshot 到 anchor date & due date 欄
2. stateBased-item 更新語意定義：
    - 開始日`anchorDate`當天為第1天
    - 若`warningAfter` = 4，在第4天item就要進入warning提示
    - 若`dangerAfter` = 10，在第10天item就要進入danger提示
3. resourceBased-item 完成後進入下一輪的規則：
    - 完成後，開始日＝當日
``` example:
anchor date = '2026/4/1'
duration day = 10

若完成於'2026/4/9' 並輸入 `addedDay` = 2
new data:
duration day = 4; //(durationday - (today - 1 - auchordate) + addedDay)
anchor date = '2026/4/9'
```

===
主頁 > resourced-item > 狀態欄（尾欄）: 補充剩於天數數值

主頁 > statebased-item > 狀態欄（尾欄）: 補充已持續天數

主頁 > fixed-item > 狀態欄（尾欄）: 補充剩餘天數／今天到期／過期

主頁 > item card: 移除提示列及相關的coding

===
不允許編輯item type


====
user setting
- define state-nextturn