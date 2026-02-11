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
- **オプション**: Brave Search API Key ([Brave Search API](https://brave.com/search/api/) から取得) - Web 検索機能を有効化

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

# オプション: Web 検索を有効化（月2,000リクエスト無料）
BRAVE_SEARCH_API_KEY=<Brave Search APIで生成したキー>
```

`OPENCLAW_GATEWAY_TOKEN` は setup.sh が自動生成するので空欄のままでOKです。

`BRAVE_SEARCH_API_KEY` はオプションです。設定すると、OpenClaw が Web 検索機能を使用できるようになります。

### 3. セットアップスクリプトを実行

```bash
bash scripts/setup.sh
```

このスクリプトは以下を自動実行します:

- ゲートウェイ認証トークンの生成
- Dockerイメージのビルド（初回は10-20分程度）
- OpenClaw設定ファイル (openclaw.json) の生成
- Telegram チャネルの自動有効化 (`openclaw doctor --fix`)
- コンテナの起動
- **Web ダッシュボードのデバイス自動承認**（30秒待機）

### 4. 動作確認

**重要**: セットアップスクリプトが「30秒待機します」と表示したら、**すぐにブラウザで Dashboard URL を開いてください**。これにより、ブラウザのデバイスが自動的に承認されます。

**Web ダッシュボード**でアクセス:

セットアップ完了時に表示される URL（token付き）をブラウザで開きます:

```text
http://localhost:18789?token=<自動生成されたトークン>
```

または **Telegram** で Bot にメッセージを送信してください。Gemini 3 Flash が応答します。

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

# 設定ファイルを再読み込み
bash scripts/reload-config.sh

# 設定ファイルの自動監視（開発時）
bash scripts/watch-config.sh

# 最新版にアップデート
bash scripts/rebuild.sh
```

## ディレクトリ構成

```text
my-openclaw/
├── Dockerfile                # OpenClawをソースからビルド
├── docker-compose.yml        # セキュリティ強化済み構成
├── .env                      # 環境変数（gitignore済み）
├── .env.example              # 環境変数テンプレート
├── config/
│   └── openclaw.json         # OpenClaw設定ファイル（環境変数対応）
├── scripts/
│   ├── setup.sh              # 初回セットアップ
│   ├── rebuild.sh            # 最新版リビルド
│   └── approve-devices.sh    # デバイス自動承認
├── CLAUDE.md                 # 開発者向けガイド
└── README.md                 # このファイル
```

## 設定のカスタマイズ

OpenClaw の設定は `config/openclaw.json` で管理されています。このファイルを直接編集して設定を変更できます。

- **環境変数の参照**: `${VARIABLE_NAME}` の形式で環境変数を参照可能
- **変更の反映**: 以下の方法で設定を反映できます

### 方法1: 手動で反映（推奨）

```bash
bash scripts/reload-config.sh
```

### 方法2: 自動監視（開発時に便利）

```bash
# 事前に fswatch をインストール（Mac の場合）
brew install fswatch

# 監視開始（設定ファイルを編集すると自動で反映）
bash scripts/watch-config.sh
```

### 設定例

```json
{
  "models": {
    "providers": {
      "google": {
        "apiKey": "${GEMINI_API_KEY}"
      }
    }
  },
  "tools": {
    "web": {
      "search": {
        "provider": "brave",
        "apiKey": "${BRAVE_SEARCH_API_KEY}",
        "maxResults": 10
      }
    }
  }
}
```

## セキュリティ

以下のセキュリティ対策を実装済み:

- ✅ **最小権限** — `cap_drop: ALL` で全権限削除、必要最小限のみ付与
- ✅ **非rootユーザー** — uid 1000 (node) で実行
- ✅ **localhost-only** — ポートは `127.0.0.1` のみにバインド
- ✅ **no-new-privileges** — 実行時の権限昇格を防止
- ✅ **リソース制限** — メモリ2GB、CPU 2コアの上限設定
- ✅ **ログローテーション** — 10MB x 3ファイルに自動制限
- ✅ **トークン認証** — Web ダッシュボードへのアクセスにトークンが必要

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

### Brave Search API の設定

Web 検索機能を有効化するには：

1. [Brave Search API](https://brave.com/search/api/) でアカウント作成
2. **Data for Search** プランを選択（無料で月2,000リクエスト）
3. API キーを生成
4. `.env` に追加:

   ```bash
   BRAVE_SEARCH_API_KEY=<生成したAPIキー>
   ```

5. コンテナを再起動:

   ```bash
   docker compose restart openclaw-gateway
   ```

これにより、OpenClaw が最新情報を検索して回答できるようになります。

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
