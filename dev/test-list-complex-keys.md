# Test list — Complex & empty keys

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do

## In progress

## Done
- [x] ? [1, 2] : value - flow sequence as key
- [x] ? {a: 1} : value - flow mapping as key
- [x] : value - implicit empty key (null key)
- [x] ? : value - explicit empty key
- [x] : alone - empty key and empty value

## Parked (worries / refactorings noticed, not yet tests)
- quoted strings as keys (already handled)
- block scalar keys (may need work)
