# Obsidian 連携セットアップ

## 設定内容

✅ **Obsidian Vault 内の `/OpenClaw` ディレクトリが作業領域になります**

```
ObsidianVault/
├── OpenClaw/              ← OpenClaw がここに記憶・メモを保存
│   ├── 会話ログ/
│   ├── 学習メモ/
│   └── タスク/
├── あなたの既存ノート.md
└── ...
```

## 設定方法

1. `.env` に Obsidian Vault のパスを追加：
   ```bash
   OBSIDIAN_VAULT_PATH=/Users/username/Documents/ObsidianVault
   ```

2. セットアップ実行：
   ```bash
   bash scripts/setup.sh
   ```

`setup.sh` が自動で `/obsidian/OpenClaw` ディレクトリを作成します。

## 使い方

### 自動保存される内容

OpenClaw が以下を自動的に `/obsidian/OpenClaw/` に保存：
- 🧠 **会話の記憶**: 重要な情報
- 📝 **作業ログ**: エージェントの実行履歴
- 📊 **生成したファイル**: コード、ドキュメントなど

### Telegram で手動保存

```
「今の会話をObsidianに保存して」
→ /obsidian/OpenClaw/会話ログ/2026-02-11.md に保存

「Dockerの使い方をメモして」
→ /obsidian/OpenClaw/学習メモ/Docker.md に保存
```

### Obsidian 全体を検索

```
「Obsidian内でAIについて書かれたファイルを探して」
→ Vault 全体から検索

「OpenClawディレクトリ内のメモを一覧表示して」
→ /obsidian/OpenClaw/ を一覧表示
```

## トラブルシューティング

### ディレクトリが作成されない

```bash
# 手動で作成
mkdir -p "$OBSIDIAN_VAULT_PATH/OpenClaw"

# 権限確認
ls -la "$OBSIDIAN_VAULT_PATH"
```

### 書き込めない

```bash
# 書き込み権限を付与
chmod -R u+w "$OBSIDIAN_VAULT_PATH"

# コンテナ内で確認
docker exec openclaw-gateway ls -la /obsidian/OpenClaw
```

### ファイルが見つからない

```bash
# Obsidian を開き直してキャッシュ更新
# または Ctrl+R で Vault を再読み込み
```


