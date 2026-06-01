# Test List: YAML 1.3 Divergence (yaml-parther-i7g)

Version-dependent behavior handling for YAML 1.1/1.2/1.3.

## Test List

- [x] `*yaml-version*` special variable defaults to (1 . 2)
- [x] `parse` with %YAML 1.2 sets version to (1 . 2)
- [x] `parse` with %YAML 1.1 sets version to (1 . 1)
- [ ] `parse` with %YAML 1.3 sets version to (1 . 3) (no changes needed, works)
- [ ] Version check for unsupported versions (e.g., 2.0) signals warning
- [ ] Different behavior for 1.3-err cases (error in 1.3 mode)
- [ ] Different behavior for 1.3-mod cases (modified in 1.3)

## Version-Specific Differences

### 1.3-err cases (should error in YAML 1.3)
- Certain spec violations that 1.2 was lenient about

### 1.3-mod cases (modified behavior in 1.3)
- Whitespace handling in some contexts
- Block scalar indicators

### upto-1.2 cases
- Constructs valid in 1.1/1.2 but deprecated or removed in 1.3

## Implementation Approach

1. Add `*yaml-version*` dynamic variable
2. Update parse-yaml-directive to set version
3. Add version-aware error checking in parser
4. Default to 1.2 behavior for compatibility
