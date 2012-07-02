#     Documentation Generator

# **Docco** is a quick-and-dirty, hundred-line-long, literate-programming-style
# documentation generator. It produces HTML
# that displays your comments alongside your code. Comments are passed through
# [Markdown](http://daringfireball.net/projects/markdown/syntax), and code is
# passed through [Pygments](http://pygments.org/) syntax highlighting.
# This page is the result of running Docco against its own source file.
#
# If you install Docco, you can run it from the command-line:
#
#     docco src/*.coffee
#
# ...will generate an HTML documentation page for each of the named source files, 
# with a menu linking to the other pages, saving it into a `docs` folder.
#
# The [source for Docco](http://github.com/jashkenas/docco) is available on GitHub,
# and released under the MIT license.
#
# To install Docco, first make sure you have [Node.js](http://nodejs.org/),
# [Pygments](http://pygments.org/) (install the latest dev version of Pygments
# from [its Mercurial repo](http://dev.pocoo.org/hg/pygments-main)), and
# [CoffeeScript](http://coffeescript.org/). Then, with NPM:
#
#     sudo npm install -g docco
#
# Docco can be used to process CoffeeScript, JavaScript, Ruby, Python, or TeX files.
# Only single-line comments are processed -- block comments are ignored.
#
#### Partners in Crime:
#
# * If **Node.js** doesn't run on your platform, or you'd prefer a more 
# convenient package, get [Ryan Tomayko](http://github.com/rtomayko)'s 
# [Rocco](http://rtomayko.github.com/rocco/rocco.html), the Ruby port that's 
# available as a gem. 
# 
# * If you're writing shell scripts, try
# [Shocco](http://rtomayko.github.com/shocco/), a port for the **POSIX shell**,
# also by Mr. Tomayko.
# 
# * If Python's more your speed, take a look at 
# [Nick Fitzgerald](http://github.com/fitzgen)'s [Pycco](http://fitzgen.github.com/pycco/). 
#
# * For **Clojure** fans, [Fogus](http://blog.fogus.me/)'s 
# [Marginalia](http://fogus.me/fun/marginalia/) is a bit of a departure from 
# "quick-and-dirty", but it'll get the job done.
#
# * **Lua** enthusiasts can get their fix with 
# [Robert Gieseke](https://github.com/rgieseke)'s [Locco](http://rgieseke.github.com/locco/).
# 
# * And if you happen to be a **.NET**
# aficionado, check out [Don Wilson](https://github.com/dontangg)'s 
# [Nocco](http://dontangg.github.com/nocco/).
_ = require 'underscore'
fs = require 'fs'
http = require 'http'
querystring = require 'querystring'
config = {}
try
  config = require('./config_parser').parse ".docas/conf"

#### Main Documentation Generation Functions

# Generate the documentation for a source file by reading it in, splitting it
# up into comment/code sections, highlighting them for the appropriate language,
# and merging them into an HTML template.
generate_documentation = (source, callback) ->
  fs.readFile (get_real_source source), "utf-8", (error, code) ->
    
    throw error if error
    
    {description, sections} = parse source, code
    highlight source, sections, ->
      if /[^_]_$/.exec path.extname source
        if sections.length > 0 and sections[0].code_text[0..1] is '#!'
          code_html = sections[0].code_text.split(' ') \
            .map((x) -> "<span>#{x}</span>").join(' ')
          sections[0].code_html = "<div class=\"highlight shebang\"><pre>#{code_html}</pre></div>"
          if sections[0].code_text.trim().length and sections.length > 1
            tmp = sections[0]
            sections[0] = sections[1]
            sections[1] = tmp
          # if sections[0].code_text.trim().length > 0
          #   idx = 1
          #   while idx < sections.length and not sections[idx].code_text.trim().length
          #     idx += 1
          #   if idx < sections.length
          #     sections.splice idx, 0, sections[0]
          #     sections.splice 0, 1
      depth = source.split('/').length - 1
      if depth then css = [0..depth-1].map(-> '..').join('/') + '/stylesheets/docco.min.css' else css = 'stylesheets/docco.min.css'
      generate_html source, css, sections, description, depth
      callback()

