# OpenClaw Docker 環境

[OpenClaw](https://github.com/openclaw/openclaw) をDocker Composeで常時稼働させる環境です。Telegram経由でGemini 3 Flashと対話できます。

## 特徴

- 🦞 **常に最新版**: `git clone`でソースを取得してビルド、`--no-cache`で簡単更新
- 🔒 **セキュリティ強化**: read-only rootfs、最小限の権限、localhost-only binding
- 🤖 **Gemini 3 Flash**: Google の最新モデルを使用
- 💬 **Telegram Bot**: メッセージング経由でAIアシスタントにアクセス
- 🍎 **ARM64対応**: M1/M2/M3 Mac で動作確認済み

## 必要なもの

- Docker & Docker Compose
- Telegram Bot Token ([@BotFather](https://t.me/BotFather) から取得)
- Google Gemini API Key ([Google AI Studio](https://aistudio.google.com/apikey) から取得)

## セットアップ

### 1. リポジトリをクローン

```bash
git clone <このリポジトリのURL>
cd my-openclaw
```

### 2. 環境変数を設定

```bash
cp .env.example .env
```

`.env` を編集して以下を記入:

```bash
TELEGRAM_BOT_TOKEN=<@BotFatherから取得したトークン>
GEMINI_API_KEY=<Google AI Studioで生成したAPIキー>
```

`OPENCLAW_GATEWAY_TOKEN` は setup.sh が自動生成するので空欄のままでOKです。

### 3. セットアップスクリプトを実行

```bash
bash scripts/setup.sh
```

このスクリプトは以下を自動実行します:
- ゲートウェイ認証トークンの生成
- Dockerイメージのビルド（初回は10-20分程度）
- Telegramチャネルの登録
- コンテナの起動

### 4. 動作確認

Telegram で Bot にメッセージを送信してみてください。Gemini 3 Flash が応答します。

```bash
# ログ確認
docker compose logs -f openclaw-gateway

# コンテナ状態確認
docker compose ps
```

## 運用コマンド

```bash
# 起動
docker compose up -d

# 停止
docker compose down

# ログ確認（リアルタイム）
docker compose logs -f openclaw-gateway

# 最新版にアップデート
bash scripts/rebuild.sh
```

## ディレクトリ構成

```
my-openclaw/
├── Dockerfile              # OpenClawをソースからビルド
├── docker-compose.yml      # セキュリティ強化済み構成
├── .env                    # 環境変数（gitignore済み）
├── .env.example            # 環境変数テンプレート
├── config/
│   └── openclaw.json       # AIモデル設定
├── scripts/
│   ├── setup.sh            # 初回セットアップ
│   └── rebuild.sh          # 最新版リビルド
└── CLAUDE.md               # 開発者向けガイド
```

## セキュリティ

以下のセキュリティ対策を実装済み:

- ✅ **read-only rootfs** — コンテナ内ファイルシステムの改竄防止
- ✅ **最小権限** — `cap_drop: ALL` で全権限削除、必要最小限のみ付与
- ✅ **非rootユーザー** — uid 1000 (node) で実行
- ✅ **localhost-only** — ポートは `127.0.0.1` のみにバインド
- ✅ **no-new-privileges** — 実行時の権限昇格を防止
- ✅ **リソース制限** — メモリ2GB、CPU 2コアの上限設定
- ✅ **ログローテーション** — 10MB x 3ファイルに自動制限

## トラブルシューティング

### ビルドが失敗する

```bash
# キャッシュをクリアして再ビルド
docker compose build --no-cache --pull
```

### Bot が応答しない

1. ログを確認: `docker compose logs -f openclaw-gateway`
2. コンテナが起動しているか確認: `docker compose ps`
3. Telegram トークンが正しいか `.env` を確認
4. Gemini API キーが有効か確認

### コンテナが起動しない

ヘルスチェックが失敗している可能性があります:

```bash
# ヘルスチェックを無効化して起動してみる
docker compose up -d --no-healthcheck

# ログで原因を特定
docker compose logs openclaw-gateway
```

### 権限エラーが出る

Docker volumes の権限問題の可能性:

```bash
# ボリュームを削除して再作成
docker compose down -v
bash scripts/setup.sh
```

## 高度な設定

### 特定バージョンをビルド

`.env` に追加:

```bash
OPENCLAW_VERSION=v2026.2.9
```

その後:

```bash
docker compose build --no-cache
docker compose up -d --force-recreate
```

### LAN内の他デバイスからアクセス

`docker-compose.yml` のポート設定を変更:

```yaml
ports:
  - "18789:18789"  # 127.0.0.1: を削除
  - "18790:18790"
```

**⚠️ 警告**: `OPENCLAW_GATEWAY_TOKEN` による認証は必須です。

### 複数のメッセージングチャネルを追加

```bash
# Discord の場合
docker compose run --rm openclaw-gateway \
  node openclaw.mjs channels add --channel discord --token <DISCORD_BOT_TOKEN>

# Slack の場合
docker compose run --rm openclaw-gateway \
  node openclaw.mjs channels add --channel slack --token <SLACK_BOT_TOKEN>
```

対応チャネル一覧は [OpenClaw公式ドキュメント](https://github.com/openclaw/openclaw#supported-channels) を参照。

## ライセンス

このDocker環境は MIT License です。OpenClaw 本体のライセンスは [openclaw/openclaw](https://github.com/openclaw/openclaw) を参照してください。

## 参考リンク

- [OpenClaw 公式リポジトリ](https://github.com/openclaw/openclaw)
- [Google AI Studio](https://aistudio.google.com/)
- [Telegram BotFather](https://t.me/BotFather)
- [OpenClaw ドキュメント](https://docs.openclaw.ai/)
