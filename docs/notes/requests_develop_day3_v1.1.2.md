在新增 Task頁面:
- 針對一次性任務(`Task.kind = "one-time"`)，不需要建立TaskTemplate，直接建立Task即可。所以template_id欄位可以為null。(可評估目資料流是否允許)
- [UI]針對重複性任務(`Task.kind = "recurring"`)。若使用者選擇advance，才顯示offset欄位，其他選項則隱藏。

在主畫面 - Today分頁:
- 顯示當天到期的task(`today == task.dueDate if deferredDueDate = null` or `today == deferredDueDate`)
- 顯示當天是目標的milestone(`today == targetDate`)
- 僅提供查看功能（不支持點擊進入編輯頁面）

在主畫面 - Upcoming分頁:
- effectiveDueAt means `deferredDueDate` if `deferredDueDate != null` else `dueDate`
- 顯示立即提醒的task(`today != effectiveDueAt` && TaskTemplate.reminderRule = `immediate`)
- 顯示進入提醒期的task(`today >= effectiveDueAt - TaskTemplate.reminderRule.offset` && TaskTemplate.reminderRule != onDue)
- 顯示未來且進入提醒期的milestone(`today >= targetDate - Timeline.milestoneReminderRule.offset` && Timeline.milestoneReminderRule != onDue)
- 僅提供查看功能（不支持點擊進入編輯頁面）

在主畫面 - Overdue分頁:
- 顯示過期的task(`today > effectiveDueAt`)
- 於過期的task加入完成、跳過、延期、取消操作選項

在管理頁面 - 對TaskTemplate的操作:
- [UI]為TaskTemplate資訊卡加入`編輯`及`暫停`及`封存`按鈕﹐取消點擊TaskTemplate資訊卡進入編輯頁面的功能。
- [UI]若TaskTemplate的狀態為`paused`，則顯示`恢復`按鈕，並隱藏`暫停`按鈕。
- 編輯TaskTemplate時，ReminderRule欄位沒有反映當時template的reminderRule數值。（只會顯示預設值）
- [UI]編輯TaskTemplate時，若欄位選擇advance，才顯示offset欄位，其他選項則隱藏。

在管理頁面 - 對Timeline的操作:
- [UI]為Timeline資訊卡加入`編輯`按鈕﹐取消點擊Timeline資訊卡進入編輯頁面的功能。
- 編輯Timeline時，Timeline.MilestoneReminderRule欄位沒有反映當時Timeline.milestoneReminderRule數值。（只會顯示預設值）
- [UI]編輯Timeline時，若欄位選擇advance，才顯示offset欄位，其他選項則隱藏。
- [UI]編輯Timeline時，若顯示的milestone超於3個，則只顯示最近的3個milestone，並提供查看全部的選項。

在歷史紀錄分頁:
- [UI]顯示過去30天內完成、跳過、延期的task，並以頁數方式呈現，單頁顯示10筆紀錄。
- [UI]資訊卡上需加入updateAt欄位，顯示該紀錄的最後更新時間。

===========
建議 data model control:
- 針對創建一次性任務(`Task.kind = "one-time"`)，不需要建立TaskTemplate，直接建立Task即可。所以template_id欄位可以為null。
- 若取消的Task屬於重複性任務(`Task.kind = "recurring"`)，系統將其TaskTemplate也轉為 `paused`。
- 若暫停的TaskTemplate同時存在pending的Task，則將這些Task的狀態轉為 `cancelled`，並將它們的deferredDueDate設為null。
- 移除timeline.status enum中的 `paused` 狀態，timeline不再有暫停的概念。
- [Rule]TaskTemplate的狀態轉為 `archived`後成為唯讀，無法再被修改。
- [Rule]Timeline的狀態轉為 `archived`後成為唯讀，無法再被修改。

===========
紀錄用（可忽略）

