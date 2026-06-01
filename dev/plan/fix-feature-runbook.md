# Runbook: drive one feature to conformance (build → test → revise loop)

Reusable. The measuring stick is the **official yaml-test-suite**, run through
this repo's conformance harness. You are given ONE feature/tag (e.g. `flow`,
`anchor`, `block-scalars`) and you raise its conformance pass count to green
without regressing any case that already passes.

## Hard constraints (non-negotiable — violating any of these fails the task)
- Pure Common Lisp, **ZERO runtime dependencies**. Recursive-descent only.
- **Loud failure**: malformed input signals a `yaml-error` subclass *with
  position*. Never return a sentinel, never silently degrade, never add a
  fallback/try-the-easy-thing path. An error case in the suite must SIGNAL.
- Representation is fixed: mapping → `hash-table` (test `equal`),
  sequence → `vector`, `null`→`cl:null`, `false`→`nil`, `true`→`t`,
  int→integer, float→float, else→string.
- Do NOT weaken or delete existing tests to make numbers go up. Do NOT edit the
  conformance harness to mask failures.

## The loop
1. **MEASURE (before).** From repo root `/data/projects/yaml-parther`:
   ```
   ros run -- --disable-debugger \
     --eval '(ql:register-local-projects)' \
     --eval '(ql:quickload :yaml-parther/test :silent t)' \
     --eval '(uiop:quit (if (parachute:status (parachute:test :yaml-parther/test :report (quote parachute:summary))) 0 1))'
   ```
   Record the `;; Conformance: N passed, M failed` line (OVERALL) and your
   feature's slice. (Find how the harness loads/filters cases under
   `test/conformance/`; the vendored suite or /tmp/yts holds `in.yaml` +
   expected `test.event`/JSON + an `error` marker per case.)
2. **LOOK.** Read a handful of your feature's FAILING cases — input + expected
   output — to see the real gap. Don't guess; look at the cases.
3. **REVISE.** Implement in the right module (`src/reader.lisp` for grammar,
   `src/resolve.lisp` for scalars, `src/tags.lisp`, `src/emit.lisp`). Keep the
   recursive descent coherent.
4. **TEST (after).** Re-run the command. Your feature's passes must go UP and
   OVERALL passes must not drop (no regressions). Keep the unit suite green too.
5. Loop 2–4 until your feature's cases pass (or you've extracted all reachable
   wins and the remainder genuinely depends on another feature — say so).
6. **RECORD.** Update the matching bead: `br update <id> --status closed` when
   the feature's cases pass (else add a progress note). `br sync`.

## Report back (compact, <20 lines, NO code dumps)
- OVERALL conformance: `<before> → <after>` passed.
- This feature: `<before> → <after>` passed / how many remain.
- Regressions: MUST be 0 — state explicitly "0 regressions" or list them.
- Bead id touched + its new status.
- One line: any remaining failures in this feature and what they depend on.
