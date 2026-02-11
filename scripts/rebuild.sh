#!/usr/bin/env bash
# =============================================================
# OpenClaw 最新版リビルド
# 使い方: bash scripts/rebuild.sh
# =============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> OpenClaw を最新版にリビルド中..."
echo "    （キャッシュなしでビルドするため時間がかかります）"
echo ""

# --no-cache: git clone を含む全レイヤーを再実行（最新ソース取得）
# --pull: ベースイメージも最新に更新
docker compose build --no-cache --pull

echo ""
echo "==> コンテナを再作成して起動..."
docker compose up -d --force-recreate

echo ""
echo "==> 完了! ログ確認: docker compose logs -f openclaw-gateway"

echo ""
echo "Dashboard:   http://localhost:18779?token=${OPENCLAW_GATEWAY_TOKEN}"
echo ""
