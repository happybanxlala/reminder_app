# Reminder App

Flutter MVP for a split reminder product model:

- `Item Pack + Item`
- `Resource`
- `StageTracker + StageRule + StageRecord + StageRelatedItem`

正式規格與真相來源：

- `docs/core/04_core_model_spec_v1.md`
- Drift schema in `lib/features/reminders/data/local/`

StageTracker 模型採 rule-first：

- `StageTracker` 保存 `trackingStartDate` 與可選 `trackingEndDate`
- `StageRule` 定義 interval 與 reminder offset
- generated occurrence 於 Home / StageTracker detail 動態計算
- `stage_records` 只在 manual stage 或 generated occurrence 有互動時持久化
- `stage_related_items` 連接 stage 與由 stage 建立的 normal Item

## Drift Schema Note

- 早期開發期 migration（包含舊 `task` / `responsibility` cutover）已清理。
- 目前 repository 以乾淨的 Drift schema 為主，不再維護早期 migration 鏈。
- 現有 `schemaVersion` 仍保留必要的輕量 Drift migration，例如 v1 -> v2 新增固定週期欄位與 pack preset tables。

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run Checks

```bash
dart format lib test
flutter analyze
flutter test
```

## Run App

```bash
flutter run
```

## Project Structure

```text
lib/
  app/
    app_shell.dart
    router.dart
  features/
    reminders/
      data/
        home_repository.dart
        item_repository.dart
        stage_tracker_repository.dart
        local/
          app_database.dart
          reminder_dao.dart
          tables.dart
      domain/
      presentation/
      providers/
        database_providers.dart
        developer_settings_providers.dart
        home_providers.dart
        item_providers.dart
        stage_tracker_providers.dart
      ui/
        pages/
          home_page.dart
          feature_page.dart
          feature_management_sections.dart
          item_edit_page.dart
          stage_tracker_pages.dart
        widgets/
          editor_common_fields.dart
          item_config_form_section.dart
          item_summary_dialog.dart
```

## Documentation Rules

### Source of truth
Use only documents under `/docs/core/` for implementation decisions.

### Product thinking
Documents under `/docs/concept/` explain why the product is designed this way.

### Personal notes
Documents under `/docs/notes/` are exploratory notes only.
They are not implementation references.

### Archived docs
Documents under `/docs/archive/` are historical only and should not guide current decisions.
