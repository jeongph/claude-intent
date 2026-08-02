---
name: intent-retract
description: >-
  Use when the user wants to retract/void an already-recorded decision in docs/intent/ — marking it invalid WITHOUT a replacement decision. 사용자가 한국어로 "#0042 철회해줘", "그 결정 없던 걸로 기록해줘", "intent retract", "그 결정 무효화해줘", "그거 폐기된 결정이야 남겨줘"라고 하거나, 영어로 "retract decision #42", "void that decision", "intent retract"라고 할 때. 구분: 코드를 되돌리는 것(git revert)이 아니라 기록된 결정의 무효화다. 대체 결정이 있으면 retract가 아니라 intent-record(supersedes) 영역이고, 결정이 여전히 유효한데 보강만 하려면 intent-refine 영역이다.
---

# Intent Retract

기록된 결정을 **철회**합니다 — 무효화하되 대체하지 않습니다. 철회 이유가 온전한 기록으로 남습니다.

비유: `git revert`의 의도 레이어. 되돌리되 히스토리는 남긴다.

**supersede와의 구분 (핵심 가드레일)**: supersede는 "대신 이렇게 한다"(대체), retract는 "이건 없던 걸로, 대체 없음"(무효화). 대화에서 **대체 결정이 드러나면 철회가 아니다** → intent-record(supersedes)로 안내한다. 이때 코드 변경이 없어도 intent-record의 supersede 목적 기록은 변경사항 0건이 허용된다.

## 워크플로우

### 1. 사전 점검

```bash
ls docs/intent/ 2>/dev/null
```

- 없거나 비어있음 → "기록된 결정이 없음. `intent-record`로 첫 사이클부터 만드세요." 안내 후 종료. 추측·환각 금지.

### 2. 대상 결정 식별

intent-why와 동일한 규칙으로 검색 (#ID 직접 / 파일 경로 / 키워드 / 커밋 hash).

- 매칭 0건 → 추측하지 않고 사용자에게 재확인
- 매칭 2건 이상 → 후보 나열 후 사용자 선택
- **이미 철회됨(`retracted_by` 있음) → 진행 불가(하드 블록).** "#NNNN이 이미 이 결정을 철회했습니다." 안내 후 종료. `retracted_by`는 스칼라 — 덮어쓰기 금지.
- 이미 대체됨(`superseded_by` 있음) → "⚠️ #NNNN이 이미 이 결정을 대체했습니다. 그래도 철회 기록을 남길까요?" 경고 후 진행 여부 확인 (대체된 결정의 무효 선언이 별도로 필요한 경우가 있음).

### 3. 대상 로드·표시

대상 decision.md의 `Intent` / `Chosen` / `Assumptions`를 요약해 보여주고 철회 대상이 맞는지 확인한다.

### 4. 철회 이유 추출

**"왜 없던 걸로 하는가"**를 대화에서 뽑는다. 명시적이지 않으면 질문한다. 전형적 이유:

| 유형 | 예시 |
|---|---|
| 가정 붕괴 | "외부 API rate limit이 100rps라 했는데 실제 10rps였음" |
| 전제 소멸 | "그 기능 자체가 제품에서 빠짐" |
| 판단 오류 | "측정해보니 애초에 문제가 아니었음" |

이 시점에 **대체 방향이 언급되면 중단하고 supersede로 안내** (위 가드레일).

### 5. ID·slug 결정

intent-record와 동일 규칙: 기존 최대 ID + 1 (4자리 zero-padding), slug는 영어 소문자 kebab-case 4-6단어. 예: `retract-retry-backoff-assumption`.

### 6. Draft 검수

`decision.md` 초안을 **전체 표시**하고 명시적 승인을 받는다. **검수 생략 금지.**

```markdown
---
id: 0044
title: "..."
date: <YYYY-MM-DD>
author: "<git config user.name>"
commits: []          # 철회는 보통 코드 변경 없음 — 빈 리스트 허용
files: []
supersedes: []
superseded_by: null
refines: []
refined_by: []
retracts: [0042]
retracted_by: null
assumptions: []
session: "<현재 Claude Code session id>"
---

## Intent
(왜 이 결정을 무효화하는가 한 문장)

## Retraction
- 대상: #0042 <제목>
- 철회 이유: ...
- 깨진 가정: ... (해당 시)
- 대체 결정: 없음 (있다면 이 문서가 아니라 supersede여야 함)

## Source
[transcript.md](transcript.md)
```

사용자가 수정하면 반영, 거절하면 저장하지 않고 종료.

### 7. 저장 + 뒷링크 갱신

```bash
mkdir -p docs/intent/<NNNN>-<slug>
```

1. 새 디렉토리에 `decision.md` + `transcript.md` 저장 (transcript 규칙은 intent-record와 동일)
2. **옛 결정** frontmatter의 `retracted_by: <새 ID>` 갱신. **필드가 없으면 추가한다** (구버전 스키마 호환). 본문·다른 필드는 절대 건드리지 않음 — 통제된 append-only 예외.

### 8. _INDEX.md 갱신

갱신 전에 이전 이름의 파일을 확인한다. 두 파일이 함께 방치되면 갱신이 멈춘
쪽이 실제와 어긋난 채 남는다.

- `docs/intent/INDEX.md`만 있으면 `docs/intent/_INDEX.md`로 이름을 바꾼 뒤 갱신한다.
- 둘 다 있으면 `_INDEX.md`가 최신이다. **절대 덮어쓰지 않는다.** `INDEX.md`에만 있는 행을 ID 기준으로 `_INDEX.md`에 옮기고, 같은 ID가 양쪽에 있으면 `_INDEX.md` 쪽 행을 남긴다. 합친 표는 ID 역순(최신이 맨 위)으로 정렬한 뒤 `INDEX.md`를 삭제한다.
- `_INDEX.md`만 있으면 그대로 갱신을 진행한다.

맨 위(시간 역순)에 새 행 추가. 관계 컬럼에 `retracts #0042`. 다중 관계는 쉼표 병기. INDEX에는 **forward 관계만** 기록한다.

### 9. 사용자 안내

```
사이클 #<NNNN> 저장 완료 (retracts #<대상>)

  docs/intent/<NNNN>-<slug>/decision.md
  docs/intent/<NNNN>-<slug>/transcript.md
  docs/intent/<대상>-*/decision.md (retracted_by 갱신됨)
  docs/intent/_INDEX.md (갱신됨)

이후 intent-why에서 #<대상>은 "⚠️ 철회됨"으로 표시됩니다.
```

git commit·amend는 하지 않는다. 코드 되돌리기(revert)가 필요하면 그것은 별도의 git 작업이다.

## 함정

1. **supersede와 혼동이 가장 흔한 오용.** "대신 ~로 간다"가 한 마디라도 나오면 retract가 아니다.
2. **retract의 retract는 없다.** 철회를 되돌리고 싶으면 새 결정을 intent-record로 기록하고 본문에서 철회 사이클을 참조하라 (관계 체인의 순환 방지).
3. **철회해도 파일은 남는다.** 옛 decision.md를 삭제·수정하지 않는다. 철회는 상태 표시이지 말소가 아니다.
