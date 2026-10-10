---
name: intent-record
description: >-
  Use when the user wants to record/save the current work cycle's intent, decisions, and trade-offs into docs/intent/. 사용자가 한국어로 "이번 사이클 정리해줘", "기록해줘", "intent record", "사이클 저장", "방금 한 거 의도 저장", "오늘 작업 의도 기록", "이거 의도 남겨", "사이클 마무리" 같은 말을 하거나, 영어로 "record this cycle", "save the intent", "log the decision", "intent record"라고 할 때. 구분: 이미 기록된 결정에 근거·가정을 보강만 하는 건 intent-refine, 기록된 결정을 대체 없이 무효화하는 건 intent-retract 영역. 기존 결정을 뒤집고 대체하는 기록(supersedes)은 이 스킬 영역이다.
---

# Intent Record

현재 작업 사이클의 **의도(Intent)·대안(Alternatives)·트레이드오프(Trade-offs)·가정(Assumptions)**을 추출해 `docs/intent/<NNNN>-<slug>/`에 저장합니다.

비유: `git commit`의 의도 레이어 버전.

## 저장 방식

기록을 요청받으면 **1~9단계를 이어서 수행해 저장한 뒤 보고한다.** 범위·제목·slug는 스스로 정하고, 대화에 드러나지 않은 항목은 비워 둔다. 무엇을 정했고 무엇을 비웠는지는 9단계 보고에 적는다.

