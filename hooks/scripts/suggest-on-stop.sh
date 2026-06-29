#!/usr/bin/env bash
# 세션 종료 시 intent 기록을 제안한다. 기록할 결정이 없으면 그대로 마무리하도록 안내하며,
# stop_hook_active일 때는 재진입하지 않아 루프를 방지한다.
set -euo pipefail

payload=$(cat 2>/dev/null || true)
active=$(printf '%s' "$payload" | grep -oE '"stop_hook_active"[[:space:]]*:[[:space:]]*true' || true)
[ -n "$active" ] && exit 0

cat <<'JSON'
{"decision":"block","reason":"세션을 마치기 전에, 이번 작업에 의도·대안·트레이드오프를 남길 만한 결정이 있었다면 intent-record로 기록을 제안하라. 남길 것이 없으면 그대로 마무리하라."}
JSON
