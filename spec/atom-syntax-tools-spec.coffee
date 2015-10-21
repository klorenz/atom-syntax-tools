{makeGrammar, makeRegexFromWords} = require '../lib/atom-syntax-tools.coffee'

describe "Atom Syntax Tools", ->

  describe "when you use macros in regexes", ->
    inputGrammar =
      scopeName: "source.my-grammar-1"
      macros:
        nested_item: /{ident}\[{item_getter}\]/
        ident: /[a-zA-Z_]\w*/
        digits: /\d+/
        item_getter: /(?:{digits}|{ident})/
        ignoreCase: /foo/i

      patterns: [
        { match: /// {ident} /// }
        { match: /// {nested_item} /// }
      ]

    it "expands simple macros", ->
      g = makeGrammar inputGrammar
      expect(g.patterns[0].match).toBe("[a-zA-Z_]\\w*")

    it "expands nested macros", ->
      g = makeGrammar inputGrammar
      expect(g.patterns[1].match).toBe("[a-zA-Z_]\\w*\\[(?:\\d+|[a-zA-Z_]\\w*)\\]")

    it "can handle ignore case", ->
      g = makeGrammar inputGrammar
      expect(g.macros['ignoreCase']).toBe("(?i)foo")

  describe "makeRegexFromWords", ->

    it "can make regexes from words 1", ->
      expect(makeRegexFromWords "STDIN", "STDOUT", "STDERR").toBe(/STD(?:ERR|IN|OUT)/.source)

    it "can make regexes from words 2", ->
      expect(makeRegexFromWords ["STDIN", "STDINOUT", "STDERR"]).toBe(/STD(?:ERR|IN(?:OUT)?)/.source)

    it "can make regexes from words 3", ->
      expect(makeRegexFromWords ["STDIN", "STDINOUT", "STDINERR", "STDERR"]).toBe(/STD(?:ERR|IN(?:ERR|OUT)?)/.source)

    it "can make regexes from words 4", ->
      expect(makeRegexFromWords ["STDIN", "STDINOUT", "STDINERR", "xTDERR"]).toBe(/(?:STDIN(?:ERR|OUT)?|xTDERR)/.source)

    it "can make regexes from words 5", ->
      expect(makeRegexFromWords ["STDIN"]).toBe('STDIN')

    it "can make regexes from words 6", ->
      expect(makeRegexFromWords []).toBe('')



  describe "when you want to keep your grammar short", ->

    inputGrammar =
      scopeName: "source.my-grammar"

      patterns: [
        "#block"
        {i: "#another-one"}
      ]

      repository:
        block:
          n: "string.quoted.double.my-grammar"
          N: "constant.character.escape.my-grammar"
          b: /// begin here ///
          c: { 1: "hello" }
          e: /// end here ///
          C: { 2: "world" }
          p: [ "#match" ]

        match:
          m: /// match ///
          c: { 1: "hello world" }

        one_more_block:
          p: "#match"

    it "lets you abbreviate name with n", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].name).toBe("string.quoted.double.my-grammar")

    it "lets you abbreviate contentName with N", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].contentName).toBe("constant.character.escape.my-grammar")

    it "lets you abbreviate begin with b", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].begin).toBe("beginhere")

    it "lets you use an (include) string as pattern", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].patterns).toEqual([ {include: "#match"} ])

    it "lets you abbreviate end with e", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].end).toBe("endhere")

    it "lets you abbreviate beginCaptures with c, if you used begin regex", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].beginCaptures).toEqual {1: { "name": "hello.my-grammar"} }

    it "lets you abbreviate endCaptures with C", ->
      g = makeGrammar inputGrammar
      expect(g.repository.block.patterns[0].endCaptures).toEqual {2: { name: "world.my-grammar"} }

    it "lets you use a string instead of object with include key", ->
      g = makeGrammar inputGrammar
      expect(g.patterns[0]).toEqual {include: "#block"}

    it "lets you abbreviate include with i", ->
      g = makeGrammar inputGrammar
      expect(g.patterns[1].include).toBe "#another-one"

    it "lets you abbreviate match with m", ->
      g = makeGrammar inputGrammar
      expect(g.repository.match.patterns[0].match).toBe "match"

    it "lets you abbreviate captures for match with c", ->
      g = makeGrammar inputGrammar
      expect(g.repository.match.patterns[0].captures).toEqual {1: {name: "hello world.my-grammar"}}
