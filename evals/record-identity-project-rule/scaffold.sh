#!/usr/bin/env bash
# 커밋 1개와 미커밋 변경 1건이 있는 git 저장소를 만든다. 작성자 표기를 정한 CLAUDE.md를 둔다.
set -euo pipefail

git init -q
git config user.name "Test User"
git config user.email "test@example.com"
mkdir -p src
printf 'export const RETRY_DELAY_MS = 30000;\n' > src/retry.ts
printf '# 프로젝트 지침\n\n의사결정 기록(docs/intent/)의 author는 `octo-bot`으로 적는다.\n' > CLAUDE.md
git add -A
git commit -qm "chore: 초기 커밋"
printf 'export const retryDelayMs = (attempt: number) => 1000 * 2 ** attempt;\n' > src/retry.ts
