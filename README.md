# claude-intent

> 코드는 의도의 그림자다.

작업 사이클의 **의도(Intent)·대안(Alternatives)·트레이드오프(Trade-offs)**를 자동 추출해 `docs/intent/`에 기록하고, 나중에 코드의 "왜"를 역추적하는 Claude Code 플러그인입니다.

## 왜 만들었는가

기존 저장 방식(코드, 커밋 메시지, PR 설명, ADR)은 모두 **결과**만 담아왔습니다. 사고의 흐름 그 자체는 휘발됩니다. ADR이 "의도를 담자"고 시도했지만 **사람이 손으로 써야 했기에** 정착하지 못했습니다.

Claude Code와의 페어 프로그래밍은 사고를 자연스럽게 텍스트화합니다. 이 플러그인은 그 transcript를 **자동으로 구조화**해 보존합니다.

## 동작 원칙

- **append-only**: 옛 결정은 수정하지 않고, 새 결정이 `supersedes`로 뒤집음 (정직성)
- **자동 추출 + 사용자 검수**: 자동이되 사후 미화 방지를 위해 검수 단계 필수
- **git을 건드리지 않음**: 커밋 trailer는 사용자가 직접 추가. 도구가 git history를 자동 amend하지 않음

## 더 큰 그림

이 플러그인은 "코드와 의도가 1:1로 대응되는 저장소"라는 더 큰 아이디어의 첫 발자국입니다. why-blame, assumption verification, 의도 기반 검색 같은 기능은 향후 방향이며 현재 범위는 아닙니다.

## 스킬

| 스킬 | 동작 | 비유 |
|---|---|---|
| `intent-record` | 현재 작업 사이클의 의도를 추출·저장 | `git commit` |
| `intent-why` | 코드·키워드로 과거 결정 역추적 | `git blame` |

## 사용 흐름

작업 마치고:

> "이번 사이클 정리해줘"

→ `intent-record` 스킬 발동 → transcript에서 의도/대안/근거/가정 추출 → yaml draft → 사용자 검수 → `docs/intent/<NNNN>-<slug>/decision.md` + `transcript.md` 저장 + `INDEX.md` 갱신

나중에:

> "src/retry.ts 왜 이래?"

→ `intent-why` 스킬 발동 → frontmatter·INDEX 검색 → 관련 결정 표시 + supersedes 체인 추적

## 데이터 모델

저장 위치: 사용하는 프로젝트의 `docs/intent/`

```
docs/intent/
├── INDEX.md                          # 자동 생성 timeline
├── 0001-add-retry-backoff/
│   ├── decision.md                   # 정제본 (yaml frontmatter + 본문)
│   └── transcript.md                 # raw 대화 발췌
└── 0002-tighten-jitter/
    ├── decision.md
    └── transcript.md
```

상세 schema는 [docs/SCHEMA.md](docs/SCHEMA.md) 참고.

## 설치

```bash
# Claude Code 마켓플레이스 (예정)
/plugin install claude-intent

# 또는 로컬 개발
git clone https://github.com/jeongph/claude-intent.git ~/.claude/plugins/claude-intent
```

## Status

🚧 v0.1.0 — Phase 1 (MVP). 자체 dogfood 단계.

## License

MIT
