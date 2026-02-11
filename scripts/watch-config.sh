#!/usr/bin/env bash
# =============================================================
# OpenClaw 設定ファイル自動監視
# config/openclaw.json の変更を検知して自動反映
# 使い方: bash scripts/watch-config.sh
# 停止: Ctrl+C
# =============================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

echo "=========================================="
echo "  OpenClaw 設定ファイル監視を開始"
echo "=========================================="
echo ""
echo "監視対象: $ROOT_DIR/config/openclaw.json"
echo "停止: Ctrl+C"
echo ""

# fswatch のインストール確認（Mac）
if [[ "$(uname)" == "Darwin" ]]; then
  if ! command -v fswatch &> /dev/null; then
    echo "!!! fswatch がインストールされていません"
    echo "    インストール: brew install fswatch"
    exit 1
  fi

  # fswatch で監視
  fswatch -o "$ROOT_DIR/config/openclaw.json" | while read -r event; do
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 設定ファイルの変更を検知"
    echo "    設定を再読み込み中..."
    bash "$ROOT_DIR/scripts/reload-config.sh"
    echo ""
  done
else
  # Linux の場合は inotifywait
  if ! command -v inotifywait &> /dev/null; then
    echo "!!! inotify-tools がインストールされていません"
    echo "    インストール: sudo apt-get install inotify-tools"
    exit 1
  fi

  while true; do
    inotifywait -e modify "$ROOT_DIR/config/openclaw.json"
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 設定ファイルの変更を検知"
    echo "    設定を再読み込み中..."
    bash "$ROOT_DIR/scripts/reload-config.sh"
    echo ""
  done
fi
