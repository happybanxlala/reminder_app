# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---

# Core Spec 編排指引

本文件是下次修訂 core spec 的編排參考，不是 implementation source of truth。實作決策只以 `/docs/core/` 內的規格為準。

## 1. 修訂原則

- Core spec 必須符合目前 repo 內容；任何「已實作」聲明都要能在 `lib/features/reminders/**` 或 `test/**` 找到對應。
- 已實作內容、MVP 待完成、非 MVP / 長線方向必須分開寫。
- 不把未完成項目混入已實作行為。
- 程式模型、enum、table、route、repository API 使用 repo 內實際命名。
- UI 文案使用繁體中文與產品語意，不直接暴露 raw enum 或 raw class name。
- 舊文件、notes、archive 只能作背景理解，不可覆蓋 core spec 與 repo 事實。

## 2. 固定章節順序

Core spec 優先使用以下順序：

1. 總覽
2. 已實作模型
3. 跨 Domain 行為
4. UI 心智模型
5. Drift Schema
6. MVP 待完成
7. 非 MVP / 長線方向
8. 命名規則

章節順序穩定，可以降低 agent 下次修訂時重複搬移文字的風險。

## 3. Domain 小節格式

每個 domain 使用同一套小節：

```text
產品語意
已實作資料模型
已實作行為
範例
MVP 待完成
```

補充產品語意和例子只放在 `產品語意` 或 `範例`。不要把例子散落在資料模型、schema 或 transaction 規則裡。

## 4. 已實作內容的寫法

- 使用肯定描述，例如「已實作」「會」「固定」「只支援」。
- 避免用「建議」「應該」「未來可」描述已實作行為。
- route、enum、field、repository method 必須寫實際名稱。
- 若 UI 已存在但 service summary 尚未納入，分開描述。例如「Home 已顯示 Resource section」和「Resource 尚未納入 AttentionSummary」不能混成同一件事。

## 5. 未完成內容的寫法

- MVP 仍要做的項目放在 `MVP 待完成`。
- 長線想法放在 `非 MVP / 長線方向`。
- 不在已實作章節用含糊文字暗示尚未完成能力已存在。
- 若某能力只有 repository API、沒有 UI，就寫清楚「repository 已有，UI 未完成」。

## 6. 修訂前檢查清單

- 對照 domain files：`lib/features/reminders/domain/**`
- 對照 Drift schema：`lib/features/reminders/data/local/tables.dart`
- 對照 repository 行為：`lib/features/reminders/data/**_repository.dart`
- 對照 UI route：`lib/app/router.dart` 與各 page 的 `routePath / routeName`
- 對照 tests：`test/**`

## 7. 修訂後檢查清單

- 搜尋過時詞，確認沒有把舊模型重新寫回 core spec。
- 搜尋「建議」「應該」「未來可」，確認沒有拿這些字描述已實作行為。
- 搜尋未完成能力名稱，確認只出現在 `MVP 待完成` 或 `非 MVP / 長線方向`。
- 檢查 notes 檔沒有宣稱自己是 source of truth。
- 若修訂改變 product / domain 決策，補上日期與依據。

