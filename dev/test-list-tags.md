# Test List: Tags (yaml-parther-juw)

Explicit, local, and unknown tag resolution.

## Test List

- [x] `expand-tag-shorthand` — `!!str` expands to `tag:yaml.org,2002:str`
- [x] `expand-tag-shorthand` — `!!int` expands to `tag:yaml.org,2002:int`
- [x] `expand-tag-shorthand` — `!!bool` expands to `tag:yaml.org,2002:bool`
- [x] `expand-tag-shorthand` — `!!null` expands to `tag:yaml.org,2002:null`
- [x] `expand-verbatim-tag` — `!<tag:yaml.org,2002:str>` returns verbatim tag
- [x] `expand-local-tag` — `!foo` expands to local tag `!foo`
- [x] `read-tag` — reads tag from source and returns expanded form
- [x] Custom %TAG handle support

## Tag Formats

- `!!type` — Secondary handle, expands with default %TAG !! prefix
- `!handle!suffix` — Named handle, expands with registered prefix
- `!local` — Local tag (no prefix expansion)
- `!<verbatim>` — Verbatim tag (no expansion)

## Default Tag Handle

The secondary handle `!!` has a default expansion to `tag:yaml.org,2002:`
unless overridden by a %TAG directive.
