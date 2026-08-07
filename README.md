# Reminder App

Flutter MVP for a split reminder product model:

- `Item Pack + Item`
- `Resource`
- `StageTracker + StageRule + StageRecord + StageRelatedItem`
- local JSON backup / import / reset
- large iOS / Android Home Widget

正式規格與真相來源：

- `docs/core/04_core_model_spec_v1.md`：現有 core domain / local model。
- `docs/core/05_home_widget_spec.md`：Home Widget boundary。
- `docs/core/06_shared_pack_direction_spec_v1.md`：Shared Pack product direction and phased scope。
- `docs/core/07_shared_pack_remote_contract_v1.md`：future remote request / contract catalog, including Shared cache, full-snapshot mutation consistency, membership/config invariants, UTC timestamp semantics, protocol version 1, idempotency and snapshot projection contracts。
- `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`：planned Shared Pack client runtime consistency, response ordering, cache trust, freshness, idempotent retry, and projection failure semantics。
- Drift schema implementation：`lib/features/reminders/data/local/`

Shared Pack v6 local storage capacity, the Phase 2a contract skeleton, and the
Phase 2c Drift-backed local cache read adapter are implemented. The repository
still has no production Shared projector/runtime, remote API, Supabase
dependency, remote table, RPC, auth flow, provider, or Shared Pack UI route.

StageTracker 模型採 rule-first：

- `StageTracker` 保存 `trackingStartDate` 與可選 `trackingEndDate`
- `StageRule` 定義 interval 與 reminder offset
- generated occurrence 於 Home / StageTracker detail 動態計算
- `stage_records` 只在 manual stage 或 generated occurrence 有互動時持久化
- `stage_related_items` 連接 stage 與由 stage 建立的 normal Item

## Drift Schema Note

- `driftSchemaVersion` 為 `6`，來源是 `AppDatabase.schemaVersion`。
- Personal 表結構位於 `lib/features/reminders/data/local/tables.dart`；Shared v6 declarations 位於 `lib/features/shared_packs/data/local/shared_pack_cache_tables.dart`。
- `backupFormatVersion` 目前為 `1`，來源是 `BackupPayload.currentSchemaVersion`；JSON 欄位仍名為 `schemaVersion`，但它不是 Drift schema version。
- `widgetSnapshotSchemaVersion` 目前為 `1`，來源是 `HomeWidgetSnapshot.currentSchemaVersion` 與 native widget supported schema。
- `remoteApiContractVersion = 1` / `remoteSnapshotSchemaVersion = 1` are planned contract values，尚未有 production API。

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
        backup_models.dart
        reminder_backup_service.dart
        home_repository.dart
        item_repository.dart
        resource_repository.dart
        stage_tracker_repository.dart
        local/
          app_database.dart
          reminder_dao.dart
          tables.dart
      domain/
      presentation/
      providers/
        backup_providers.dart
        database_providers.dart
        developer_settings_providers.dart
        home_providers.dart
        item_providers.dart
        resource_providers.dart
        stage_tracker_providers.dart
      ui/
        pages/
          home_page.dart
          feature_page.dart
          feature_management_sections.dart
          feature_management_resources.dart
          feature_page_activity.dart
          feature_page_more.dart
          feature_page_packs.dart
          feature_page_settings.dart
          item_edit_page.dart
          item_history_page.dart
          resource_edit_page.dart
          resource_history_page.dart
          stage_tracker_pages.dart
        widgets/
          editor_common_fields.dart
          item_config_form_section.dart
          item_summary_dialog.dart
  features/
    home_widget/
      application/
      data/
      providers/
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
