# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenClaw (https://github.com/openclaw/openclaw) を Docker Compose でセルフホストする環境。Telegram + Gemini 3 Flash で運用。M1 Mac (ARM64) 上で常時稼働を想定。

## Commands

```bash
# 初回セットアップ（.env 記入後）
bash scripts/setup.sh

# 最新版にリビルド（ソースを再cloneしてビルド）
bash scripts/rebuild.sh

# 起動 / 停止 / ログ
docker compose up -d
docker compose down
docker compose logs -f openclaw-gateway

# 状態・ヘルスチェック確認
docker compose ps

# 特定バージョンでビルド
OPENCLAW_VERSION=v2026.2.9 docker compose build --no-cache
```

## Architecture

```
Dockerfile          ソースからビルド（git clone → pnpm build）
docker-compose.yml  セキュリティ強化済みの単一サービス構成
config/openclaw.json  AIモデル設定（Gemini 3 Flash）
scripts/setup.sh      初回セットアップ（トークン生成、Telegram接続、起動）
scripts/rebuild.sh    最新版リビルド（--no-cache で全レイヤー再実行）
```

- **ビルド方式**: Dockerfile内で `git clone --depth 1` により最新ソースを取得。`--no-cache` ビルドで常に最新版を取得可能
- **永続化**: `openclaw-config` と `openclaw-workspace` の named volumes にデータ保持
- **セキュリティ**: read-only rootfs, cap_drop ALL, no-new-privileges, localhost-only port binding

## Key Environment Variables

- `OPENCLAW_GATEWAY_TOKEN`: ゲートウェイ認証（setup.sh で自動生成）
- `TELEGRAM_BOT_TOKEN`: Telegram Bot API トークン
- `GEMINI_API_KEY`: Google Gemini API キー
- `OPENCLAW_VERSION`: ビルドするブランチ/タグ（デフォルト: main）
