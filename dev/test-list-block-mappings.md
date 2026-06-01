# Test List — Block Mappings (yaml-parther-6ru)

## Tests

- [x] Single key-value pair — `"key: value"` parses to hash-table with one entry
- [x] Multiple key-value pairs — parses to hash-table with multiple entries  
- [x] Empty value — `"key:"` parses with nil/null value
- [x] Value resolves via core schema — `"key: true"` becomes T
- [x] Key resolves via core schema — numeric key `"42: value"` becomes integer key
- [x] Hook up to yaml:parse — `(yaml:parse "key: value")` works

## DONE
