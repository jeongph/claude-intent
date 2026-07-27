---
name: intent-refine
description: >-
  Use when the user wants to refine/elaborate an already-recorded decision in docs/intent/ — adding evidence, assumptions, or clearer rationale, typically WITHOUT new code changes. 사용자가 한국어로 "#0042 정교화해줘", "그 결정에 근거 보강해줘", "intent refine", "이전 결정 더 명확히 남겨줘", "그때 결정한 거에 가정 추가해줘", "그 결정 이해가 깊어졌어 기록하자"라고 하거나, 영어로 "refine decision #42", "add rationale to that decision", "intent refine"이라고 할 때. 기존 결정을 앵커로 새 사이클을 만들고 refines/refined_by로 연결한다. git 변경사항이 없어도 동작한다. 구분: 새 작업 사이클 기록(코드 변경 동반)은 intent-record, 결정을 뒤집고 대체하는 건 intent-record(supersedes), 결정 무효화는 intent-retract 영역.
---

# Intent Refine

기록된 결정을 나중에 **정교화**합니다. 근거·가정·이해를 덧붙이되, 옛 결정은 **여전히 유효**합니다 (같은 방향 심화).

비유: 각주·보론 달기.

**intent-record와의 차이**: intent-record는 git 변경 사이클이 앵커라서 변경사항 0건이면 종료한다. intent-refine은 **기존 결정이 앵커**이며 **git 변경사항 없이 동작**한다. 전형적 상황: "지난달 #0042를 결정했는데, 지금 보니 그 가정이 왜 맞는지 더 명확해졌다."

## 워크플로우

### 1. 사전 점검

```bash
ls docs/intent/ 2>/dev/null
```

- 없거나 비어있음 → "기록된 결정이 없음. `intent-record`로 첫 사이클부터 만드세요." 안내 후 종료. 추측·환각 금지.

### 2. 대상 결정 식별

사용자 입력을 intent-why와 동일한 규칙으로 분류해 검색한다 (#ID 직접 / 파일 경로 / 키워드 / 커밋 hash).

```bash
ls -d docs/intent/<NNNN>-*/           # ID 직접
grep -rli "<keyword>" docs/intent/*/decision.md   # 키워드
```

- 매칭 0건 → 추측하지 않고 사용자에게 재확인
- 매칭 2건 이상 → 후보 나열 후 사용자 선택
- 대상이 이미 철회됨(`retracted_by` 있음) → "⚠️ 철회된 결정입니다. 정교화가 의미 있나요?" 경고 후 진행 여부 확인
- 대상이 이미 대체됨(`superseded_by` 있음) → "⚠️ #NNNN이 이 결정을 대체했습니다. 신결정을 정교화할까요?" 확인

### 3. 대상 로드·표시

대상 decision.md의 `Intent` / `Chosen` / `Assumptions`를 요약해 보여주고, **무엇을 정교화하려는지** 사용자와 맞춘다.

### 4. 정교화 내용 추출

현재 대화에서 다음을 뽑는다. **명시적으로 드러나지 않은 항목은 추측하지 말고 질문한다.**

| 항목 | 예시 단서 |
|---|---|
| 추가된 근거 | "돌려보니 실제로 ~더라", "문서 찾아보니" |
| 명확해진 가정 | "그 가정이 맞는 이유가 ~였음", 기존 assumption의 구체화 |
| 보강 설명 | "그때 못 적었는데 사실 ~" |

### 5. ID·slug 결정

intent-record와 동일 규칙: 기존 최대 ID + 1 (4자리 zero-padding), slug는 영어 소문자 kebab-case 4-6단어.

### 6. Draft 검수

`decision.md` 초안을 **전체 표시**하고 명시적 승인을 받는다. **검수 생략 금지** (자동 미화 방지 원칙).

```markdown
---
id: 0043
title: "..."
date: <YYYY-MM-DD>
author: "<git config user.name>"
commits: []          # 코드 변경 없는 정교화가 기본 — 빈 리스트 허용
files: []
supersedes: []
superseded_by: null
refines: [0042]
refined_by: []
retracts: []
retracted_by: null
assumptions:
  - "..."
session: "<현재 Claude Code session id>"
---

## Intent
(무엇을 명확히 하려 했는가 한 문장)

## Refinement
- 대상: #0042 <제목>
- 추가된 근거: ...
- 명확해진 가정: ...

## Source
[transcript.md](transcript.md)
```

사용자가 수정하면 반영, 거절하면 저장하지 않고 종료.

### 7. 저장 + 뒷링크 갱신

```bash
mkdir -p docs/intent/<NNNN>-<slug>
```

1. 새 디렉토리에 `decision.md` + `transcript.md` 저장 (transcript 작성 규칙은 intent-record와 동일)
2. **옛 결정** frontmatter의 `refined_by` 리스트에 새 ID를 append. **필드가 없으면 추가한다** (구버전 스키마 호환). 옛 결정의 본문·다른 필드는 절대 건드리지 않음 — 통제된 append-only 예외.

### 8. INDEX.md 갱신

맨 위(시간 역순)에 새 행 추가. 관계 컬럼에 `refines #0042`. 다중 관계는 쉼표 병기 (`refines #0042, supersedes #0019`). INDEX에는 **forward 관계만** 기록한다.

### 9. 사용자 안내

```
사이클 #<NNNN> 저장 완료 (refines #<대상>)

  docs/intent/<NNNN>-<slug>/decision.md
  docs/intent/<NNNN>-<slug>/transcript.md
  docs/intent/<대상>-*/decision.md (refined_by 갱신됨)
  docs/intent/INDEX.md (갱신됨)
```

git commit·amend는 하지 않는다.

## 함정

1. **대체와 혼동**: 대화에서 "기존 결정 대신 다르게 간다"가 드러나면 정교화가 아니라 **supersede**다 → intent-record(supersedes)로 안내.
2. **무효화와 혼동**: "그 결정 자체가 잘못됐고 대체도 없다"면 → intent-retract로 안내.
3. **재정교화는 정상**: `refined_by`가 이미 있는 결정도 다시 정교화할 수 있다 (리스트에 append).