| 조건 | 동작 |
|---|---|
| 기본 | 끝까지 진행해 저장하고 9단계 보고로 마친다 |
| 사용자 요청에 "검수", "초안 먼저", "확인하고 저장", "review first"가 있다. 또는 프로젝트 지침 파일(`CLAUDE.md`·`AGENTS.md`)이 저장 전 검수를 요구한다 | **검수 모드**: 5단계에서 초안을 전체 표시하고 승인을 받은 뒤 저장한다. 수정 요청은 반영하고, 거절하면 저장하지 않는다 |
| [예외 처리](#예외-처리)에 해당한다 | 그 절대로 알리거나 입력을 요청한다 |

기록의 정직성은 세 가지로 지킨다. 대화에 없는 내용을 쓰지 않는다(3·5단계). 원문 발췌를 함께 남긴다(7단계). 저장한 내용을 전부 보여 준다(9단계).

## 워크플로우

### 1. 사이클 경계 결정

사용자가 범위를 말했으면 그 범위를 쓴다. 말하지 않았으면 이 대화에서 다룬 변경을 범위로 삼는다. 대화만으로 범위가 서지 않으면 **마지막 push 이후 ~ 현재 HEAD**와 미커밋 변경을 쓰고, push 이력이 없으면 **마지막 commit ~ 현재 변경사항**을 쓴다.

```bash
git log --oneline -10
git diff HEAD --stat
git diff HEAD
```

정한 범위는 9단계 보고에 적는다.

### 2. 다음 ID 결정

```bash
ls docs/intent/ 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1
```

- 결과 없음 → `0001`
- 결과 있음 → `(max + 1)` 4자리 zero-padding
- `docs/intent/` 디렉토리 자체가 없으면 생성

### 3. 의도 추출

현재 대화 컨텍스트에서 다음을 뽑습니다. **대화나 git 변경에서 근거를 짚을 수 있는 내용만 적는다.** 근거가 없는 항목은 비워 둔다. frontmatter 리스트는 `[]`, 본문 절은 "대화에 드러나지 않음"으로 둔다. 비운 항목은 9단계 보고에 적는다.

| 필드 | 의미 | 추출 단서 |
|---|---|---|
| `intent` | 무엇을 하려 했는가 (한 문장) | "X가 필요해서", "Y가 문제라서" 발화 |
| `alternatives` | 검토한 대안들 (각 한 줄 평가) | "A 대신 B는?", "C도 가능하긴 한데" 발화 |
| `chosen` | 선택한 대안 + 이유 1-2줄 | "이걸로 가자", "B가 나아 보임" 발화 |
| `trade-offs` | 받아들인 비용 | "이게 늘긴 하는데", "X는 포기" 발화 |
| `rejected` | 일찍 기각한 옵션 + 이유 | "그건 아니야 왜냐면" 발화 |
| `assumptions` | 결정이 의존하는 가정 | 대화에서 누군가 말한 가정만. 없으면 `[]` |
| `files` | 변경 파일 | `git diff --name-only` |
| `commits` | 관련 커밋 | `git log --since=<cycle-start>` |
| `title` | 결정 한 줄 요약 | `intent`를 한 줄로 줄인다 |

### 4. Slug 생성

영어 소문자 kebab-case, 4-6 단어, 의도 압축.

- 좋음: `add-retry-backoff`, `tighten-jitter-floor`, `migrate-auth-middleware`
- 나쁨: `feature`, `update-code`, `fix-bug`, `한글-슬러그`

후보가 여럿이면 의도를 가장 짧게 압축한 것을 쓴다.

### 5. decision.md 작성과 점검

```markdown
---
id: 0001
title: "..."
date: <YYYY-MM-DD>
author: "<기록을 작성한 주체 — 필드 규칙 참고>"
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

저장 전에 초안의 문장을 하나씩 대화·git 변경과 대조한다.

- 근거가 되는 발화나 변경을 짚을 수 있는 문장만 남긴다
- 선택하지 않은 대안은 대화에서 나온 평가 그대로 적는다
- `assumptions`에는 대화에서 누군가 말한 가정만 둔다
- [개인정보](#개인정보) 규칙에 해당하는 값이 남아 있지 않은지 확인한다

검수 모드면 이 단계에서 초안을 전체 표시하고 승인을 받는다([저장 방식](#저장-방식)).

### 6. 저장

```bash
mkdir -p docs/intent/<NNNN>-<slug>
```

두 파일 작성:

- `docs/intent/<NNNN>-<slug>/decision.md` — 5단계에서 점검한 내용
- `docs/intent/<NNNN>-<slug>/transcript.md` — raw 대화 발췌

### 7. transcript.md 작성 규칙

raw 대화의 핵심 부분을 Markdown으로 변환:

- user/assistant 메시지 본문은 **원문 그대로** (정제 X, 요약 X). 단, [개인정보](#개인정보)에 해당하는 값만 가린다
- 도구 호출은 한 줄 요약: `[Bash: git diff HEAD --stat]`, `[Read: src/retry.ts]`
- 도구 결과는 의미 있을 때만 짧게 인용 (`> 변경 파일 3개, +120 -45`)
- 시간순
- 시작/종료 시각을 첫 줄에 메타로 명시한다. 세션 ID는 프로젝트 지침이 요구할 때만 `**Range**` 위에 `**Session**: <id>` 줄로 넣는다([필드 규칙](#필드-규칙)):

```markdown
# Cycle 0001 — Transcript

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

### 9. 저장 보고

저장한 `decision.md` **전문**을 포함해 보고한다. 사용자가 저장된 내용을 처음 보는 자리다.

```
사이클 #<NNNN> 저장 완료

  docs/intent/<NNNN>-<slug>/decision.md
  docs/intent/<NNNN>-<slug>/transcript.md
  docs/intent/_INDEX.md (갱신됨)

범위: <커밋 범위 또는 "미커밋 변경">
비워 둔 항목: <예: assumptions — 대화에 드러나지 않음>   # 없으면 이 줄 생략

<decision.md 전문>

고칠 곳이 있으면 말해 주세요. 커밋 전이면 이 기록을 바로 고칩니다.

다음 단계 (선택):
  - 다음 커밋 메시지 본문에 "Intent: <NNNN>" trailer 추가
  - 코드와 의도가 영구적으로 연결됨
```

**자동으로 `git commit --amend`하거나 새 커밋을 만들지 마세요.** 사용자가 다음 커밋부터 수동으로 trailer 추가.

## 저장 후 수정

사용자가 저장된 기록의 수정을 요청하면 그 기록이 커밋됐는지 확인한다.

```bash
git status --porcelain docs/intent/<NNNN>-<slug>/
```

| 결과 | 동작 |
|---|---|
| 출력이 있다 (아직 커밋되지 않음) | `decision.md`를 직접 고치고 `_INDEX.md`의 제목도 맞춘다 |
| 출력이 없다 (커밋됨) | 본문을 고치지 않는다. 보강은 `intent-refine`, 대체는 새 기록의 `supersedes`, 무효화는 `intent-retract`로 남긴다 |

## 관계 처리 (supersedes / refines)

사용자가 "이전 #0019 결정을 뒤집는 작업이다"라고 명시하면:

1. 새 사이클 frontmatter에 `supersedes: [0019]`
2. 옛 사이클 `docs/intent/0019-*/decision.md`의 frontmatter `superseded_by: <새 ID>`로 갱신

`refines`를 기록할 때도 대칭으로 옛 결정의 `refined_by` 리스트에 새 ID를 append한다.

backward 필드(`superseded_by`/`refined_by`/`retracted_by`) 갱신은 append-only 원칙의 **통제된 예외 3종**이다. 옛 결정의 해당 필드 한 개만 갱신하고(필드가 없으면 추가), 본문·다른 필드는 절대 건드리지 않음.

기록된 결정의 정교화 전용 흐름은 `intent-refine`, 철회는 `intent-retract` 스킬이 담당한다.

## 개인정보

기록은 저장소에 커밋되어 다른 사람과 공유된다. `decision.md`와 `transcript.md` 모두 다음을 지킨다.

- 비밀값(토큰·비밀번호·키), 접속 정보(서버 주소·계정), 개인 식별 정보(실명·이메일 주소·사용자 홈 디렉토리의 절대 경로)는 `[비공개 처리]`로 바꾼다. 그 밖의 원문은 고치지 않는다.
- 프로젝트 지침(`CLAUDE.md`·`AGENTS.md`)에 개인정보 규칙이 있으면 그 규칙을 따른다.
- 가린 값이 있으면 9단계 보고에 무엇을 가렸는지 적는다(값 자체는 적지 않는다).

## 예외 처리

기록 자체가 성립하지 않는 경우다. 이때만 저장하지 않고 사용자에게 알리거나 묻는다.

- `git`이 초기화 안 된 디렉토리: 사용자에게 알리고 종료. claude-intent는 git 위에서 동작.
- 변경사항 0건: 사용자에게 "기록할 변경 없음" 알림 후 종료. **예외**: supersede 목적 기록(코드 변경 없이 기존 결정을 뒤집고 대체하는 결정)은 변경사항 0건을 허용하며, 이때 `commits`/`files`는 빈 리스트로 둔다.
- 대화 내 의도 추출 실패(`intent`를 한 문장으로 쓸 근거가 대화에 없음): 추측하지 않고 사용자에게 직접 입력 요청.

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
- **assumptions**: 결정이 의존하는 가정. 구체적·측정 가능하게 적는다(예: "외부 API ~100rps"). 가정이 깨지면 결정을 재검토하는 신호다. 대화에 드러난 것만 적으며, 없으면 `[]`다.
- **author**: 기록을 작성한 주체. 프로젝트 지침이 작성자 표기를 정하면 그 값을 쓰고, 정하지 않았으면 `claude`다. git `user.name`은 쓰지 않는다. 기록을 커밋한 사람은 커밋 author로 남는다.
- **session** (선택): 기본으로 기록하지 않는다. 프로젝트 지침이 요구할 때만 Claude Code session ID(UUID)를 넣는다. 세션 ID는 기록을 만든 기기에서 원본 대화를 찾을 때만 쓸모가 있고, 공유 저장소에서는 다른 사람에게 의미가 없는 식별자다.

### transcript.md
user·assistant 본문은 원문 그대로, 도구 호출은 한 줄 요약, 도구 결과는 의미 있을 때만 짧게 인용한다. 시간순으로 적고 미화하지 않는다.
