---
type: regex
target:
  source: file
  path: docs/intent/0001-adopt-exponential-retry-backoff/transcript.md
pattern: '/(Users|home)/[^/\s\[]+/'
flags: m
match: not_contains
---
