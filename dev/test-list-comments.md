# Test list — Comment handling

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do

## In progress

## Done
- [x] source-skip-comment skips from # to end of line
- [x] source-skip-comment returns 0 when no # present
- [x] source-skip-comment does not consume the line break
- [x] source-skip-whitespace-and-comments skips space then comment
- [x] source-skip-whitespace-and-comments skips multiple lines with comments
- [x] source-skip-whitespace-and-comments handles blank lines between comments
- [x] comment at end of line (trailing comment sequence)

## Parked (worries / refactorings noticed, not yet tests)
- # inside quoted strings handled by quoted scalar parser, not here
- # without preceding whitespace (like foo#bar) - context-dependent, handle in reader
