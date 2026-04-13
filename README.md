# Reminder App

Flutter MVP for a split reminder product model:

- `TaskTemplate + Task`
- `Timeline + Milestone`

正式規格與真相來源：

- `docs/01_mvp_spec.md`
- `docs/02_architecture_refactor.md`
- Drift schema in `lib/features/reminders/data/local/`

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run Checks

```bash
dart format lib test docs
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
  features/
    reminders/
      data/
        home_query_service.dart
        task_repository.dart
        timeline_repository.dart
        local/
          app_database.dart
          task_timeline_dao.dart
          tables.dart
      domain/
      presentation/
      providers/
        database_providers.dart
        home_providers.dart
        history_providers.dart
        task_providers.dart
        timeline_providers.dart
      ui/
        pages/
          home_page.dart
          history_page.dart
          management_page.dart
          task_timeline_editor_page.dart
```
