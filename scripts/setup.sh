#!/usr/bin/env bash
# =============================================================
# OpenClaw 初回セットアップ
# 使い方: bash scripts/setup.sh
# =============================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

echo "==> OpenClaw Docker セットアップ"

# --- .env ファイル ---
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  echo "    .env.example → .env にコピーしました"
fi

# --- OPENCLAW_GATEWAY_TOKEN 自動生成 ---
source "$ROOT_DIR/.env"
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  TOKEN="$(openssl rand -hex 32)"
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=${TOKEN}/" "$ROOT_DIR/.env"
  else
    sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=${TOKEN}/" "$ROOT_DIR/.env"
  fi
  echo "    OPENCLAW_GATEWAY_TOKEN を自動生成しました"
fi

# --- 必須変数チェック ---
source "$ROOT_DIR/.env"

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo ""
  echo "!!! TELEGRAM_BOT_TOKEN が未設定です"
  echo "    @BotFather からトークンを取得し、.env に記入してください"
  echo "    記入後、再度このスクリプトを実行してください"
  exit 1
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo ""
  echo "!!! GEMINI_API_KEY が未設定です"
  echo "    https://aistudio.google.com/apikey から取得し、.env に記入してください"
  echo "    記入後、再度このスクリプトを実行してください"
  exit 1
fi

# --- Docker イメージビルド ---
echo ""
echo "==> Docker イメージをビルド中（初回は時間がかかります）..."
docker compose build --pull

# --- 設定ファイルをボリュームにコピー ---
echo ""
echo "==> 設定ファイルを初期化中..."

# config/openclaw.json から環境変数を置換
if [[ ! -f "$ROOT_DIR/config/openclaw.json" ]]; then
  echo "!!! config/openclaw.json が見つかりません"
  exit 1
fi

# 環境変数を置換して一時ファイルに出力
envsubst < "$ROOT_DIR/config/openclaw.json" > /tmp/openclaw.json.tmp

# コンテナに設定ファイルをコピー
docker compose run --rm --user node openclaw-gateway bash -c "
  mkdir -p ~/.openclaw/workspace ~/.openclaw/devices
  if [ ! -f ~/.openclaw/openclaw.json ]; then
    cat > ~/.openclaw/openclaw.json
    chmod 600 ~/.openclaw/openclaw.json
    echo '設定ファイルを作成しました'
  else
    echo '設定ファイルは既に存在します'
  fi
" < /tmp/openclaw.json.tmp

# --- 起動 ---
echo ""
echo "==> ゲートウェイを起動中..."
docker compose up -d

# --- doctor --fix を自動実行 ---
echo ""
echo "==> Telegram を有効化中..."
sleep 3
docker compose exec openclaw-gateway node openclaw.mjs doctor --fix

echo ""
echo "=========================================="
echo "  セットアップ完了!"
echo "=========================================="
echo ""
echo "ログ確認:    docker compose logs -f openclaw-gateway"
echo "状態確認:    docker compose ps"
echo "停止:        docker compose down"
echo "最新版更新:  bash scripts/rebuild.sh"
echo ""
echo "Dashboard:   http://localhost:18789?token=${OPENCLAW_GATEWAY_TOKEN}"
echo ""
echo "==> Dashboard に初回アクセス中（デバイス承認のため）..."
echo "    ブラウザで上記 URL を開いてください（30秒待機します）"
echo ""

# 30秒待機してからデバイスを自動承認
sleep 30
bash "$ROOT_DIR/scripts/approve-devices.sh" || echo "    (デバイス承認をスキップしました)"

echo ""
echo "Telegram で Bot にメッセージを送信して動作確認してください。"
