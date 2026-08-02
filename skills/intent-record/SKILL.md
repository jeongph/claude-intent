---
name: intent-record
description: >-
  Use when the user wants to record/save the current work cycle's intent, decisions, and trade-offs into docs/intent/. 사용자가 한국어로 "이번 사이클 정리해줘", "기록해줘", "intent record", "사이클 저장", "방금 한 거 의도 저장", "오늘 작업 의도 기록", "이거 의도 남겨", "사이클 마무리" 같은 말을 하거나, 영어로 "record this cycle", "save the intent", "log the decision", "intent record"라고 할 때. Extracts intent/alternatives/chosen/trade-offs/assumptions from the current conversation transcript and recent git changes, drafts a decision.md, asks user to review, then saves to docs/intent/<NNNN>-<slug>/. Does NOT auto-amend commits — user adds the trailer themselves. 구분: 이미 기록된 결정에 근거·가정을 보강만 하는 건 intent-refine, 기록된 결정을 대체 없이 무효화하는 건 intent-retract 영역. 기존 결정을 뒤집고 대체하는 기록(supersedes)은 이 스킬 영역이다.
---

# Intent Record

현재 작업 사이클의 **의도(Intent)·대안(Alternatives)·트레이드오프(Trade-offs)·가정(Assumptions)**을 추출해 `docs/intent/<NNNN>-<slug>/`에 저장합니다.

비유: `git commit`의 의도 레이어 버전.

## 워크플로우

### 1. 사이클 경계 확인

기본은 **마지막 push 이후 ~ 현재 HEAD**의 변경 또는 **마지막 commit ~ 현재 변경사항**입니다.

```bash
git log --oneline -10
git diff HEAD --stat
git diff HEAD
```

사용자에게 "이 범위가 사이클 경계로 맞는지" 확인합니다. 다른 범위(특정 커밋 이후, 특정 파일군 등)를 원하면 조정.

### 2. 다음 ID 결정

```bash
ls docs/intent/ 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1
```

- 결과 없음 → `0001`
- 결과 있음 → `(max + 1)` 4자리 zero-padding
- `docs/intent/` 디렉토리 자체가 없으면 생성

### 3. 의도 추출

현재 대화 컨텍스트에서 다음을 뽑습니다. **대화에 명시적으로 드러나지 않은 항목은 추측해서 채우지 말고 사용자에게 질문합니다.**

| 필드 | 의미 | 추출 단서 |
|---|---|---|
| `intent` | 무엇을 하려 했는가 (한 문장) | "X가 필요해서", "Y가 문제라서" 발화 |
| `alternatives` | 검토한 대안들 (각 한 줄 평가) | "A 대신 B는?", "C도 가능하긴 한데" 발화 |
| `chosen` | 선택한 대안 + 이유 1-2줄 | "이걸로 가자", "B가 나아 보임" 발화 |
| `trade-offs` | 받아들인 비용 | "이게 늘긴 하는데", "X는 포기" 발화 |
| `rejected` | 일찍 기각한 옵션 + 이유 | "그건 아니야 왜냐면" 발화 |
| `assumptions` | 결정이 의존하는 가정 | 발화에서 명시적으로 안 나오면 사용자에게 질문 필수 |
| `files` | 변경 파일 | `git diff --name-only` |
| `commits` | 관련 커밋 | `git log --since=<cycle-start>` |
| `title` | 결정 한 줄 요약 | 사용자 확인 받음 |

### 4. Slug 생성

영어 소문자 kebab-case, 4-6 단어, 의도 압축.

- 좋음: `add-retry-backoff`, `tighten-jitter-floor`, `migrate-auth-middleware`
- 나쁨: `feature`, `update-code`, `fix-bug`, `한글-슬러그`

자신 없으면 사용자에게 후보 2-3개 제시 후 선택.

### 5. Draft 보여주고 검수 받기

`decision.md` 초안을 사용자에게 **전체 표시**하고 명시적 승인을 받습니다.

```markdown
---
id: 0001
title: "..."
date: <YYYY-MM-DD>
author: "<git config user.name>"
commits: [...]
files: [...]
supersedes: []
superseded_by: null
refines: []
refined_by: []
retracts: []
retracted_by: null
assumptions:
  - "..."
session: "<현재 Claude Code session id>"
---

## Intent
...

## Alternatives
- ...
- **... (선택)**: ...

## Trade-offs
- ...

## Rejected
...

## Source
[transcript.md](transcript.md)
```

검수 단계는 **건너뛰지 않습니다.** 자동 미화 방지가 이 플러그인의 정직성 기반입니다.

사용자가 수정·추가하면 그대로 반영. 사용자가 거절하면 저장하지 않고 종료.

### 6. 저장

```bash
mkdir -p docs/intent/<NNNN>-<slug>
```

두 파일 작성:

- `docs/intent/<NNNN>-<slug>/decision.md` — 5단계의 검수 통과한 내용
- `docs/intent/<NNNN>-<slug>/transcript.md` — raw 대화 발췌

### 7. transcript.md 작성 규칙

raw 대화의 핵심 부분을 Markdown으로 변환:

- user/assistant 메시지 본문은 **원문 그대로** (정제 X, 요약 X)
- 도구 호출은 한 줄 요약: `[Bash: git diff HEAD --stat]`, `[Read: src/retry.ts]`
- 도구 결과는 의미 있을 때만 짧게 인용 (`> 변경 파일 3개, +120 -45`)
- 시간순
- Claude session ID와 시작/종료 시각 첫 줄에 메타로 명시:

