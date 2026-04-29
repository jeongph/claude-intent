# Decision Schema

claude-intent가 만들고 읽는 데이터의 형식 정의.

## 디렉토리 구조

저장 루트는 사용하는 프로젝트의 `docs/intent/`입니다.

```
docs/intent/
├── INDEX.md                          # 자동 생성 timeline (intent-record가 갱신)
├── 0001-add-retry-backoff/
│   ├── decision.md                   # 정제본 — 사람이 읽고 도구가 검색
│   └── transcript.md                 # raw 대화 발췌
└── 0002-tighten-jitter/
    ├── decision.md
    └── transcript.md
```

## decision.md

YAML frontmatter + Markdown 본문.

```markdown
---
id: 0001
title: "재시도 정책에 지수 백오프 도입"
date: 2026-04-29
author: "jeongph"
commits:
  - a1b2c3d
  - d4e5f67
files:
  - src/retry.ts
  - src/retry.test.ts
supersedes: []                        # [<id>, ...] — 뒤집은 옛 결정들
superseded_by: null                   # 새 결정이 이걸 뒤집으면 채워짐 (예외적 수정 허용)
refines: []                           # [<id>, ...] — 정교화한 옛 결정들
assumptions:
  - "외부 API rate limit ~100rps"
  - "tail latency p99 < 500ms"
session: "8e6e52ee-3017-4ecb-b394-dc9a28f3d9ae"
---

## Intent
재시도가 외부 API에 과부하

## Alternatives
- linear-backoff: 단순하지만 여전히 공격적
- circuit-breaker: 근본적이지만 이번 스코프 초과
- **exponential-backoff (선택)**: 즉효 + 간단

## Trade-offs
- p99 latency 늘어남 → 알람 임계 조정 필요
- min 1초 floor (사용자 직관 깨짐 방지)

## Rejected
API 측 rate limit 받기 — 우리 쪽 제어 못 함

## Source
[transcript.md](transcript.md) — Claude session, 2026-04-29 22:30~22:42
```

## INDEX.md

`intent-record` 스킬이 매 사이클마다 갱신. 최신이 위.

```markdown
# Intent Timeline

| ID | 날짜 | 제목 | 커밋 | 관계 |
|----|------|------|------|------|
| [0002](0002-tighten-jitter/) | 2026-04-30 | jitter 추가 | d4e5f6 | refines #0001 |
| [0001](0001-add-retry-backoff/) | 2026-04-29 | 재시도 백오프 | a1b2c3 | — |
```

## 필드 규칙

### `id`
- 4자리 zero-padded sequential
- INDEX.md max + 1
- 한 번 부여되면 절대 변경 안 됨

### `slug`
- 영어 소문자 kebab-case
- 4-6 단어, 의도 압축
- 디렉토리명 = `<id>-<slug>`
- 좋음: `add-retry-backoff`, `tighten-jitter-floor`
- 나쁨: `feature`, `update`, `한글`

### `supersedes` vs `refines`
- **`supersedes`**: 옛 결정을 **뒤집음** (반대 방향, 새 결정이 이긴다)
- **`refines`**: 옛 결정을 **정교화** (같은 방향, 더 자세히 명시)

### `superseded_by` — 유일한 예외적 수정
- 일반 원칙: append-only (옛 결정 수정 금지)
- 예외: 새 결정이 옛 결정을 supersede할 때 옛 결정의 `superseded_by` 필드만 갱신
- 이유: "이 결정은 이미 뒤집혔다"는 신호를 옛 파일에서 즉시 보이게 하기 위함

### `assumptions`
- 이 결정이 의존하는 가정들
- 미래 검증 포인트 — 가정이 깨지면 결정 자체 재검토 필요
- 구체적이고 측정 가능하게 ("외부 API 빠르다"보다 "외부 API ~100rps")

### `session`
- Claude Code session ID (UUID)
- raw transcript 원본 (`~/.claude/projects/.../<session>.jsonl`) 추적용
- 무결성 검증·디버깅에 사용

## transcript.md

raw 대화의 핵심 부분을 Markdown으로 변환.

규칙:
- user/assistant 메시지 본문은 **그대로** (정제·요약 X)
- 도구 호출은 한 줄 요약 (`[Bash: git log -10]`, `[Read: src/retry.ts]`)
- 도구 결과는 **의미 있을 때만** 짧게 인용
- 시간순
- 코드 블록·들여쓰기는 그대로 보존

목적: "이 결정이 정말 어떻게 만들어졌는가"의 정직한 증거. 미화 X.

## 진화 정책

이 schema는 v0.1.0이며 dogfood 단계에서 변할 수 있습니다.

- 필수 필드 추가: 마이그레이션 스크립트 제공
- 필드 의미 변경: schema version bump (`schema_version: 1` 같은 필드 도입)
- 호환성 깨짐: SCHEMA.md에 명시 + 옛 사이클은 옛 schema로 둠 (재해석 X)
