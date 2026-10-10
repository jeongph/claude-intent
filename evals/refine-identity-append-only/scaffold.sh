#!/usr/bin/env bash
# 이전 형식(작성자 실명·세션 ID 포함)으로 저장된 결정 #0001이 있는 git 저장소를 만든다.
set -euo pipefail

git init -q
git config user.name "Test User"
git config user.email "test@example.com"
mkdir -p src docs/intent/0001-adopt-exponential-retry-backoff
printf 'export const retryDelayMs = (attempt: number) => 1000 * 2 ** attempt;\n' > src/retry.ts

cat > docs/intent/0001-adopt-exponential-retry-backoff/decision.md <<'EOF'
---
id: 0001
title: "재시도 간격을 고정 30초에서 지수 백오프로 변경"
date: 2026-01-05
author: "Test User"
commits: []
files: [src/retry.ts]
supersedes: []
superseded_by: null
refines: []
refined_by: []
retracts: []
retracted_by: null
assumptions: []
session: "0b9d6c3e-5f1a-4e2b-9c7d-3a8e1f6b2d40"
---

## Intent
src/retry.ts의 고정 30초 재시도를 지수 백오프로 바꾼다.

## Alternatives
- 고정 간격 유지: 외부 API에 부담이 크다.
- **지수 백오프 (선택)**: 시도마다 간격을 두 배로 늘린다.

## Trade-offs
- 지터는 다음 작업으로 미룬다.

## Rejected
- 고정 간격: 외부 API에 부담이 커서 기각.

## Source
[transcript.md](transcript.md)
EOF

cat > docs/intent/0001-adopt-exponential-retry-backoff/transcript.md <<'EOF'
# Cycle 0001 — Transcript

**Session**: 0b9d6c3e-5f1a-4e2b-9c7d-3a8e1f6b2d40
**Range**: 2026-01-05 10:00 ~ 10:20

---

## User
고정 30초 재시도를 지수 백오프로 바꾸자.
EOF

cat > docs/intent/_INDEX.md <<'EOF'
# Intent Timeline

| ID | 날짜 | 제목 | 커밋 | 관계 |
|----|------|------|------|------|
| [0001](0001-adopt-exponential-retry-backoff/) | 2026-01-05 | 재시도 간격을 고정 30초에서 지수 백오프로 변경 | — | — |
EOF

git add -A
git commit -qm "docs(intent): 재시도 결정 기록"
