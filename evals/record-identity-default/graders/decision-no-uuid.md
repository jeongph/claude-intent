---
type: regex
target:
  source: file
  path: docs/intent/0001-adopt-exponential-retry-backoff/decision.md
pattern: '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
flags: i
match: not_contains
---
