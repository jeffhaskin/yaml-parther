# Test List — Duplicate-key detection (yaml-parther-9qn)

## Tests

- [ ] **→ Duplicate key signals error** — `"a: 1\na: 2"` signals yaml-duplicate-key-error
- [ ] Different keys accepted — `"a: 1\nb: 2"` works fine
- [ ] Key comparison is by resolved value — `"1: a\n1: b"` signals error (integer keys)

## DONE
