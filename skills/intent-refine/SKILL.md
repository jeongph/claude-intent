---
name: intent-refine
description: >-
  Use when the user wants to refine/elaborate an already-recorded decision in docs/intent/ — adding evidence, assumptions, or clearer rationale, typically WITHOUT new code changes. 사용자가 한국어로 "#0042 정교화해줘", "그 결정에 근거 보강해줘", "intent refine", "이전 결정 더 명확히 남겨줘", "그때 결정한 거에 가정 추가해줘", "그 결정 이해가 깊어졌어 기록하자"라고 하거나, 영어로 "refine decision #42", "add rationale to that decision", "intent refine"이라고 할 때. 기존 결정을 앵커로 새 사이클을 만들고 refines/refined_by로 연결한다. git 변경사항이 없어도 동작한다. 구분: 새 작업 사이클 기록(코드 변경 동반)은 intent-record, 결정을 뒤집고 대체하는 건 intent-record(supersedes), 결정 무효화는 intent-retract 영역.
---

# Intent Refine

기록된 결정을 나중에 **정교화**합니다. 근거·가정·이해를 덧붙이되, 옛 결정은 **여전히 유효**합니다 (같은 방향 심화).

비유: 각주·보론 달기.

**intent-record와의 차이**: intent-record는 git 변경 사이클이 앵커라서 변경사항 0건이면 종료한다. intent-refine은 **기존 결정이 앵커**이며 **git 변경사항 없이 동작**한다. 전형적 상황: "지난달 #0042를 결정했는데, 지금 보니 그 가정이 왜 맞는지 더 명확해졌다."

## 저장 방식

정교화를 요청받으면 **1~9단계를 이어서 수행해 저장한 뒤 보고한다.** ID·제목·slug는 스스로 정하고, 대화에 드러나지 않은 항목은 비워 둔다.

| 조건 | 동작 |
|---|---|
| 기본 | 끝까지 진행해 저장하고 9단계 보고로 마친다 |
| 사용자 요청에 "검수", "초안 먼저", "확인하고 저장", "review first"가 있다. 또는 프로젝트 지침 파일(`CLAUDE.md`·`AGENTS.md`)이 저장 전 검수를 요구한다 | **검수 모드**: 6단계에서 초안을 전체 표시하고 승인을 받은 뒤 저장한다. 수정 요청은 반영하고, 거절하면 저장하지 않는다 |
| 대상을 하나로 정할 수 없다(2단계), 정교화할 내용이 대화에 없다(4단계) | 그 단계대로 사용자에게 묻는다 |

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

### 3. 대상 로드

대상 decision.md의 `Intent` / `Chosen` / `Assumptions`를 읽는다. 대상의 제목과 한 줄 요약은 9단계 보고에 넣는다.

### 4. 정교화 내용 추출

현재 대화에서 다음을 뽑는다. **대화에서 근거를 짚을 수 있는 내용만 적는다.** 세 항목 중 드러난 것만 쓰고 나머지는 생략한다. 세 항목 모두 대화에 없으면 무엇을 보강할지 사용자에게 묻는다.

| 항목 | 예시 단서 |
|---|---|
| 추가된 근거 | "돌려보니 실제로 ~더라", "문서 찾아보니" |
| 명확해진 가정 | "그 가정이 맞는 이유가 ~였음", 기존 assumption의 구체화 |
| 보강 설명 | "그때 못 적었는데 사실 ~" |

### 5. ID·slug 결정

intent-record와 동일 규칙: 기존 최대 ID + 1 (4자리 zero-padding), slug는 영어 소문자 kebab-case 4-6단어.

### 6. decision.md 작성과 점검

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

저장 전에 초안의 문장을 하나씩 대화와 대조한다. 근거가 되는 발화를 짚을 수 있는 문장만 남기고, `assumptions`에는 대화에서 누군가 말한 가정만 둔다.

검수 모드면 이 단계에서 초안을 전체 표시하고 승인을 받는다([저장 방식](#저장-방식)).

### 7. 저장 + 뒷링크 갱신

```bash
mkdir -p docs/intent/<NNNN>-<slug>
```

1. 새 디렉토리에 `decision.md` + `transcript.md` 저장 (transcript 작성 규칙은 intent-record와 동일)
2. **옛 결정** frontmatter의 `refined_by` 리스트에 새 ID를 append. **필드가 없으면 추가한다** (구버전 스키마 호환). 옛 결정의 본문·다른 필드는 절대 건드리지 않음 — 통제된 append-only 예외.

### 8. _INDEX.md 갱신

갱신 전에 이전 이름의 파일을 확인한다. 두 파일이 함께 방치되면 갱신이 멈춘
쪽이 실제와 어긋난 채 남는다.

- `docs/intent/INDEX.md`만 있으면 `docs/intent/_INDEX.md`로 이름을 바꾼 뒤 갱신한다.
- 둘 다 있으면 `_INDEX.md`가 최신이다. **절대 덮어쓰지 않는다.** `INDEX.md`에만 있는 행을 ID 기준으로 `_INDEX.md`에 옮기고, 같은 ID가 양쪽에 있으면 `_INDEX.md` 쪽 행을 남긴다. 합친 표는 ID 역순(최신이 맨 위)으로 정렬한 뒤 `INDEX.md`를 삭제한다.
- `_INDEX.md`만 있으면 그대로 갱신을 진행한다.

맨 위(시간 역순)에 새 행 추가. 관계 컬럼에 `refines #0042`. 다중 관계는 쉼표 병기 (`refines #0042, supersedes #0019`). INDEX에는 **forward 관계만** 기록한다.

### 9. 저장 보고

저장한 `decision.md` **전문**을 포함해 보고한다. 사용자가 저장된 내용을 처음 보는 자리다.

```
사이클 #<NNNN> 저장 완료 (refines #<대상>)

  docs/intent/<NNNN>-<slug>/decision.md
  docs/intent/<NNNN>-<slug>/transcript.md
  docs/intent/<대상>-*/decision.md (refined_by 갱신됨)
  docs/intent/_INDEX.md (갱신됨)

대상: #<대상> <제목> — <한 줄 요약>

<decision.md 전문>

고칠 곳이 있으면 말해 주세요. 커밋 전이면 이 기록을 바로 고칩니다.
```

git commit·amend는 하지 않는다. 저장 후 수정 요청은 intent-record의 "저장 후 수정" 규칙을 따른다: 커밋 전이면 직접 고치고, 커밋 뒤에는 새 기록으로 남긴다.

## 함정

1. **대체와 혼동**: 대화에서 "기존 결정 대신 다르게 간다"가 드러나면 정교화가 아니라 **supersede**다 → intent-record(supersedes)로 안내.
2. **무효화와 혼동**: "그 결정 자체가 잘못됐고 대체도 없다"면 → intent-retract로 안내.
3. **재정교화는 정상**: `refined_by`가 이미 있는 결정도 다시 정교화할 수 있다 (리스트에 append).
