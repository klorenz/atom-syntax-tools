"""
$ curl https://raw.githubusercontent.com/twilson63/cakefile-template/master/Cakefile > ../Cakefile

$ cd .. && coffee -c -o lib src/main.coffee
$ cd .. && npm version minor
$ cd .. && git comm
$ cd .. && cake build

$ npm install --save underscore
  underscore@1.8.3 ../node_modules/underscore

"""

{uniq} = require "underscore"


resolveRegexp = (r) ->
  s = r
  if r instanceof RegExp
    s = r.source.replace /\\\//g, "/"
    flags = ''
    if r.ignoreCase
      flags += 'i'
    if r.multiline
      flags += 'm'
    if flags
      s = "(?#{flags})#{s}"

  return s

# http://stackoverflow.com/questions/1916218/find-the-longest-common-starting-substring-in-a-set-of-stringshttp://stackoverflow.com/questions/1916218/find-the-longest-common-starting-substring-in-a-set-of-strings

# get sorted words
sharedStart = (words) ->
  w1 = words[0]
  w2 = words[words.length-1]
  L  = w1.length
  i  = 0

  while i < L && w1.charAt(i) == w2.charAt(i)
    i++

  w1[...i]


makeRegexFromWords = (wordlists...) ->
  all_words = []

  all_words = makeWords wordlists...

  # for words in wordlists
  #   if words not instanceof Array
  #     words = makeWords
  #   for w in words
  #     all_words.push w

  _makeRegexFromWords = (prefix_words) ->
    #debugger

    other_words = []

    return [] unless prefix_words.length

    # TODO: make this divide and conquer
    c = prefix_words[0][0]
    j = prefix_words.length-1
    range = j
    while true
      range = Math.ceil(range/2)

      if prefix_words[j][0] == c
        if j+1 == prefix_words.length
          break

        if prefix_words[j+1][0] != c
          other_words = prefix_words[j+1...]
          prefix_words = prefix_words[..j]
          break

        j += range

      if prefix_words[j][0] != c
        j -= range
        j = 0 if j < 0

    result = []

    if prefix_words.length == 1
      result = [ prefix_words[0] ]
    else
      prefix = sharedStart prefix_words
      suffixes = (w[prefix.length...] for w in prefix_words)

      is_optional = false
      if '' in suffixes
        is_optional = true
        suffixes.splice(suffixes.indexOf(''), 1)

      result = prefix
      if suffixes.length
        result += "(?:"+_makeRegexFromWords(suffixes).join("|")+")"
        if is_optional
          result += "?"
      else
        if is_optional
          result = "(?:#{result})?"

      result = [ result ]

    if other_words.length
      for r in _makeRegexFromWords other_words
        result.push r

    return result

  all_words.sort()
  all_words = (w.replace(/\W/, '\\$1') for w in uniq all_words)

  result = _makeRegexFromWords(all_words)

  if result.length == 1
    return result[0]

  if result.length == 0
    return ''

  return "(?:" +  result.join("|") + ")"


