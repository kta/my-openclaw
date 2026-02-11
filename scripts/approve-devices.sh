#!/usr/bin/env bash
# =============================================================
# OpenClaw デバイス自動承認スクリプト
# pending.json の全デバイスを paired.json に移動
# =============================================================
set -euo pipefail

echo "==> ペアリング待ちデバイスを確認中..."

# pending.json と paired.json を取得
docker compose exec -T openclaw-gateway cat /home/node/.openclaw/devices/pending.json > /tmp/openclaw-pending.json
docker compose exec -T openclaw-gateway cat /home/node/.openclaw/devices/paired.json > /tmp/openclaw-paired.json

# Python で処理
python3 << 'EOPY'
import json
import time
import sys

with open('/tmp/openclaw-pending.json', 'r') as f:
    pending = json.load(f)

with open('/tmp/openclaw-paired.json', 'r') as f:
    paired = json.load(f)

if not pending:
    print("    ペアリング待ちのデバイスはありません")
    sys.exit(0)

# pending のデバイスを paired に移動
approved_count = 0
for request_id, device in pending.items():
    device_id = device['deviceId']
    paired[device_id] = {
        'deviceId': device_id,
        'publicKey': device['publicKey'],
        'platform': device['platform'],
        'clientId': device['clientId'],
        'clientMode': device['clientMode'],
        'role': device['role'],
        'roles': device['roles'],
        'scopes': device['scopes'],
        'tokens': {},
        'createdAtMs': device['ts'],
        'approvedAtMs': int(time.time() * 1000)
    }
    print(f"    ✓ デバイスを承認: {device['clientId']} ({device['platform']})")
    approved_count += 1

# 保存
with open('/tmp/openclaw-paired-new.json', 'w') as f:
    json.dump(paired, f, indent=4)

with open('/tmp/openclaw-pending-new.json', 'w') as f:
    json.dump({}, f, indent=4)

print(f"    合計 {approved_count} 個のデバイスを承認しました")
EOPY

# ファイルをコンテナにコピー
docker cp /tmp/openclaw-paired-new.json openclaw-gateway:/home/node/.openclaw/devices/paired.json
docker cp /tmp/openclaw-pending-new.json openclaw-gateway:/home/node/.openclaw/devices/pending.json

echo "    デバイス承認が完了しました"
