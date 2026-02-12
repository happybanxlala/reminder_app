#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[setup] 取得 Flutter / Dart 版本資訊..."
flutter --version
dart --version

echo "[setup] 安裝相依套件..."
flutter pub get

echo "[setup] 產生 Drift 程式碼..."
dart run build_runner build --delete-conflicting-outputs

echo "[setup] 完成。"
