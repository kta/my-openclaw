#!/usr/bin/env bash
# =============================================================
# OpenClaw 設定ファイル再読み込み
# 使い方: bash scripts/reload-config.sh
# =============================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

echo "==> OpenClaw 設定を更新中..."

# .env を読み込み
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "!!! .env ファイルが見つかりません"
  exit 1
fi

source "$ROOT_DIR/.env"

# config/openclaw.json を読み込み
if [[ ! -f "$ROOT_DIR/config/openclaw.json" ]]; then
  echo "!!! config/openclaw.json が見つかりません"
  exit 1
fi

# 環境変数を置換
echo "    環境変数を置換中..."
envsubst < "$ROOT_DIR/config/openclaw.json" > /tmp/openclaw.json.tmp

# コンテナに設定ファイルをコピー
echo "    設定ファイルをコンテナにコピー中..."
docker cp /tmp/openclaw.json.tmp openclaw-gateway:/home/node/.openclaw/openclaw.json

# コンテナを再起動
echo "    コンテナを再起動中..."
docker compose restart openclaw-gateway

echo ""
echo "=========================================="
echo "  設定の更新が完了しました！"
echo "=========================================="
echo ""
echo "ログ確認: docker compose logs -f openclaw-gateway"
