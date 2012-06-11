{spawn, exec} = require 'child_process'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'
option '-w', '--watch', 'continually build the docas library'
option '-a', '--auth [AUTH]', 'specify basic authentication when install'

task 'build', 'build the docco library', (options) ->
  exec [
    'coffee ' + ['-c' + (if options.watch then 'w' else ''), '-o', 'lib', 'src'].join(' ')
    'coffee -cj lib/client/index.js src/shared/parse.coffee src/client/index.coffee'
    'coffee -cj lib/client/docco.js src/shared/parse.coffee src/client/docco.coffee'
    'java -jar ~/compiler.jar --js lib/client/index.js --js_output_file lib/client/index.min.js'
    'java -jar ~/compiler.jar --js lib/client/docco.js --js_output_file lib/client/docco.min.js'
    'cleancss -o resources/index.min.css resources/index.css'
    'cleancss -o resources/docco.min.css resources/docco.css'
  ].join(' && '), (err, stdout, stderr) ->
    console.error stderr if err

task 'install', 'install the `docco`, `docci`, `doccx`, and `docas` command into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib  = base + '/lib/docas'
  exec([
    "echo #{options.auth} > /usr/local/lib/docas/auth"
    'mkdir -p ' + lib
    'cp -rf bin resources vendor lib src ' + lib
    'ln -sf ' + lib + '/bin/docco ' + base + '/bin/docco'
    'ln -sf ' + lib + '/bin/docci ' + base + '/bin/docci'
    'ln -sf ' + lib + '/bin/doccx ' + base + '/bin/doccx'
    'ln -sf ' + lib + '/bin/docas ' + base + '/bin/docas'
  ].join(' && '), (err, stdout, stderr) ->
    console.error stderr if err
  )
