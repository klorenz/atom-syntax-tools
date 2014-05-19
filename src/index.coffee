make_regex = (regex, macros) ->
  if regex instanceof RegExp
    regex = regex.source

  regex.replace /// \{(\w+)\} ///g, (mob) ->
    if macros[mob[1]]?
      macros[mob[1]]
    else
      mob[0]

# Transforms an easy grammar specification object into a tmLanguage grammar
# specification object.
#
# n -> name
# N -> contentName
# p -> patterns
# i -> include
# m -> match
# b -> begin
# e -> end
# c -> captures/beginCaptures
# C -> endCaptures
# x -> extendedContext
#
make_pattern = (pattern, macros) ->
  pat = pattern
  P   = {}

  if typeof pattern == "string"
    P.include = pattern
    P

  for k,v of pat
    switch k
      when "n", "name"
        P.name = pat[k]
      when "N", "contentName"
        P.contentName = pat[k]
      when "i", "include"
        P.include     = pat[k]
      when "m", "match"
        P.match       = make_regex(pat[k], macros)
      when "b", "begin"
         P.begin      = make_regex(pat[k], macros)
      when "e", "end"
         P.end        = make_regex(pat[k], macros)
      when "x", "extendedContext"
        P.extendedContext = pat[k]

      when "c", "captures", "beginCaptures"
        if P.begin?
          P.beginCaptures = c = {}
        else
          P.captures = c = {}
        for k,v of pat[k]
          c[k] = make_pattern(v, macros)

      when "C", "endCaptures"
        P.endCaptures = c = {}
        for k,v of pat[k]
          c[k] = make_pattern(v, macros)

      when "p", "patterns"
        P.patterns = make_pattern(p, macros) for p in pat[k]

  P


# Transforms an easy grammar specification object into a tmLanguage grammar
# specification object.
makeGrammar = (grammar, print = false) ->
  G = {}
  for n in [ "comment", "fileTypes", "firstLineMatch", "keyEquivalent", "name" ]
    if grammar[n]?
      G[n] = grammar[n]

  # resolve macros
  macros = if grammar.macros? then grammar.macros else {}
  for k,v of macros
    macros[k] = make_regex(v,macros)

  loop
    all_done = true
    for k,v of macros
      macros[k] = make_regex(v,macros)

      if /\{[a-zA-Z_]\w*\}/.test(macros[k])
        all_done = false
        if v == macros[k]
          throw "unresolved macro in #{v}"

    if all_done
      break

  for k,v in make_pattern(grammar)
    G[k] = v

  if grammar.repository?
    G.repository = {}
    for k,v of grammar.repository
      G.repository[k] = make_pattern(v, macros)

  if print
    if print == "CSON"
      CSON = require "CSON"
      process.stdout.write CSON.stringify(G)
    else
      process.stdout.write JSON.stringify(G, null, "    ")

  G

module.exports = makeGrammar
