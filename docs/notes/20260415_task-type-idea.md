# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---

# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---

## Task 構思:

Task分為三類（未定名字）

---

### 類型1：想做就做（不重要）:

* 例子: 跑步
* 使用者角度：非必要的任務，只會期限內顯示

#### 關鍵欄位
- Start Date／ 開始日
- Completion Days/ 完成期限

### 提醒窗口（未定）
- [跑步]

#### Date Flow
- 使用者「完成」、「跳過」操作勻正常修改task.status
- 超過完成期限及使用者無任何操作，task.status = 跳過
- 支援延期

---

### 類型2：需要完成（中等）:

* 例子: 清潔濾水器
* 使用者角度：生活任務，不需要馬上完成，但要保持醒目，避免溜掉

#### 關鍵欄位
- Start Date/ 開始日

### 提示窗口（未定）
- 當天：清潔濾水器
- 到期3天：3天未有[清潔濾水器]紀錄
- 到期21天：21天未有[清潔濾水器]紀錄

#### Date Flow
- 使用者「完成」、「跳過」操作勻正常修改task.status
- 超過完成期限及使用者無任何操作，task.status = 跳過

---

### 類型3：Deadline（重要）:
* 例子: 購入貓糧
* 使用者角度：必需在期限內完成，在到期前就需要開始提醒，

#### 關鍵欄位
- Deadline Date／ 到期日
- remind offset/ 提醒期

### 提示窗口（未定）
- 前3天：[購入貓糧]尚餘3天
- 到期日當天：[購入貓糧]今天到期，先速速處理
- 逾期2天：[購入貓糧]逾期2天，請盡快處理及檢查相關事項

#### Date Flow
- 使用者「完成」、「跳過」操作勻正常修改task.status
- 支援延期

---

### Remark
- 延期定義＆data flow
- 未比較與timeline 的語意，避兔衝突 
