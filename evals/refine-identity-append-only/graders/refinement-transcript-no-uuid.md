---
type: regex
target:
  source: file
  path: docs/intent/0002-document-api-rate-limit-evidence/transcript.md
pattern: '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
flags: i
match: not_contains
---
