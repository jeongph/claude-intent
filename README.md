# claude-intent

[![version](https://img.shields.io/github/v/release/jeongph/claude-intent?label=version&color=blue)](https://github.com/jeongph/claude-intent/releases)
[![license](https://img.shields.io/github/license/jeongph/claude-intent?color=lightgrey)](LICENSE)

코드를 왜 이렇게 작성했는지, 어떤 대안을 검토했는지 기록하고 나중에 찾아볼 수 있습니다.

## 왜 만들었는가

코드, 커밋 메시지, PR 설명만으로는 어떤 대안을 검토했고 왜 현재 방식을 선택했는지 파악하기 어려울 때가 있습니다. ADR에 결정 이유를 남길 수도 있지만, 작업 후 별도로 작성해야 하는 부담이 있습니다.

이 플러그인은 Claude Code와 나눈 대화에서 결정 이유를 정리합니다. 사용자가 초안을 검토한 뒤 기록으로 저장합니다.

## 동작 원칙

- **기존 결정 보존**: 옛 결정의 본문을 수정하지 않고 새 기록을 추가한다. `supersedes`(대체), `refines`(보강), `retracts`(철회)로 결정 간 관계를 연결한다
- **사용자 검수 필수**: 추출한 내용이 실제 대화와 일치하는지 확인한 뒤 저장한다
- **git을 건드리지 않음**: 커밋 trailer는 사용자가 직접 추가. 도구가 git history를 자동 amend하지 않음

## 향후 방향

장기적으로는 코드와 결정 이유를 연결하는 저장소를 목표로 합니다. 코드의 결정 이유를 추적하는 why-blame, 가정 검증, 의도 기반 검색은 향후 검토할 기능이며 현재는 제공하지 않습니다.

## 스킬

| 스킬 | 동작 | 비유 |
|---|---|---|
| `intent-record` | 현재 작업 사이클의 의도를 추출·저장 | `git commit` |
| `intent-why` | 코드·키워드로 과거 결정 역추적 | `git blame` |
| `intent-refine` | 기록된 결정에 근거·가정을 나중에 보강 (코드 변경 불필요) | 각주·보론 |
| `intent-retract` | 기록된 결정을 대체 없이 철회 (이유가 기록으로 남음) | `git revert` |

### 관계 모델

| forward | backward | 의미 |
|---|---|---|
| `supersedes` | `superseded_by` | 뒤집고 **대체** (새 방향 있음) |
| `refines` | `refined_by` | 같은 방향 **정교화** (옛 결정 여전히 유효) |
| `retracts` | `retracted_by` | **철회** — 무효화, 대체 없음 |

예외적으로 기존 결정의 backward 필드는 갱신할 수 있다. 새 결정과의 관계를 표시하기 위한 변경이며, 해당 필드 하나만 수정하고 본문은 그대로 둔다.

## 사용 흐름

작업 마치고:

> "이번 사이클 정리해줘"

→ `intent-record` 스킬 발동 → 대화 기록에서 의도·대안·근거·가정 추출 → YAML 초안 → 사용자 검수 → `docs/intent/<NNNN>-<slug>/decision.md` + `transcript.md` 저장 + `_INDEX.md` 갱신

나중에:

> "src/retry.ts 왜 이래?"

→ `intent-why` 스킬 발동 → frontmatter·INDEX 검색 → 관련 결정 표시 + 관계 체인 추적 (철회된 결정은 ⚠️ 경고)

결정이 더 명확해졌거나 무효가 됐을 때:

> "#0042에 근거 보강해줘" → `intent-refine` (코드 변경 없이 정교화)
>
> "#0042 없던 걸로 기록해줘" → `intent-retract` (대체 없이 철회, 이유 기록)

## 데이터 모델

저장 위치: 사용하는 프로젝트의 `docs/intent/`

```
docs/intent/
├── _INDEX.md                         # 자동 생성 timeline
├── 0001-add-retry-backoff/
│   ├── decision.md                   # 정제본 (yaml frontmatter + 본문)
│   └── transcript.md                 # raw 대화 발췌
└── 0002-tighten-jitter/
    ├── decision.md
    └── transcript.md
```

자세한 데이터 형식은 [skills/intent-record/SKILL.md](skills/intent-record/SKILL.md)의 "데이터 형식" 절 참고.

### 이전 이름(`INDEX.md`)을 쓰던 프로젝트

별도 조치가 필요 없다. `intent-record`·`intent-refine`·`intent-retract`가 인덱스를 다음에 갱신할 때 처리한다: `INDEX.md`만 있으면 `_INDEX.md`로 이름을 바꾸고, `_INDEX.md`가 이미 있으면 그것을 최신으로 보고 `INDEX.md`에만 있던 행을 병합한 뒤 `INDEX.md`를 지운다. `intent-why`는 조회 전용이라 파일을 바꾸지 않고, `_INDEX.md`가 없으면 `INDEX.md`를 읽는다.

## 설치

[jeongph/claude-plugins 마켓플레이스](https://github.com/jeongph/claude-plugins)에서 설치한다.

마켓플레이스 등록(최초 1회):

```
/plugin marketplace add jeongph/claude-plugins
```

플러그인 설치:

```
/plugin install claude-intent@jeongph-claude-plugins
```

로컬 개발 시에는 저장소를 clone한 뒤 `claude --plugin-dir <경로>`로 로드한다.

## License

MIT
