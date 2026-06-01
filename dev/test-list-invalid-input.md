# Test list — Comprehensive invalid-input errors

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do

## In progress

## Done
- [x] Unterminated single-quoted string signals yaml-scanner-error
- [x] Unterminated double-quoted string signals yaml-scanner-error
- [x] Invalid escape sequence signals yaml-scanner-error
- [x] Invalid %YAML version format signals yaml-directive-error
- [x] Undefined alias signals yaml-reference-error
- [x] Duplicate key in mapping signals yaml-duplicate-key-error
- [x] Parse errors include line/column position
- [x] Added `*` (alias) handling to read-document-content
- [x] Updated unterminated quote error to use yaml-parse-fail for position

## Parked (worries / refactorings noticed, not yet tests)
- Inconsistent indentation detection (requires sophisticated indent tracking)
- Other error types from yaml-test-suite error cases
