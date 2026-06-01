# Test List — Literal & Folded Block Scalars (yaml-parther-dnx)

## Tests

- [x] Simple literal scalar — `"| \n text"` preserves newlines
- [x] Simple folded scalar — `"> \n text"` folds newlines to spaces
- [ ] **→ Strip chomping (`|-`)** — removes trailing newlines
- [ ] Literal preserves leading whitespace
- [ ] Folded collapses single newlines
- [ ] Folded preserves blank lines (double newline)
- [ ] Strip chomping (`|-`) removes trailing newlines
- [ ] Keep chomping (`|+`) keeps all trailing newlines
- [ ] Clip chomping (default) keeps exactly one trailing newline
- [ ] Explicit indent indicator (`|2`) sets content indent
- [ ] Auto-detect indent from first content line
- [ ] Hook up to value position in mappings

## Refactorings

## Worries / Notes

- Indentation indicator can be 1-9
- Chomping and indent can be combined in either order: `|2-` or `|-2`
