{spawn, exec} = require 'child_process'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'
option '-w', '--watch', 'continually build the docas library'
option '-a', '--auth [AUTH]', 'specify basic authentication when install'

task 'build', 'build the docco library', (options) ->
  exec [
    'coffee ' + ['-c' + (if options.watch then 'w' else ''), '-o', 'lib', 'src'].join(' ')
    'java -jar ~/compiler.jar --js lib/index.js --js_output_file lib/index.min.js' # && rm lib/index.js'
    'cleancss -o resources/index.min.css resources/index.css'
    'cleancss -o resources/docco.min.css resources/docco.css'
  ].join(' && '), (err, stdout, stderr) ->
    console.error stderr if err

  # coffee.stdout.on 'data', (data) -> console.log data.toString()
  # coffee.stderr.on 'data', (data) -> console.error data.toString()

task 'install', 'install the `docco`, `docci`, `doccx`, and `docas` command into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib  = base + '/lib/docas'
  exec([
    "echo #{options.auth} > /usr/local/lib/docas/auth"
    'mkdir -p ' + lib
    'cp -rf bin resources vendor lib ' + lib
    'ln -sf ' + lib + '/bin/docco ' + base + '/bin/docco'
    'ln -sf ' + lib + '/bin/docci ' + base + '/bin/docci'
    'ln -sf ' + lib + '/bin/doccx ' + base + '/bin/doccx'
    'ln -sf ' + lib + '/bin/docas ' + base + '/bin/docas'
  ].join(' && '), (err, stdout, stderr) ->
    console.error stderr if err
  )
