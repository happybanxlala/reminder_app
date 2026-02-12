# Reminder App

這是一個使用 Flutter 打造的 Reminder App MVP，採用：

- Riverpod（狀態管理）
- go_router（路由）
- Drift + SQLite（資料層）

## 環境需求

在本機執行前，請先安裝：

- Flutter SDK（建議使用 stable channel）
- Dart SDK（通常已隨 Flutter 安裝）
- Android Studio / Xcode（依目標平台）

可先確認版本：

```bash
flutter --version
dart --version
```

## 安裝相依套件

```bash
flutter pub get
```

## 產生 Drift 程式碼（第一次或資料表變更後）

本專案使用 Drift code generation，請執行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

若要在開發中持續監看並自動產生：

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## 自動化腳本

新增兩個常用腳本放在 `scripts/`：

- `./scripts/setup.sh`：初始化開發環境，會依序執行版本確認、`flutter pub get`，以及 Drift code generation。
- `./scripts/maintain.sh`：日常維護檢查，會依序執行程式格式檢查、`flutter analyze` 與 `flutter test`。

可直接執行：

```bash
./scripts/setup.sh
./scripts/maintain.sh
```

## 執行（Run）

### 1) 查看可用裝置

```bash
flutter devices
```

### 2) 在預設裝置執行

```bash
flutter run
```

### 3) 指定裝置執行（範例）

```bash
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

## 建置（Build）

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle（Play Store）

```bash
flutter build appbundle --release
```

### iOS（需 macOS + Xcode）

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Windows / macOS / Linux

```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 常用檢查

```bash
flutter analyze
flutter test
```

## 專案結構（重點）

```text
lib/
  app/
  features/
    reminders/
      data/
        local/
          app_database.dart
          tables.dart
          daos.dart
        reminder_repository.dart
      domain/
      services/
      ui/
```

