# Runbook: materialize the DAG in `dev/plan/dag.tsv` as beads

Reusable. Any agent can execute this against `dag.tsv` with no bespoke prompt.
Tool: `br` (beads) v0.2.x at `~/.local/bin/br`. Run from repo root
`/data/projects/yaml-parther`.

## Input
`dev/plan/dag.tsv` — tab-separated, header row, columns:
`KEY  SPRINT  TITLE  LABELS  DEPS  DESC`
- `KEY` = stable local handle used only to wire dependencies (not the bead ID).
- `DEPS` = `;`-separated KEYs this bead is blocked by, or `-` for none.
- Sprint = the parallelism layer; every bead's DEPS live in an earlier sprint.

## Procedure
1. **Init** (only if `.beads/` absent):
   `br init --prefix yaml-parther`
2. **Pass 1 — create every bead, map KEY -> real ID.**
   For each data row, in sprint order:
   ```
   ID=$(br create "<TITLE>" -t task -p P1 \
        -d "<DESC>" -l "<LABELS>,sprint-<SPRINT>" --silent)
   ```
   Record `KEY -> ID` (e.g. in an associative array or a temp map file).
   Do NOT pass deps yet.
3. **Pass 2 — wire dependencies.**
   For each row with non-`-` DEPS, for each depKEY:
   ```
   br dep add "<ID-of-KEY>" "<ID-of-depKEY>" --type blocks
   ```
   (first arg = the blocked/dependent bead, second = its prerequisite.)
4. **Validate**:
   - `br dep cycles`  -> must report NO cycles.
   - `br ready`       -> must list exactly the sprint-1 beads
                         (src-cursor, conditions, harness).
5. **Persist**: `br sync` (writes `.beads/issues.jsonl`). Do not push.

## Report back (compact)
- bead count created, cycle-check result.
- `br ready` titles (should be the 3 sprint-1 beads).
- per-sprint count (sprint-1..7): expected 3 / 4 / 4 / 3 / 3 / 3 / 5 = 25.
- any KEY whose dep failed to resolve.
