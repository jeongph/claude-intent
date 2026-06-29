#!/usr/bin/env bash
# git commit 직후 intent 기록을 제안한다. 제안만 하며, 기록 자체는 intent-record skill이
# 추출 → 사용자 검수 → 저장 순서로 수행한다.
set -euo pipefail

payload=$(cat 2>/dev/null || true)
cmd=$(printf '%s' "$payload" \
  | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || true)

case "$cmd" in
  *"git commit"*)
    cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"방금 git commit이 실행됐다. 이번 변경이 의도·대안·트레이드오프를 남길 만한 결정이면 intent-record로 기록을 제안하라. 사소한 변경이면 제안하지 않는다."}}
JSON
    ;;
esac
