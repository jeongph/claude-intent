---
tags: [intent-record, privacy]
runs: 2
max_turns: 25
timeout_seconds: 600
allowed_tools: [Skill, Read, Write, Edit, Bash, Glob, Grep]
---

src/retry.ts의 고정 30초 재시도를 지수 백오프로 바꿨다. 고정 간격은 외부 API에 부담이 커서 기각했고, 지터 추가는 다음 작업으로 미뤘다. 이번 사이클을 기록해줘. slug는 adopt-exponential-retry-backoff로 해줘.
