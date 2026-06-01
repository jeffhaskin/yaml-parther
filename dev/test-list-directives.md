# Test List: Directives (yaml-parther-24s)

%YAML version and %TAG handle declarations.

## Test List

- [x] `parse-yaml-directive` — `%YAML 1.2` returns version (1 . 2)
- [x] `parse-yaml-directive-version-1.1` — `%YAML 1.1` returns (1 . 1)  
- [x] `parse-yaml-directive-errors-on-invalid` — `%YAML foo` signals error
- [x] `parse-tag-directive` — `%TAG !yaml! tag:yaml.org,2002:` registers handle
- [x] `parse-tag-directive-secondary` — `%TAG !! tag:yaml.org,2002:` for secondary
- [ ] `parse-tag-directive-named` — `%TAG !e! tag:example.com:` for named
- [ ] `source-skip-directives` — skips all directives until content/---
- [ ] `parse` with `%YAML 1.2` directive before content works
- [ ] `parse` with `%TAG` directive registers for document
- [ ] Error on duplicate `%YAML` directive
- [ ] Error on malformed directive line

## YAML Directive Format

```
%YAML 1.2
%TAG !yaml! tag:yaml.org,2002:
%TAG !! tag:yaml.org,2002:
%TAG !e! tag:example.com:
---
content
```

Directives appear before `---` and apply to the following document.
