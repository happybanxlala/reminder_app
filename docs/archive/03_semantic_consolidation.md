# Semantic Consolidation

本文件記錄本次「語意收斂」重構的最終結果，供後續開發者快速對齊 repo 心智模型。

## Canonical Truth

目前 repo 只以以下內容作為真相來源：

- `docs/01_mvp_spec.md`
- `docs/02_architecture_refactor.md`
- Drift schema: `tables.dart` + `app_database.dart`

## Final Vocabulary

- `Task`: 要完成的事，可 overdue
- `TaskTemplate`: recurring task 的模板
- `Timeline`: 從某天開始經過的時間，不可 overdue
- `Milestone`: timeline 的重要日子，只可 `noticed / skipped`

## Removed Legacy Concepts

已移除或禁止再出現在主流程命名中的概念：

- `Reminder`
- `RecurringReminder`
- `trackingMode`
- `triggerMode`
- `TimelineStatus.paused`
- mixed history aggregation
- 混合承載 Task 與 Timeline domain logic 的 single repository

## Naming Rules

- repository 依 domain 切分：`task_repository.dart` / `timeline_repository.dart`
- Home 聚合查詢集中在 `home_query_service.dart`
- providers 依用途切分：`task / timeline / home / history`
- page / route / mode 命名需直接指出 `home / task / task template / timeline`
- 文件不可再把 milestone 稱為 reminder，也不可把 timeline 當 task

## Migration Notes

- 舊 `reminder_repository.dart` 已移除
- DAO surface 已改為 `TaskTimelineDao`
- Home / History / Management 的資料來源已依 spec 分離
- dead legacy docs 與 unused domain aliases 已刪除
