# Test list — Block sequences

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do
- [ ] nested sequence: "- - a\n  - b" -> #(#("a" "b"))
- [ ] sequence with indented continuation: "- long\n  item" -> #("long item")
- [ ] sequence indentation error: item less indented than dash

## In progress

## Done
- [x] single item sequence: "- foo" -> #("foo")
- [x] multi-item sequence: "- a\n- b\n- c" -> #("a" "b" "c")
- [x] sequence with scalars resolved: "- 1\n- true\n- null" -> #(1 T NULL)
- [x] empty sequence item: "-\n- b" -> #(NULL "b")

## Parked (worries / refactorings noticed, not yet tests)
- nested sequences require recursive descent (complex)
- indented continuations require line-folding
