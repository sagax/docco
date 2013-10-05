Morocco
=======

**Morocco** is a fork of [Docco](http://jashkenas.github.io/docco/), written in
[Literate CoffeeScript](http://coffeescript.org/#literate).
It produces an HTML document that displays your comments intermingled with your
code. All prose is passed through
[Markdown](http://daringfireball.net/projects/markdown/syntax), and code is
passed through [Highlight.js](http://highlightjs.org/) syntax highlighting.

1. Install Morocco with **npm**: `sudo npm install -g morocco`

2. Run it against your code: `morocco src/*.coffee`

There is no "Step 3". This will generate an HTML page for each of the named
source files, with a menu linking to the other pages, saving the whole mess
into a `docs` folder (configurable).

The [Morocco source](http://github.com/dtao/morocco) is available on GitHub,
and is released under the [MIT license](http://opensource.org/licenses/MIT).

Morocco is basically Docco plus some special logic to handle the `@examples` tag
in comments. These are parsed to generate specs that may accompany the generated
documentation.


Main Documentation Generation Functions
---------------------------------------

Generate the documentation for our configured source file by copying over static
assets, reading all the source files in, splitting them up into prose+code
sections, highlighting each file in the appropriate language, and printing them
out in an HTML template.

    document = (options = {}, callback) ->
      config = configure options

      config.onNewSection = (section) ->
        examples = null
        docLines = section.docsText.split('\n')

        for line, i in docLines
          if line.match(/^\s*@examples/)
            examples = docLines.splice(i)
            examples.shift()
            break

        if examples?
          section.docsText = docLines.join('\n')
          section.examples = for example in examples when example.indexOf('// =>') != -1
            [input, output] = example.split('// =>', 2)
            [input, output] = [trim(input), trim(output)]
            {input, output}

      fs.mkdirs config.output, ->

        callback or= (error) -> throw error if error
        copyAsset  = (file, callback) ->
          fs.copy file, path.join(config.output, path.basename(file)), callback
        complete   = ->
          copyAsset config.css, (error) ->
            if error then callback error
            else if fs.existsSync config.public then copyAsset config.public, callback
            else callback()

        files = config.sources.slice()

        nextFile = ->
          source = files.shift()
          fs.readFile source, (error, buffer) ->
            return callback error if error

            code = buffer.toString()
            sections = parse source, code, config
            format source, sections, config
            write source, sections, config
            if files.length then nextFile() else complete()

        nextFile()

Just a little helper to trim leading and trailing whitespace from a string.

    trim = (str) ->
      str.replace(/^\s+/, '').replace(/\s+$/, '')

Given a string of source code, **parse** out each block of prose and the code that
follows it — by detecting which is which, line by line — and then create an
individual **section** for it. Each section is an object with `docsText` and
`codeText` properties, and eventually `docsHtml` and `codeHtml` as well.

    parse = (source, code, config = {}) ->
      lines    = code.split '\n'
      sections = []
      lang     = getLanguage source, config
      hasCode  = docsText = codeText = ''

Provide a way for calling code to access (and, if desired, modify) sections as they
are encountered.

      handleNewSection = config.onNewSection || (section) ->

      save = ->
        section = {docsText, codeText}

Call any custom hooks that want to fiddle with the section before saving it.

        handleNewSection(section)

        sections.push section
        hasCode = docsText = codeText = ''

Our quick-and-dirty implementation of the literate programming style. Simply
invert the prose and code relationship on a per-line basis, and then continue as
normal below.

      if lang.literate
        isText = maybeCode = yes
        for line, i in lines
          lines[i] = if maybeCode and match = /^([ ]{4}|[ ]{0,3}\t)/.exec line
            isText = no
            line[match[0].length..]
          else if maybeCode = /^\s*$/.test line
            if isText then lang.symbol else ''
          else
            isText = yes
            lang.symbol + ' ' + line

      for line in lines
        if line.match(lang.commentMatcher) and not line.match(lang.commentFilter)
          save() if hasCode
          docsText += (line = line.replace(lang.commentMatcher, '')) + '\n'
          save() if /^(---+|===+)$/.test line
        else
          hasCode = yes
          codeText += line + '\n'
      save()

      sections

To **format** and highlight the now-parsed sections of code, we use **Highlight.js**
over stdio, and run the text of their corresponding comments through
**Markdown**, using [Marked](https://github.com/chjj/marked).

    format = (source, sections, config) ->
      language = getLanguage source, config

Tell Marked how to highlight code blocks within comments, treating that code
as either the language specified in the code block or the language of the file
if not specified.

      marked.setOptions {
        highlight: (code, lang) ->
          lang or= language.name

          if highlightjs.LANGUAGES[lang]
            highlightjs.highlight(lang, code).value
          else
            console.warn "morocco: couldn't highlight code block with unknown language '#{lang}' in #{source}"
            code
      }

      for section, i in sections
        code = highlightjs.highlight(language.name, section.codeText).value
        code = code.replace(/\s+$/, '')
        section.codeHtml = "<div class='highlight'><pre>#{code}</pre></div>"
        section.docsHtml = marked(section.docsText)

Once all of the code has finished highlighting, we can **write** the resulting
documentation file by passing the completed HTML sections into the template,
and rendering it to the specified output path.

    write = (source, sections, config) ->

      destination = (file) ->
        path.join(config.output, path.basename(file, path.extname(file)) + '.html')

The **title** of the file is either the first heading in the prose, or the
name of the source file.

      first = marked.lexer(sections[0].docsText)[0]
      hasTitle = first and first.type is 'heading' and first.depth is 1
      title = if hasTitle then first.text else path.basename source

      html = config.template {sources: config.sources, css: path.basename(config.css),
        title, hasTitle, sections, path, destination,}

      console.log "morocco: #{source} -> #{destination source}"
      fs.writeFileSync destination(source), html


Configuration
-------------

Default configuration **options**. All of these may be extended by
user-specified options.

    defaults =
      layout:     'parallel'
      output:     'docs'
      template:   null
      css:        null
      extension:  null
      languages:  {}

**Configure** this particular run of Morocco. We might use a passed-in external
template, or one of the built-in **layouts**. We only attempt to process
source files for languages for which we have definitions.

    configure = (options) ->
      config = _.extend {}, defaults, _.pick(options, _.keys(defaults)...)

      config.languages = buildMatchers config.languages
      if options.template
        config.layout = null
      else
        dir = config.layout = path.join __dirname, 'resources', config.layout
        config.public       = path.join dir, 'public' if fs.existsSync path.join dir, 'public'
        config.template     = path.join dir, 'docco.jst'
        config.css          = options.css or path.join dir, 'docco.css'
      config.template = _.template fs.readFileSync(config.template).toString()

      config.sources = options.args.filter((source) ->
        lang = getLanguage source, config
        console.warn "morocco: skipped unknown type (#{path.basename source})" unless lang
        lang
      ).sort()

      config


Helpers & Initial Setup
-----------------------

Require our external dependencies.

    _           = require 'underscore'
    fs          = require 'fs-extra'
    path        = require 'path'
    marked      = require 'marked'
    commander   = require 'commander'
    highlightjs = require 'highlight.js'

Enable nicer typography with marked.

    marked.setOptions smartypants: yes

Languages are stored in JSON in the file `resources/languages.json`.
Each item maps the file extension to the name of the language and the
`symbol` that indicates a line comment. To add support for a new programming
language to Morocco, just add it to the file.

    languages = JSON.parse fs.readFileSync(path.join(__dirname, 'resources', 'languages.json'))

Build out the appropriate matchers and delimiters for each language.

    buildMatchers = (languages) ->
      for ext, l of languages

Does the line begin with a comment?

        l.commentMatcher = ///^\s*#{l.symbol}\s?///

Ignore [hashbangs](http://en.wikipedia.org/wiki/Shebang_%28Unix%29) and interpolations...

        l.commentFilter = /(^#![/]|^\s*#\{)/
      languages
    languages = buildMatchers languages

A function to get the current language we're documenting, based on the
file extension. Detect and tag "literate" `.ext.md` variants.

    getLanguage = (source, config) ->
      ext  = config.extension or path.extname(source) or path.basename(source)
      lang = config.languages[ext] or languages[ext]
      if lang and lang.name is 'markdown'
        codeExt = path.extname(path.basename(source, ext))
        if codeExt and codeLang = languages[codeExt]
          lang = _.extend {}, codeLang, {literate: yes}
      lang

Keep it DRY. Extract the Morocco **version** from `package.json`

    version = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'))).version


Command Line Interface
----------------------

Finally, let's define the interface to run Morocco from the command line.
Parse options using [Commander](https://github.com/visionmedia/commander.js).

    run = (args = process.argv) ->
      c = defaults
      commander.version(version)
        .usage('[options] files')
        .option('-L, --languages [file]', 'use a custom languages.json', _.compose JSON.parse, fs.readFileSync)
        .option('-l, --layout [name]',    'choose a layout (parallel, linear or classic)', c.layout)
        .option('-o, --output [path]',    'output to a given folder', c.output)
        .option('-c, --css [file]',       'use a custom css file', c.css)
        .option('-t, --template [file]',  'use a custom .jst template', c.template)
        .option('-e, --extension [ext]',  'assume a file extension for all inputs', c.extension)
        .parse(args)
        .name = "morocco"
      if commander.args.length
        document commander
      else
        console.log commander.helpInformation()


Public API
----------

    Morocco = module.exports = {run, document, parse, format, version}
