{spawn, exec} = require 'child_process'
path = require 'path'

node = process.argv[0]

run = (args, cb) ->
  coffee = fs.resolve('node_modules/.bin', '/usr/local/bin', '/usr/bin')
  
  proc = spawn node, [ coffee ].concat args
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

run_test = (node) ->
  jasmine = spawn node, [
    # '--harmony_collections'
    "node_modules/.bin/jasmine-focused"
    '--coffee'
    '--captureExceptions'
    'spec'
  ]
  jasmine.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  jasmine.stdout.on 'data', (data) ->
    process.stdout.write data.toString()
  jasmine.on 'exit', (code) ->
    callback?() if code is 0

task "test", "run test specs", ->
  run_test node

task "debug", "run test specs in debug mode", ->
  run_test "#{node}-debug"

task "build", "build syntax tools", ->
  for file in fs.readdirSync "src"
    if /\.coffee$/.test(file)
      run ['-c', '-o', 'lib', 'src/#{file}']
