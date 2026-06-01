;;;; conformance-data.lisp --- Auto-generated conformance test data.
;;;; DO NOT EDIT. Regenerate with: python3 generate-conformance-data.py

(in-package #:yaml-parther/test)

(defparameter *conformance-tests*
  '(
    (:id "229Q"
     :name "Spec Example 2.4. Sequence of Mappings"
     :yaml "-
  name: Mark McGwire
  hr:   65
  avg:  0.278
-
  name: Sammy Sosa
  hr:   63
  avg:  0.288
"
     :json "\"[\\n  {\\n    \\\"name\\\": \\\"Mark McGwire\\\",\\n    \\\"hr\\\": 65,\\n    \\\"avg\\\": 0.278\\n  },\\n  {\\n    \\\"name\\\": \\\"Sammy Sosa\\\",\\n    \\\"hr\\\": 63,\\n    \\\"avg\\\": 0.288\\n  }\\n]\\n\""
     :fail nil
     :tags "sequence mapping spec")
    (:id "236B"
     :name "Invalid value after mapping"
     :yaml "foo:
  bar
invalid
"
     :json nil
     :fail t
     :tags "error mapping")
    (:id "26DV"
     :name "Whitespace around colon in mappings"
     :yaml "\"top1\" : 
  \"key1\" : &alias1 scalar1
'top2' : 
  'key2' : &alias2 scalar2
top3: &node3 
  *alias1 : scalar3
top4: 
  *alias2 : scalar4
top5   :    
  scalar5
top6: 
  &anchor6 'key6' : scalar6
"
     :json "\"{\\n  \\\"top1\\\": {\\n    \\\"key1\\\": \\\"scalar1\\\"\\n  },\\n  \\\"top2\\\": {\\n    \\\"key2\\\": \\\"scalar2\\\"\\n  },\\n  \\\"top3\\\": {\\n    \\\"scalar1\\\": \\\"scalar3\\\"\\n  },\\n  \\\"top4\\\": {\\n    \\\"scalar2\\\": \\\"scalar4\\\"\\n  },\\n  \\\"top5\\\": \\\"scalar5\\\",\\n  \\\"top6\\\": {\\n    \\\"key6\\\": \\\"scalar6\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "alias mapping whitespace")
    (:id "27NA"
     :name "Spec Example 5.9. Directive Indicator"
     :yaml "%YAML 1.2
--- text
"
     :json "\"\\\"text\\\"\\n\""
     :fail nil
     :tags "spec directive 1.3-err")
    (:id "2AUY"
     :name "Tags in Block Sequence"
     :yaml " - !!str a
 - b
 - !!int 42
 - d
"
     :json "\"[\\n  \\\"a\\\",\\n  \\\"b\\\",\\n  42,\\n  \\\"d\\\"\\n]\\n\""
     :fail nil
     :tags "tag sequence")
    (:id "2CMS"
     :name "Invalid mapping in plain multiline"
     :yaml "this
 is
  invalid: x
"
     :json nil
     :fail t
     :tags "error mapping")
    (:id "2EBW"
     :name "Allowed characters in keys"
     :yaml "a!\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~: safe
?foo: safe question mark
:foo: safe colon
-foo: safe dash
this is#not: a comment
"
     :json "\"{\\n  \\\"a!\\\\\\\"#$%&'()*+,-./09:;<=>?@AZ[\\\\\\\\]^_`az{|}~\\\": \\\"safe\\\",\\n  \\\"?foo\\\": \\\"safe question mark\\\",\\n  \\\":foo\\\": \\\"safe colon\\\",\\n  \\\"-foo\\\": \\\"safe dash\\\",\\n  \\\"this is#not\\\": \\\"a comment\\\"\\n}\\n\""
     :fail nil
     :tags "mapping scalar")
    (:id "2G84/00"
     :name "Literal modifers"
     :yaml "--- |0
"
     :json nil
     :fail t
     :tags "literal scalar")
    (:id "2G84/01"
     :name "2G84/01"
     :yaml "--- |10
"
     :json nil
     :fail t
     :tags "")
    (:id "2G84/02"
     :name "2G84/02"
     :yaml "--- |1-"
     :json "\"\\\"\\\"\\n\""
     :fail nil
     :tags "")
    (:id "2G84/03"
     :name "2G84/03"
     :yaml "--- |1+"
     :json nil
     :fail nil
     :tags "")
    (:id "2JQS"
     :name "Block Mapping with Missing Keys"
     :yaml ": a
: b
"
     :json nil
     :fail nil
     :tags "duplicate-key mapping empty-key")
    (:id "2LFX"
     :name "Spec Example 6.13. Reserved Directives [1.3]"
     :yaml "%FOO  bar baz # Should be ignored
              # with a warning.
---
\"foo\"
"
     :json "\"\\\"foo\\\"\\n\""
     :fail nil
     :tags "spec directive header double 1.3-mod")
    (:id "2SXE"
     :name "Anchors With Colon in Name"
     :yaml "&a: key: &a value
foo:
  *a:
"
     :json "\"{\\n  \\\"key\\\": \\\"value\\\",\\n  \\\"foo\\\": \\\"key\\\"\\n}\\n\""
     :fail nil
     :tags "alias edge mapping 1.3-err")
    (:id "2XXW"
     :name "Spec Example 2.25. Unordered Sets"
     :yaml "# Sets are represented as a
# Mapping where each key is
# associated with a null value
--- !!set
? Mark McGwire
? Sammy Sosa
? Ken Griff
"
     :json "\"{\\n  \\\"Mark McGwire\\\": null,\\n  \\\"Sammy Sosa\\\": null,\\n  \\\"Ken Griff\\\": null\\n}\\n\""
     :fail nil
     :tags "spec mapping unknown-tag explicit-key")
    (:id "33X3"
     :name "Three explicit integers in a block sequence"
     :yaml "---
- !!int 1
- !!int -2
- !!int 33
"
     :json "\"[\\n  1,\\n  -2,\\n  33\\n]\\n\""
     :fail nil
     :tags "sequence tag")
    (:id "35KP"
     :name "Tags for Root Objects"
     :yaml "--- !!map
? a
: b
--- !!seq
- !!str c
--- !!str
d
e
"
     :json "\"{\\n  \\\"a\\\": \\\"b\\\"\\n}\\n[\\n  \\\"c\\\"\\n]\\n\\\"d e\\\"\\n\""
     :fail nil
     :tags "explicit-key header mapping tag")
    (:id "36F6"
     :name "Multiline plain scalar with empty line"
     :yaml "---
plain: a
 b

 c
"
     :json "\"{\\n  \\\"plain\\\": \\\"a b\\\\nc\\\"\\n}\\n\""
     :fail nil
     :tags "mapping scalar")
    (:id "3ALJ"
     :name "Block Sequence in Block Sequence"
     :yaml "- - s1_i1
  - s1_i2
- s2
"
     :json "\"[\\n  [\\n    \\\"s1_i1\\\",\\n    \\\"s1_i2\\\"\\n  ],\\n  \\\"s2\\\"\\n]\\n\""
     :fail nil
     :tags "sequence")
    (:id "3GZX"
     :name "Spec Example 7.1. Alias Nodes"
     :yaml "First occurrence: &anchor Foo
Second occurrence: *anchor
Override anchor: &anchor Bar
Reuse anchor: *anchor
"
     :json "\"{\\n  \\\"First occurrence\\\": \\\"Foo\\\",\\n  \\\"Second occurrence\\\": \\\"Foo\\\",\\n  \\\"Override anchor\\\": \\\"Bar\\\",\\n  \\\"Reuse anchor\\\": \\\"Bar\\\"\\n}\\n\""
     :fail nil
     :tags "mapping spec alias")
    (:id "3HFZ"
     :name "Invalid content after document end marker"
     :yaml "---
key: value
... invalid
"
     :json nil
     :fail t
     :tags "error footer")
    (:id "3MYT"
     :name "Plain Scalar looking like key, comment, anchor and tag"
     :yaml "---
k:#foo
 &a !t s
"
     :json "\"\\\"k:#foo &a !t s\\\"\\n\""
     :fail nil
     :tags "scalar")
    (:id "3R3P"
     :name "Single block sequence with anchor"
     :yaml "&sequence
- a
"
     :json "\"[\\n  \\\"a\\\"\\n]\\n\""
     :fail nil
     :tags "anchor sequence")
    (:id "3RLN/00"
     :name "Leading tabs in double quoted"
     :yaml "\"1 leading
    \\ttab\"
"
     :json "\"\\\"1 leading \\\\ttab\\\"\\n\""
     :fail nil
     :tags "double whitespace")
    (:id "3RLN/01"
     :name "3RLN/01"
     :yaml "\"2 leading
    \\	tab\"
"
     :json "\"\\\"2 leading \\\\ttab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "3RLN/02"
     :name "3RLN/02"
     :yaml "\"3 leading
    	tab\"
"
     :json "\"\\\"3 leading tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "3RLN/03"
     :name "3RLN/03"
     :yaml "\"4 leading
    \\t  tab\"
"
     :json "\"\\\"4 leading \\\\t  tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "3RLN/04"
     :name "3RLN/04"
     :yaml "\"5 leading
    \\	  tab\"
"
     :json "\"\\\"5 leading \\\\t  tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "3RLN/05"
     :name "3RLN/05"
     :yaml "\"6 leading
    	  tab\"
"
     :json "\"\\\"6 leading tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "3UYS"
     :name "Escaped slash in double quotes"
     :yaml "escaped slash: \"a\\/b\"
"
     :json "\"{\\n  \\\"escaped slash\\\": \\\"a/b\\\"\\n}\\n\""
     :fail nil
     :tags "double")
    (:id "4ABK"
     :name "Flow Mapping Separate Values"
     :yaml "{
unquoted : \"separate\",
http://foo.com,
omitted value:,
}
"
     :json nil
     :fail nil
     :tags "flow mapping")
    (:id "4CQQ"
     :name "Spec Example 2.18. Multi-line Flow Scalars"
     :yaml "plain:
  This unquoted scalar
  spans many lines.

quoted: \"So does this
  quoted scalar.\\n\"
"
     :json "\"{\\n  \\\"plain\\\": \\\"This unquoted scalar spans many lines.\\\",\\n  \\\"quoted\\\": \\\"So does this quoted scalar.\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec scalar")
    (:id "4EJS"
     :name "Invalid tabs as indendation in a mapping"
     :yaml "---
a:
	b:
		c: value
"
     :json nil
     :fail t
     :tags "error mapping whitespace")
    (:id "4FJ6"
     :name "Nested implicit complex keys"
     :yaml "---
[
  [ a, [ [[b,c]]: d, e]]: 23
]
"
     :json nil
     :fail nil
     :tags "complex-key flow mapping sequence")
    (:id "4GC6"
     :name "Spec Example 7.7. Single Quoted Characters"
     :yaml "'here''s to \"quotes\"'
"
     :json "\"\\\"here's to \\\\\\\"quotes\\\\\\\"\\\"\\n\""
     :fail nil
     :tags "spec scalar 1.3-err")
    (:id "4H7K"
     :name "Flow sequence with invalid extra closing bracket"
     :yaml "---
[ a, b, c ] ]
"
     :json nil
     :fail t
     :tags "error flow sequence")
    (:id "4HVU"
     :name "Wrong indendation in Sequence"
     :yaml "key:
   - ok
   - also ok
  - wrong
"
     :json nil
     :fail t
     :tags "error sequence indent")
    (:id "4JVG"
     :name "Scalar value with two anchors"
     :yaml "top1: &node1
  &k1 key1: val1
top2: &node2
  &v2 val2
"
     :json nil
     :fail t
     :tags "anchor error mapping")
    (:id "4MUZ/00"
     :name "Flow mapping colon on line after key"
     :yaml "{\"foo\"
: \"bar\"}
"
     :json "\"{\\n  \\\"foo\\\": \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "flow mapping")
    (:id "4MUZ/01"
     :name "4MUZ/01"
     :yaml "{\"foo\"
: bar}
"
     :json nil
     :fail nil
     :tags "")
    (:id "4MUZ/02"
     :name "4MUZ/02"
     :yaml "{foo
: bar}
"
     :json "\"{\\n  \\\"foo\\\": \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "")
    (:id "4Q9F"
     :name "Folded Block Scalar [1.3]"
     :yaml "--- >
 ab
 cd
 
 ef


 gh
"
     :json "\"\\\"ab cd\\\\nef\\\\n\\\\ngh\\\\n\\\"\\n\""
     :fail nil
     :tags "folded scalar 1.3-mod whitespace")
    (:id "4QFQ"
     :name "Spec Example 8.2. Block Indentation Indicator [1.3]"
     :yaml "- |
 detected
- >
 
  
  # detected
- |1
  explicit
- >
 detected
"
     :json "\"[\\n  \\\"detected\\\\n\\\",\\n  \\\"\\\\n\\\\n# detected\\\\n\\\",\\n  \\\" explicit\\\\n\\\",\\n  \\\"detected\\\\n\\\"\\n]\\n\""
     :fail nil
     :tags "spec literal folded scalar libyaml-err 1.3-mod whitespace")
    (:id "4RWC"
     :name "Trailing spaces after flow collection"
     :yaml "  [1, 2, 3]  
  "
     :json "\"[\\n  1,\\n  2,\\n  3\\n]\\n\""
     :fail nil
     :tags "flow whitespace")
    (:id "4UYU"
     :name "Colon in Double Quoted String"
     :yaml "\"foo: bar\\\": baz\"
"
     :json "\"\\\"foo: bar\\\\\\\": baz\\\"\\n\""
     :fail nil
     :tags "mapping scalar 1.3-err")
    (:id "4V8U"
     :name "Plain scalar with backslashes"
     :yaml "---
plain\\value\\with\\backslashes
"
     :json "\"\\\"plain\\\\\\\\value\\\\\\\\with\\\\\\\\backslashes\\\"\\n\""
     :fail nil
     :tags "scalar")
    (:id "4WA9"
     :name "Literal scalars"
     :yaml "- aaa: |2
    xxx
  bbb: |
    xxx
"
     :json "\"[\\n  {\\n    \\\"aaa\\\" : \\\"xxx\\\\n\\\",\\n    \\\"bbb\\\" : \\\"xxx\\\\n\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "indent literal")
    (:id "4ZYM"
     :name "Spec Example 6.4. Line Prefixes"
     :yaml "plain: text
  lines
quoted: \"text
  	lines\"
block: |
  text
   	lines
"
     :json "\"{\\n  \\\"plain\\\": \\\"text lines\\\",\\n  \\\"quoted\\\": \\\"text lines\\\",\\n  \\\"block\\\": \\\"text\\\\n \\\\tlines\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec scalar literal double upto-1.2 whitespace")
    (:id "52DL"
     :name "Explicit Non-Specific Tag [1.3]"
     :yaml "---
! a
"
     :json "\"\\\"a\\\"\\n\""
     :fail nil
     :tags "tag 1.3-mod")
    (:id "54T7"
     :name "Flow Mapping"
     :yaml "{foo: you, bar: far}
"
     :json "\"{\\n  \\\"foo\\\": \\\"you\\\",\\n  \\\"bar\\\": \\\"far\\\"\\n}\\n\""
     :fail nil
     :tags "flow mapping")
    (:id "55WF"
     :name "Invalid escape in double quoted string"
     :yaml "---
\"\\.\"
"
     :json nil
     :fail t
     :tags "error double")
    (:id "565N"
     :name "Construct Binary"
     :yaml "canonical: !!binary \"\\
 R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\\
 OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\\
 +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\\
 AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=\"
generic: !!binary |
 R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5
 OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+
 +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC
 AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=
description:
 The binary value above is a tiny arrow encoded as a gif image.
"
     :json "\"{\\n  \\\"canonical\\\": \\\"R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLCAgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=\\\",\\n  \\\"generic\\\": \\\"R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\\\\nOTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\\\\n+f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\\\\nAgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=\\\\n\\\",\\n  \\\"description\\\": \\\"The binary value above is a tiny arrow encoded as a gif image.\\\"\\n}\\n\""
     :fail nil
     :tags "tag unknown-tag")
    (:id "57H4"
     :name "Spec Example 8.22. Block Collection Nodes"
     :yaml "sequence: !!seq
- entry
- !!seq
 - nested
mapping: !!map
 foo: bar
"
     :json "\"{\\n  \\\"sequence\\\": [\\n    \\\"entry\\\",\\n    [\\n      \\\"nested\\\"\\n    ]\\n  ],\\n  \\\"mapping\\\": {\\n    \\\"foo\\\": \\\"bar\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "sequence mapping tag")
    (:id "58MP"
     :name "Flow mapping edge cases"
     :yaml "{x: :x}
"
     :json "\"{\\n  \\\"x\\\": \\\":x\\\"\\n}\\n\""
     :fail nil
     :tags "edge flow mapping")
    (:id "5BVJ"
     :name "Spec Example 5.7. Block Scalar Indicators"
     :yaml "literal: |
  some
  text
folded: >
  some
  text
"
     :json "\"{\\n  \\\"literal\\\": \\\"some\\\\ntext\\\\n\\\",\\n  \\\"folded\\\": \\\"some text\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec literal folded scalar")
    (:id "5C5M"
     :name "Spec Example 7.15. Flow Mappings"
     :yaml "- { one : two , three: four , }
- {five: six,seven : eight}
"
     :json "\"[\\n  {\\n    \\\"one\\\": \\\"two\\\",\\n    \\\"three\\\": \\\"four\\\"\\n  },\\n  {\\n    \\\"five\\\": \\\"six\\\",\\n    \\\"seven\\\": \\\"eight\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "spec flow mapping")
    (:id "5GBF"
     :name "Spec Example 6.5. Empty Lines"
     :yaml "Folding:
  \"Empty line
   	
  as a line feed\"
Chomping: |
  Clipped empty lines
 

"
     :json "\"{\\n  \\\"Folding\\\": \\\"Empty line\\\\nas a line feed\\\",\\n  \\\"Chomping\\\": \\\"Clipped empty lines\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "double literal spec scalar upto-1.2 whitespace")
    (:id "5KJE"
     :name "Spec Example 7.13. Flow Sequence"
     :yaml "- [ one, two, ]
- [three ,four]
"
     :json "\"[\\n  [\\n    \\\"one\\\",\\n    \\\"two\\\"\\n  ],\\n  [\\n    \\\"three\\\",\\n    \\\"four\\\"\\n  ]\\n]\\n\""
     :fail nil
     :tags "spec flow sequence")
    (:id "5LLU"
     :name "Block scalar with wrong indented line after spaces only"
     :yaml "block scalar: >
 
  
   
 invalid
"
     :json nil
     :fail t
     :tags "error folded whitespace")
    (:id "5MUD"
     :name "Colon and adjacent value on next line"
     :yaml "---
{ \"foo\"
  :bar }
"
     :json "\"{\\n  \\\"foo\\\": \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "double flow mapping")
    (:id "5NYZ"
     :name "Spec Example 6.9. Separated Comment"
     :yaml "key:    # Comment
  value
"
     :json "\"{\\n  \\\"key\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "mapping spec comment")
    (:id "5T43"
     :name "Colon at the beginning of adjacent flow scalar"
     :yaml "- { \"key\":value }
- { \"key\"::value }
"
     :json "\"[\\n  {\\n    \\\"key\\\": \\\"value\\\"\\n  },\\n  {\\n    \\\"key\\\": \\\":value\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "flow mapping scalar")
    (:id "5TRB"
     :name "Invalid document-start marker in doublequoted tring"
     :yaml "---
\"
---
\"
"
     :json nil
     :fail t
     :tags "header double error")
    (:id "5TYM"
     :name "Spec Example 6.21. Local Tag Prefix"
     :yaml "%TAG !m! !my-
--- # Bulb here
!m!light fluorescent
...
%TAG !m! !my-
--- # Color here
!m!light green
"
     :json "\"\\\"fluorescent\\\"\\n\\\"green\\\"\\n\""
     :fail nil
     :tags "local-tag spec directive tag")
    (:id "5U3A"
     :name "Sequence on same Line as Mapping Key"
     :yaml "key: - a
     - b
"
     :json nil
     :fail t
     :tags "error sequence mapping")
    (:id "5WE3"
     :name "Spec Example 8.17. Explicit Block Mapping Entries"
     :yaml "? explicit key # Empty value
? |
  block key
: - one # Explicit compact
  - two # block value
"
     :json "\"{\\n  \\\"explicit key\\\": null,\\n  \\\"block key\\\\n\\\": [\\n    \\\"one\\\",\\n    \\\"two\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "explicit-key spec mapping comment literal sequence")
    (:id "62EZ"
     :name "Invalid block mapping key on same line as previous key"
     :yaml "---
x: { y: z }in: valid
"
     :json nil
     :fail t
     :tags "error flow mapping")
    (:id "652Z"
     :name "Question mark at start of flow key"
     :yaml "{ ?foo: bar,
bar: 42
}
"
     :json "\"{\\n  \\\"?foo\\\" : \\\"bar\\\",\\n  \\\"bar\\\" : 42\\n}\\n\""
     :fail nil
     :tags "flow")
    (:id "65WH"
     :name "Single Entry Block Sequence"
     :yaml "- foo
"
     :json "\"[\\n  \\\"foo\\\"\\n]\\n\""
     :fail nil
     :tags "sequence")
    (:id "6BCT"
     :name "Spec Example 6.3. Separation Spaces"
     :yaml "- foo:	 bar
- - baz
  -	baz
"
     :json "\"[\\n  {\\n    \\\"foo\\\": \\\"bar\\\"\\n  },\\n  [\\n    \\\"baz\\\",\\n    \\\"baz\\\"\\n  ]\\n]\\n\""
     :fail nil
     :tags "spec libyaml-err sequence whitespace upto-1.2")
    (:id "6BFJ"
     :name "Mapping, key and flow sequence item anchors"
     :yaml "---
&mapping
&key [ &item a, b, c ]: value
"
     :json nil
     :fail nil
     :tags "anchor complex-key flow mapping sequence")
    (:id "6CA3"
     :name "Tab indented top flow"
     :yaml "	[
	]
"
     :json "\"[]\\n\""
     :fail nil
     :tags "indent whitespace")
    (:id "6CK3"
     :name "Spec Example 6.26. Tag Shorthands"
     :yaml "%TAG !e! tag:example.com,2000:app/
---
- !local foo
- !!str bar
- !e!tag%21 baz
"
     :json "\"[\\n  \\\"foo\\\",\\n  \\\"bar\\\",\\n  \\\"baz\\\"\\n]\\n\""
     :fail nil
     :tags "spec tag local-tag")
    (:id "6FWR"
     :name "Block Scalar Keep"
     :yaml "--- |+
 ab
 
  
...
"
     :json "\"\\\"ab\\\\n\\\\n \\\\n\\\"\\n\""
     :fail nil
     :tags "literal scalar whitespace")
    (:id "6H3V"
     :name "Backslashes in singlequotes"
     :yaml "'foo: bar\\': baz'
"
     :json "\"{\\n  \\\"foo: bar\\\\\\\\\\\": \\\"baz'\\\"\\n}\\n\""
     :fail nil
     :tags "scalar single")
    (:id "6HB6"
     :name "Spec Example 6.1. Indentation Spaces"
     :yaml "  # Leading comment line spaces are
   # neither content nor indentation.
    
Not indented:
 By one space: |
    By four
      spaces
 Flow style: [    # Leading spaces
   By two,        # in flow style
  Also by two,    # are neither
  	Still by two   # content nor
    ]             # indentation.
"
     :json "\"{\\n  \\\"Not indented\\\": {\\n    \\\"By one space\\\": \\\"By four\\\\n  spaces\\\\n\\\",\\n    \\\"Flow style\\\": [\\n      \\\"By two\\\",\\n      \\\"Also by two\\\",\\n      \\\"Still by two\\\"\\n    ]\\n  }\\n}\\n\""
     :fail nil
     :tags "comment flow spec indent upto-1.2 whitespace")
    (:id "6JQW"
     :name "Spec Example 2.13. In literals, newlines are preserved"
     :yaml "# ASCII Art
--- |
  \\//||\\/||
  // ||  ||__
"
     :json "\"\\\"\\\\\\\\//||\\\\\\\\/||\\\\n// ||  ||__\\\\n\\\"\\n\""
     :fail nil
     :tags "spec scalar literal comment")
    (:id "6JTT"
     :name "Flow sequence without closing bracket"
     :yaml "---
[ [ a, b, c ]
"
     :json nil
     :fail t
     :tags "error flow sequence")
    (:id "6JWB"
     :name "Tags for Block Objects"
     :yaml "foo: !!seq
  - !!str a
  - !!map
    key: !!str value
"
     :json "\"{\\n  \\\"foo\\\": [\\n    \\\"a\\\",\\n    {\\n      \\\"key\\\": \\\"value\\\"\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "mapping sequence tag")
    (:id "6KGN"
     :name "Anchor for empty node"
     :yaml "---
a: &anchor
b: *anchor
"
     :json "\"{\\n  \\\"a\\\": null,\\n  \\\"b\\\": null\\n}\\n\""
     :fail nil
     :tags "alias anchor")
    (:id "6LVF"
     :name "Spec Example 6.13. Reserved Directives"
     :yaml "%FOO  bar baz # Should be ignored
              # with a warning.
--- \"foo\"
"
     :json "\"\\\"foo\\\"\\n\""
     :fail nil
     :tags "spec directive header double 1.3-err")
    (:id "6M2F"
     :name "Aliases in Explicit Block Mapping"
     :yaml "? &a a
: &b b
: *a
"
     :json nil
     :fail nil
     :tags "alias explicit-key empty-key")
    (:id "6PBE"
     :name "Zero-indented sequences in explicit mapping keys"
     :yaml "---
?
- a
- b
:
- c
- d
"
     :json nil
     :fail nil
     :tags "explicit-key mapping sequence")
    (:id "6S55"
     :name "Invalid scalar at the end of sequence"
     :yaml "key:
 - bar
 - baz
 invalid
"
     :json nil
     :fail t
     :tags "error mapping sequence")
    (:id "6SLA"
     :name "Allowed characters in quoted mapping key"
     :yaml "\"foo\\nbar:baz\\tx \\\\$%^&*()x\": 23
'x\\ny:z\\tx $%^&*()x': 24
"
     :json "\"{\\n  \\\"foo\\\\nbar:baz\\\\tx \\\\\\\\$%^&*()x\\\": 23,\\n  \\\"x\\\\\\\\ny:z\\\\\\\\tx $%^&*()x\\\": 24\\n}\\n\""
     :fail nil
     :tags "mapping single double")
    (:id "6VJK"
     :name "Spec Example 2.15. Folded newlines are preserved for \"more indented\" and blank lines"
     :yaml ">
 Sammy Sosa completed another
 fine season with great stats.

   63 Home Runs
   0.288 Batting Average

 What a year!
"
     :json "\"\\\"Sammy Sosa completed another fine season with great stats.\\\\n\\\\n  63 Home Runs\\\\n  0.288 Batting Average\\\\n\\\\nWhat a year!\\\\n\\\"\\n\""
     :fail nil
     :tags "spec folded scalar 1.3-err")
    (:id "6WLZ"
     :name "Spec Example 6.18. Primary Tag Handle [1.3]"
     :yaml "# Private
---
!foo \"bar\"
...
# Global
%TAG ! tag:example.com,2000:app/
---
!foo \"bar\"
"
     :json "\"\\\"bar\\\"\\n\\\"bar\\\"\\n\""
     :fail nil
     :tags "local-tag spec directive tag 1.3-mod")
    (:id "6WPF"
     :name "Spec Example 6.8. Flow Folding [1.3]"
     :yaml "---
\"
  foo 
 
    bar

  baz
\"
"
     :json "\"\\\" foo\\\\nbar\\\\nbaz \\\"\\n\""
     :fail nil
     :tags "double spec whitespace scalar 1.3-mod")
    (:id "6XDY"
     :name "Two document start markers"
     :yaml "---
---
"
     :json "\"null\\nnull\\n\""
     :fail nil
     :tags "header")
    (:id "6ZKB"
     :name "Spec Example 9.6. Stream"
     :yaml "Document
---
# Empty
...
%YAML 1.2
---
matches %: 20
"
     :json "\"\\\"Document\\\"\\nnull\\n{\\n  \\\"matches %\\\": 20\\n}\\n\""
     :fail nil
     :tags "spec header 1.3-err")
    (:id "735Y"
     :name "Spec Example 8.20. Block Node Types"
     :yaml "-
  \"flow in block\"
- >
 Block scalar
- !!map # Block collection
  foo : bar
"
     :json "\"[\\n  \\\"flow in block\\\",\\n  \\\"Block scalar\\\\n\\\",\\n  {\\n    \\\"foo\\\": \\\"bar\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "comment double spec folded tag")
    (:id "74H7"
     :name "Tags in Implicit Mapping"
     :yaml "!!str a: b
c: !!int 42
e: !!str f
g: h
!!str 23: !!bool false
"
     :json "\"{\\n  \\\"a\\\": \\\"b\\\",\\n  \\\"c\\\": 42,\\n  \\\"e\\\": \\\"f\\\",\\n  \\\"g\\\": \\\"h\\\",\\n  \\\"23\\\": false\\n}\\n\""
     :fail nil
     :tags "tag mapping")
    (:id "753E"
     :name "Block Scalar Strip [1.3]"
     :yaml "--- |-
 ab
 
 
...
"
     :json "\"\\\"ab\\\"\\n\""
     :fail nil
     :tags "literal scalar 1.3-mod whitespace")
    (:id "7A4E"
     :name "Spec Example 7.6. Double Quoted Lines"
     :yaml "\" 1st non-empty

 2nd non-empty 
	3rd non-empty \"
"
     :json "\"\\\" 1st non-empty\\\\n2nd non-empty 3rd non-empty \\\"\\n\""
     :fail nil
     :tags "spec scalar upto-1.2 whitespace")
    (:id "7BMT"
     :name "Node and Mapping Key Anchors [1.3]"
     :yaml "---
top1: &node1
  &k1 key1: one
top2: &node2 # comment
  key2: two
top3:
  &k3 key3: three
top4: &node4
  &k4 key4: four
top5: &node5
  key5: five
top6: &val6
  six
top7:
  &val7 seven
"
     :json "\"{\\n  \\\"top1\\\": {\\n    \\\"key1\\\": \\\"one\\\"\\n  },\\n  \\\"top2\\\": {\\n    \\\"key2\\\": \\\"two\\\"\\n  },\\n  \\\"top3\\\": {\\n    \\\"key3\\\": \\\"three\\\"\\n  },\\n  \\\"top4\\\": {\\n    \\\"key4\\\": \\\"four\\\"\\n  },\\n  \\\"top5\\\": {\\n    \\\"key5\\\": \\\"five\\\"\\n  },\\n  \\\"top6\\\": \\\"six\\\",\\n  \\\"top7\\\": \\\"seven\\\"\\n}\\n\""
     :fail nil
     :tags "anchor comment mapping 1.3-mod")
    (:id "7BUB"
     :name "Spec Example 2.10. Node for “Sammy Sosa” appears twice in this document"
     :yaml "---
hr:
  - Mark McGwire
  # Following node labeled SS
  - &SS Sammy Sosa
rbi:
  - *SS # Subsequent occurrence
  - Ken Griffey
"
     :json "\"{\\n  \\\"hr\\\": [\\n    \\\"Mark McGwire\\\",\\n    \\\"Sammy Sosa\\\"\\n  ],\\n  \\\"rbi\\\": [\\n    \\\"Sammy Sosa\\\",\\n    \\\"Ken Griffey\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "mapping sequence spec alias")
    (:id "7FWL"
     :name "Spec Example 6.24. Verbatim Tags"
     :yaml "!<tag:yaml.org,2002:str> foo :
  !<!bar> baz
"
     :json "\"{\\n  \\\"foo\\\": \\\"baz\\\"\\n}\\n\""
     :fail nil
     :tags "mapping spec tag unknown-tag")
    (:id "7LBH"
     :name "Multiline double quoted implicit keys"
     :yaml "\"a\\nb\": 1
\"c
 d\": 1
"
     :json nil
     :fail t
     :tags "error double")
    (:id "7MNF"
     :name "Missing colon"
     :yaml "top1:
  key1: val1
top2
"
     :json nil
     :fail t
     :tags "error mapping")
    (:id "7T8X"
     :name "Spec Example 8.10. Folded Lines - 8.13. Final Empty Lines"
     :yaml ">

 folded
 line

 next
 line
   * bullet

   * list
   * lines

 last
 line

# Comment
"
     :json "\"\\\"\\\\nfolded line\\\\nnext line\\\\n  * bullet\\\\n\\\\n  * list\\\\n  * lines\\\\n\\\\nlast line\\\\n\\\"\\n\""
     :fail nil
     :tags "spec folded scalar comment 1.3-err")
    (:id "7TMG"
     :name "Comment in flow sequence before comma"
     :yaml "---
[ word1
# comment
, word2]
"
     :json "\"[\\n  \\\"word1\\\",\\n  \\\"word2\\\"\\n]\\n\""
     :fail nil
     :tags "comment flow sequence")
    (:id "7W2P"
     :name "Block Mapping with Missing Values"
     :yaml "? a
? b
c:
"
     :json "\"{\\n  \\\"a\\\": null,\\n  \\\"b\\\": null,\\n  \\\"c\\\": null\\n}\\n\""
     :fail nil
     :tags "explicit-key mapping")
    (:id "7Z25"
     :name "Bare document after document end marker"
     :yaml "---
scalar1
...
key: value
"
     :json "\"\\\"scalar1\\\"\\n{\\n  \\\"key\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "footer")
    (:id "7ZZ5"
     :name "Empty flow collections"
     :yaml "---
nested sequences:
- - - []
- - - {}
key1: []
key2: {}
"
     :json "\"{\\n  \\\"nested sequences\\\": [\\n    [\\n      [\\n        []\\n      ]\\n    ],\\n    [\\n      [\\n        {}\\n      ]\\n    ]\\n  ],\\n  \\\"key1\\\": [],\\n  \\\"key2\\\": {}\\n}\\n\""
     :fail nil
     :tags "flow mapping sequence")
    (:id "82AN"
     :name "Three dashes and content without space"
     :yaml "---word1
word2
"
     :json "\"\\\"---word1 word2\\\"\\n\""
     :fail nil
     :tags "scalar 1.3-err")
    (:id "87E4"
     :name "Spec Example 7.8. Single Quoted Implicit Keys"
     :yaml "'implicit block key' : [
  'implicit flow key' : value,
 ]
"
     :json "\"{\\n  \\\"implicit block key\\\": [\\n    {\\n      \\\"implicit flow key\\\": \\\"value\\\"\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "spec flow sequence mapping")
    (:id "8CWC"
     :name "Plain mapping key ending with colon"
     :yaml "---
key ends with two colons::: value
"
     :json "\"{\\n  \\\"key ends with two colons::\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "mapping scalar")
    (:id "8G76"
     :name "Spec Example 6.10. Comment Lines"
     :yaml "  # Comment
   


"
     :json "\"\""
     :fail nil
     :tags "spec comment empty scalar whitespace")
    (:id "8KB6"
     :name "Multiline plain flow mapping key without value"
     :yaml "---
- { single line, a: b}
- { multi
  line, a: b}
"
     :json "\"[\\n  {\\n    \\\"single line\\\": null,\\n    \\\"a\\\": \\\"b\\\"\\n  },\\n  {\\n    \\\"multi line\\\": null,\\n    \\\"a\\\": \\\"b\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "flow mapping")
    (:id "8MK2"
     :name "Explicit Non-Specific Tag"
     :yaml "! a
"
     :json "\"\\\"a\\\"\\n\""
     :fail nil
     :tags "tag 1.3-err")
    (:id "8QBE"
     :name "Block Sequence in Block Mapping"
     :yaml "key:
 - item1
 - item2
"
     :json "\"{\\n  \\\"key\\\": [\\n    \\\"item1\\\",\\n    \\\"item2\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "mapping sequence")
    (:id "8UDB"
     :name "Spec Example 7.14. Flow Sequence Entries"
     :yaml "[
\"double
 quoted\", 'single
           quoted',
plain
 text, [ nested ],
single: pair,
]
"
     :json "\"[\\n  \\\"double quoted\\\",\\n  \\\"single quoted\\\",\\n  \\\"plain text\\\",\\n  [\\n    \\\"nested\\\"\\n  ],\\n  {\\n    \\\"single\\\": \\\"pair\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "spec flow sequence")
    (:id "8XDJ"
     :name "Comment in plain multiline value"
     :yaml "key: word1
#  xxx
  word2
"
     :json nil
     :fail t
     :tags "error comment scalar")
    (:id "8XYN"
     :name "Anchor with unicode character"
     :yaml "---
- &😁 unicode anchor
"
     :json "\"[\\n  \\\"unicode anchor\\\"\\n]\\n\""
     :fail nil
     :tags "anchor")
    (:id "93JH"
     :name "Block Mappings in Block Sequence"
     :yaml " - key: value
   key2: value2
 -
   key3: value3
"
     :json "\"[\\n  {\\n    \\\"key\\\": \\\"value\\\",\\n    \\\"key2\\\": \\\"value2\\\"\\n  },\\n  {\\n    \\\"key3\\\": \\\"value3\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "mapping sequence")
    (:id "93WF"
     :name "Spec Example 6.6. Line Folding [1.3]"
     :yaml "--- >-
  trimmed
  
 

  as
  space
"
     :json "\"\\\"trimmed\\\\n\\\\n\\\\nas space\\\"\\n\""
     :fail nil
     :tags "folded spec whitespace scalar 1.3-mod")
    (:id "96L6"
     :name "Spec Example 2.14. In the folded scalars, newlines become spaces"
     :yaml "--- >
  Mark McGwire's
  year was crippled
  by a knee injury.
"
     :json "\"\\\"Mark McGwire's year was crippled by a knee injury.\\\\n\\\"\\n\""
     :fail nil
     :tags "spec folded scalar")
    (:id "96NN/00"
     :name "Leading tab content in literals"
     :yaml "foo: |-
 	bar
"
     :json "\"{\\\"foo\\\":\\\"\\\\tbar\\\"}\\n\""
     :fail nil
     :tags "indent literal whitespace")
    (:id "96NN/01"
     :name "96NN/01"
     :yaml "foo: |-
 	bar"
     :json nil
     :fail nil
     :tags "")
    (:id "98YD"
     :name "Spec Example 5.5. Comment Indicator"
     :yaml "# Comment only.
"
     :json "\"\""
     :fail nil
     :tags "spec comment empty")
    (:id "9BXH"
     :name "Multiline doublequoted flow mapping key without value"
     :yaml "---
- { \"single line\", a: b}
- { \"multi
  line\", a: b}
"
     :json "\"[\\n  {\\n    \\\"single line\\\": null,\\n    \\\"a\\\": \\\"b\\\"\\n  },\\n  {\\n    \\\"multi line\\\": null,\\n    \\\"a\\\": \\\"b\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "double flow mapping")
    (:id "9C9N"
     :name "Wrong indented flow sequence"
     :yaml "---
flow: [a,
b,
c]
"
     :json nil
     :fail t
     :tags "error flow indent sequence")
    (:id "9CWY"
     :name "Invalid scalar at the end of mapping"
     :yaml "key:
 - item1
 - item2
invalid
"
     :json nil
     :fail t
     :tags "error mapping sequence")
    (:id "9DXL"
     :name "Spec Example 9.6. Stream [1.3]"
     :yaml "Mapping: Document
---
# Empty
...
%YAML 1.2
---
matches %: 20
"
     :json "\"{\\n  \\\"Mapping\\\": \\\"Document\\\"\\n}\\nnull\\n{\\n  \\\"matches %\\\": 20\\n}\\n\""
     :fail nil
     :tags "spec header 1.3-mod")
    (:id "9FMG"
     :name "Multi-level Mapping Indent"
     :yaml "a:
  b:
    c: d
  e:
    f: g
h: i
"
     :json "\"{\\n  \\\"a\\\": {\\n    \\\"b\\\": {\\n      \\\"c\\\": \\\"d\\\"\\n    },\\n    \\\"e\\\": {\\n      \\\"f\\\": \\\"g\\\"\\n    }\\n  },\\n  \\\"h\\\": \\\"i\\\"\\n}\\n\""
     :fail nil
     :tags "mapping indent")
    (:id "9HCY"
     :name "Need document footer before directives"
     :yaml "!foo \"bar\"
%TAG ! tag:example.com,2000:app/
---
!foo \"bar\"
"
     :json nil
     :fail t
     :tags "directive error footer tag unknown-tag")
    (:id "9J7A"
     :name "Simple Mapping Indent"
     :yaml "foo:
  bar: baz
"
     :json "\"{\\n  \\\"foo\\\": {\\n    \\\"bar\\\": \\\"baz\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "simple mapping indent")
    (:id "9JBA"
     :name "Invalid comment after end of flow sequence"
     :yaml "---
[ a, b, c, ]#invalid
"
     :json nil
     :fail t
     :tags "comment error flow sequence")
    (:id "9KAX"
     :name "Various combinations of tags and anchors"
     :yaml "---
&a1
!!str
scalar1
---
!!str
&a2
scalar2
---
&a3
!!str scalar3
---
&a4 !!map
&a5 !!str key5: value4
---
a6: 1
&anchor6 b6: 2
---
!!map
&a8 !!str key8: value7
---
!!map
!!str &a10 key10: value9
---
!!str &a11
value11
"
     :json "\"\\\"scalar1\\\"\\n\\\"scalar2\\\"\\n\\\"scalar3\\\"\\n{\\n  \\\"key5\\\": \\\"value4\\\"\\n}\\n{\\n  \\\"a6\\\": 1,\\n  \\\"b6\\\": 2\\n}\\n{\\n  \\\"key8\\\": \\\"value7\\\"\\n}\\n{\\n  \\\"key10\\\": \\\"value9\\\"\\n}\\n\\\"value11\\\"\\n\""
     :fail nil
     :tags "anchor mapping 1.3-err tag")
    (:id "9KBC"
     :name "Mapping starting at --- line"
     :yaml "--- key1: value1
    key2: value2
"
     :json nil
     :fail t
     :tags "error header mapping")
    (:id "9MAG"
     :name "Flow sequence with invalid comma at the beginning"
     :yaml "---
[ , a, b, c ]
"
     :json nil
     :fail t
     :tags "error flow sequence")
    (:id "9MMA"
     :name "Directive by itself with no document"
     :yaml "%YAML 1.2
"
     :json nil
     :fail t
     :tags "error directive")
    (:id "9MMW"
     :name "Single Pair Implicit Entries"
     :yaml "- [ YAML : separate ]
- [ \"JSON like\":adjacent ]
- [ {JSON: like}:adjacent ]
"
     :json nil
     :fail nil
     :tags "flow mapping sequence")
    (:id "9MQT/00"
     :name "Scalar doc with '...' in content"
     :yaml "--- \"a
...x
b\"
"
     :json "\"\\\"a ...x b\\\"\\n\""
     :fail nil
     :tags "double scalar")
    (:id "9MQT/01"
     :name "9MQT/01"
     :yaml "--- \"a
... x
b\"
"
     :json nil
     :fail t
     :tags "")
    (:id "9SA2"
     :name "Multiline double quoted flow mapping key"
     :yaml "---
- { \"single line\": value}
- { \"multi
  line\": value}
"
     :json "\"[\\n  {\\n    \\\"single line\\\": \\\"value\\\"\\n  },\\n  {\\n    \\\"multi line\\\": \\\"value\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "double flow mapping")
    (:id "9SHH"
     :name "Spec Example 5.8. Quoted Scalar Indicators"
     :yaml "single: 'text'
double: \"text\"
"
     :json "\"{\\n  \\\"single\\\": \\\"text\\\",\\n  \\\"double\\\": \\\"text\\\"\\n}\\n\""
     :fail nil
     :tags "spec scalar")
    (:id "9TFX"
     :name "Spec Example 7.6. Double Quoted Lines [1.3]"
     :yaml "---
\" 1st non-empty

 2nd non-empty 
 3rd non-empty \"
"
     :json "\"\\\" 1st non-empty\\\\n2nd non-empty 3rd non-empty \\\"\\n\""
     :fail nil
     :tags "double spec scalar whitespace 1.3-mod")
    (:id "9U5K"
     :name "Spec Example 2.12. Compact Nested Mapping"
     :yaml "---
# Products purchased
- item    : Super Hoop
  quantity: 1
- item    : Basketball
  quantity: 4
- item    : Big Shoes
  quantity: 1
"
     :json "\"[\\n  {\\n    \\\"item\\\": \\\"Super Hoop\\\",\\n    \\\"quantity\\\": 1\\n  },\\n  {\\n    \\\"item\\\": \\\"Basketball\\\",\\n    \\\"quantity\\\": 4\\n  },\\n  {\\n    \\\"item\\\": \\\"Big Shoes\\\",\\n    \\\"quantity\\\": 1\\n  }\\n]\\n\""
     :fail nil
     :tags "spec mapping sequence")
    (:id "9WXW"
     :name "Spec Example 6.18. Primary Tag Handle"
     :yaml "# Private
!foo \"bar\"
...
# Global
%TAG ! tag:example.com,2000:app/
---
!foo \"bar\"
"
     :json "\"\\\"bar\\\"\\n\\\"bar\\\"\\n\""
     :fail nil
     :tags "local-tag spec directive tag unknown-tag 1.3-err")
    (:id "9YRD"
     :name "Multiline Scalar at Top Level"
     :yaml "a
b  
  c
d

e
"
     :json "\"\\\"a b c d\\\\ne\\\"\\n\""
     :fail nil
     :tags "scalar whitespace 1.3-err")
    (:id "A2M4"
     :name "Spec Example 6.2. Indentation Indicators"
     :yaml "? a
: -	b
  -  -	c
     - d
"
     :json "\"{\\n  \\\"a\\\": [\\n    \\\"b\\\",\\n    [\\n      \\\"c\\\",\\n      \\\"d\\\"\\n    ]\\n  ]\\n}\\n\""
     :fail nil
     :tags "explicit-key spec libyaml-err indent whitespace sequence upto-1.2")
    (:id "A6F9"
     :name "Spec Example 8.4. Chomping Final Line Break"
     :yaml "strip: |-
  text
clip: |
  text
keep: |+
  text
"
     :json "\"{\\n  \\\"strip\\\": \\\"text\\\",\\n  \\\"clip\\\": \\\"text\\\\n\\\",\\n  \\\"keep\\\": \\\"text\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec literal scalar")
    (:id "A984"
     :name "Multiline Scalar in Mapping"
     :yaml "a: b
 c
d:
 e
  f
"
     :json "\"{\\n  \\\"a\\\": \\\"b c\\\",\\n  \\\"d\\\": \\\"e f\\\"\\n}\\n\""
     :fail nil
     :tags "scalar")
    (:id "AB8U"
     :name "Sequence entry that looks like two with wrong indentation"
     :yaml "- single multiline
 - sequence entry
"
     :json "\"[\\n  \\\"single multiline - sequence entry\\\"\\n]\\n\""
     :fail nil
     :tags "scalar sequence")
    (:id "AVM7"
     :name "Empty Stream"
     :yaml ""
     :json "\"\""
     :fail nil
     :tags "edge")
    (:id "AZ63"
     :name "Sequence With Same Indentation as Parent Mapping"
     :yaml "one:
- 2
- 3
four: 5
"
     :json "\"{\\n  \\\"one\\\": [\\n    2,\\n    3\\n  ],\\n  \\\"four\\\": 5\\n}\\n\""
     :fail nil
     :tags "indent mapping sequence")
    (:id "AZW3"
     :name "Lookahead test cases"
     :yaml "- bla\"keks: foo
- bla]keks: foo
"
     :json "\"[\\n  {\\n    \\\"bla\\\\\\\"keks\\\": \\\"foo\\\"\\n  },\\n  {\\n    \\\"bla]keks\\\": \\\"foo\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "mapping edge")
    (:id "B3HG"
     :name "Spec Example 8.9. Folded Scalar [1.3]"
     :yaml "--- >
 folded
 text


"
     :json "\"\\\"folded text\\\\n\\\"\\n\""
     :fail nil
     :tags "spec folded scalar 1.3-mod")
    (:id "B63P"
     :name "Directive without document"
     :yaml "%YAML 1.2
...
"
     :json nil
     :fail t
     :tags "error directive document")
    (:id "BD7L"
     :name "Invalid mapping after sequence"
     :yaml "- item1
- item2
invalid: x
"
     :json nil
     :fail t
     :tags "error mapping sequence")
    (:id "BEC7"
     :name "Spec Example 6.14. “YAML” directive"
     :yaml "%YAML 1.3 # Attempt parsing
          # with a warning
---
\"foo\"
"
     :json "\"\\\"foo\\\"\\n\""
     :fail nil
     :tags "spec directive")
    (:id "BF9H"
     :name "Trailing comment in multiline plain scalar"
     :yaml "---
plain: a
       b # end of scalar
       c
"
     :json nil
     :fail t
     :tags "comment error scalar")
    (:id "BS4K"
     :name "Comment between plain scalar lines"
     :yaml "word1  # comment
word2
"
     :json nil
     :fail t
     :tags "error scalar")
    (:id "BU8L"
     :name "Node Anchor and Tag on Seperate Lines"
     :yaml "key: &anchor
 !!map
  a: b
"
     :json "\"{\\n  \\\"key\\\": {\\n    \\\"a\\\": \\\"b\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "anchor indent 1.3-err tag")
    (:id "C2DT"
     :name "Spec Example 7.18. Flow Mapping Adjacent Values"
     :yaml "{
\"adjacent\":value,
\"readable\": value,
\"empty\":
}
"
     :json "\"{\\n  \\\"adjacent\\\": \\\"value\\\",\\n  \\\"readable\\\": \\\"value\\\",\\n  \\\"empty\\\": null\\n}\\n\""
     :fail nil
     :tags "spec flow mapping")
    (:id "C2SP"
     :name "Flow Mapping Key on two lines"
     :yaml "[23
]: 42
"
     :json nil
     :fail t
     :tags "error flow mapping")
    (:id "C4HZ"
     :name "Spec Example 2.24. Global Tags"
     :yaml "%TAG ! tag:clarkevans.com,2002:
--- !shape
  # Use the ! handle for presenting
  # tag:clarkevans.com,2002:circle
- !circle
  center: &ORIGIN {x: 73, y: 129}
  radius: 7
- !line
  start: *ORIGIN
  finish: { x: 89, y: 102 }
- !label
  start: *ORIGIN
  color: 0xFFEEBB
  text: Pretty vector drawing.
"
     :json "\"[\\n  {\\n    \\\"center\\\": {\\n      \\\"x\\\": 73,\\n      \\\"y\\\": 129\\n    },\\n    \\\"radius\\\": 7\\n  },\\n  {\\n    \\\"start\\\": {\\n      \\\"x\\\": 73,\\n      \\\"y\\\": 129\\n    },\\n    \\\"finish\\\": {\\n      \\\"x\\\": 89,\\n      \\\"y\\\": 102\\n    }\\n  },\\n  {\\n    \\\"start\\\": {\\n      \\\"x\\\": 73,\\n      \\\"y\\\": 129\\n    },\\n    \\\"color\\\": 16772795,\\n    \\\"text\\\": \\\"Pretty vector drawing.\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "spec tag alias directive local-tag")
    (:id "CC74"
     :name "Spec Example 6.20. Tag Handles"
     :yaml "%TAG !e! tag:example.com,2000:app/
---
!e!foo \"bar\"
"
     :json "\"\\\"bar\\\"\\n\""
     :fail nil
     :tags "spec directive tag unknown-tag")
    (:id "CFD4"
     :name "Empty implicit key in single pair flow sequences"
     :yaml "- [ : empty key ]
- [: another empty key]
"
     :json nil
     :fail nil
     :tags "empty-key flow sequence")
    (:id "CML9"
     :name "Missing comma in flow"
     :yaml "key: [ word1
#  xxx
  word2 ]
"
     :json nil
     :fail t
     :tags "error flow comment")
    (:id "CN3R"
     :name "Various location of anchors in flow sequence"
     :yaml "&flowseq [
 a: b,
 &c c: d,
 { &e e: f },
 &g { g: h }
]
"
     :json "\"[\\n  {\\n    \\\"a\\\": \\\"b\\\"\\n  },\\n  {\\n    \\\"c\\\": \\\"d\\\"\\n  },\\n  {\\n    \\\"e\\\": \\\"f\\\"\\n  },\\n  {\\n    \\\"g\\\": \\\"h\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "anchor flow mapping sequence")
    (:id "CPZ3"
     :name "Doublequoted scalar starting with a tab"
     :yaml "---
tab: \"\\tstring\"
"
     :json "\"{\\n  \\\"tab\\\": \\\"\\\\tstring\\\"\\n}\\n\""
     :fail nil
     :tags "double scalar")
    (:id "CQ3W"
     :name "Double quoted string without closing quote"
     :yaml "---
key: \"missing closing quote
"
     :json nil
     :fail t
     :tags "error double")
    (:id "CT4Q"
     :name "Spec Example 7.20. Single Pair Explicit Entry"
     :yaml "[
? foo
 bar : baz
]
"
     :json "\"[\\n  {\\n    \\\"foo bar\\\": \\\"baz\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "explicit-key spec flow mapping")
    (:id "CTN5"
     :name "Flow sequence with invalid extra comma"
     :yaml "---
[ a, b, c, , ]
"
     :json nil
     :fail t
     :tags "error flow sequence")
    (:id "CUP7"
     :name "Spec Example 5.6. Node Property Indicators"
     :yaml "anchored: !local &anchor value
alias: *anchor
"
     :json "\"{\\n  \\\"anchored\\\": \\\"value\\\",\\n  \\\"alias\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "local-tag spec tag alias")
    (:id "CVW2"
     :name "Invalid comment after comma"
     :yaml "---
[ a, b, c,#invalid
]
"
     :json nil
     :fail t
     :tags "comment error flow sequence")
    (:id "CXX2"
     :name "Mapping with anchor on document start line"
     :yaml "--- &anchor a: b
"
     :json nil
     :fail t
     :tags "anchor error header mapping")
    (:id "D49Q"
     :name "Multiline single quoted implicit keys"
     :yaml "'a\\nb': 1
'c
 d': 1
"
     :json nil
     :fail t
     :tags "error single mapping")
    (:id "D83L"
     :name "Block scalar indicator order"
     :yaml "- |2-
  explicit indent and chomp
- |-2
  chomp and explicit indent
"
     :json "\"[\\n  \\\"explicit indent and chomp\\\",\\n  \\\"chomp and explicit indent\\\"\\n]\\n\""
     :fail nil
     :tags "indent literal")
    (:id "D88J"
     :name "Flow Sequence in Block Mapping"
     :yaml "a: [b, c]
"
     :json "\"{\\n  \\\"a\\\": [\\n    \\\"b\\\",\\n    \\\"c\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "flow sequence mapping")
    (:id "D9TU"
     :name "Single Pair Block Mapping"
     :yaml "foo: bar
"
     :json "\"{\\n  \\\"foo\\\": \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "simple mapping")
    (:id "DBG4"
     :name "Spec Example 7.10. Plain Characters"
     :yaml "# Outside flow collection:
- ::vector
- \": - ()\"
- Up, up, and away!
- -123
- http://example.com/foo#bar
# Inside flow collection:
- [ ::vector,
  \": - ()\",
  \"Up, up and away!\",
  -123,
  http://example.com/foo#bar ]
"
     :json "\"[\\n  \\\"::vector\\\",\\n  \\\": - ()\\\",\\n  \\\"Up, up, and away!\\\",\\n  -123,\\n  \\\"http://example.com/foo#bar\\\",\\n  [\\n    \\\"::vector\\\",\\n    \\\": - ()\\\",\\n    \\\"Up, up and away!\\\",\\n    -123,\\n    \\\"http://example.com/foo#bar\\\"\\n  ]\\n]\\n\""
     :fail nil
     :tags "spec flow sequence scalar")
    (:id "DC7X"
     :name "Various trailing tabs"
     :yaml "a: b	
seq:	
 - a	
c: d	#X
"
     :json "\"{\\n  \\\"a\\\": \\\"b\\\",\\n  \\\"seq\\\": [\\n    \\\"a\\\"\\n  ],\\n  \\\"c\\\": \\\"d\\\"\\n}\\n\""
     :fail nil
     :tags "comment whitespace")
    (:id "DE56/00"
     :name "Trailing tabs in double quoted"
     :yaml "\"1 trailing\\t
    tab\"
"
     :json "\"\\\"1 trailing\\\\t tab\\\"\\n\""
     :fail nil
     :tags "double whitespace")
    (:id "DE56/01"
     :name "DE56/01"
     :yaml "\"2 trailing\\t  
    tab\"
"
     :json "\"\\\"2 trailing\\\\t tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "DE56/02"
     :name "DE56/02"
     :yaml "\"3 trailing\\	
    tab\"
"
     :json "\"\\\"3 trailing\\\\t tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "DE56/03"
     :name "DE56/03"
     :yaml "\"4 trailing\\	  
    tab\"
"
     :json "\"\\\"4 trailing\\\\t tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "DE56/04"
     :name "DE56/04"
     :yaml "\"5 trailing	
    tab\"
"
     :json "\"\\\"5 trailing tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "DE56/05"
     :name "DE56/05"
     :yaml "\"6 trailing	  
    tab\"
"
     :json "\"\\\"6 trailing tab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "DFF7"
     :name "Spec Example 7.16. Flow Mapping Entries"
     :yaml "{
? explicit: entry,
implicit: entry,
?
}
"
     :json nil
     :fail nil
     :tags "explicit-key spec flow mapping")
    (:id "DHP8"
     :name "Flow Sequence"
     :yaml "[foo, bar, 42]
"
     :json "\"[\\n  \\\"foo\\\",\\n  \\\"bar\\\",\\n  42\\n]\\n\""
     :fail nil
     :tags "flow sequence")
    (:id "DK3J"
     :name "Zero indented block scalar with line that looks like a comment"
     :yaml "--- >
line1
# no comment
line3
"
     :json "\"\\\"line1 # no comment line3\\\\n\\\"\\n\""
     :fail nil
     :tags "comment folded scalar")
    (:id "DK4H"
     :name "Implicit key followed by newline"
     :yaml "---
[ key
  : value ]
"
     :json nil
     :fail t
     :tags "error flow mapping sequence")
    (:id "DK95/00"
     :name "Tabs that look like indentation"
     :yaml "foo:
 	bar
"
     :json "\"{\\n  \\\"foo\\\" : \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "indent whitespace")
    (:id "DK95/01"
     :name "DK95/01"
     :yaml "foo: \"bar
	baz\"
"
     :json nil
     :fail t
     :tags "")
    (:id "DK95/02"
     :name "DK95/02"
     :yaml "foo: \"bar
  	baz\"
"
     :json "\"{\\n  \\\"foo\\\" : \\\"bar baz\\\"\\n}\\n\""
     :fail nil
     :tags "")
    (:id "DK95/03"
     :name "DK95/03"
     :yaml " 	
foo: 1
"
     :json "\"{\\n  \\\"foo\\\" : 1\\n}\\n\""
     :fail nil
     :tags "")
    (:id "DK95/04"
     :name "DK95/04"
     :yaml "foo: 1
	
bar: 2
"
     :json "\"{\\n  \\\"foo\\\" : 1,\\n  \\\"bar\\\" : 2\\n}\\n\""
     :fail nil
     :tags "")
    (:id "DK95/05"
     :name "DK95/05"
     :yaml "foo: 1
 	
bar: 2
"
     :json "\"{\\n  \\\"foo\\\" : 1,\\n  \\\"bar\\\" : 2\\n}\\n\""
     :fail nil
     :tags "")
    (:id "DK95/06"
     :name "DK95/06"
     :yaml "foo:
  a: 1
  	b: 2
"
     :json nil
     :fail t
     :tags "")
    (:id "DK95/07"
     :name "DK95/07"
     :yaml "%YAML 1.2
	
---
"
     :json "\"null\\n\""
     :fail nil
     :tags "")
    (:id "DK95/08"
     :name "DK95/08"
     :yaml "foo: \"bar
 	 	 baz 	 	 \"
"
     :json "\"{\\n  \\\"foo\\\" : \\\"bar baz \\\\t \\\\t \\\"\\n}\\n\""
     :fail nil
     :tags "")
    (:id "DMG6"
     :name "Wrong indendation in Map"
     :yaml "key:
  ok: 1
 wrong: 2
"
     :json nil
     :fail t
     :tags "error mapping indent")
    (:id "DWX9"
     :name "Spec Example 8.8. Literal Content"
     :yaml "|
 
  
  literal
   
  
  text

 # Comment
"
     :json "\"\\\"\\\\n\\\\nliteral\\\\n \\\\n\\\\ntext\\\\n\\\"\\n\""
     :fail nil
     :tags "spec literal scalar comment whitespace 1.3-err")
    (:id "E76Z"
     :name "Aliases in Implicit Block Mapping"
     :yaml "&a a: &b b
*b : *a
"
     :json "\"{\\n  \\\"a\\\": \\\"b\\\",\\n  \\\"b\\\": \\\"a\\\"\\n}\\n\""
     :fail nil
     :tags "mapping alias")
    (:id "EB22"
     :name "Missing document-end marker before directive"
     :yaml "---
scalar1 # comment
%YAML 1.2
---
scalar2
"
     :json nil
     :fail t
     :tags "error directive footer")
    (:id "EHF6"
     :name "Tags for Flow Objects"
     :yaml "!!map {
  k: !!seq
  [ a, !!str b]
}
"
     :json "\"{\\n  \\\"k\\\": [\\n    \\\"a\\\",\\n    \\\"b\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "tag flow mapping sequence")
    (:id "EW3V"
     :name "Wrong indendation in mapping"
     :yaml "k1: v1
 k2: v2
"
     :json nil
     :fail t
     :tags "error mapping indent")
    (:id "EX5H"
     :name "Multiline Scalar at Top Level [1.3]"
     :yaml "---
a
b  
  c
d

e
"
     :json "\"\\\"a b c d\\\\ne\\\"\\n\""
     :fail nil
     :tags "scalar whitespace 1.3-mod")
    (:id "EXG3"
     :name "Three dashes and content without space [1.3]"
     :yaml "---
---word1
word2
"
     :json "\"\\\"---word1 word2\\\"\\n\""
     :fail nil
     :tags "scalar 1.3-mod")
    (:id "F2C7"
     :name "Anchors and Tags"
     :yaml " - &a !!str a
 - !!int 2
 - !!int &c 4
 - &d d
"
     :json "\"[\\n  \\\"a\\\",\\n  2,\\n  4,\\n  \\\"d\\\"\\n]\\n\""
     :fail nil
     :tags "anchor tag")
    (:id "F3CP"
     :name "Nested flow collections on one line"
     :yaml "---
{ a: [b, c, { d: [e, f] } ] }
"
     :json "\"{\\n  \\\"a\\\": [\\n    \\\"b\\\",\\n    \\\"c\\\",\\n    {\\n      \\\"d\\\": [\\n        \\\"e\\\",\\n        \\\"f\\\"\\n      ]\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "flow mapping sequence")
    (:id "F6MC"
     :name "More indented lines at the beginning of folded block scalars"
     :yaml "---
a: >2
   more indented
  regular
b: >2


   more indented
  regular
"
     :json "\"{\\n  \\\"a\\\": \\\" more indented\\\\nregular\\\\n\\\",\\n  \\\"b\\\": \\\"\\\\n\\\\n more indented\\\\nregular\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "folded indent")
    (:id "F8F9"
     :name "Spec Example 8.5. Chomping Trailing Lines"
     :yaml " # Strip
  # Comments:
strip: |-
  # text
  
 # Clip
  # comments:

clip: |
  # text
 
 # Keep
  # comments:

keep: |+
  # text

 # Trail
  # comments.
"
     :json "\"{\\n  \\\"strip\\\": \\\"# text\\\",\\n  \\\"clip\\\": \\\"# text\\\\n\\\",\\n  \\\"keep\\\": \\\"# text\\\\n\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec literal scalar comment")
    (:id "FBC9"
     :name "Allowed characters in plain scalars"
     :yaml "safe: a!\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~
     !\"#$%&'()*+,-./09:;<=>?@AZ[\\]^_`az{|}~
safe question mark: ?foo
safe colon: :foo
safe dash: -foo
"
     :json "\"{\\n  \\\"safe\\\": \\\"a!\\\\\\\"#$%&'()*+,-./09:;<=>?@AZ[\\\\\\\\]^_`az{|}~ !\\\\\\\"#$%&'()*+,-./09:;<=>?@AZ[\\\\\\\\]^_`az{|}~\\\",\\n  \\\"safe question mark\\\": \\\"?foo\\\",\\n  \\\"safe colon\\\": \\\":foo\\\",\\n  \\\"safe dash\\\": \\\"-foo\\\"\\n}\\n\""
     :fail nil
     :tags "scalar")
    (:id "FH7J"
     :name "Tags on Empty Scalars"
     :yaml "- !!str
-
  !!null : a
  b: !!str
- !!str : !!null
"
     :json nil
     :fail nil
     :tags "tag scalar")
    (:id "FP8R"
     :name "Zero indented block scalar"
     :yaml "--- >
line1
line2
line3
"
     :json "\"\\\"line1 line2 line3\\\\n\\\"\\n\""
     :fail nil
     :tags "folded indent scalar")
    (:id "FQ7F"
     :name "Spec Example 2.1. Sequence of Scalars"
     :yaml "- Mark McGwire
- Sammy Sosa
- Ken Griffey
"
     :json "\"[\\n  \\\"Mark McGwire\\\",\\n  \\\"Sammy Sosa\\\",\\n  \\\"Ken Griffey\\\"\\n]\\n\""
     :fail nil
     :tags "spec sequence")
    (:id "FRK4"
     :name "Spec Example 7.3. Completely Empty Flow Nodes"
     :yaml "{
  ? foo :,
  : bar,
}
"
     :json nil
     :fail nil
     :tags "empty-key explicit-key spec flow mapping")
    (:id "FTA2"
     :name "Single block sequence with anchor and explicit document start"
     :yaml "--- &sequence
- a
"
     :json "\"[\\n  \\\"a\\\"\\n]\\n\""
     :fail nil
     :tags "anchor header sequence")
    (:id "FUP4"
     :name "Flow Sequence in Flow Sequence"
     :yaml "[a, [b, c]]
"
     :json "\"[\\n  \\\"a\\\",\\n  [\\n    \\\"b\\\",\\n    \\\"c\\\"\\n  ]\\n]\\n\""
     :fail nil
     :tags "sequence flow")
    (:id "G4RS"
     :name "Spec Example 2.17. Quoted Scalars"
     :yaml "unicode: \"Sosa did fine.\\u263A\"
control: \"\\b1998\\t1999\\t2000\\n\"
hex esc: \"\\x0d\\x0a is \\r\\n\"

single: '\"Howdy!\" he cried.'
quoted: ' # Not a ''comment''.'
tie-fighter: '|\\-*-/|'
"
     :json "\"{\\n  \\\"unicode\\\": \\\"Sosa did fine.\\u263a\\\",\\n  \\\"control\\\": \\\"\\\\b1998\\\\t1999\\\\t2000\\\\n\\\",\\n  \\\"hex esc\\\": \\\"\\\\r\\\\n is \\\\r\\\\n\\\",\\n  \\\"single\\\": \\\"\\\\\\\"Howdy!\\\\\\\" he cried.\\\",\\n  \\\"quoted\\\": \\\" # Not a 'comment'.\\\",\\n  \\\"tie-fighter\\\": \\\"|\\\\\\\\-*-/|\\\"\\n}\\n\""
     :fail nil
     :tags "spec scalar")
    (:id "G5U8"
     :name "Plain dashes in flow sequence"
     :yaml "---
- [-, -]
"
     :json nil
     :fail t
     :tags "flow sequence")
    (:id "G7JE"
     :name "Multiline implicit keys"
     :yaml "a\\nb: 1
c
 d: 1
"
     :json nil
     :fail t
     :tags "error mapping")
    (:id "G992"
     :name "Spec Example 8.9. Folded Scalar"
     :yaml ">
 folded
 text


"
     :json "\"\\\"folded text\\\\n\\\"\\n\""
     :fail nil
     :tags "spec folded scalar 1.3-err")
    (:id "G9HC"
     :name "Invalid anchor in zero indented sequence"
     :yaml "---
seq:
&anchor
- a
- b
"
     :json nil
     :fail t
     :tags "anchor error sequence")
    (:id "GDY7"
     :name "Comment that looks like a mapping key"
     :yaml "key: value
this is #not a: key
"
     :json nil
     :fail t
     :tags "comment error mapping")
    (:id "GH63"
     :name "Mixed Block Mapping (explicit to implicit)"
     :yaml "? a
: 1.3
fifteen: d
"
     :json "\"{\\n  \\\"a\\\": 1.3,\\n  \\\"fifteen\\\": \\\"d\\\"\\n}\\n\""
     :fail nil
     :tags "explicit-key mapping")
    (:id "GT5M"
     :name "Node anchor in sequence"
     :yaml "- item1
&node
- item2
"
     :json nil
     :fail t
     :tags "anchor error sequence")
    (:id "H2RW"
     :name "Blank lines"
     :yaml "foo: 1

bar: 2
    
text: |
  a
    
  b

  c
 
  d
"
     :json "\"{\\n  \\\"foo\\\": 1,\\n  \\\"bar\\\": 2,\\n  \\\"text\\\": \\\"a\\\\n  \\\\nb\\\\n\\\\nc\\\\n\\\\nd\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "comment literal scalar whitespace")
    (:id "H3Z8"
     :name "Literal unicode"
     :yaml "---
wanted: love ♥ and peace ☮
"
     :json "\"{\\n  \\\"wanted\\\": \\\"love \\u2665 and peace \\u262e\\\"\\n}\\n\""
     :fail nil
     :tags "scalar")
    (:id "H7J7"
     :name "Node anchor not indented"
     :yaml "key: &x
!!map
  a: b
"
     :json nil
     :fail t
     :tags "anchor error indent tag")
    (:id "H7TQ"
     :name "Extra words on %YAML directive"
     :yaml "%YAML 1.2 foo
---
"
     :json nil
     :fail t
     :tags "directive")
    (:id "HM87/00"
     :name "Scalars in flow start with syntax char"
     :yaml "[:x]
"
     :json "\"[\\n  \\\":x\\\"\\n]\\n\""
     :fail nil
     :tags "flow scalar")
    (:id "HM87/01"
     :name "HM87/01"
     :yaml "[?x]
"
     :json "\"[\\n  \\\"?x\\\"\\n]\\n\""
     :fail nil
     :tags "")
    (:id "HMK4"
     :name "Spec Example 2.16. Indentation determines scope"
     :yaml "name: Mark McGwire
accomplishment: >
  Mark set a major league
  home run record in 1998.
stats: |
  65 Home Runs
  0.278 Batting Average
"
     :json "\"{\\n  \\\"name\\\": \\\"Mark McGwire\\\",\\n  \\\"accomplishment\\\": \\\"Mark set a major league home run record in 1998.\\\\n\\\",\\n  \\\"stats\\\": \\\"65 Home Runs\\\\n0.278 Batting Average\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec folded literal")
    (:id "HMQ5"
     :name "Spec Example 6.23. Node Properties"
     :yaml "!!str &a1 \"foo\":
  !!str bar
&a2 baz : *a1
"
     :json "\"{\\n  \\\"foo\\\": \\\"bar\\\",\\n  \\\"baz\\\": \\\"foo\\\"\\n}\\n\""
     :fail nil
     :tags "spec tag alias")
    (:id "HRE5"
     :name "Double quoted scalar with escaped single quote"
     :yaml "---
double: \"quoted \\' scalar\"
"
     :json nil
     :fail t
     :tags "double error single")
    (:id "HS5T"
     :name "Spec Example 7.12. Plain Lines"
     :yaml "1st non-empty

 2nd non-empty 
	3rd non-empty
"
     :json "\"\\\"1st non-empty\\\\n2nd non-empty 3rd non-empty\\\"\\n\""
     :fail nil
     :tags "spec scalar whitespace upto-1.2")
    (:id "HU3P"
     :name "Invalid Mapping in plain scalar"
     :yaml "key:
  word1 word2
  no: key
"
     :json nil
     :fail t
     :tags "error mapping scalar")
    (:id "HWV9"
     :name "Document-end marker"
     :yaml "...
"
     :json "\"\""
     :fail nil
     :tags "footer")
    (:id "J3BT"
     :name "Spec Example 5.12. Tabs and Spaces"
     :yaml "# Tabs and spaces
quoted: \"Quoted 	\"
block:	|
  void main() {
  	printf(\"Hello, world!\\n\");
  }
"
     :json "\"{\\n  \\\"quoted\\\": \\\"Quoted \\\\t\\\",\\n  \\\"block\\\": \\\"void main() {\\\\n\\\\tprintf(\\\\\\\"Hello, world!\\\\\\\\n\\\\\\\");\\\\n}\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec whitespace upto-1.2")
    (:id "J5UC"
     :name "Multiple Pair Block Mapping"
     :yaml "foo: blue
bar: arrr
baz: jazz
"
     :json "\"{\\n  \\\"foo\\\": \\\"blue\\\",\\n  \\\"bar\\\": \\\"arrr\\\",\\n  \\\"baz\\\": \\\"jazz\\\"\\n}\\n\""
     :fail nil
     :tags "mapping")
    (:id "J7PZ"
     :name "Spec Example 2.26. Ordered Mappings"
     :yaml "# The !!omap tag is one of the optional types
# introduced for YAML 1.1. In 1.2, it is not
# part of the standard tags and should not be
# enabled by default.
# Ordered maps are represented as
# A sequence of mappings, with
# each mapping having one key
--- !!omap
- Mark McGwire: 65
- Sammy Sosa: 63
- Ken Griffy: 58
"
     :json "\"[\\n  {\\n    \\\"Mark McGwire\\\": 65\\n  },\\n  {\\n    \\\"Sammy Sosa\\\": 63\\n  },\\n  {\\n    \\\"Ken Griffy\\\": 58\\n  }\\n]\\n\""
     :fail nil
     :tags "spec mapping tag unknown-tag")
    (:id "J7VC"
     :name "Empty Lines Between Mapping Elements"
     :yaml "one: 2


three: 4
"
     :json "\"{\\n  \\\"one\\\": 2,\\n  \\\"three\\\": 4\\n}\\n\""
     :fail nil
     :tags "whitespace mapping")
    (:id "J9HZ"
     :name "Spec Example 2.9. Single Document with Two Comments"
     :yaml "---
hr: # 1998 hr ranking
  - Mark McGwire
  - Sammy Sosa
rbi:
  # 1998 rbi ranking
  - Sammy Sosa
  - Ken Griffey
"
     :json "\"{\\n  \\\"hr\\\": [\\n    \\\"Mark McGwire\\\",\\n    \\\"Sammy Sosa\\\"\\n  ],\\n  \\\"rbi\\\": [\\n    \\\"Sammy Sosa\\\",\\n    \\\"Ken Griffey\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "mapping sequence spec comment")
    (:id "JEF9/00"
     :name "Trailing whitespace in streams"
     :yaml "- |+


"
     :json "\"[\\n  \\\"\\\\n\\\\n\\\"\\n]\\n\""
     :fail nil
     :tags "literal")
    (:id "JEF9/01"
     :name "JEF9/01"
     :yaml "- |+
   
"
     :json "\"[\\n  \\\"\\\\n\\\"\\n]\\n\""
     :fail nil
     :tags "")
    (:id "JEF9/02"
     :name "JEF9/02"
     :yaml "- |+
   "
     :json nil
     :fail nil
     :tags "")
    (:id "JHB9"
     :name "Spec Example 2.7. Two Documents in a Stream"
     :yaml "# Ranking of 1998 home runs
---
- Mark McGwire
- Sammy Sosa
- Ken Griffey

# Team ranking
---
- Chicago Cubs
- St Louis Cardinals
"
     :json "\"[\\n  \\\"Mark McGwire\\\",\\n  \\\"Sammy Sosa\\\",\\n  \\\"Ken Griffey\\\"\\n]\\n[\\n  \\\"Chicago Cubs\\\",\\n  \\\"St Louis Cardinals\\\"\\n]\\n\""
     :fail nil
     :tags "spec header")
    (:id "JKF3"
     :name "Multiline unidented double quoted block key"
     :yaml "- - \"bar
bar\": x
"
     :json nil
     :fail t
     :tags "indent")
    (:id "JQ4R"
     :name "Spec Example 8.14. Block Sequence"
     :yaml "block sequence:
  - one
  - two : three
"
     :json "\"{\\n  \\\"block sequence\\\": [\\n    \\\"one\\\",\\n    {\\n      \\\"two\\\": \\\"three\\\"\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "mapping spec sequence")
    (:id "JR7V"
     :name "Question marks in scalars"
     :yaml "- a?string
- another ? string
- key: value?
- [a?string]
- [another ? string]
- {key: value? }
- {key: value?}
- {key?: value }
"
     :json "\"[\\n  \\\"a?string\\\",\\n  \\\"another ? string\\\",\\n  {\\n    \\\"key\\\": \\\"value?\\\"\\n  },\\n  [\\n    \\\"a?string\\\"\\n  ],\\n  [\\n    \\\"another ? string\\\"\\n  ],\\n  {\\n    \\\"key\\\": \\\"value?\\\"\\n  },\\n  {\\n    \\\"key\\\": \\\"value?\\\"\\n  },\\n  {\\n    \\\"key?\\\": \\\"value\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "flow scalar")
    (:id "JS2J"
     :name "Spec Example 6.29. Node Anchors"
     :yaml "First occurrence: &anchor Value
Second occurrence: *anchor
"
     :json "\"{\\n  \\\"First occurrence\\\": \\\"Value\\\",\\n  \\\"Second occurrence\\\": \\\"Value\\\"\\n}\\n\""
     :fail nil
     :tags "spec alias")
    (:id "JTV5"
     :name "Block Mapping with Multiline Scalars"
     :yaml "? a
  true
: null
  d
? e
  42
"
     :json "\"{\\n  \\\"a true\\\": \\\"null d\\\",\\n  \\\"e 42\\\": null\\n}\\n\""
     :fail nil
     :tags "explicit-key mapping scalar")
    (:id "JY7Z"
     :name "Trailing content that looks like a mapping"
     :yaml "key1: \"quoted1\"
key2: \"quoted2\" no key: nor value
key3: \"quoted3\"
"
     :json nil
     :fail t
     :tags "error mapping double")
    (:id "K3WX"
     :name "Colon and adjacent value after comment on next line"
     :yaml "---
{ \"foo\" # comment
  :bar }
"
     :json "\"{\\n  \\\"foo\\\": \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "comment flow mapping")
    (:id "K4SU"
     :name "Multiple Entry Block Sequence"
     :yaml "- foo
- bar
- 42
"
     :json "\"[\\n  \\\"foo\\\",\\n  \\\"bar\\\",\\n  42\\n]\\n\""
     :fail nil
     :tags "sequence")
    (:id "K527"
     :name "Spec Example 6.6. Line Folding"
     :yaml ">-
  trimmed
  
 

  as
  space
"
     :json "\"\\\"trimmed\\\\n\\\\n\\\\nas space\\\"\\n\""
     :fail nil
     :tags "folded spec whitespace scalar 1.3-err")
    (:id "K54U"
     :name "Tab after document header"
     :yaml "---	scalar
"
     :json "\"\\\"scalar\\\"\\n\""
     :fail nil
     :tags "header whitespace")
    (:id "K858"
     :name "Spec Example 8.6. Empty Scalar Chomping"
     :yaml "strip: >-

clip: >

keep: |+

"
     :json "\"{\\n  \\\"strip\\\": \\\"\\\",\\n  \\\"clip\\\": \\\"\\\",\\n  \\\"keep\\\": \\\"\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "spec folded literal whitespace")
    (:id "KH5V/00"
     :name "Inline tabs in double quoted"
     :yaml "\"1 inline\\ttab\"
"
     :json "\"\\\"1 inline\\\\ttab\\\"\\n\""
     :fail nil
     :tags "double whitespace")
    (:id "KH5V/01"
     :name "KH5V/01"
     :yaml "\"2 inline\\	tab\"
"
     :json "\"\\\"2 inline\\\\ttab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "KH5V/02"
     :name "KH5V/02"
     :yaml "\"3 inline	tab\"
"
     :json "\"\\\"3 inline\\\\ttab\\\"\\n\""
     :fail nil
     :tags "")
    (:id "KK5P"
     :name "Various combinations of explicit block mappings"
     :yaml "complex1:
  ? - a
complex2:
  ? - a
  : b
complex3:
  ? - a
  : >
    b
complex4:
  ? >
    a
  :
complex5:
  ? - a
  : - b
"
     :json nil
     :fail nil
     :tags "explicit-key mapping sequence")
    (:id "KMK3"
     :name "Block Submapping"
     :yaml "foo:
  bar: 1
baz: 2
"
     :json "\"{\\n  \\\"foo\\\": {\\n    \\\"bar\\\": 1\\n  },\\n  \\\"baz\\\": 2\\n}\\n\""
     :fail nil
     :tags "mapping")
    (:id "KS4U"
     :name "Invalid item after end of flow sequence"
     :yaml "---
[
sequence item
]
invalid item
"
     :json nil
     :fail t
     :tags "error flow sequence")
    (:id "KSS4"
     :name "Scalars on --- line"
     :yaml "--- \"quoted
string\"
--- &node foo
"
     :json "\"\\\"quoted string\\\"\\n\\\"foo\\\"\\n\""
     :fail nil
     :tags "anchor header scalar 1.3-err")
    (:id "L24T/00"
     :name "Trailing line of spaces"
     :yaml "foo: |
  x
   
"
     :json "\"{\\n  \\\"foo\\\" : \\\"x\\\\n \\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "whitespace")
    (:id "L24T/01"
     :name "L24T/01"
     :yaml "foo: |
  x
   "
     :json "\"{\\n  \\\"foo\\\" : \\\"x\\\\n \\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "")
    (:id "L383"
     :name "Two scalar docs with trailing comments"
     :yaml "--- foo  # comment
--- foo  # comment
"
     :json "\"\\\"foo\\\"\\n\\\"foo\\\"\\n\""
     :fail nil
     :tags "comment")
    (:id "L94M"
     :name "Tags in Explicit Mapping"
     :yaml "? !!str a
: !!int 47
? c
: !!str d
"
     :json "\"{\\n  \\\"a\\\": 47,\\n  \\\"c\\\": \\\"d\\\"\\n}\\n\""
     :fail nil
     :tags "explicit-key tag mapping")
    (:id "L9U5"
     :name "Spec Example 7.11. Plain Implicit Keys"
     :yaml "implicit block key : [
  implicit flow key : value,
 ]
"
     :json "\"{\\n  \\\"implicit block key\\\": [\\n    {\\n      \\\"implicit flow key\\\": \\\"value\\\"\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "spec flow mapping")
    (:id "LE5A"
     :name "Spec Example 7.24. Flow Nodes"
     :yaml "- !!str \"a\"
- 'b'
- &anchor \"c\"
- *anchor
- !!str
"
     :json "\"[\\n  \\\"a\\\",\\n  \\\"b\\\",\\n  \\\"c\\\",\\n  \\\"c\\\",\\n  \\\"\\\"\\n]\\n\""
     :fail nil
     :tags "spec tag alias")
    (:id "LHL4"
     :name "Invalid tag"
     :yaml "---
!invalid{}tag scalar
"
     :json nil
     :fail t
     :tags "error tag")
    (:id "LP6E"
     :name "Whitespace After Scalars in Flow"
     :yaml "- [a, b , c ]
- { \"a\"  : b
   , c : 'd' ,
   e   : \"f\"
  }
- [      ]
"
     :json "\"[\\n  [\\n    \\\"a\\\",\\n    \\\"b\\\",\\n    \\\"c\\\"\\n  ],\\n  {\\n    \\\"a\\\": \\\"b\\\",\\n    \\\"c\\\": \\\"d\\\",\\n    \\\"e\\\": \\\"f\\\"\\n  },\\n  []\\n]\\n\""
     :fail nil
     :tags "flow scalar whitespace")
    (:id "LQZ7"
     :name "Spec Example 7.4. Double Quoted Implicit Keys"
     :yaml "\"implicit block key\" : [
  \"implicit flow key\" : value,
 ]
"
     :json "\"{\\n  \\\"implicit block key\\\": [\\n    {\\n      \\\"implicit flow key\\\": \\\"value\\\"\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "spec scalar flow")
    (:id "LX3P"
     :name "Implicit Flow Mapping Key on one line"
     :yaml "[flow]: block
"
     :json nil
     :fail nil
     :tags "complex-key mapping flow sequence 1.3-err")
    (:id "M29M"
     :name "Literal Block Scalar"
     :yaml "a: |
 ab
 
 cd
 ef
 

...
"
     :json "\"{\\n  \\\"a\\\": \\\"ab\\\\n\\\\ncd\\\\nef\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "literal scalar whitespace")
    (:id "M2N8/00"
     :name "Question mark edge cases"
     :yaml "- ? : x
"
     :json nil
     :fail nil
     :tags "edge empty-key")
    (:id "M2N8/01"
     :name "M2N8/01"
     :yaml "? []: x
"
     :json nil
     :fail nil
     :tags "")
    (:id "M5C3"
     :name "Spec Example 8.21. Block Scalar Nodes"
     :yaml "literal: |2
  value
folded:
   !foo
  >1
 value
"
     :json "\"{\\n  \\\"literal\\\": \\\"value\\\\n\\\",\\n  \\\"folded\\\": \\\"value\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "indent spec literal folded tag local-tag 1.3-err")
    (:id "M5DY"
     :name "Spec Example 2.11. Mapping between Sequences"
     :yaml "? - Detroit Tigers
  - Chicago cubs
:
  - 2001-07-23

? [ New York Yankees,
    Atlanta Braves ]
: [ 2001-07-02, 2001-08-12,
    2001-08-14 ]
"
     :json nil
     :fail nil
     :tags "complex-key explicit-key spec mapping sequence")
    (:id "M6YH"
     :name "Block sequence indentation"
     :yaml "- |
 x
-
 foo: bar
-
 - 42
"
     :json "\"[\\n  \\\"x\\\\n\\\",\\n  {\\n    \\\"foo\\\" : \\\"bar\\\"\\n  },\\n  [\\n    42\\n  ]\\n]\\n\""
     :fail nil
     :tags "indent")
    (:id "M7A3"
     :name "Spec Example 9.3. Bare Documents"
     :yaml "Bare
document
...
# No document
...
|
%!PS-Adobe-2.0 # Not the first line
"
     :json "\"\\\"Bare document\\\"\\n\\\"%!PS-Adobe-2.0 # Not the first line\\\\n\\\"\\n\""
     :fail nil
     :tags "spec footer 1.3-err")
    (:id "M7NX"
     :name "Nested flow collections"
     :yaml "---
{
 a: [
  b, c, {
   d: [e, f]
  }
 ]
}
"
     :json "\"{\\n  \\\"a\\\": [\\n    \\\"b\\\",\\n    \\\"c\\\",\\n    {\\n      \\\"d\\\": [\\n        \\\"e\\\",\\n        \\\"f\\\"\\n      ]\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "flow mapping sequence")
    (:id "M9B4"
     :name "Spec Example 8.7. Literal Scalar"
     :yaml "|
 literal
 	text


"
     :json "\"\\\"literal\\\\n\\\\ttext\\\\n\\\"\\n\""
     :fail nil
     :tags "spec literal scalar whitespace 1.3-err")
    (:id "MJS9"
     :name "Spec Example 6.7. Block Folding"
     :yaml ">
  foo 
 
  	 bar

  baz
"
     :json "\"\\\"foo \\\\n\\\\n\\\\t bar\\\\n\\\\nbaz\\\\n\\\"\\n\""
     :fail nil
     :tags "folded spec scalar whitespace 1.3-err")
    (:id "MUS6/00"
     :name "Directive variants"
     :yaml "%YAML 1.1#...
---
"
     :json nil
     :fail t
     :tags "directive")
    (:id "MUS6/01"
     :name "MUS6/01"
     :yaml "%YAML 1.2
---
%YAML 1.2
---
"
     :json nil
     :fail t
     :tags "")
    (:id "MUS6/02"
     :name "MUS6/02"
     :yaml "%YAML  1.1
---
"
     :json "\"null\\n\""
     :fail nil
     :tags "")
    (:id "MUS6/03"
     :name "MUS6/03"
     :yaml "%YAML 	 1.1
---
"
     :json nil
     :fail nil
     :tags "")
    (:id "MUS6/04"
     :name "MUS6/04"
     :yaml "%YAML 1.1  # comment
---
"
     :json nil
     :fail nil
     :tags "")
    (:id "MUS6/05"
     :name "MUS6/05"
     :yaml "%YAM 1.1
---
"
     :json nil
     :fail nil
     :tags "")
    (:id "MUS6/06"
     :name "MUS6/06"
     :yaml "%YAMLL 1.1
---
"
     :json nil
     :fail nil
     :tags "")
    (:id "MXS3"
     :name "Flow Mapping in Block Sequence"
     :yaml "- {a: b}
"
     :json "\"[\\n  {\\n    \\\"a\\\": \\\"b\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "mapping sequence flow")
    (:id "MYW6"
     :name "Block Scalar Strip"
     :yaml "|-
 ab
 
 
...
"
     :json "\"\\\"ab\\\"\\n\""
     :fail nil
     :tags "literal scalar whitespace 1.3-err")
    (:id "MZX3"
     :name "Non-Specific Tags on Scalars"
     :yaml "- plain
- \"double quoted\"
- 'single quoted'
- >
  block
- plain again
"
     :json "\"[\\n  \\\"plain\\\",\\n  \\\"double quoted\\\",\\n  \\\"single quoted\\\",\\n  \\\"block\\\\n\\\",\\n  \\\"plain again\\\"\\n]\\n\""
     :fail nil
     :tags "folded scalar")
    (:id "N4JP"
     :name "Bad indentation in mapping"
     :yaml "map:
  key1: \"quoted1\"
 key2: \"bad indentation\"
"
     :json nil
     :fail t
     :tags "error mapping indent double")
    (:id "N782"
     :name "Invalid document markers in flow style"
     :yaml "[
--- ,
...
]
"
     :json nil
     :fail t
     :tags "flow edge header footer error")
    (:id "NAT4"
     :name "Various empty or newline only quoted strings"
     :yaml "---
a: '
  '
b: '  
  '
c: \"
  \"
d: \"  
  \"
e: '

  '
f: \"

  \"
g: '


  '
h: \"


  \"
"
     :json "\"{\\n  \\\"a\\\": \\\" \\\",\\n  \\\"b\\\": \\\" \\\",\\n  \\\"c\\\": \\\" \\\",\\n  \\\"d\\\": \\\" \\\",\\n  \\\"e\\\": \\\"\\\\n\\\",\\n  \\\"f\\\": \\\"\\\\n\\\",\\n  \\\"g\\\": \\\"\\\\n\\\\n\\\",\\n  \\\"h\\\": \\\"\\\\n\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "double scalar single whitespace")
    (:id "NB6Z"
     :name "Multiline plain value with tabs on empty lines"
     :yaml "key:
  value
  with
  	
  tabs
"
     :json "\"{\\n  \\\"key\\\": \\\"value with\\\\ntabs\\\"\\n}\\n\""
     :fail nil
     :tags "scalar whitespace")
    (:id "NHX8"
     :name "Empty Lines at End of Document"
     :yaml ":


"
     :json nil
     :fail nil
     :tags "empty-key whitespace")
    (:id "NJ66"
     :name "Multiline plain flow mapping key"
     :yaml "---
- { single line: value}
- { multi
  line: value}
"
     :json "\"[\\n  {\\n    \\\"single line\\\": \\\"value\\\"\\n  },\\n  {\\n    \\\"multi line\\\": \\\"value\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "flow mapping")
    (:id "NKF9"
     :name "Empty keys in block and flow mapping"
     :yaml "---
key: value
: empty key
---
{
 key: value, : empty key
}
---
# empty key and value
:
---
# empty key and value
{ : }
"
     :json nil
     :fail nil
     :tags "empty-key mapping")
    (:id "NP9H"
     :name "Spec Example 7.5. Double Quoted Line Breaks"
     :yaml "\"folded 
to a space,	
 
to a line feed, or 	\\
 \\ 	non-content\"
"
     :json "\"\\\"folded to a space,\\\\nto a line feed, or \\\\t \\\\tnon-content\\\"\\n\""
     :fail nil
     :tags "double spec scalar whitespace upto-1.2")
    (:id "P2AD"
     :name "Spec Example 8.1. Block Scalar Header"
     :yaml "- | # Empty header↓
 literal
- >1 # Indentation indicator↓
  folded
- |+ # Chomping indicator↓
 keep

- >1- # Both indicators↓
  strip
"
     :json "\"[\\n  \\\"literal\\\\n\\\",\\n  \\\" folded\\\\n\\\",\\n  \\\"keep\\\\n\\\\n\\\",\\n  \\\" strip\\\"\\n]\\n\""
     :fail nil
     :tags "spec literal folded comment scalar")
    (:id "P2EQ"
     :name "Invalid sequene item on same line as previous item"
     :yaml "---
- { y: z }- invalid
"
     :json nil
     :fail t
     :tags "error flow mapping sequence")
    (:id "P76L"
     :name "Spec Example 6.19. Secondary Tag Handle"
     :yaml "%TAG !! tag:example.com,2000:app/
---
!!int 1 - 3 # Interval, not integer
"
     :json "\"\\\"1 - 3\\\"\\n\""
     :fail nil
     :tags "spec header tag unknown-tag")
    (:id "P94K"
     :name "Spec Example 6.11. Multi-Line Comments"
     :yaml "key:    # Comment
        # lines
  value


"
     :json "\"{\\n  \\\"key\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "spec comment")
    (:id "PBJ2"
     :name "Spec Example 2.3. Mapping Scalars to Sequences"
     :yaml "american:
  - Boston Red Sox
  - Detroit Tigers
  - New York Yankees
national:
  - New York Mets
  - Chicago Cubs
  - Atlanta Braves
"
     :json "\"{\\n  \\\"american\\\": [\\n    \\\"Boston Red Sox\\\",\\n    \\\"Detroit Tigers\\\",\\n    \\\"New York Yankees\\\"\\n  ],\\n  \\\"national\\\": [\\n    \\\"New York Mets\\\",\\n    \\\"Chicago Cubs\\\",\\n    \\\"Atlanta Braves\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "spec mapping sequence")
    (:id "PRH3"
     :name "Spec Example 7.9. Single Quoted Lines"
     :yaml "' 1st non-empty

 2nd non-empty 
	3rd non-empty '
"
     :json "\"\\\" 1st non-empty\\\\n2nd non-empty 3rd non-empty \\\"\\n\""
     :fail nil
     :tags "single spec scalar whitespace upto-1.2")
    (:id "PUW8"
     :name "Document start on last line"
     :yaml "---
a: b
---
"
     :json "\"{\\n  \\\"a\\\": \\\"b\\\"\\n}\\nnull\\n\""
     :fail nil
     :tags "header")
    (:id "PW8X"
     :name "Anchors on Empty Scalars"
     :yaml "- &a
- a
-
  &a : a
  b: &b
-
  &c : &a
-
  ? &d
-
  ? &e
  : &a
"
     :json nil
     :fail nil
     :tags "anchor explicit-key")
    (:id "Q4CL"
     :name "Trailing content after quoted value"
     :yaml "key1: \"quoted1\"
key2: \"quoted2\" trailing content
key3: \"quoted3\"
"
     :json nil
     :fail t
     :tags "error mapping double")
    (:id "Q5MG"
     :name "Tab at beginning of line followed by a flow mapping"
     :yaml "	{}
"
     :json "\"{}\\n\""
     :fail nil
     :tags "flow whitespace")
    (:id "Q88A"
     :name "Spec Example 7.23. Flow Content"
     :yaml "- [ a, b ]
- { a: b }
- \"a\"
- 'b'
- c
"
     :json "\"[\\n  [\\n    \\\"a\\\",\\n    \\\"b\\\"\\n  ],\\n  {\\n    \\\"a\\\": \\\"b\\\"\\n  },\\n  \\\"a\\\",\\n  \\\"b\\\",\\n  \\\"c\\\"\\n]\\n\""
     :fail nil
     :tags "spec flow sequence mapping")
    (:id "Q8AD"
     :name "Spec Example 7.5. Double Quoted Line Breaks [1.3]"
     :yaml "---
\"folded 
to a space,
 
to a line feed, or 	\\
 \\ 	non-content\"
"
     :json "\"\\\"folded to a space,\\\\nto a line feed, or \\\\t \\\\tnon-content\\\"\\n\""
     :fail nil
     :tags "double spec scalar whitespace 1.3-mod")
    (:id "Q9WF"
     :name "Spec Example 6.12. Separation Spaces"
     :yaml "{ first: Sammy, last: Sosa }:
# Statistics:
  hr:  # Home runs
     65
  avg: # Average
   0.278
"
     :json nil
     :fail nil
     :tags "complex-key flow spec comment whitespace 1.3-err")
    (:id "QB6E"
     :name "Wrong indented multiline quoted scalar"
     :yaml "---
quoted: \"a
b
c\"
"
     :json nil
     :fail t
     :tags "double error indent")
    (:id "QF4Y"
     :name "Spec Example 7.19. Single Pair Flow Mappings"
     :yaml "[
foo: bar
]
"
     :json "\"[\\n  {\\n    \\\"foo\\\": \\\"bar\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "spec flow mapping")
    (:id "QLJ7"
     :name "Tag shorthand used in documents but only defined in the first"
     :yaml "%TAG !prefix! tag:example.com,2011:
--- !prefix!A
a: b
--- !prefix!B
c: d
--- !prefix!C
e: f
"
     :json nil
     :fail t
     :tags "error directive tag")
    (:id "QT73"
     :name "Comment and document-end marker"
     :yaml "# comment
...
"
     :json "\"\""
     :fail nil
     :tags "comment footer")
    (:id "R4YG"
     :name "Spec Example 8.2. Block Indentation Indicator"
     :yaml "- |
 detected
- >
 
  
  # detected
- |1
  explicit
- >
 	
 detected
"
     :json "\"[\\n  \\\"detected\\\\n\\\",\\n  \\\"\\\\n\\\\n# detected\\\\n\\\",\\n  \\\" explicit\\\\n\\\",\\n  \\\"\\\\t\\\\ndetected\\\\n\\\"\\n]\\n\""
     :fail nil
     :tags "spec literal folded scalar whitespace libyaml-err upto-1.2")
    (:id "R52L"
     :name "Nested flow mapping sequence and mappings"
     :yaml "---
{ top1: [item1, {key2: value2}, item3], top2: value2 }
"
     :json "\"{\\n  \\\"top1\\\": [\\n    \\\"item1\\\",\\n    {\\n      \\\"key2\\\": \\\"value2\\\"\\n    },\\n    \\\"item3\\\"\\n  ],\\n  \\\"top2\\\": \\\"value2\\\"\\n}\\n\""
     :fail nil
     :tags "flow mapping sequence")
    (:id "RHX7"
     :name "YAML directive without document end marker"
     :yaml "---
key: value
%YAML 1.2
---
"
     :json nil
     :fail t
     :tags "directive error")
    (:id "RLU9"
     :name "Sequence Indent"
     :yaml "foo:
- 42
bar:
  - 44
"
     :json "\"{\\n  \\\"foo\\\": [\\n    42\\n  ],\\n  \\\"bar\\\": [\\n    44\\n  ]\\n}\\n\""
     :fail nil
     :tags "sequence indent")
    (:id "RR7F"
     :name "Mixed Block Mapping (implicit to explicit)"
     :yaml "a: 4.2
? d
: 23
"
     :json "\"{\\n  \\\"d\\\": 23,\\n  \\\"a\\\": 4.2\\n}\\n\""
     :fail nil
     :tags "explicit-key mapping")
    (:id "RTP8"
     :name "Spec Example 9.2. Document Markers"
     :yaml "%YAML 1.2
---
Document
... # Suffix
"
     :json "\"\\\"Document\\\"\\n\""
     :fail nil
     :tags "spec header footer")
    (:id "RXY3"
     :name "Invalid document-end marker in single quoted string"
     :yaml "---
'
...
'
"
     :json nil
     :fail t
     :tags "footer single error")
    (:id "RZP5"
     :name "Various Trailing Comments [1.3]"
     :yaml "a: \"double
  quotes\" # lala
b: plain
 value  # lala
c  : #lala
  d
? # lala
 - seq1
: # lala
 - #lala
  seq2
e: &node # lala
 - x: y
block: > # lala
  abcde
"
     :json nil
     :fail nil
     :tags "anchor comment folded mapping 1.3-mod")
    (:id "RZT7"
     :name "Spec Example 2.28. Log File"
     :yaml "---
Time: 2001-11-23 15:01:42 -5
User: ed
Warning:
  This is an error message
  for the log file
---
Time: 2001-11-23 15:02:31 -5
User: ed
Warning:
  A slightly different error
  message.
---
Date: 2001-11-23 15:03:17 -5
User: ed
Fatal:
  Unknown variable \"bar\"
Stack:
  - file: TopClass.py
    line: 23
    code: |
      x = MoreObject(\"345\\n\")
  - file: MoreClass.py
    line: 58
    code: |-
      foo = bar
"
     :json "\"{\\n  \\\"Time\\\": \\\"2001-11-23 15:01:42 -5\\\",\\n  \\\"User\\\": \\\"ed\\\",\\n  \\\"Warning\\\": \\\"This is an error message for the log file\\\"\\n}\\n{\\n  \\\"Time\\\": \\\"2001-11-23 15:02:31 -5\\\",\\n  \\\"User\\\": \\\"ed\\\",\\n  \\\"Warning\\\": \\\"A slightly different error message.\\\"\\n}\\n{\\n  \\\"Date\\\": \\\"2001-11-23 15:03:17 -5\\\",\\n  \\\"User\\\": \\\"ed\\\",\\n  \\\"Fatal\\\": \\\"Unknown variable \\\\\\\"bar\\\\\\\"\\\",\\n  \\\"Stack\\\": [\\n    {\\n      \\\"file\\\": \\\"TopClass.py\\\",\\n      \\\"line\\\": 23,\\n      \\\"code\\\": \\\"x = MoreObject(\\\\\\\"345\\\\\\\\n\\\\\\\")\\\\n\\\"\\n    },\\n    {\\n      \\\"file\\\": \\\"MoreClass.py\\\",\\n      \\\"line\\\": 58,\\n      \\\"code\\\": \\\"foo = bar\\\"\\n    }\\n  ]\\n}\\n\""
     :fail nil
     :tags "spec header literal mapping sequence")
    (:id "S3PD"
     :name "Spec Example 8.18. Implicit Block Mapping Entries"
     :yaml "plain key: in-line value
: # Both empty
\"quoted key\":
- entry
"
     :json nil
     :fail nil
     :tags "empty-key spec mapping")
    (:id "S4GJ"
     :name "Invalid text after block scalar indicator"
     :yaml "---
folded: > first line
  second line
"
     :json nil
     :fail t
     :tags "error folded")
    (:id "S4JQ"
     :name "Spec Example 6.28. Non-Specific Tags"
     :yaml "# Assuming conventional resolution:
- \"12\"
- 12
- ! 12
"
     :json "\"[\\n  \\\"12\\\",\\n  12,\\n  \\\"12\\\"\\n]\\n\""
     :fail nil
     :tags "spec tag")
    (:id "S4T7"
     :name "Document with footer"
     :yaml "aaa: bbb
...
"
     :json "\"{\\n  \\\"aaa\\\": \\\"bbb\\\"\\n}\\n\""
     :fail nil
     :tags "mapping footer")
    (:id "S7BG"
     :name "Colon followed by comma"
     :yaml "---
- :,
"
     :json "\"[\\n  \\\":,\\\"\\n]\\n\""
     :fail nil
     :tags "scalar")
    (:id "S98Z"
     :name "Block scalar with more spaces than first content line"
     :yaml "empty block scalar: >
 
  
   
 # comment
"
     :json nil
     :fail t
     :tags "error folded comment scalar whitespace")
    (:id "S9E8"
     :name "Spec Example 5.3. Block Structure Indicators"
     :yaml "sequence:
- one
- two
mapping:
  ? sky
  : blue
  sea : green
"
     :json "\"{\\n  \\\"sequence\\\": [\\n    \\\"one\\\",\\n    \\\"two\\\"\\n  ],\\n  \\\"mapping\\\": {\\n    \\\"sky\\\": \\\"blue\\\",\\n    \\\"sea\\\": \\\"green\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "explicit-key spec mapping sequence")
    (:id "SBG9"
     :name "Flow Sequence in Flow Mapping"
     :yaml "{a: [b, c], [d, e]: f}
"
     :json nil
     :fail nil
     :tags "complex-key sequence mapping flow")
    (:id "SF5V"
     :name "Duplicate YAML directive"
     :yaml "%YAML 1.2
%YAML 1.2
---
"
     :json nil
     :fail t
     :tags "directive error")
    (:id "SKE5"
     :name "Anchor before zero indented sequence"
     :yaml "---
seq:
 &anchor
- a
- b
"
     :json "\"{\\n  \\\"seq\\\": [\\n    \\\"a\\\",\\n    \\\"b\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "anchor indent sequence")
    (:id "SM9W/00"
     :name "Single character streams"
     :yaml "-"
     :json "\"[null]\\n\""
     :fail nil
     :tags "sequence")
    (:id "SM9W/01"
     :name "SM9W/01"
     :yaml ":"
     :json nil
     :fail nil
     :tags "mapping")
    (:id "SR86"
     :name "Anchor plus Alias"
     :yaml "key1: &a value
key2: &b *a
"
     :json nil
     :fail t
     :tags "alias error")
    (:id "SSW6"
     :name "Spec Example 7.7. Single Quoted Characters [1.3]"
     :yaml "---
'here''s to \"quotes\"'
"
     :json "\"\\\"here's to \\\\\\\"quotes\\\\\\\"\\\"\\n\""
     :fail nil
     :tags "spec scalar single 1.3-mod")
    (:id "SU5Z"
     :name "Comment without whitespace after doublequoted scalar"
     :yaml "key: \"value\"# invalid comment
"
     :json nil
     :fail t
     :tags "comment error double whitespace")
    (:id "SU74"
     :name "Anchor and alias as mapping key"
     :yaml "key1: &alias value1
&b *alias : value2
"
     :json nil
     :fail t
     :tags "error anchor alias mapping")
    (:id "SY6V"
     :name "Anchor before sequence entry on same line"
     :yaml "&anchor - sequence entry
"
     :json nil
     :fail t
     :tags "anchor error sequence")
    (:id "SYW4"
     :name "Spec Example 2.2. Mapping Scalars to Scalars"
     :yaml "hr:  65    # Home runs
avg: 0.278 # Batting average
rbi: 147   # Runs Batted In
"
     :json "\"{\\n  \\\"hr\\\": 65,\\n  \\\"avg\\\": 0.278,\\n  \\\"rbi\\\": 147\\n}\\n\""
     :fail nil
     :tags "spec scalar comment")
    (:id "T26H"
     :name "Spec Example 8.8. Literal Content [1.3]"
     :yaml "--- |
 
  
  literal
   
  
  text

 # Comment
"
     :json "\"\\\"\\\\n\\\\nliteral\\\\n \\\\n\\\\ntext\\\\n\\\"\\n\""
     :fail nil
     :tags "spec literal scalar comment whitespace 1.3-mod")
    (:id "T4YY"
     :name "Spec Example 7.9. Single Quoted Lines [1.3]"
     :yaml "---
' 1st non-empty

 2nd non-empty 
 3rd non-empty '
"
     :json "\"\\\" 1st non-empty\\\\n2nd non-empty 3rd non-empty \\\"\\n\""
     :fail nil
     :tags "single spec scalar whitespace 1.3-mod")
    (:id "T5N4"
     :name "Spec Example 8.7. Literal Scalar [1.3]"
     :yaml "--- |
 literal
 	text


"
     :json "\"\\\"literal\\\\n\\\\ttext\\\\n\\\"\\n\""
     :fail nil
     :tags "spec literal scalar whitespace 1.3-mod")
    (:id "T833"
     :name "Flow mapping missing a separating comma"
     :yaml "---
{
 foo: 1
 bar: 2 }
"
     :json nil
     :fail t
     :tags "error flow mapping")
    (:id "TD5N"
     :name "Invalid scalar after sequence"
     :yaml "- item1
- item2
invalid
"
     :json nil
     :fail t
     :tags "error sequence scalar")
    (:id "TE2A"
     :name "Spec Example 8.16. Block Mappings"
     :yaml "block mapping:
 key: value
"
     :json "\"{\\n  \\\"block mapping\\\": {\\n    \\\"key\\\": \\\"value\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "spec mapping")
    (:id "TL85"
     :name "Spec Example 6.8. Flow Folding"
     :yaml "\"
  foo 
 
  	 bar

  baz
\"
"
     :json "\"\\\" foo\\\\nbar\\\\nbaz \\\"\\n\""
     :fail nil
     :tags "double spec whitespace scalar upto-1.2")
    (:id "TS54"
     :name "Folded Block Scalar"
     :yaml ">
 ab
 cd
 
 ef


 gh
"
     :json "\"\\\"ab cd\\\\nef\\\\n\\\\ngh\\\\n\\\"\\n\""
     :fail nil
     :tags "folded scalar 1.3-err")
    (:id "U3C3"
     :name "Spec Example 6.16. “TAG” directive"
     :yaml "%TAG !yaml! tag:yaml.org,2002:
---
!yaml!str \"foo\"
"
     :json "\"\\\"foo\\\"\\n\""
     :fail nil
     :tags "spec header tag")
    (:id "U3XV"
     :name "Node and Mapping Key Anchors"
     :yaml "---
top1: &node1
  &k1 key1: one
top2: &node2 # comment
  key2: two
top3:
  &k3 key3: three
top4:
  &node4
  &k4 key4: four
top5:
  &node5
  key5: five
top6: &val6
  six
top7:
  &val7 seven
"
     :json "\"{\\n  \\\"top1\\\": {\\n    \\\"key1\\\": \\\"one\\\"\\n  },\\n  \\\"top2\\\": {\\n    \\\"key2\\\": \\\"two\\\"\\n  },\\n  \\\"top3\\\": {\\n    \\\"key3\\\": \\\"three\\\"\\n  },\\n  \\\"top4\\\": {\\n    \\\"key4\\\": \\\"four\\\"\\n  },\\n  \\\"top5\\\": {\\n    \\\"key5\\\": \\\"five\\\"\\n  },\\n  \\\"top6\\\": \\\"six\\\",\\n  \\\"top7\\\": \\\"seven\\\"\\n}\\n\""
     :fail nil
     :tags "anchor comment 1.3-err")
    (:id "U44R"
     :name "Bad indentation in mapping (2)"
     :yaml "map:
  key1: \"quoted1\"
   key2: \"bad indentation\"
"
     :json nil
     :fail t
     :tags "error mapping indent double")
    (:id "U99R"
     :name "Invalid comma in tag"
     :yaml "- !!str, xxx
"
     :json nil
     :fail t
     :tags "error tag")
    (:id "U9NS"
     :name "Spec Example 2.8. Play by Play Feed from a Game"
     :yaml "---
time: 20:03:20
player: Sammy Sosa
action: strike (miss)
...
---
time: 20:03:47
player: Sammy Sosa
action: grand slam
...
"
     :json "\"{\\n  \\\"time\\\": \\\"20:03:20\\\",\\n  \\\"player\\\": \\\"Sammy Sosa\\\",\\n  \\\"action\\\": \\\"strike (miss)\\\"\\n}\\n{\\n  \\\"time\\\": \\\"20:03:47\\\",\\n  \\\"player\\\": \\\"Sammy Sosa\\\",\\n  \\\"action\\\": \\\"grand slam\\\"\\n}\\n\""
     :fail nil
     :tags "spec header")
    (:id "UDM2"
     :name "Plain URL in flow mapping"
     :yaml "- { url: http://example.org }
"
     :json "\"[\\n  {\\n    \\\"url\\\": \\\"http://example.org\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "flow scalar")
    (:id "UDR7"
     :name "Spec Example 5.4. Flow Collection Indicators"
     :yaml "sequence: [ one, two, ]
mapping: { sky: blue, sea: green }
"
     :json "\"{\\n  \\\"sequence\\\": [\\n    \\\"one\\\",\\n    \\\"two\\\"\\n  ],\\n  \\\"mapping\\\": {\\n    \\\"sky\\\": \\\"blue\\\",\\n    \\\"sea\\\": \\\"green\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "spec flow sequence mapping")
    (:id "UGM3"
     :name "Spec Example 2.27. Invoice"
     :yaml "--- !<tag:clarkevans.com,2002:invoice>
invoice: 34843
date   : 2001-01-23
bill-to: &id001
    given  : Chris
    family : Dumars
    address:
        lines: |
            458 Walkman Dr.
            Suite #292
        city    : Royal Oak
        state   : MI
        postal  : 48046
ship-to: *id001
product:
    - sku         : BL394D
      quantity    : 4
      description : Basketball
      price       : 450.00
    - sku         : BL4438H
      quantity    : 1
      description : Super Hoop
      price       : 2392.00
tax  : 251.42
total: 4443.52
comments:
    Late afternoon is best.
    Backup contact is Nancy
    Billsmer @ 338-4338.
"
     :json "\"{\\n  \\\"invoice\\\": 34843,\\n  \\\"date\\\": \\\"2001-01-23\\\",\\n  \\\"bill-to\\\": {\\n    \\\"given\\\": \\\"Chris\\\",\\n    \\\"family\\\": \\\"Dumars\\\",\\n    \\\"address\\\": {\\n      \\\"lines\\\": \\\"458 Walkman Dr.\\\\nSuite #292\\\\n\\\",\\n      \\\"city\\\": \\\"Royal Oak\\\",\\n      \\\"state\\\": \\\"MI\\\",\\n      \\\"postal\\\": 48046\\n    }\\n  },\\n  \\\"ship-to\\\": {\\n    \\\"given\\\": \\\"Chris\\\",\\n    \\\"family\\\": \\\"Dumars\\\",\\n    \\\"address\\\": {\\n      \\\"lines\\\": \\\"458 Walkman Dr.\\\\nSuite #292\\\\n\\\",\\n      \\\"city\\\": \\\"Royal Oak\\\",\\n      \\\"state\\\": \\\"MI\\\",\\n      \\\"postal\\\": 48046\\n    }\\n  },\\n  \\\"product\\\": [\\n    {\\n      \\\"sku\\\": \\\"BL394D\\\",\\n      \\\"quantity\\\": 4,\\n      \\\"description\\\": \\\"Basketball\\\",\\n      \\\"price\\\": 450\\n    },\\n    {\\n      \\\"sku\\\": \\\"BL4438H\\\",\\n      \\\"quantity\\\": 1,\\n      \\\"description\\\": \\\"Super Hoop\\\",\\n      \\\"price\\\": 2392\\n    }\\n  ],\\n  \\\"tax\\\": 251.42,\\n  \\\"total\\\": 4443.52,\\n  \\\"comments\\\": \\\"Late afternoon is best. Backup contact is Nancy Billsmer @ 338-4338.\\\"\\n}\\n\""
     :fail nil
     :tags "spec tag literal mapping sequence alias unknown-tag")
    (:id "UKK6/00"
     :name "Syntax character edge cases"
     :yaml "- :
"
     :json nil
     :fail nil
     :tags "edge empty-key")
    (:id "UKK6/01"
     :name "UKK6/01"
     :yaml "::
"
     :json "\"{\\n  \\\":\\\": null\\n}\\n\""
     :fail nil
     :tags "")
    (:id "UKK6/02"
     :name "UKK6/02"
     :yaml "!
"
     :json nil
     :fail nil
     :tags "")
    (:id "UT92"
     :name "Spec Example 9.4. Explicit Documents"
     :yaml "---
{ matches
% : 20 }
...
---
# Empty
...
"
     :json "\"{\\n  \\\"matches %\\\": 20\\n}\\nnull\\n\""
     :fail nil
     :tags "flow spec header footer comment")
    (:id "UV7Q"
     :name "Legal tab after indentation"
     :yaml "x:
 - x
  	x
"
     :json "\"{\\n  \\\"x\\\": [\\n    \\\"x x\\\"\\n  ]\\n}\\n\""
     :fail nil
     :tags "indent whitespace")
    (:id "V55R"
     :name "Aliases in Block Sequence"
     :yaml "- &a a
- &b b
- *a
- *b
"
     :json "\"[\\n  \\\"a\\\",\\n  \\\"b\\\",\\n  \\\"a\\\",\\n  \\\"b\\\"\\n]\\n\""
     :fail nil
     :tags "alias sequence")
    (:id "V9D5"
     :name "Spec Example 8.19. Compact Block Mappings"
     :yaml "- sun: yellow
- ? earth: blue
  : moon: white
"
     :json nil
     :fail nil
     :tags "complex-key explicit-key spec mapping")
    (:id "VJP3/00"
     :name "Flow collections over many lines"
     :yaml "k: {
k
:
v
}
"
     :json nil
     :fail t
     :tags "flow indent")
    (:id "VJP3/01"
     :name "VJP3/01"
     :yaml "k: {
 k
 :
 v
 }
"
     :json "\"{\\n  \\\"k\\\" : {\\n    \\\"k\\\" : \\\"v\\\"\\n  }\\n}\\n\""
     :fail nil
     :tags "")
    (:id "W42U"
     :name "Spec Example 8.15. Block Sequence Entry Types"
     :yaml "- # Empty
- |
 block node
- - one # Compact
  - two # sequence
- one: two # Compact mapping
"
     :json "\"[\\n  null,\\n  \\\"block node\\\\n\\\",\\n  [\\n    \\\"one\\\",\\n    \\\"two\\\"\\n  ],\\n  {\\n    \\\"one\\\": \\\"two\\\"\\n  }\\n]\\n\""
     :fail nil
     :tags "comment spec literal sequence")
    (:id "W4TN"
     :name "Spec Example 9.5. Directives Documents"
     :yaml "%YAML 1.2
--- |
%!PS-Adobe-2.0
...
%YAML 1.2
---
# Empty
...
"
     :json "\"\\\"%!PS-Adobe-2.0\\\\n\\\"\\nnull\\n\""
     :fail nil
     :tags "spec header footer 1.3-err")
    (:id "W5VH"
     :name "Allowed characters in alias"
     :yaml "a: &:@*!$\"<foo>: scalar a
b: *:@*!$\"<foo>:
"
     :json "\"{\\n  \\\"a\\\": \\\"scalar a\\\",\\n  \\\"b\\\": \\\"scalar a\\\"\\n}\\n\""
     :fail nil
     :tags "alias 1.3-err")
    (:id "W9L4"
     :name "Literal block scalar with more spaces in first line"
     :yaml "---
block scalar: |
     
  more spaces at the beginning
  are invalid
"
     :json nil
     :fail t
     :tags "error literal whitespace")
    (:id "WZ62"
     :name "Spec Example 7.2. Empty Content"
     :yaml "{
  foo : !!str,
  !!str : bar,
}
"
     :json "\"{\\n  \\\"foo\\\": \\\"\\\",\\n  \\\"\\\": \\\"bar\\\"\\n}\\n\""
     :fail nil
     :tags "spec flow scalar tag")
    (:id "X38W"
     :name "Aliases in Flow Objects"
     :yaml "{ &a [a, &b b]: *b, *a : [c, *b, d]}
"
     :json nil
     :fail nil
     :tags "alias complex-key flow")
    (:id "X4QW"
     :name "Comment without whitespace after block scalar indicator"
     :yaml "block: ># comment
  scalar
"
     :json nil
     :fail t
     :tags "folded comment error whitespace")
    (:id "X8DW"
     :name "Explicit key and value seperated by comment"
     :yaml "---
? key
# comment
: value
"
     :json "\"{\\n  \\\"key\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "comment explicit-key mapping")
    (:id "XLQ9"
     :name "Multiline scalar that looks like a YAML directive"
     :yaml "---
scalar
%YAML 1.2
"
     :json "\"\\\"scalar %YAML 1.2\\\"\\n\""
     :fail nil
     :tags "directive scalar")
    (:id "XV9V"
     :name "Spec Example 6.5. Empty Lines [1.3]"
     :yaml "Folding:
  \"Empty line

  as a line feed\"
Chomping: |
  Clipped empty lines
 

"
     :json "\"{\\n  \\\"Folding\\\": \\\"Empty line\\\\nas a line feed\\\",\\n  \\\"Chomping\\\": \\\"Clipped empty lines\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "literal spec scalar 1.3-mod")
    (:id "XW4D"
     :name "Various Trailing Comments"
     :yaml "a: \"double
  quotes\" # lala
b: plain
 value  # lala
c  : #lala
  d
? # lala
 - seq1
: # lala
 - #lala
  seq2
e:
 &node # lala
 - x: y
block: > # lala
  abcde
"
     :json nil
     :fail nil
     :tags "comment explicit-key folded 1.3-err")
    (:id "Y2GN"
     :name "Anchor with colon in the middle"
     :yaml "---
key: &an:chor value
"
     :json "\"{\\n  \\\"key\\\": \\\"value\\\"\\n}\\n\""
     :fail nil
     :tags "anchor")
    (:id "Y79Y/00"
     :name "Tabs in various contexts"
     :yaml "foo: |
	
bar: 1
"
     :json nil
     :fail t
     :tags "whitespace")
    (:id "Y79Y/01"
     :name "Y79Y/01"
     :yaml "foo: |
 	
bar: 1
"
     :json "\"{\\n  \\\"foo\\\": \\\"\\\\t\\\\n\\\",\\n  \\\"bar\\\": 1\\n}\\n\""
     :fail nil
     :tags "")
    (:id "Y79Y/02"
     :name "Y79Y/02"
     :yaml "- [
	
 foo
 ]
"
     :json "\"[\\n  [\\n    \\\"foo\\\"\\n  ]\\n]\\n\""
     :fail nil
     :tags "")
    (:id "Y79Y/03"
     :name "Y79Y/03"
     :yaml "- [
	foo,
 foo
 ]
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/04"
     :name "Y79Y/04"
     :yaml "-	-
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/05"
     :name "Y79Y/05"
     :yaml "- 	-
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/06"
     :name "Y79Y/06"
     :yaml "?	-
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/07"
     :name "Y79Y/07"
     :yaml "? -
:	-
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/08"
     :name "Y79Y/08"
     :yaml "?	key:
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/09"
     :name "Y79Y/09"
     :yaml "? key:
:	key:
"
     :json nil
     :fail t
     :tags "")
    (:id "Y79Y/10"
     :name "Y79Y/10"
     :yaml "-	-1
"
     :json "\"[\\n  -1\\n]\\n\""
     :fail nil
     :tags "")
    (:id "YD5X"
     :name "Spec Example 2.5. Sequence of Sequences"
     :yaml "- [name        , hr, avg  ]
- [Mark McGwire, 65, 0.278]
- [Sammy Sosa  , 63, 0.288]
"
     :json "\"[\\n  [\\n    \\\"name\\\",\\n    \\\"hr\\\",\\n    \\\"avg\\\"\\n  ],\\n  [\\n    \\\"Mark McGwire\\\",\\n    65,\\n    0.278\\n  ],\\n  [\\n    \\\"Sammy Sosa\\\",\\n    63,\\n    0.288\\n  ]\\n]\\n\""
     :fail nil
     :tags "spec sequence")
    (:id "YJV2"
     :name "Dash in flow sequence"
     :yaml "[-]
"
     :json nil
     :fail t
     :tags "flow sequence")
    (:id "Z67P"
     :name "Spec Example 8.21. Block Scalar Nodes [1.3]"
     :yaml "literal: |2
  value
folded: !foo >1
 value
"
     :json "\"{\\n  \\\"literal\\\": \\\"value\\\\n\\\",\\n  \\\"folded\\\": \\\"value\\\\n\\\"\\n}\\n\""
     :fail nil
     :tags "indent spec literal folded tag local-tag 1.3-mod")
    (:id "Z9M4"
     :name "Spec Example 6.22. Global Tag Prefix"
     :yaml "%TAG !e! tag:example.com,2000:app/
---
- !e!foo \"bar\"
"
     :json "\"[\\n  \\\"bar\\\"\\n]\\n\""
     :fail nil
     :tags "spec header tag unknown-tag")
    (:id "ZCZ6"
     :name "Invalid mapping in plain single line value"
     :yaml "a: b: c: d
"
     :json nil
     :fail t
     :tags "error mapping scalar")
    (:id "ZF4X"
     :name "Spec Example 2.6. Mapping of Mappings"
     :yaml "Mark McGwire: {hr: 65, avg: 0.278}
Sammy Sosa: {
    hr: 63,
    avg: 0.288
  }
"
     :json "\"{\\n  \\\"Mark McGwire\\\": {\\n    \\\"hr\\\": 65,\\n    \\\"avg\\\": 0.278\\n  },\\n  \\\"Sammy Sosa\\\": {\\n    \\\"hr\\\": 63,\\n    \\\"avg\\\": 0.288\\n  }\\n}\\n\""
     :fail nil
     :tags "flow spec mapping")
    (:id "ZH7C"
     :name "Anchors in Mapping"
     :yaml "&a a: b
c: &d d
"
     :json "\"{\\n  \\\"a\\\": \\\"b\\\",\\n  \\\"c\\\": \\\"d\\\"\\n}\\n\""
     :fail nil
     :tags "anchor mapping")
    (:id "ZK9H"
     :name "Nested top level flow mapping"
     :yaml "{ key: [[[
  value
 ]]]
}
"
     :json "\"{\\n  \\\"key\\\": [\\n    [\\n      [\\n        \\\"value\\\"\\n      ]\\n    ]\\n  ]\\n}\\n\""
     :fail nil
     :tags "flow indent mapping sequence")
    (:id "ZL4Z"
     :name "Invalid nested mapping"
     :yaml "---
a: 'b': c
"
     :json nil
     :fail t
     :tags "error mapping")
    (:id "ZVH3"
     :name "Wrong indented sequence item"
     :yaml "- key: value
 - item1
"
     :json nil
     :fail t
     :tags "error sequence indent")
    (:id "ZWK4"
     :name "Key with anchor after missing explicit mapping value"
     :yaml "---
a: 1
? b
&anchor c: 3
"
     :json "\"{\\n  \\\"a\\\": 1,\\n  \\\"b\\\": null,\\n  \\\"c\\\": 3\\n}\\n\""
     :fail nil
     :tags "anchor explicit-key mapping")
    (:id "ZXT5"
     :name "Implicit key followed by newline and adjacent value"
     :yaml "[ \"key\"
  :value ]
"
     :json nil
     :fail t
     :tags "error flow mapping sequence")
    (:id "ZYU8/00"
     :name "Directive variants"
     :yaml "%YAML1.1
---
"
     :json "\"null\\n\""
     :fail nil
     :tags "directive")
    (:id "ZYU8/01"
     :name "ZYU8/01"
     :yaml "%***
---
"
     :json nil
     :fail nil
     :tags "")
    (:id "ZYU8/02"
     :name "ZYU8/02"
     :yaml "%YAML 1.1 1.2
---
"
     :json nil
     :fail nil
     :tags "")
    (:id "ZYU8/03"
     :name "ZYU8/03"
     :yaml "%YAML 1.12345
---
"
     :json nil
     :fail nil
     :tags "")
    )
  "Conformance test cases from yaml-test-suite.")

;; Total: 406 test cases
;; Expected failures: 94
