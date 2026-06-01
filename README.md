# yaml-parther

A from-scratch, **zero-dependency YAML 1.2 parser and emitter** for Common Lisp.

The parser is the primary concern; the emitter is secondary. Aim is full
[YAML 1.2](https://yaml.org/spec/1.2.2/) conformance, verified against the
official [yaml-test-suite](https://github.com/yaml/yaml-test-suite).

## Representation

Parsed YAML becomes native Lisp data:

| YAML            | Lisp                          |
|-----------------|-------------------------------|
| mapping         | `hash-table` (test `equal`)   |
| sequence        | `vector`                      |
| `null`          | the symbol `cl:null`          |
| `false`         | `nil`                         |
| `true`          | `t`                           |
| integer         | integer                       |
| float           | float                         |
| everything else | string                        |

## Principles

- **Recursive descent, hand-written.** No parser-generator, no dependencies.
- **Loud failure.** Malformed input or an unresolvable reference signals a
  condition (a subclass of `yaml-error`). No silent fallbacks, no sentinels.

## Layout

```
src/
  packages.lisp    public package + exported surface
  conditions.lisp  the yaml-error failure taxonomy
  source.lisp      input cursor + line/column position
  reader.lisp      fused lex+parse+compose+construct (the whole input side)
  resolve.lisp     scalar text -> native Lisp value (core schema)
  tags.lisp        %TAG handles + shorthand expansion
  emit.lisp        the whole output side
  api.lisp         the public facade (parse / parse-all / emit / ...)
test/              Parachute suite + conformance runner (see docs/adr)
```

## Toolchain (Roswell)

```sh
# Run the test suite
ros run -- --eval '(asdf:test-system :yaml-parther)' --quit

# Load into a REPL
ros run -- --eval '(ql:quickload :yaml-parther)'
```

## Status

Skeleton. The public verbs are stubs that signal until implemented.
