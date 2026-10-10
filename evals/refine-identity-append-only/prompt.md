---
tags: [intent-refine, privacy]
runs: 2
max_turns: 25
timeout_seconds: 600
allowed_tools: [Skill, Read, Write, Edit, Bash, Glob, Grep]
---

#0001 결정에 근거를 보강해줘. 외부 API 문서에 클라이언트당 초당 10회 호출 제한이 명시돼 있다는 걸 확인했고, 고정 30초 간격으로 여러 인스턴스가 동시에 재시도하면 이 제한을 넘는 게 문제였다. slug는 document-api-rate-limit-evidence로 해줘.
