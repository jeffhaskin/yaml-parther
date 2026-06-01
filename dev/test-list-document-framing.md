# Test List: Document Framing (yaml-parther-5w3)

Document start/end markers and multi-document streams.

## Test List

- [x] `source-match-document-start` — `---` followed by space, newline, or EOF returns T
- [x] `source-match-document-start-requires-boundary` — `---x` (no boundary) returns NIL
- [x] `source-match-document-end` — `...` followed by space, newline, or EOF returns T
- [x] `source-match-document-end-requires-boundary` — `...x` returns NIL
- [x] `parse` — empty string returns NULL
- [x] `parse` — single implicit document (no markers) returns value
- [x] `parse` — explicit `---` before content returns value
- [x] `parse` — `---` with trailing `...` returns value
- [x] `parse-all` — empty string returns empty vector
- [x] `parse-all` — single document returns single-element vector
- [x] `parse-all` — two documents separated by `---` returns two-element vector
- [x] `parse-all` — document ending with `...` then new `---` works
- [ ] `parse` — multiple documents without allow-multiple signals error (SKIPPED - depends on other beads)

## Notes

- Document markers must be at start of line (column 0)
- `---` and `...` must be followed by whitespace, newline, or EOF to be markers
- Bare `...` without `---` is valid (implicit document end)
