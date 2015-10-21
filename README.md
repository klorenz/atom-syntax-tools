atom-syntax-tools
=================

Tools for easier language grammar specification for atom editor.

- This tool lets you define grammar in a coffeescript file and takes the input
  cson, and generates a full grammar cson.

- Make use of syntax highlighting of javascript regular expressions, which
  will be used as Oniguruma Regexes.  This way you do not need escape too
  much.

- make use of macros in scopenames and regexes

- grammar scopename is autoappended to scopenames

- you can shortcut the keys like follows:

  | shortcut |          name          |
  | :------: | ---------------------- |
  |    n     | name                   |
  |    N     | contentName            |
  |    p     | patterns               |
  |    i     | include                |
  |    I     | injections             |
  |    m     | match                  |
  |    b     | begin                  |
  |    e     | end                    |
  |    c     | captures/beginCaptures |
  |    C     | endCaptures            |
  |    L     | applyEndPatternLast    |


Here a little example, how to produce `json.cson` file:

```coffeescript
{makeGrammar, rule} = require('atom-syntax-tools')

grammar =
  name: "JSON"
  scopeName: "source.json"
  keyEquivalent: "^~J"
  fileTypes: [ "json" ]

  macros:
    # for demonstartion purpose, how to use regexes as macros
    hexdigit: /[0-9a-fA-F]/
    en: "entity.name"
    pd: "punctuation.definition"
    ps: "punctuation.separator"
    ii: "invalid.illegal"

  patterns: [
    "#value"
  ]

  repository:
    array:
      n: "meta.structure.array"
      b: /\[/
      c: "{pd}.array.begin"
      e: /\]/
      C: "{pd}.array.end"
      p: [
        "#value"

        rule
          m: /,/
          n: "{ps}.array"

        rule
          m: /[^\s\]]/
          n: "{ii}.expected-array-separator"

      ]
    constant:
      n: "constant.language"
      m: /\b(?:true|false|null)\b/
    number:
      # this comment is just for demonstration, you will rather use
      # normal coffee comments
      comment: "handles integer and decimal numbers"
      n: "constant.numeric"
      # This multiline match with be boiled down into a single linen regular
      # expression. See http://coffeescript.org
      m: ///
        -?        # an optional minus
        (?:
          0       # a zero
        |         # ...or...
          [1-9]   # a 1-9 character
          \d*     # followed by zero or more digits
        )
        (?:       # optional decimal portion
          (?:
            \.    # a period
            \d+   # followed by one or more digits
          )?
          (?:
            [eE]  # an e character
            [+-]? # followed by an optional +/-
            \d+   # followed by one of more digits
          )?      # make exponent optional
        )? ///

    object:
      # "a JSON object"
      n: "meta.structure.dictionary"
      b: /\{/
      c: "{pd}.dictionary.begin"
      e: /\}/
      C: "{pd}.dictionary.end"
      p: [
        "#string"   # JSON object key

        rule
          b: /:/
          c: "{ps}.dictionary.key-value"
          e: /(,)|(?=\})/
          C:
            1: "{ps}.dictionary.pair"
          n: "meta.structure.dictionary.value"
          p: [
            "#value" # JSON object value
            rule m: /[^\s,]/, n: "{ii}.expected-dictionary-separator"
          ]

        rule
          m: /[^\s\}]/
          n: "{ii}.expected-dictionary-separator"

      ]
    string:
      b: /"/
      c: "{pd}.string.begin"
      e: /"/
      C: "{pd}.definition.string.end"
      n: "string.quoted.double"
      p: [
        rule
          n: "constant.character.escape"
          m: ///
            \\               # literal backslash
            (?:              # ...followed by...
              ["\\/bfnrt]    # one of these characters
              |              # ...or...
              u              # a u
              {hexdigit}{4}  # and four hex digits
            ) ///
        rule
          m: /\\./
          n: "{ii}.unrecognized-string-escape"
        }
      ]
    value: [     # the 'value' diagram at http://json.org
      "#constant"
      "#number"
      "#string"
      "#array"
      "#object"
    ]

makeGrammar grammar, "CSON"
```

Then run your script with `coffee grammar-json.coffee > json.cson`

Or create grammar directly with
```coffeescript
    {CompositeDisposable} = require 'atom'
    subscriptions = new CompositeDisposable
    subscriptions.add atom.grammars.createGrammar __filename, makeGrammar grammar
```

Here an example for a package code for a complete dynamical managed grammar:

```coffeescript
{CompositeDisposable} = require 'atom'
grammar = require './my-grammar.coffee'

module.exports =
  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.grammars.createGrammar __filename, makeGrammar grammar

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
```

Functions exported
------------------

``makeGrammar grammar, [format | path]``
  Create and return a grammar object from input grammar `grammar`.  If format
  given print a `CSON` or `JSON` string to STDOUT, if `path` given, write
  grammar to file.  It can be a `.json` or `.cson` file.

``makeWords {string | list}...``
  This will split all given strings at whitespace and return a list of strings.
  Given lists are taken returned unchanged

``rule obj``, ``makeRule obj``
  Return the obj. This is a convenience method for nicer separating rules in
  pattern lists.

``makeRegexFromWords {string | list}...``
  arguments are processed by ``makeWords()``.  Then there is created an optimized
  regex from it like in following example:
  ```coffeescript
  makeRegexFromWords """
    STDIN
    STDOUT
    STDERR
  """
  # returns "STD(?:ERR|IN|OUT)"

  makeRegexFromWords """
    STDIN
    STDINOUT
    STDERR
    .OTHER
  """
  # returns "(?:STD(?:ERR|IN(?:OUT)?)|\\.OTHER)"
  ```