# Transforms an easy grammar specification object into a tmLanguage grammar
# specification object.
class GrammarCreator
  constructor: (@grammar, @print = false) ->

  process: ->
    grammar = @grammar
    print = @print
    G = {}

    for n in [ "comment", "fileTypes", "firstLineMatch", "keyEquivalent",
      "name", "scopeName", "injectionSelector", 'injections',
      'foldingStartMarker', 'foldingStopMarker'
      ]
      G[n] = grammar[n] if grammar[n]?

    {@autoAppendScopeName, @macros} = grammar

    @autoAppendScopeName = true if typeof @autoAppendScopeName is "undefined"
    @macros = {} if typeof @macros is "undefined"
    @grammarScopeName = G.scopeName.replace /.*\./, ''

    @hasGrammarScopeName = new RegExp "\\.#{@grammarScopeName}$"

    macros = @macros

    # make regexes to strings
    for k,v of macros
      macros[k] = resolveRegexp(v)

    # resolve macros
    for k,v of macros
      macros[k] = @resolveMacros(v)

    loop
      all_done = true
      for k,v of macros
        macros[k] = @resolveMacros(v)

        if m = macros[k].match /\{[a-zA-Z_]\w*\}/g
          _count = m.length
          if m = macros[k].match /\\x\{[a-f0-9A-F]+\}/g
            _charrefs = m.length
          else
            _charrefs = 0

          if _count - _charrefs > 0
            all_done = false
            if v == macros[k]
              throw "unresolved macro in #{v}"

      if all_done
        break

    name = grammar['name']
    for k,v of @makePattern(grammar, skipInjections: true)
      G[k] = v

    G['name'] = name

    if grammar.repository?
      G.repository = @makeRepository grammar.repository

    if grammar.injections?
      G.injections = @makeInjections grammar.injections

    if 'macros' of G
      delete G.macros

    # resolve final macros
    for k,v of G
      if v instanceof RegExp or typeof v is 'string'
        G[k] = @resolveMacros(v)

    if print
      if print.match /\.cson$/
        CSON = require "season"
        fs   = require "fs"

        fs.writeFileSync print, CSON.stringify(G)

      else if print.match /\.json$/
        fs.writeFileSync print, JSON.stringify(G, null, "    ")

      else if print == "CSON"
        CSON = require "season"
        process.stdout.write CSON.stringify(G)

      else
        process.stdout.write JSON.stringify(G, null, "    ")

    G

  resolveMacros: (regex) ->
    regex = resolveRegexp(regex)

    macros = @macros

    regex.replace /// \{\w+\} ///g, (mob) ->
      s = mob[1...-1]

      if typeof macros[s] isnt "undefined"
        macros[s]
      else
        mob

  makeScopeName: (name) ->
    name = @resolveMacros(name)
    if @autoAppendScopeName
      unless @hasGrammarScopeName.test(name)
        return "#{name}.#{@grammarScopeName}"

    name


  makeInjections: (injections) ->
    result = {}
    for k,v of injections
      pats = @makePattern(v, @macros)
      if pats.begin? or pats.match?
        pats = { "patterns": [ pats ] }
      else if pats instanceof Array
        pats = { "patterns": pats }

      result[k.replace(/\s+/g, ' ')] = pats
    result

  makeRepository: (repository) ->
    result = {}
    for k,v of repository
      pats = @makePattern(v, @macros)
      if pats.begin? or pats.match?
        pats = { "patterns": [ pats ] }
      else if pats instanceof Array
        pats = { "patterns": pats }

      result[k] = pats
    result

  # Transforms an easy grammar specification object into a tmLanguage grammar
  # specification object.
  #
  # n -> name
  # N -> contentName
  # p -> patterns
  # i -> include
  # I -> injections
  # R -> repository
  # m -> match
  # b -> begin
  # e -> end
  # c -> captures/beginCaptures
  # C -> endCaptures
  # L -> applyEndPatternLast
  #
  makePattern: (pattern, opts={}) ->
    pat = pattern
    P   = {}

    if typeof pattern == "string"
      P.include = pattern
      return P

    if pattern instanceof Array
      return (@makePattern(p) for p in pattern)

    for k,v of pat
      switch k
        when "N", "contentName"
          P.contentName = @makeScopeName(v)
        when "i", "include"
          P.include = v
        when "n", "name"
          P.name  = @makeScopeName(v)
        when "m", "match"
          P.match = @resolveMacros(v)
        when "b", "begin"
          P.begin = @resolveMacros(v)
        when "e", "end"
          P.end   = @resolveMacros(v)
        when "I", "injections"
          unless opts.skipInjections
            P.injections = @makeInjections(v)

        when "R", "repository"
          P.repository = @makeRepository(v)

        when "c", "captures", "beginCaptures"
          if P.begin?
            P.beginCaptures = c = {}
          else
            P.captures = c = {}

          if typeof v == "string"
            c[0] = { name: @makeScopeName(v) }
          else if v instanceof Array
            c[0] = { patterns: @makePattern(v) }
          else
            for ck,cv of v
              if typeof cv isnt "string"
                c[ck] = @makePattern(cv)
              else
                c[ck] = { name: @makeScopeName(cv) }

        when "C", "endCaptures"
          P.endCaptures = c = {}
          if typeof v == "string"
            c[0] = { name: @makeScopeName(v) }
          else if v instanceof Array
            c[0] = { patterns: @makePattern(v) }
          else
            for ck,cv of v
              if typeof cv is "string"
                c[ck] = { name: @makeScopeName(cv) }
              else if cv instanceof Array
                c[ck] = { patterns: @makePattern(cv) }
              else
                c[ck] = @makePattern(cv)

        when "p", "patterns"
          unless v instanceof Array
            v = [ v ]
          P.patterns = (@makePattern(p) for p in v)

        when "L", "applyEndPatternLast"
          P.applyEndPatternLast = v

        else
          P[k] = v

    P

makeWords = (strings...) ->
  words = []
  for s in strings
    if s instanceof Array
      words.push s...
    else
      for w in s.trim().split /\s+/
        words.push w

  return words

makeGrammar = (grammar, print = false) ->
  r = (new GrammarCreator grammar, print).process()
  r

# {Grammar} = require 'first-mate'

createGrammar = (filename, grammar) ->
  atom.grammars.createGrammar filename, makeGrammar grammar

makeRule = rule = (opts) -> opts

module.exports = {makeGrammar, createGrammar, makeRegexFromWords, makeWords, rule, makeRule}