```markdown
# Cycle 0001 — Transcript

**Session**: 8e6e52ee-3017-4ecb-b394-dc9a28f3d9ae
**Range**: 2026-04-29 22:30 ~ 22:42

---

## User
재시도 정책 다시 봐야 할 것 같은데...

## Assistant
[Read: src/retry.ts]

현재 30초 고정 재시도가 5번 — 외부 API 입장에서 공격적임. 옵션 3가지...

## User
exponential-backoff로 가자

...
```

발화 본문이 매우 길면 (수천 단어) 핵심 단락만 발췌하되 **잘라낸 부분 표시**(`[... 중간 생략 ...]`)를 명시. 통째 미화 X.

### 8. _INDEX.md 갱신

갱신 전에 이전 이름의 파일을 확인한다. 두 파일이 함께 방치되면 갱신이 멈춘
쪽이 실제와 어긋난 채 남는다.

- `docs/intent/INDEX.md`만 있으면 `docs/intent/_INDEX.md`로 이름을 바꾼 뒤 갱신한다.
- 둘 다 있으면 `_INDEX.md`가 최신이다. **절대 덮어쓰지 않는다.** `INDEX.md`에만 있는 행을 ID 기준으로 `_INDEX.md`에 옮기고, 같은 ID가 양쪽에 있으면 `_INDEX.md` 쪽 행을 남긴다. 합친 표는 ID 역순(최신이 맨 위)으로 정렬한 뒤 `INDEX.md`를 삭제한다.
- `_INDEX.md`만 있으면 그대로 갱신을 진행한다.

`docs/intent/_INDEX.md`에 새 행을 **맨 위(시간 역순)**로 추가:

```markdown
| [<NNNN>](<NNNN>-<slug>/) | <YYYY-MM-DD> | <title> | <short-commit> | <relations> |
```

`<relations>` 예시: `supersedes #0019`, `refines #0001`, `—`

_INDEX.md가 없으면 생성:

```markdown
# Intent Timeline

| ID | 날짜 | 제목 | 커밋 | 관계 |
|----|------|------|------|------|
| <새 행> |
```

### 9. 사용자 안내

저장 후 명확히 보고:

```
사이클 #<NNNN> 저장 완료

  docs/intent/<NNNN>-<slug>/decision.md
  docs/intent/<NNNN>-<slug>/transcript.md
  docs/intent/_INDEX.md (갱신됨)

다음 단계 (선택):
  - 다음 커밋 메시지 본문에 "Intent: <NNNN>" trailer 추가
  - 코드와 의도가 영구적으로 연결됨
```

**자동으로 `git commit --amend`하거나 새 커밋을 만들지 마세요.** 사용자가 다음 커밋부터 수동으로 trailer 추가.

## 관계 처리 (supersedes / refines)

사용자가 "이전 #0019 결정을 뒤집는 작업이다"라고 명시하면:

1. 새 사이클 frontmatter에 `supersedes: [0019]`
2. 옛 사이클 `docs/intent/0019-*/decision.md`의 frontmatter `superseded_by: <새 ID>`로 갱신

`refines`를 기록할 때도 대칭으로 옛 결정의 `refined_by` 리스트에 새 ID를 append한다.

backward 필드(`superseded_by`/`refined_by`/`retracted_by`) 갱신은 append-only 원칙의 **통제된 예외 3종**이다. 옛 결정의 해당 필드 한 개만 갱신하고(필드가 없으면 추가), 본문·다른 필드는 절대 건드리지 않음.

기록된 결정의 정교화 전용 흐름은 `intent-refine`, 철회는 `intent-retract` 스킬이 담당한다.

## 예외 처리

- `git`이 초기화 안 된 디렉토리: 사용자에게 알리고 종료. claude-intent는 git 위에서 동작.
- 변경사항 0건: 사용자에게 "기록할 변경 없음" 알림 후 종료. **예외**: supersede 목적 기록(코드 변경 없이 기존 결정을 뒤집고 대체하는 결정)은 변경사항 0건을 허용하며, 이때 `commits`/`files`는 빈 리스트로 둔다.
- 대화 내 의도 추출 실패: 추측하지 않고 사용자에게 직접 입력 요청.

## 데이터 형식

### 디렉토리
`docs/intent/<NNNN>-<slug>/`에 `decision.md`(정제본)와 `transcript.md`(대화 발췌)를 둔다. 루트 `docs/intent/_INDEX.md`는 시간 역순 타임라인이다.

### 필드 규칙
- **id**: 4자리 zero-padded. INDEX의 최대값 + 1. 한 번 부여하면 변경하지 않는다.
- **slug**: 영어 소문자 kebab-case, 4-6 단어. 디렉토리명은 `<id>-<slug>`.
- 관계는 3종 대칭 구조다. forward는 새 결정에, backward는 옛 결정에 기록한다:

  | forward | backward | 의미 | 카디널리티 |
  |---|---|---|---|
  | `supersedes: []` | `superseded_by: null` | 뒤집고 대체 (새 방향 있음) | 옛 결정당 1회 |
  | `refines: []` | `refined_by: []` | 같은 방향 정교화 (옛 결정 여전히 유효) | 여러 번 가능 (리스트) |
  | `retracts: []` | `retracted_by: null` | 철회 — 무효화, 대체 없음 | 옛 결정당 1회 |

- backward 필드 갱신은 append-only의 **통제된 예외 3종**. 새 결정이 관계를 맺으면 옛 결정의 해당 필드만 갱신한다(필드가 없으면 추가).
- **assumptions**: 결정이 의존하는 가정. 구체적·측정 가능하게 적는다(예: "외부 API ~100rps"). 가정이 깨지면 결정을 재검토하는 신호다.
- **session**: Claude Code session ID(UUID). raw transcript 추적용.

### transcript.md
user·assistant 본문은 원문 그대로, 도구 호출은 한 줄 요약, 도구 결과는 의미 있을 때만 짧게 인용한다. 시간순으로 적고 미화하지 않는다.
