# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenClaw (https://github.com/openclaw/openclaw) を Docker Compose でセルフホストする環境。Telegram + Gemini 3 Flash で運用。M1 Mac (ARM64) 上で常時稼働を想定。

## Commands

```bash
# 初回セットアップ（.env 記入後）
bash scripts/setup.sh

# 設定ファイルを再読み込み（config/openclaw.json 編集後）
bash scripts/reload-config.sh

# 設定ファイルの自動監視（開発時、要 fswatch）
bash scripts/watch-config.sh

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
Dockerfile                   ソースからビルド（git clone → pnpm build）
docker-compose.yml           セキュリティ強化済みの単一サービス構成
config/openclaw.json         OpenClaw設定ファイル（JSON、環境変数対応）
scripts/setup.sh             初回セットアップ（設定展開、Telegram有効化、起動）
scripts/rebuild.sh           最新版リビルド（--no-cache で全レイヤー再実行）
scripts/approve-devices.sh   Web ダッシュボード用デバイス自動承認
```

設定の特徴：

- **ビルド方式**: Dockerfile内で `git clone --depth 1` により最新ソースを取得。`--no-cache` ビルドで常に最新版を取得可能
- **永続化**: `openclaw-config` の named volume に設定とデータを保持
- **セキュリティ**: cap_drop ALL, no-new-privileges, localhost-only port binding
- **設定管理**:
  - `config/openclaw.json` で設定を管理（JSON形式、バージョン管理可能）
  - `${VARIABLE_NAME}` で環境変数を参照
  - setup.sh が `envsubst` で環境変数を置換してコンテナにデプロイ
- **自動設定**:
  - `openclaw doctor --fix` で Telegram を自動有効化
  - approve-devices.sh で Web ダッシュボードのデバイスペアリングを自動承認
- **デバイス承認**: setup.sh/rebuild.sh が 30秒待機し、ブラウザでアクセス後に pending デバイスを自動承認

---

## Key Environment Variables

- `OPENCLAW_GATEWAY_TOKEN`: ゲートウェイ認証（setup.sh で自動生成）
- `TELEGRAM_BOT_TOKEN`: Telegram Bot API トークン
- `GEMINI_API_KEY`: Google Gemini API キー
- `BRAVE_SEARCH_API_KEY`: Brave Search API キー（オプション、Web 検索機能を有効化）
- `OPENCLAW_VERSION`: ビルドするブランチ/タグ（デフォルト: main）

## Web Search Integration

Brave Search API を統合済み：
- 設定: `tools.web.search` セクションで provider="brave" を指定
- API キー: 環境変数 `BRAVE_SEARCH_API_KEY` から自動読み込み
- 制限: 無料プランで月2,000リクエスト
- タイムアウト: 30秒、最大結果: 5件
