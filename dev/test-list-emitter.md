# Test List — Emitter + round-trip (yaml-parther-i01)

## Tests

- [ ] **→ Emit scalar string** — `(yaml:emit "hello")` returns `"hello"` or `hello`
- [ ] Emit integer — `(yaml:emit 42)` returns `"42"`
- [ ] Emit float — `(yaml:emit 3.14)` returns `"3.14"`
- [ ] Emit null — `(yaml:emit 'null)` returns `"null"` or `"~"`
- [ ] Emit boolean T — `(yaml:emit t)` returns `"true"`
- [ ] Emit boolean NIL — `(yaml:emit nil)` returns `"false"`
- [ ] Emit simple sequence — `(yaml:emit #(1 2 3))` returns block sequence
- [ ] Emit simple mapping — hash-table with string keys
- [ ] Round-trip: parse then emit preserves structure

## DONE