# Given a string of source code, parse out each comment and the code that
# follows it, and create an individual **section** for it.
# Sections take the form:
#
#     {
#       docs_text: ...
#       docs_html: ...
#       code_text: ...
#       code_html: ...
#     }
#
parse = (source, code) ->
  lines    = code.split '\n'
  sections = []
  language = get_language source
  has_code = docs_text = code_text = ''

  save = (docs, code) ->
    sections.push docs_text: docs, code_text: code

  if lines[0].match(language.comment_matcher) and not lines[0].match(language.comment_filter)
    if lines[1] is ''
      description = lines[0].replace(language.comment_matcher, '').trim()
    else
      description = ''
  else description = ''

  for line in lines
    if line.match(language.comment_matcher) and not line.match(language.comment_filter)
      if has_code
        save docs_text, code_text
        has_code = docs_text = code_text = ''
      docs_text += line.replace(language.comment_matcher, '') + '\n'
    else
      has_code = yes
      code_text += line + '\n'
  save docs_text, code_text
  {
    description: description
    sections: sections
  }

pygments_http_ports = [5923, 5924, 5925, 5926]

rand_port = ->
  # pygments_http_ports.push (pygments_http_ports.splice 0, 1)...
  pygments_http_ports.pop()

# Highlights a single chunk of CoffeeScript code, using **Pygments** over stdio,
# and runs the text of its corresponding comment through **Markdown**, using
# [Showdown.js](http://attacklab.net/showdown/).
#
# We process the entire file in a single call to Pygments by inserting little
# marker comments between each section and then splitting the result string
# wherever our markers occur.
highlight = (source, sections, callback) ->
  language = get_language source

  post_data = querystring.stringify
    lang: language.name
    code: (section.code_text for section in sections).join(language.divider_text)
  
  current_port = rand_port()
  options = 
    host: '127.0.0.1'
    path: '/pygments'
    method: 'POST'
    port: current_port
    headers:
      'Content-Type': 'application/x-www-form-urlencoded'
      'Content-Length': post_data.length
  
  output = ''
  
  do (current_port) ->

    req = http.request options, (res) ->
      res.setEncoding('utf8')
      res.on 'data', (result) ->
        output += result if result
      res.on 'end', ->
        pygments_http_ports.push current_port
        output = output.replace(highlight_start, '').replace(highlight_end, '')
        fragments = output.split language.divider_html
        for section, i in sections
          section.code_html = highlight_start + fragments[i] + highlight_end
          section.docs_html = showdown.makeHtml section.docs_text
        callback()
    
    req.write post_data
    req.end()
    # console.log 'pygmenting', source

# Once all of the code is finished highlighting, we can generate the HTML file
# and write out the documentation. Pass the completed sections into the template
# found in `resources/docco.jst`
generate_html = (source, css, sections, description, depth) ->
  real_source = get_real_source source
  title_segments = real_source.split('/')
  title_segments.shift() if title_segments[0] is '.'
  head_title = process.OPTS.repo + ' » ' + title_segments.join(' › ') #  path.basename real_source source
  title = title_segments[title_segments.length - 1]
  dest  = destination source
  depth = source.split('/').length - 1
  if depth then root_dir = [0..depth-1].map(-> '..').join('/') + '/' else root_dir = ''

  javascripts = []
  for pattern, javascript of config.page_javascripts
    if match = real_source.match new RegExp "^#{pattern.replace('*', '(.*)')}$"
      javascript = javascript.replace('[1]', (match[1] or '')).replace('[2]', (match[2] or '')).replace('[3]', (match[3] or ''))
      javascripts.push root_dir + 'docas/' + javascript

  stylesheets = []
  for pattern, stylesheet of config.page_stylesheets
    if match = real_source.match new RegExp "^#{pattern.replace('*', '(.*)')}$"
      stylesheet = stylesheet.replace('[1]', (match[1] or '')).replace('[2]', (match[2] or '')).replace('[3]', (match[3] or ''))
      stylesheets.push root_dir + 'docas/' + stylesheet

  html  = docco_template {
    head_title: head_title
    root: root_dir + (config.project_page or 'index.html')
    title: title
    sections: sections
    css: css
    javascripts: javascripts
    stylesheets: stylesheets
    google_analytics: config.google_analytics
    description: description
    depth: depth
    repo: process.OPTS.repo
  }
  console.log "docco: #{source} -> #{dest}"
  ensure_directory (path.dirname dest), ->
    fs.writeFile dest, html

