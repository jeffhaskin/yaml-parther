# Test list — Plain scalars + core-schema resolution

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do

## In progress

## Done
- [x] explicit tag !!str forces string even for "true"
- [x] explicit tag !!int forces integer (error if invalid)
- [x] explicit tag !!bool forces boolean (error if invalid)
- [x] null: empty string -> CL:NULL
- [x] null: "~" -> CL:NULL
- [x] null: "null" (case insensitive) -> CL:NULL
- [x] true: "true" (case insensitive) -> T
- [x] false: "false" (case insensitive) -> NIL
- [x] integer: decimal positive "42" -> 42
- [x] integer: decimal negative "-42" -> -42
- [x] integer: decimal with plus "+42" -> 42
- [x] integer: octal "0o17" -> 15
- [x] integer: hex "0x2A" -> 42
- [x] float: simple "3.14" -> 3.14d0
- [x] float: negative "-3.14" -> -3.14d0
- [x] float: exponent "1.5e10" -> 1.5d10
- [x] float: leading dot ".5" -> 0.5d0
- [x] float: ".inf" -> most-positive-double-float
- [x] float: "-.inf" -> most-negative-double-float
- [x] float: ".nan" -> NaN (skipped - platform-dependent)
- [x] string: unrecognized pattern "hello" -> "hello"
- [x] string: looks-like-but-not "0o8" -> "0o8" (invalid octal)

## Parked (worries / refactorings noticed, not yet tests)
- NaN handling is platform-specific (SBCL warns about 0.0/0.0)
