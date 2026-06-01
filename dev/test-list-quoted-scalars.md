# Test list — Single- & double-quoted scalars

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do

## In progress

## Done

### Single-quoted scalars
- [x] read-single-quoted-scalar reads `'hello'` as "hello"
- [x] read-single-quoted-scalar reads `''` (empty) as ""
- [x] read-single-quoted-scalar reads `'it''s'` as "it's" (escaped single quote)
- [x] read-single-quoted-scalar reads `'line\nfoo'` as literal "line\nfoo" (no escapes)

### Double-quoted scalars
- [x] read-double-quoted-scalar reads `"hello"` as "hello"
- [x] read-double-quoted-scalar reads `""` (empty) as ""
- [x] read-double-quoted-scalar reads `"line\nfoo"` as "line<LF>foo"
- [x] read-double-quoted-scalar reads `"tab\there"` as "tab<TAB>here"
- [x] read-double-quoted-scalar reads `"\""` as `"`
- [x] read-double-quoted-scalar reads `"\\"` as `\`
- [x] read-double-quoted-scalar reads `"\x41"` as "A" (hex escape)
- [x] read-double-quoted-scalar reads `"A"` as "A" (unicode 4-digit)
- [x] read-double-quoted-scalar reads `"\U00000041"` as "A" (unicode 8-digit)

## Parked (worries / refactorings noticed, not yet tests)
- multiline quoted scalars with folding (future bead)
- escaped line break continuation in double-quoted (future bead)
- error tests for unterminated quotes and invalid escapes (future bead)
