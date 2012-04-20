# **Docci** generates a simple cover page for each repository, helping users
# take a quick glance at the project. 
# The generated cover page contains following components:
#
#     1. A stats of languages and source lines of code.
#     2. Log of recent changes.
#     3. A GitHub-style file browser which can take you to the documentation
#        of that file.
#     4. Last but not least, everything in your README.md file.
#     
# Since the input for generating the cover page is the whole project, you should
# invoke it from the command-line as:
#
#     docci path_to_your_repository
#
# ...will generate an HTML documentation page for the repository., 
#
# The [source for Docci](http://github.com/baoshan/docas) is available on GitHub,
# and released under the MIT license.
#
# Docco can be used to process any languages recognized by Linguist.
#

#### Main Documentation Generation Functions

# Once all of the code is finished highlighting, we can generate the HTML file
# and write out the documentation. Pass the completed sections into the template
# found in `resources/docci.jst`
generate_index = (dirname, dest) ->
  generate_statistics dirname, (err, data) ->
    statistics = data
    generate_log dirname, (err, data) ->
      log = data
      generate_tree dirname, (err, data) ->
        tree = data
        readme = dirname + '/README.md'
        readme = if path.existsSync(readme) and fs.statSync(readme).isFile() then showdown.makeHtml fs.readFileSync(readme).toString() else ''
        html = index_template {
          title: "title", subtitle: "subtitle", statistics: statistics, log: log, readme: readme, tree: tree, opts: process.OPTS
        }
        fs.writeFile dest, html, (err) ->
          throw err if err
          console.log "docci: #{dest} generated."

# Get the current language we're documenting, based on the extension.
get_language = (source) -> languages[path.extname(source)]

generate_statistics = (dir, callback) ->
  data = fs.readFileSync(dir + '/../stats').toString()
  # exec "wget -qO- http://127.0.0.1:4567/stat#{dir}", (err, data) ->
  #callback err, data if err
  data = data.split '\n'
  data.pop()
  for line, i in data
    data[i] = []
    for item in line.split ' '
      data[i].push "<span>#{item}</span>" if item
      data[i].push "&nbsp;"
    data[i] = data[i].join ''
  callback null, data

generate_log = (path, callback) ->
  exec 'git log -5 --format="%aD, %an, %s"', {cwd: path}, (err, data) ->
    data = data.split '\n'
    data.pop()
    for log, i in data
      pos0 = log.indexOf ',', 4
      date = log.substr 0, pos0
      pos1 = log.indexOf ',', pos0 + 1
      author = log.substring pos0 + 2, pos1
      subject = log.substr pos1 + 2
      data[i] = {date: date, author: author, subject: subject}
    callback null, data

generate_tree = (path, callback) ->
  result = []
  fs.readdir path, (err, files) ->
    return callback err, files if err
    i = 0
    next = ->
      file = files[i++]
      return callback null, result if not file
      fullpath = "#{path}/#{file}"
      if /\/\.git($|\/)/.exec fullpath
        do next
      else
        fs.stat fullpath, (err, stats) ->
          return callback err, result if err
          if stats.isDirectory()
            generate_tree fullpath, (err, files) ->
              result.push {n: file, c: files}
              do next
          else
            exec 'git log -1 --format="%aD" ' + file, {cwd: path}, (err, data) ->
              item = {n: file, s: stats.size, m: data.trim()}
              if not(get_language fullpath)
                result.push item
              else
                exec 'grep -Fx "' + fullpath + '" ../source', (err, data) ->
                  item.d = 1 if data.toString().trim()
                  result.push item
              do next
    do next

#### Helpers & Setup

# Require our external dependencies, including **Showdown.js**
# (the JavaScript implementation of Markdown).
fs       = require 'fs'
path     = require 'path'
showdown = require('./../vendor/showdown').Showdown
# require 'js-yaml'
{exec}   = require 'child_process'
vendor = fs.readFileSync(__dirname + '/../vendor/linguist/lib/linguist/vendor.yml').toString()

vendor_regex = new RegExp vendor.split('\n').filter((item) -> item[0] is '-').map((item) -> (item.substr 1).trim()).join('|')

languages = require './languages'

# Ensure that the destination directory exists.
ensure_directory = (dir, callback) ->
  exec "mkdir -p #{dir}", -> callback()

# Micro-templating, originally by John Resig, borrowed by way of
# [Underscore.js](http://documentcloud.github.com/underscore/).
template = (str) ->
  new Function 'obj',
    'var p=[],print=function(){p.push.apply(p,arguments);};' +
    'with(obj){p.push(\'' +
    str.replace(/[\r\t\n]/g, " ")
       .replace(/'(?=[^<]*%>)/g,"\t")
       .split("'").join("\\'")
       .split("\t").join("'")
       .replace(/<%=(.+?)%>/g, "',$1,'")
       .split('<%').join("');")
       .split('%>').join("p.push('") +
       "');}return p.join('');"

# Create the template that we will use to generate the Docco HTML page.
index_template  = template fs.readFileSync(__dirname + '/../resources/docci.jst').toString()

# The CSS styles we'd like to apply to the documentation.
index_styles    = fs.readFileSync(__dirname + '/../resources/index.css').toString()

# Run the script.
# For each recognized source file passed in as an argument, generate the documentation. Log sources of unknown types.
destdir = process.OPTS.out ? 'docs'
ensure_directory destdir, ->
  fs.writeFile destdir + '/index.css', index_styles if !process.OPTS.css
  generate_index (process.ARGV[0]), destdir + '/index.html'
