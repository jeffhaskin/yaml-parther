# Test list — Conformance harness + vendored test-suite

Seeded before coding by asking: "what tests, when passing, would prove this works?"
Conventions: `[ ]` todo · `[>]` in progress (only one at a time) · `[x]` done ·
add new tests/worries/refactorings as they occur instead of chasing them.
Done when every box is `[x]`.

## To do

## In progress

## Done
- [x] yaml-test-suite vendored (351 YAML files in tests/yaml-test-suite/src/)
- [x] generate-conformance-data.py created
- [x] conformance-data.lisp generated (406 cases)
- [x] conformance.lisp skeleton created
- [x] test/yaml-parther system loads with new conformance files
- [x] *conformance-tests* contains >350 test cases (verified: 406)
- [x] run-conformance-suite returns counts without crashing (94 pass, 312 fail)
- [x] run-single-conformance-test returns :pass for fail-flagged tests that signal
- [x] .asd updated to include conformance files
- [x] .gitignore updated for tests/yaml-test-suite/.git

## Parked (worries / refactorings noticed, not yet tests)
- parse-json-string unit tests (working, but not isolated)
- values-equal-p unit tests (working, but not isolated)
- known-failing list mechanism (empty but ready)