#### Helpers & Setup

# Require our external dependencies, including **Showdown.js**
# (the JavaScript implementation of Markdown).
fs       = require 'fs'
path     = require 'path'
showdown = require('../../vendor/showdown').Showdown
{spawn, exec} = require 'child_process'

# A list of the languages that Docco supports, mapping the file extension to
# the name of the Pygments lexer and the symbol that indicates a comment. To
# add another language to Docco's repertoire, add it here.
languages = require './languages'

# Build out the appropriate matchers and delimiters for each language.
for ext, l of languages

  # Does the line begin with a comment?
  l.comment_matcher = new RegExp('^\\s*' + l.symbol + '\\s?')

  # Ignore [hashbangs](http://en.wikipedia.org/wiki/Shebang_(Unix\))
  # and interpolations...
  l.comment_filter = new RegExp('(^#![/]|^\\s*#\\{)')

  # The dividing token we feed into Pygments, to delimit the boundaries between
  # sections.
  l.divider_text = '\n' + l.symbol + 'DIVIDER\n'

  # The mirror of `divider_text` that we expect Pygments to return. We can split
  # on this to recover the original sections.
  # Note: the class is "c" for Python and "c1" for the other languages
  l.divider_html = new RegExp('\\n*<span class="c1?">' + l.symbol + 'DIVIDER<\\/span>\\n*')

# Get the current language we're documenting, based on the extension.
get_language = (source) ->
  extname = path.extname source
  extname = extname.substr 0, extname.length - 1 if /[^_]_$/.exec extname
  languages[extname.replace '__', '_']

# Compute the destination HTML path for an input source file path. If the source
# is `lib/example.coffee`, the HTML will be at `docs/example.html`
destination = (filepath) ->
  destdir + '/' + (path.dirname filepath) + '/' + (path.basename(filepath, path.extname(filepath))) + '.html'

# Ensure that the destination directory exists.
ensure_directory = (dir, callback) ->
  exec "mkdir -p #{dir}", -> callback()

# Create the template that we will use to generate the Docco HTML page.
docco_template  = _.template fs.readFileSync __dirname + '/../../resources/docco.jst', 'utf-8'

# The start of each Pygments highlight block.
highlight_start = '<div class="highlight"><pre>'

# The end of each Pygments highlight block.
highlight_end   = '</pre></div>'

# To correctly recognize shebang scripts, a pseduo extname should be passed
# in, such as bin/docco.js_, the last underscore indicates there's no extname
# actually. Dirty? But works:)
get_real_source = (source) ->
  dirname  = path.dirname  source
  extname  = path.extname  source
  basename = path.basename source, extname
  extname  = if not /[^_]_$/.exec extname then extname.replace '__', '_' else ''
  "#{dirname}/#{basename}#{extname}"

# Run the script.
# For each recognized source file passed in as an argument, generate the documentation. Log sources of unknown types.

markdowns = process.ARGV.filter((source) -> source.substr(source.length - 3) is '.md')
for markdown in markdowns
  do (markdown) ->
    fs.readFile markdown, 'utf-8', (err, res) ->
      html = showdown.makeHtml res
      dest_file = destination markdown
      ensure_directory (path.dirname dest_file), ->
        fs.writeFile dest_file, html

sources = process.ARGV.filter((source) -> (get_language source) ? console.log "Unknown Type: #{source}").sort()
destdir = process.OPTS.out ? 'docs'
if sources.length
  ensure_directory destdir, ->
    next_file = ->
      generate_documentation sources.shift(), ->
        next_file() if sources.length
    current_parallel = 0
    while current_parallel++ < 4
      next_file() if sources.length
