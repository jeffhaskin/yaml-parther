# Test List — Merge keys (<<) (yaml-parther-oq2)

## Tests

- [x] Simple merge — `"defaults: &d\n  a: 1\nactual:\n  <<: *d\n  b: 2"` gives actual with keys a,b
- [ ] Merge preserves local keys over merged — local wins on conflict
- [ ] Merge with multiple aliases in sequence
- [ ] Merge key with non-mapping value signals error

## DONE

