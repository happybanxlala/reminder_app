# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---
主頁上，item小卡 UI要求：
- 由「標題列」, 「內容列」, 「提示列」由上而下組成
- 一般情況下會將[內容列]摺疊
- 「標題列」:
    - 剔選格
        - pending 時，可「完成」
        - `未開始`則變灰或隱藏(today < `AnchorDate`)
    - 標題
    - 類型(item `type` & `scheduletype`), 使用圓框文字
        - '一次', '每天', '每週'(`Fixed`)
        - '待辦'(`StateBased`)
        - '資源'(`ResourcedBased`)
    - 展開/摺疉符號(最右)
    - 列顏色代表狀態:
        - 淺綠色: normal/ expected duration
        - 淺黃色: warning
        - 淺紅色: danger
        - 深紅色: overdue
        - 白色: `未開始`
- 「內容列」:
    - pack title
    - Note
    - 開始日期
    - 到期日期（如有）
    - Overdue Policy (如有)
    - 「跳過」按鈕
- 「提示列」:
    - day = `AnchorDate` - today
    - For `未開始`(today < `AnchorDate`): "還有{day}日({`AnchorDate`})"

    - For `Fixed`+`autoAdvence` item:
        - normal: "時間充裕"
        - warning: "尚餘{day}日"
        - danger: "剩餘{day}日"
        
    - For `Fixed`+`waitForAction` item:
        - normal: "時間充裕"
        - warning: "尚餘{day}日, 請安排處理。"
        - danger: "剩餘{day}日, 請盡快處理。"
        - overdue: "已逾期{day}天，可能有其他事情受到影響，請盡快處理。"

    - For `StateBased` item:
        - normal: "目前狀況良好"
        - warning: "需安排時間處理"
        - danger: "已有{day}未有處理，請留意該狀況並馬上處理"

    - For `ResourcedBased`
        - normal: "物資充足"
        - warning: "需安排時間補貨"
        - danger: "請盡快留意補貨渠道及安排補貨"