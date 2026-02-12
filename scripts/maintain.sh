#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[maintain] 檢查程式格式..."
dart format --set-exit-if-changed lib test

echo "[maintain] 靜態分析..."
flutter analyze

echo "[maintain] 執行測試..."
flutter test

echo "[maintain] 完成。"
