## 新 item record data model

使用者對item 作出完成/跳過時，會建立record。用於查看使用者動態及items的歷史紀錄

- id
- item_id
- status; done/skipped/延期／未處理
- remark
- createdAt
- updatedAt

## item 的 4種提醒類型

### 一般通知 (Fixed Based)

example: Podcast 晚上10點（每天）, 跑步 早上9點(每3天)

- `nodeDate` (起點日)
- `dueDate` (到期日)
- `scheduleType` (週期)
- Can overdue? No

- Config:
    - expectedBefore
    - warningBefore
    - dangerBefore

- 系統: 下一輪:
    - `nodeDate` ＝ scheduleFunc(`nodeDate`, scheduleType)
    - `dueDate` = scheduleFunc(`dueDate`, scheduleType)

- 系統: 逾期(today > `dueDate`):
    - 直接進入下一輪

### 例行事務 (Fixed Based)

example: 飲水機加水（每星期）、餵罐（每天）

- `nodeDate` (起點日)
- `dueDate` (到期日)
- `scheduleType` (週期)

- Can overdue? Yes

- Config:
    - expectedBefore
    - warningBefore
    - dangerBefore

- [系統]下一輪:
    - `nodeDate` = scheduleFunc(`nodeDate`, `scheduleType`)
    - `dueDate` = scheduleFunc(`dueDate`, `scheduleType`)

- [系統]逾期(now > DueDate):
    - 等待使用者完成

- [使用者]逾期時完成/跳過:
    - 詢問使用者，如何決定下一輪起點日`nodeDate`，照原定日期或逾期天數

### 待辦事務 (State Based)

example: 飲水機換濾水網

- `nodeDate`

- Config:
    - expectedAfter
    - warningAfter
    - dangerAfter

- [系統]下一輪:
    - `nodeDate` = nextday


### 資源補給(Resource Based)

example: 貓罐頭補貨

- `nodeDate`

- Config:
    - `durationDays` 可持續天數
    - expectedBefore
    - warningBefore
    - dangerBefore 

- [使用者]完成:
    - 詢問使用者需添加天數
    - `durationDays` = `durationDays` - (today - `nodeDate` + 1) + 添加天數
    - `nodeDate` = nextday

- [使用者]逾期時完成:
    - 詢問使用者需添加天數
    - `durationDays` = 添加天數
    - `nodeDate` = today