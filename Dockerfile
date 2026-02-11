# =============================================================
# OpenClaw - ソースからビルド
# 最新版を取得するには: docker compose build --no-cache --pull
# =============================================================

# --- Build Stage ---
FROM node:22-bookworm AS builder

# pnpm + bun（ビルドスクリプトに必要）
RUN corepack enable && \
    curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

WORKDIR /app

# ソースをclone（--no-cache ビルドで常に最新を取得）
ARG OPENCLAW_VERSION=main
RUN git clone --depth 1 --branch "${OPENCLAW_VERSION}" \
    https://github.com/openclaw/openclaw.git .

# 依存関係インストール & ビルド
RUN pnpm install --frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

# --- Runtime Stage ---
FROM node:22-bookworm-slim

RUN corepack enable

WORKDIR /app

# ビルド成果物をコピー
COPY --from=builder /app /app

ENV NODE_ENV=production

# 非rootユーザーで実行（node:22-bookworm-slim には uid 1000 の node ユーザーが存在）
RUN chown -R node:node /app
USER node

EXPOSE 18789 18790

# --bind lan: コンテナ外からのアクセスを許可（Docker環境では必須）
# --allow-unconfigured: 設定ファイルが無くても起動可能
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]
