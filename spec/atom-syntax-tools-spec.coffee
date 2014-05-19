makeGrammar = require '../index.js'

describe "Atom Syntax Tools", ->

  inputGrammar =

    macros:
      openers:            /"'\(\<\[\{/
      closers:            /"'\)\>\]\}/
      delimiters:         /\-\/\:=\+\*/
      closing_delimiters: /\.\,\;\!\?/
      hws:                /[\t\x{00000020}]/
      section_char:       /[=\-`:.'"~^_*+\#]/
      indent:             /{hws}*/

    patterns: [
      "#block"
    ]

    repository:
      block:
        n: 'meta.block.restructuredtext'
        b: /^(?=({hws}*))/
        e: /^(?!($|\1))/
        p: [
          '#headline'
          '#directive'
          '#parameter'
        ]

      headline:
        x: on
        n: scope 'markup.heading.headline'
        m: /// ({indent}) (.*)\n \1 ((section_char)\2+)\n ///
        c:
          1:
            n: scope 'e.n.section'
            p: '#inline'
          2:
            n: scope 'kw.op.section'

      headline_with_overline:
        x: on
        n: scope 'markup.heading.headline'
        m: /// ({indent}) ((section_char)\3+) \n \1 (.*)\n \1 (\2) \n ///
        c:   # 1          23                        4         5
          2:
            n: scope 'kw.op.section'
          4:
            n: scope 'e.n.section'
            p: '#inline'
          5:
            n: scope 'kw.op.section'

      directive:
        x: on
        n: scope 'meta.block.directive'
        b: /// ({indent}) (\.\.) {hws} ({ident}) (::)
             # 1          2            3
             # argument
               ( (?:{hws}.+\n|\n)   # first line
                 (?: (?=(\1{hws}+)) # 5 indentation lookahead
                     (?: \5 (?!:{ident}:) .+\n)*))
             # 4
             # keyword arguments
           ///
        c:
          2: n: scope 'kw.op.directive'
          3: n: scope 'kw.directive'
          4: n: scope 'string.other.directive.argument'

        e: /// (?!($|\1{hws})) ///

        p: [
          '#keywordarg'
        ]

  it "lets you use macros in regexes", ->
    grammar = makeGrammar inputGrammar
    grammar.
