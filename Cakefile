{spawn, exec} = require 'child_process'

build = (cb) ->
  run ['-c', '-o', '.', 'src/index.coffee'], cb

run = (args, cb) ->
  proc = spawn "node", ["/usr/local/bin/coffee"].concat args
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

task "build", "build syntax tools", build
