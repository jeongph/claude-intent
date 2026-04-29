---
name: intent-why
description: Use when the user wants to find the intent behind code, search past decisions, or trace the "why" of a file/function/keyword/commit. 사용자가 한국어로 "이 코드 왜 이래?", "왜 이렇게 됐지?", "intent why", "이전 결정 찾아", "이 파일 의도", "src/X 왜 도입?", "이거 왜 만든거야", "결정 검색", "사이클 찾아"라고 하거나, 영어로 "why this code?", "intent why", "why was X introduced?", "find decision about Y"라고 할 때. Searches docs/intent/ INDEX and frontmatter to find relevant cycles, follows supersedes/refines chains, displays results without modifying anything. Read-only.
---

# Intent Why

코드·키워드·커밋·ID로 과거 결정을 역추적합니다. **읽기 전용 — 절대 저장·수정하지 않습니다.**

비유: `git blame`의 의도 레이어 버전. 누가 썼는지가 아니라 **왜 그렇게 결정했는지**.

## 입력 종류 (자동 분류)

사용자 입력을 보고 4가지 검색 방식 중 하나로 분류:

### 1. 파일 경로 검색
- 트리거: `src/retry.ts`, `auth/middleware.go` 같은 경로 형태
- 입력 예: "src/retry.ts 왜?", "auth 왜 이렇게 됐어"
- 검색: frontmatter `files` 필드 매칭

### 2. 키워드 검색
- 트리거: 자연어 키워드
- 입력 예: "재시도 백오프 왜 도입?", "JWT 왜 골랐는지"
- 검색: `title`, 본문 `## Intent`, `## Alternatives` grep

### 3. 커밋 hash 검색
- 트리거: 7-40자리 hex 문자열
- 입력 예: "a1b2c3d 왜?", "이 커밋 의도"
- 검색: frontmatter `commits` 필드 매칭

### 4. ID 직접
- 트리거: `#0042`, `#42`, `0042`
- 입력 예: "#0042", "#0042 자세히"
- 동작: `docs/intent/0042-*/decision.md` 직접 로드

**모호하면 사용자에게 확인.** 추측해서 진행하지 않음.

## 워크플로우

### 1. 사전 점검

```bash
ls docs/intent/ 2>/dev/null
```

- `docs/intent/` 없음 또는 비어있음 → "기록된 사이클이 없음. `intent-record`로 첫 사이클부터 만드세요." 알림 후 종료. **추측·환각 금지.**
- 있으면 다음 단계.

### 2. 검색 실행

#### 파일 경로
```bash
grep -l "^  - <file-path>$" docs/intent/*/decision.md
# 또는 frontmatter files 블록 안에 매칭
grep -B1 -A20 "^files:" docs/intent/*/decision.md | grep -l "<file-path>"
```

#### 키워드
```bash
# 한국어·영어 모두. 대소문자 무시.
grep -rli "<keyword>" docs/intent/*/decision.md
```

#### 커밋 hash
```bash
# 7자리 prefix 매칭
grep -l "<short-sha>" docs/intent/*/decision.md
```

#### ID
```bash
ls -d docs/intent/<NNNN>-*/  # 정확히 1개여야 정상
```

### 3. INDEX 보조 활용

`docs/intent/INDEX.md`를 읽어 시간순·관계 정보 추가 확보:
- 매칭된 사이클의 정확한 행 위치
- supersedes/refines 관계 한 눈에

### 4. 관계 체인 추적

매칭된 각 결정 frontmatter에서:

- **`supersedes: [<id>, ...]`** → 그 옛 결정들도 함께 표시 (역사적 맥락. 한 단계만 추적, 깊이 제한)
- **`superseded_by: <id>`** → 이 결정이 이미 뒤집혔으면 신결정 안내 ("⚠️ #0042가 이걸 뒤집음")
- **`refines: [<id>, ...]`** → 정교화 관계 한 줄로 표시

체인 깊이는 **1단계만**. 2단계 이상은 사용자가 명시적으로 요청 시.

### 5. 출력 형식

#### 결과 0건
```
"<query>" 매칭되는 사이클 없음

확인:
  - docs/intent/INDEX.md (현재 N개 사이클)
  - 다른 키워드/파일로 재검색
```

추측해서 빈 결과를 채우지 말 것.

#### 결과 1건 이상 (시간 역순)

```
<query> 관련 사이클 N개

#0042 (2026-04-29) 재시도 백오프 도입
  Intent: 재시도가 외부 API에 과부하
  Chosen: exponential-backoff
  Trade-offs: p99 latency 증가 (알람 임계 조정 필요)
  Assumptions:
    - 외부 API rate limit ~100rps
    - tail latency p99 < 500ms
  Supersedes: #0019
  Files: src/retry.ts, src/retry.test.ts
  → docs/intent/0042-add-retry-backoff/

#0019 (2026-03-15) 고정 30초 재시도 ⚠️ #0042가 뒤집음
  Intent: 단순한 재시도 로직 필요
  Chosen: fixed-30s-x5
  → docs/intent/0019-fixed-retry/
```

상세 내용(전체 본문, transcript.md)이 필요하면 사용자가 추가 요청 (`#0042 본문`, `#0042 transcript`).

### 6. 다음 행동 제안 (선택)

매칭이 있으면 마지막에 한 줄 안내:

```
관련 작업하려면:
  - 새 결정 추가: "이번 사이클 정리해줘" → intent-record
  - 이 결정 뒤집기: "#0042 뒤집는 작업 시작할게" → intent-record (supersedes)
```

매칭 0건이면 안내 생략.

## 비범위

이 스킬은 다음을 **하지 않습니다**:

- 결정 작성·수정 (= `intent-record` 영역)
- 코드 직접 분석·실행 (= 일반 코드 리딩)
- 의도와 코드의 어긋남 검증 (= 미래 `intent-verify`)
- 임베딩·의미 검색 (= MVP 범위 밖, frontmatter+grep만)

## 함정

1. **저장된 사이클 0개 = 정상 0건 결과.** 빈 결과 채우려고 LLM이 만들어내지 말 것.
2. **체인 무한 루프**: supersedes 체인에서 A→B→A 같은 순환이 있으면 1단계에서 멈추고 사용자에게 알림.
3. **부분 매칭의 노이즈**: 너무 일반적인 키워드("api", "fix")는 매칭이 폭발할 수 있음. 5건 초과하면 사용자에게 더 구체적인 키워드 요청.

## Schema 참고

상세 schema는 [../../docs/SCHEMA.md](../../docs/SCHEMA.md).
